#!/bin/bash
# NeuroInsight Start Script
# Starts all services for the hybrid deployment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if already running
if [ -f "neuroinsight.pid" ]; then
    if kill -0 $(cat neuroinsight.pid) 2>/dev/null; then
        log_warning "NeuroInsight appears to be already running (PID: $(cat neuroinsight.pid))"
        log_warning "Use './stop.sh' first if you want to restart"
        exit 1
    else
        log_info "Removing stale PID file"
        rm -f neuroinsight.pid
    fi
fi

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

# Check port availability
log_info "Checking port availability..."
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    log_error "Port 8000 is already in use"
    log_error "Please stop the conflicting service or choose a different port"
    log_info "To find what's using port 8000: sudo lsof -i :8000"
    exit 1
else
    log_success "Port 8000 is available"
fi

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
PORT=$PORT PYTHONPATH="$(pwd)" python3 backend/main.py > neuroinsight.log 2>&1 &
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
print(f'✅ Maintenance completed: {result}')
" 2>/dev/null; then
    log_success "Maintenance check completed"
else
    log_warning "Maintenance check failed"
fi

# Start background monitoring for interrupted jobs
log_info "Starting background job monitoring..."
python3 -c "
import sys
sys.path.insert(0, '.')
from backend.services.job_monitor import JobMonitor
monitor = JobMonitor()
monitor.start_background_monitoring()
" 2>/dev/null && log_success "Background job monitoring started" || log_warning "Background monitoring failed to start"

# Start processing any pending jobs automatically
log_info "Checking for pending jobs to process..."
if python3 trigger_queue.py 2>/dev/null; then
    log_success "Job queue processing initiated"
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
