#!/bin/bash
# NeuroInsight Status Script
# Shows current status of all services

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detect the port NeuroInsight is running on
detect_neuroinsight_port() {
    # Check if neuroinsight.pid exists and process is running
    if [ -f "neuroinsight.pid" ] && kill -0 $(cat neuroinsight.pid) 2>/dev/null; then
        # Try to find the port the process is listening on
        PORT_INFO=$(lsof -Pan -p $(cat neuroinsight.pid) -i | grep LISTEN | head -1 | awk '{print $9}' | sed 's/.*://')
        if [ ! -z "$PORT_INFO" ]; then
            echo "$PORT_INFO"
            return 0
        fi
    fi

    # Fallback to PORT environment variable or default
    echo "${PORT:-8000}"
}

print_status() {
    local service=$1
    local status=$2
    local details=$3
    
    case $status in
        "running")
            echo -e "${service}: ${GREEN}RUNNING${NC} ${details}"
            ;;
        "stopped")
            echo -e "${service}: ${RED}STOPPED${NC} ${details}"
            ;;
        "warning")
            echo -e "${service}: ${YELLOW}WARNING${NC} ${details}"
            ;;
        *)
            echo -e "${service}: ${BLUE}UNKNOWN${NC} ${details}"
            ;;
    esac
}

echo "NeuroInsight Service Status"
echo "================================"

# Check backend
if [ -f "neuroinsight.pid" ]; then
    BACKEND_PID=$(cat neuroinsight.pid)
    if kill -0 $BACKEND_PID 2>/dev/null; then
        # Detect the port NeuroInsight is running on
        NEUROINSIGHT_PORT=$(detect_neuroinsight_port)
        # Check if API is responding
        if curl -s --max-time 5 http://localhost:$NEUROINSIGHT_PORT/health > /dev/null 2>&1; then
            print_status "Backend" "running" "(PID: $BACKEND_PID, Port: $NEUROINSIGHT_PORT, API: responding)"
        else
            print_status "backend" "warning" "(PID: $BACKEND_PID, Port: $NEUROINSIGHT_PORT, API: not responding)"
        fi
    else
        print_status "Backend" "stopped" "(stale PID file)"
        rm -f neuroinsight.pid
    fi
else
    print_status "Backend" "stopped" "(no PID file)"
fi

# Check Celery worker
if [ -f "celery.pid" ]; then
    WORKER_PID=$(cat celery.pid)
    if kill -0 $WORKER_PID 2>/dev/null; then
        print_status "Celery Worker" "running" "(PID: $WORKER_PID)"
    else
        print_status "Celery Worker" "stopped" "(stale PID file)"
        rm -f celery.pid
    fi
else
    print_status "Celery Worker" "stopped" "(no PID file)"
fi

# Check Docker containers
echo
echo "Docker Services:"
CONTAINERS=("neuroinsight-redis" "neuroinsight-postgres" "neuroinsight-minio" "neuroinsight-api-bridge")

for container in "${CONTAINERS[@]}"; do
    if docker ps | grep -q $container; then
        # Get container status
        STATUS=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep $container | awk '{print $2}')
        print_status "  $container" "running" "($STATUS)"
    else
        print_status "  $container" "stopped" ""
    fi
done

# Check license
echo
echo "FreeSurfer License:"
if [ -f "license.txt" ]; then
    if grep -q "REPLACE THIS EXAMPLE CONTENT" license.txt 2>/dev/null; then
        print_status "  License file" "warning" "(contains example content)"
    else
        LINE_COUNT=$(wc -l < license.txt)
        print_status "  License file" "running" "($LINE_COUNT lines)"
    fi
else
    print_status "  License file" "stopped" "(license.txt not found)"
fi

# System resources
echo
echo "System Resources:"
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
MEM_TOTAL=$(free -h | grep "^Mem:" | awk '{print $2}')
MEM_USED=$(free -h | grep "^Mem:" | awk '{print $3}')
DISK_USAGE=$(df / | tail -1 | awk '{print $5}')

echo "  CPU Usage: $CPU_USAGE"
echo "  Memory: $MEM_USED / $MEM_TOTAL"
echo "  Disk Usage: $DISK_USAGE"

# Job statistics (if API is available)
echo
echo "Recent Jobs:"
NEUROINSIGHT_PORT=$(detect_neuroinsight_port)
if curl -s --max-time 5 http://localhost:$NEUROINSIGHT_PORT/api/jobs/stats > /dev/null 2>&1; then
    STATS=$(curl -s http://localhost:$NEUROINSIGHT_PORT/api/jobs/stats)
    TOTAL=$(echo $STATS | grep -o '"total_jobs":[0-9]*' | cut -d: -f2)
    COMPLETED=$(echo $STATS | grep -o '"completed_jobs":[0-9]*' | cut -d: -f2)
    RUNNING=$(echo $STATS | grep -o '"running_jobs":[0-9]*' | cut -d: -f2)
    PENDING=$(echo $STATS | grep -o '"pending_jobs":[0-9]*' | cut -d: -f2)
    SUCCESS_RATE=$(echo $STATS | grep -o '"success_rate":[0-9]*' | cut -d: -f2)
    
    echo "  Total: $TOTAL jobs"
    echo "  Completed: $COMPLETED"
    echo "  Running: $RUNNING"
    echo "  Pending: $PENDING"
    echo "  Success Rate: $SUCCESS_RATE%"
else
    echo "  API not available"
fi

echo
echo "URLs:"
NEUROINSIGHT_PORT=$(detect_neuroinsight_port)
if curl -s --max-time 5 http://localhost:$NEUROINSIGHT_PORT/health > /dev/null 2>&1; then
    echo "  Web Interface: http://localhost:$NEUROINSIGHT_PORT"
    echo "  API Docs: http://localhost:$NEUROINSIGHT_PORT/docs"
else
    echo "  Services not accessible"
fi

# Check for stuck jobs (running longer than 2 hours)
echo
echo "Job Health:"
python3 -c "
import sys
sys.path.insert(0, '.')
from datetime import datetime, timedelta
from backend.core.database import get_db
from backend.models.job import Job, JobStatus

db = next(get_db())
stuck_jobs = []
now = datetime.utcnow()
timeout_hours = 2

running_jobs = db.query(Job).filter(Job.status == JobStatus.RUNNING).all()
for job in running_jobs:
    if job.started_at and (now - job.started_at) > timedelta(hours=timeout_hours):
        stuck_jobs.append(job.id)

if stuck_jobs:
    print(f'⚠️  WARNING: {len(stuck_jobs)} job(s) running longer than {timeout_hours} hours:')
    for job_id in stuck_jobs:
        print(f'   - Job {job_id} may be stuck')
    print(f'   Consider restarting services: ./stop.sh && ./start.sh')
else:
    print('✅ No stuck jobs detected')

db.close()
" 2>/dev/null || echo "  Could not check job health"

echo
echo "Log Files:"
echo "  Backend: neuroinsight.log"
echo "  Worker: celery_worker.log"
echo "  Docker: docker logs <container_name>"

echo
echo "Commands:"
echo "  Start: ./start.sh"
echo "  Stop: ./stop.sh"
echo "  License check: ./check_license.sh"
