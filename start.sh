#!/usr/bin/env python3
"""
NeuroInsight Start Script - Python-based for reliability
Bypasses terminal corruption issues by using Python directly
"""

import os
import sys
import subprocess
import time
import signal
import psutil
import requests
from pathlib import Path

# Colors for output
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'

def log_info(msg):
    print(f"{BLUE}[INFO]{NC} {msg}")

def log_success(msg):
    print(f"{GREEN}[SUCCESS]{NC} {msg}")

def log_warning(msg):
    print(f"{YELLOW}[WARNING]{NC} {msg}")

def log_error(msg):
    print(f"{RED}[ERROR]{NC} {msg}")

def find_and_kill_processes():
    """Aggressively find and kill all NeuroInsight processes"""
    killed_count = 0

    # Kill by command patterns
    patterns = [
        "python3.*backend/main.py",
        "python3.*celery.*processing_web",
        "python3.*job_monitor"
    ]

    for pattern in patterns:
        try:
            # Use pgrep to find processes
            result = subprocess.run(['pgrep', '-f', pattern],
                                  capture_output=True, text=True)
            if result.returncode == 0:
                pids = result.stdout.strip().split('\n')
                for pid in pids:
                    if pid.strip():
                        try:
                            os.kill(int(pid), signal.SIGKILL)
                            killed_count += 1
                            log_info(f"Killed process {pid}")
                        except (ProcessLookupError, OSError):
                            pass  # Process already dead
        except Exception as e:
            log_warning(f"Error killing {pattern}: {e}")

    # Also try pkill as fallback
    try:
        subprocess.run(['pkill', '-9', '-f', 'neuroinsight'], check=False)
        subprocess.run(['pkill', '-9', '-f', 'backend/main.py'], check=False)
        subprocess.run(['pkill', '-9', '-f', 'celery.*processing_web'], check=False)
    except Exception:
        pass

    if killed_count > 0:
        log_success(f"Cleaned up {killed_count} existing processes")
        time.sleep(2)  # Wait for cleanup

    return killed_count

def check_port_available(port):
    """Check if a port is available"""
    import socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        result = sock.connect_ex(('localhost', port))
        return result != 0  # True if available

def find_available_port(start_port=8000, end_port=8050):
    """Find an available port in the range"""
    for port in range(start_port, end_port + 1):
        if check_port_available(port):
            return port
    return None

def start_docker_services():
    """Start Docker services"""
    try:
        log_info("Starting Docker services...")
        # Detect docker compose command
        if subprocess.run(['docker', 'compose', 'version'],
                         capture_output=True).returncode == 0:
            docker_cmd = ['docker', 'compose']
        else:
            docker_cmd = ['docker-compose']

        # Start services
        result = subprocess.run(docker_cmd + ['-f', 'docker-compose.hybrid.yml', 'up', '-d', 'redis', 'postgres', 'minio'],
                              capture_output=True, text=True, cwd='.')

        if result.returncode == 0:
            log_success("Docker services started")
            return True
        else:
            log_error(f"Docker startup failed: {result.stderr}")
            return False

    except Exception as e:
        log_error(f"Docker error: {e}")
        return False

def start_backend(port):
    """Start the NeuroInsight backend"""
    try:
        log_info(f"Starting NeuroInsight backend on port {port}...")

        # Set environment
        env = os.environ.copy()
        env['PYTHONPATH'] = str(Path.cwd())
        env['API_PORT'] = str(port)
        env['PORT'] = str(port)

        # Start backend
        proc = subprocess.Popen([
            sys.executable, 'backend/main.py'
        ], env=env, stdout=open('neuroinsight.log', 'w'),
           stderr=subprocess.STDOUT)

        # Save PID
        with open('neuroinsight.pid', 'w') as f:
            f.write(str(proc.pid))

        log_success(f"Backend started (PID: {proc.pid})")

        # Wait for health check
        log_info("Waiting for backend to be ready...")
        for i in range(30):  # 30 second timeout
            try:
                response = requests.get(f'http://localhost:{port}/health', timeout=2)
                if response.status_code == 200:
                    log_success("Backend health check passed!")
                    return proc
            except:
                pass
            time.sleep(1)

        log_error("Backend failed to respond to health checks")
        proc.kill()
        return None

    except Exception as e:
        log_error(f"Backend startup failed: {e}")
        return None

