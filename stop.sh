#!/bin/bash
# NeuroInsight Stop Script
# Gracefully stops all services

set -e

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

log_info "Stopping NeuroInsight services..."

# Stop Celery worker
if [ -f "celery.pid" ]; then
    WORKER_PID=$(cat celery.pid)
    if kill -0 $WORKER_PID 2>/dev/null; then
        log_info "Stopping Celery worker (PID: $WORKER_PID)..."
        kill $WORKER_PID 2>/dev/null || true
        
        # Wait for graceful shutdown
        WAIT_COUNT=0
        while kill -0 $WORKER_PID 2>/dev/null && [ $WAIT_COUNT -lt 10 ]; do
            sleep 1
            WAIT_COUNT=$((WAIT_COUNT + 1))
        done
        
        if kill -0 $WORKER_PID 2>/dev/null; then
            log_warning "Worker didn't stop gracefully, forcing..."
            kill -9 $WORKER_PID 2>/dev/null || true
        fi
    else
        log_warning "Worker PID file exists but process not running"
    fi
    rm -f celery.pid
    log_success "Celery worker stopped"
else
    log_info "No Celery worker PID file found"
fi

# Stop backend
if [ -f "neuroinsight.pid" ]; then
    BACKEND_PID=$(cat neuroinsight.pid)
    if kill -0 $BACKEND_PID 2>/dev/null; then
        log_info "Stopping backend (PID: $BACKEND_PID)..."
        kill $BACKEND_PID 2>/dev/null || true
        
        # Wait for graceful shutdown
        WAIT_COUNT=0
        while kill -0 $BACKEND_PID 2>/dev/null && [ $WAIT_COUNT -lt 10 ]; do
            sleep 1
            WAIT_COUNT=$((WAIT_COUNT + 1))
        done
        
        if kill -0 $BACKEND_PID 2>/dev/null; then
            log_warning "Backend didn't stop gracefully, forcing..."
            kill -9 $BACKEND_PID 2>/dev/null || true
        fi
    else
        log_warning "Backend PID file exists but process not running"
    fi
    rm -f neuroinsight.pid
    log_success "Backend stopped"
else
    log_info "No backend PID file found"
fi

# Stop Docker containers
log_info "Stopping Docker containers..."
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
$DOCKER_COMPOSE_CMD -f docker-compose.hybrid.yml down 2>/dev/null || true

# Check for any remaining containers
if docker ps | grep -q neuroinsight; then
    log_warning "Some NeuroInsight containers still running"
    docker ps | grep neuroinsight
else
    log_success "All containers stopped"
fi

log_success "NeuroInsight services stopped"

# Clear stuck jobs if requested
if [ "$1" = "--clear-stuck" ]; then
    log_info "Clearing stuck jobs..."
    python3 -c "
import sys
sys.path.insert(0, '.')
from datetime import datetime, timedelta
from backend.core.database import get_db
from backend.models.job import Job, JobStatus

db = next(get_db())
now = datetime.utcnow()
timeout_hours = 2
cleared_count = 0

running_jobs = db.query(Job).filter(Job.status == JobStatus.RUNNING).all()
for job in running_jobs:
    if job.started_at and (now - job.started_at) > timedelta(hours=timeout_hours):
        job.status = JobStatus.FAILED
        job.error_message = f'Auto-cleared: Job stuck for >{timeout_hours} hours'
        job.completed_at = now
        cleared_count += 1
        print(f'Cleared stuck job: {job.id}')

if cleared_count > 0:
    db.commit()
    print(f'✅ Cleared {cleared_count} stuck job(s)')
else:
    print('ℹ️  No stuck jobs to clear')

db.close()
" 2>/dev/null || log_error "Failed to clear stuck jobs"
fi

echo
echo "To restart: ./start.sh"
echo "To check status: ./status.sh"
echo "To clear stuck jobs: ./stop.sh --clear-stuck"
