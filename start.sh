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
        if ! lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
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

# Check FreeSurfer license
if [ ! -f "license.txt" ]; then
    log_error "FreeSurfer license not found: license.txt"
    log_error "Please run './install.sh' or set up your license manually"
    exit 1
fi

if grep -q "REPLACE THIS EXAMPLE CONTENT" license.txt 2>/dev/null; then
    log_error "license.txt contains example content"
    log_error "Please replace with your actual FreeSurfer license"
    exit 1
fi

log_success "FreeSurfer license verified"

# Start Redis container
log_info "Starting Redis..."
if docker ps | grep -q neuroinsight-redis; then
    log_info "Redis already running"
else
    docker-compose -f docker-compose.hybrid.yml up -d redis
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
PORT=$PORT python3 backend/main.py > neuroinsight.log 2>&1 &
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