def start_celery():
    """Start Celery worker"""
    try:
        log_info("Starting Celery worker...")

        # Set environment
        env = os.environ.copy()
        env['PYTHONPATH'] = str(Path.cwd())

        # Start celery
        proc = subprocess.Popen([
            sys.executable, '-m', 'celery',
            '-A', 'workers.tasks.processing_web',
            'worker', '--loglevel=info', '--concurrency=1'
        ], env=env, stdout=open('celery_worker.log', 'w'),
           stderr=subprocess.STDOUT)

        # Save PID
        with open('celery.pid', 'w') as f:
            f.write(str(proc.pid))

        log_success(f"Celery worker started (PID: {proc.pid})")
        return proc

    except Exception as e:
        log_error(f"Celery startup failed: {e}")
        return None

def start_job_monitor():
    """Start job monitoring service"""
    try:
        log_info("Starting job monitor...")

        # Set environment
        env = os.environ.copy()
        env['PYTHONPATH'] = str(Path.cwd())

        # Start monitor
        proc = subprocess.Popen([
            sys.executable, '-c',
            """
import sys
sys.path.insert(0, '.')
from backend.services.job_monitor import JobMonitor
monitor = JobMonitor()
monitor.start_background_monitoring()
"""
        ], env=env, stdout=open('job_monitor.log', 'w'),
           stderr=subprocess.STDOUT)

        # Save PID
        with open('job_monitor.pid', 'w') as f:
            f.write(str(proc.pid))

        log_success(f"Job monitor started (PID: {proc.pid})")
        return proc

    except Exception as e:
        log_error(f"Job monitor startup failed: {e}")
        return None

def main():
    print("=" * 50)
    print("   NeuroInsight Startup (Python-based)")
    print("=" * 50)
    print()

    # Change to script directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)

    # Clean up existing processes
    log_info("Cleaning up any existing NeuroInsight processes...")
    killed = find_and_kill_processes()

    # Start Docker services
    if not start_docker_services():
        log_error("Failed to start Docker services")
        sys.exit(1)

    # Find available port
    port = find_available_port()
    if not port:
        log_error("No available ports found in range 8000-8050")
        sys.exit(1)

    log_success(f"Selected port: {port}")

    # Start backend
    backend_proc = start_backend(port)
    if not backend_proc:
        log_error("Failed to start backend")
        sys.exit(1)

    # Start Celery worker
    celery_proc = start_celery()
    if not celery_proc:
        log_warning("Celery worker failed to start - continuing anyway")

    # Start job monitor
    monitor_proc = start_job_monitor()
    if not monitor_proc:
        log_warning("Job monitor failed to start - continuing anyway")

    print()
    print("=" * 50)
    log_success("NeuroInsight is running!")
    print(f"   🌐 Web Interface: http://localhost:{port}")
    print(f"   📊 API Docs: http://localhost:{port}/docs")
    print(f"   🔍 Health Check: http://localhost:{port}/health")
    print()
    print("Management commands:")
    print("  ./status.sh    # Check system status")
    print("  ./stop.sh      # Stop all services")
    print("  ./monitor.sh   # Advanced monitoring")
    print("=" * 50)

if __name__ == "__main__":
    main()

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect available Docker Compose command
detect_docker_compose() {
    if command -v docker &> /dev/null; then
        # Try new syntax first (Docker Compose V2)
        if docker compose version &> /dev/null 2>&1; then
            echo "docker compose"
        # Fall back to old syntax
        elif docker-compose --version &> /dev/null 2>&1; then
            echo "docker-compose"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

DOCKER_COMPOSE_CMD=$(detect_docker_compose)

# Check if Docker Compose is available
if [ -z "$DOCKER_COMPOSE_CMD" ]; then
    log_error "Docker Compose not found. Please ensure Docker Desktop is running and WSL2 integration is enabled."
    log_error "For WSL2 setup: https://docs.docker.com/desktop/wsl/"
    exit 1
fi

log_success "Using Docker Compose: $DOCKER_COMPOSE_CMD"

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if already running and clean up any orphaned processes
log_info "Checking for existing NeuroInsight processes..."

# Check for backend process
EXISTING_BACKEND=$(pgrep -f "python3.*backend/main.py" 2>/dev/null || true)
if [ ! -z "$EXISTING_BACKEND" ]; then
    log_warning "Found existing backend process(es): $EXISTING_BACKEND"
    log_warning "Stopping existing processes..."
    ./stop.sh >/dev/null 2>&1 || true
    sleep 3
fi

# Double-check cleanup
EXISTING_BACKEND=$(pgrep -f "python3.*backend/main.py" 2>/dev/null || true)
EXISTING_CELERY=$(pgrep -f "python3.*celery.*processing_web" 2>/dev/null || true)

if [ ! -z "$EXISTING_BACKEND" ] || [ ! -z "$EXISTING_CELERY" ]; then
    log_error "Failed to clean up existing processes. Please run './stop.sh' manually."
    log_error "Existing backend: $EXISTING_BACKEND"
    log_error "Existing Celery: $EXISTING_CELERY"
    exit 1
fi

# Clean up any stale PID files
rm -f neuroinsight.pid celery.pid job_monitor.pid

# Port configuration - auto-select available port or use custom
if [ -z "$PORT" ]; then
    # No custom port specified, find available port in range 8000-8050
    log_info "Finding available port (8000-8050)..."

    for port in {8000..8050}; do
        if ! lsof -i :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            PORT=$port
            log_success "Auto-selected available port: $PORT"
            break
        fi
    done

    if [ -z "$PORT" ]; then
        log_error "No available ports found in range 8000-8050!"
        log_error "Please free up some ports or specify a custom port:"
        echo "   export PORT=8051"
        echo "   ./start.sh"
        exit 1
    fi
else
    # Custom port specified by user
    log_info "Using custom port: $PORT"
fi

# Check if port is available
check_port_available() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1  # Port is in use
    else
        return 0  # Port is available
    fi
}

# Final verification of selected port
if ! check_port_available $PORT; then
    log_error "Port $PORT is not available!"
    echo
    log_info "PORT CONFLICT RESOLUTION OPTIONS:"
    echo
    echo "1. Let NeuroInsight auto-select a port:"
    echo "   unset PORT  # or remove PORT from environment"
    echo "   ./start.sh"
    echo
    echo "2. Specify a different custom port:"
    echo "   export PORT=8051"
    echo "   ./start.sh"
    echo
    echo "3. Find what's using port $PORT:"
    echo "   sudo lsof -i :$PORT"
    echo "   sudo netstat -tulpn | grep :$PORT"
    echo
    echo "4. Free up the port (use with caution):"
    echo "   sudo fuser -k $PORT/tcp"
    echo
    exit 1
fi

log_info "Starting NeuroInsight services..."

# Check FreeSurfer license - Auto-detect license.txt
LICENSE_FOUND=false
LICENSE_VALID=false

if [ -f "license.txt" ]; then
    LICENSE_FOUND=true
    # Check if it contains real license content (not example text)
    if ! grep -q "REPLACE THIS EXAMPLE CONTENT" license.txt 2>/dev/null && \
       ! grep -q "FreeSurfer License File - EXAMPLE" license.txt 2>/dev/null && \
       [ $(wc -l < license.txt) -ge 4 ]; then
        LICENSE_VALID=true
        log_success "FreeSurfer license found and valid: license.txt"
    else
        log_warning "license.txt found but appears to contain example content"
        log_info "Please replace license.txt with your real FreeSurfer license"
        log_info "Get your free license at: https://surfer.nmr.mgh.harvard.edu/registration.html"
    fi
else
    log_warning "FreeSurfer license not found: license.txt"
    log_info "To enable MRI processing and visualizations:"
    log_info "1. Register at: https://surfer.nmr.mgh.harvard.edu/registration.html"
    log_info "2. Download your license.txt file"
    log_info "3. Place license.txt in this directory (same folder as NeuroInsight)"
    log_info "4. Restart with: ./start.sh"
fi

# Check system memory and provide recommendations
log_info "Checking system memory..."
TOTAL_MEM_GB=$(free -g | awk 'NR==2{printf "%.1f", $2}')
AVAILABLE_MEM_GB=$(free -g | awk 'NR==2{printf "%.1f", $7}')

if (( $(echo "$TOTAL_MEM_GB < 7" | bc -l) )); then
    log_error "CRITICAL: Insufficient memory for NeuroInsight"
    log_error "Total RAM: ${TOTAL_MEM_GB}GB (minimum 7GB required)"
    log_error "NeuroInsight cannot run on systems with less than 7GB RAM"
    exit 1
elif (( $(echo "$TOTAL_MEM_GB < 16" | bc -l) )); then
    log_warning "LIMITED MEMORY: ${TOTAL_MEM_GB}GB detected"
    log_warning "MRI processing may fail due to insufficient RAM"
    log_warning "For reliable MRI processing, upgrade to 16GB+ RAM"
    log_warning "FreeSurfer segmentation requires 4-8GB per brain"
    log_info "Continuing startup, but processing failures are likely..."
elif (( $(echo "$TOTAL_MEM_GB < 32" | bc -l) )); then
    log_info "Memory: ${TOTAL_MEM_GB}GB (adequate for basic processing)"
    log_info "For optimal performance, consider 32GB+ RAM"
else
    log_success "Memory: ${TOTAL_MEM_GB}GB (optimal for NeuroInsight)"
fi

# Check available disk space
log_info "Checking disk space..."
AVAILABLE_SPACE_GB=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ $AVAILABLE_SPACE_GB -lt 10 ]; then
    log_error "Insufficient disk space: ${AVAILABLE_SPACE_GB}GB available, minimum 10GB required"
    log_error "Please free up disk space before starting NeuroInsight"
    exit 1
elif [ $AVAILABLE_SPACE_GB -lt 50 ]; then
    log_warning "Limited disk space: ${AVAILABLE_SPACE_GB}GB available"
    log_warning "Consider 50GB+ for processing multiple MRI scans"
    log_warning "Temporary files during processing may exhaust disk space"
else
    log_success "Disk space: ${AVAILABLE_SPACE_GB}GB available"
fi

# Port availability already checked above during auto-selection

# Validate Python version
log_info "Validating Python version..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

    if [ $PYTHON_MAJOR -eq 3 ] && [ $PYTHON_MINOR -ge 8 ] && [ $PYTHON_MINOR -le 12 ]; then
        log_success "Python version: ${PYTHON_VERSION} (compatible)"
    else
        log_error "Python version ${PYTHON_VERSION} may not be compatible"
        log_error "Recommended: Python 3.8 - 3.12"
        exit 1
    fi
else
    log_error "Python 3 not found. Please install Python 3.8+"
    exit 1
fi

# Validate Docker availability
log_info "Validating Docker availability..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | sed 's/Docker version //' | cut -d, -f1)
    log_success "Docker available: ${DOCKER_VERSION}"
else
    log_error "Docker not found. Please install Docker"
    log_error "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Allow app to start even without license (graceful degradation)
if [ "$LICENSE_VALID" = true ]; then
    log_success "NeuroInsight ready with FreeSurfer support"
else
    log_warning "Starting without FreeSurfer support - MRI processing will use mock data"
    log_info "Add license.txt to enable real FreeSurfer segmentation and visualizations"
fi

# Start Redis container
log_info "Starting Redis..."
if docker ps | grep -q neuroinsight-redis; then
    log_info "Redis already running"
else
    $DOCKER_COMPOSE_CMD -f docker-compose.hybrid.yml up -d redis
    sleep 3
    
    if docker ps | grep -q neuroinsight-redis; then
        log_success "Redis started"
    else
        log_error "Failed to start Redis"
        exit 1
    fi
fi

# Activate virtual environment
log_info "Activating Python environment..."
if [ ! -d "venv" ]; then
    log_error "Python virtual environment not found. Please run './install.sh' first"
    exit 1
fi

source venv/bin/activate

# Start backend
log_info "Starting NeuroInsight backend..."
API_PORT=$PORT PORT=$PORT PYTHONPATH="$(pwd)" python3 backend/main.py > neuroinsight.log 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > neuroinsight.pid

log_success "Backend started (PID: $BACKEND_PID)"

# Wait for backend to be healthy
log_info "Waiting for backend to be ready..."
MAX_WAIT=30
WAIT_COUNT=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if curl -s http://localhost:$PORT/health > /dev/null 2>&1; then
        break
    fi
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [ $WAIT_COUNT -eq $MAX_WAIT ]; then
    log_error "Backend failed to start within $MAX_WAIT seconds"
    log_error "Check neuroinsight.log for details"
    exit 1
fi

log_success "Backend health check passed"

# Start Celery worker
log_info "Starting Celery worker..."
python3 -m celery -A workers.tasks.processing_web worker --loglevel=info --concurrency=1 > celery_worker.log 2>&1 &
WORKER_PID=$!
echo $WORKER_PID > celery.pid

log_success "Celery worker started (PID: $WORKER_PID)"

# Final verification
sleep 3

# Run maintenance to detect any interrupted jobs from previous sessions
log_info "Running maintenance to detect interrupted jobs..."
if python3 -c "
import sys
sys.path.insert(0, '.')
from backend.services.task_management_service import TaskManagementService
result = TaskManagementService.run_maintenance()
print(f' Maintenance completed: {result}')
" 2>/dev/null; then
    log_success "Maintenance check completed"
else
    log_warning "Maintenance check failed"
fi

# Start background monitoring for interrupted jobs
log_info "Starting background job monitoring..."
if python3 -c "
import sys
sys.path.insert(0, '.')
from backend.services.job_monitor import JobMonitor
try:
    monitor = JobMonitor()
    monitor.start_background_monitoring()
    print('Background monitoring started successfully')
except Exception as e:
    print(f'Error starting background monitoring: {e}')
    exit(1)
" 2>/dev/null; then
    log_success "Background job monitoring started"
else
    log_warning "Background monitoring failed to start - jobs may not auto-process on completion"
fi

# Start periodic system health monitoring
log_info "Starting periodic system health monitoring..."
if nohup ./monitor.sh full > monitor.log 2>&1 &
then
    MONITOR_PID=$!
    echo $MONITOR_PID > monitor.pid
    log_success "System health monitoring started (PID: $MONITOR_PID)"
    log_info "Monitor logs: monitor.log"
else
    log_warning "Failed to start system health monitoring"
fi

# Start processing any pending jobs automatically
log_info "Checking for pending jobs to process..."
if python3 -c "
import sys
sys.path.insert(0, '.')
from backend.core.database import get_db
from backend.services.job_service import JobService

try:
    db = next(get_db())
    pending_count = JobService.count_jobs_by_status(db, ['PENDING'])
    running_count = JobService.count_jobs_by_status(db, ['RUNNING'])

    if pending_count > 0:
        print(f'Found {pending_count} pending job(s), starting queue processing...')
        JobService.process_job_queue(db)
        print('Job queue processing initiated successfully')
    else:
        print('No pending jobs found')

except Exception as e:
    print(f'Error during job queue processing: {e}')
    exit(1)
"; then
    log_success "Job queue processing completed successfully"
else
    log_warning "Job queue processing failed - you can run 'python3 trigger_queue.py' manually"
fi

if curl -s http://localhost:$PORT/health > /dev/null 2>&1; then
    log_success "NeuroInsight is running!"
    echo
    echo "Web Interface: http://localhost:$PORT"
    echo "API Documentation: http://localhost:$PORT/docs"
    echo "Service Status: ./status.sh"
    echo "Stop Services: ./stop.sh"
    echo
    echo "Log files:"
    echo "  Backend: neuroinsight.log"
    echo "  Worker: celery_worker.log"
else
    log_error "Services failed to start properly"
    log_error "Check logs for details"
    exit 1
fi

log_info "NeuroInsight startup complete"
