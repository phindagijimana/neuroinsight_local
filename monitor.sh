#!/bin/bash
# NeuroInsight Process Monitor
# Monitors and manages NeuroInsight processes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[MONITOR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[MONITOR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[MONITOR]${NC} $1"
}

log_error() {
    echo -e "${RED}[MONITOR]${NC} $1"
}

# Function to check if a process is actually responding
check_process_health() {
    local pid=$1
    local name=$2

    if [ ! -d "/proc/$pid" ]; then
        echo "dead"
        return
    fi

    # Check if process is responsive (not zombie)
    local stat=$(cat /proc/$pid/stat 2>/dev/null | awk '{print $3}')
    if [ "$stat" = "Z" ]; then
        echo "zombie"
        return
    fi

    # Additional health check based on process type
    case $name in
        "backend")
            if curl -s --max-time 5 http://localhost:8000/health > /dev/null 2>&1; then
                echo "healthy"
            else
                echo "unresponsive"
            fi
            ;;
        "celery")
            # For Celery, just check if process exists and is not zombie
            echo "running"
            ;;
        *)
            echo "running"
            ;;
    esac
}

# Function to clean up orphaned processes
cleanup_processes() {
    log_info "Checking for orphaned NeuroInsight processes..."

    local cleaned=0

    # Find all Python processes related to NeuroInsight
    local pids=$(pgrep -f "python3.*neuroinsight\|python3.*backend\|python3.*celery.*processing_web" 2>/dev/null || true)

    for pid in $pids; do
        if [ -n "$pid" ] && [ "$pid" != "$$" ]; then  # Don't kill ourselves
            local cmdline=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ' || echo "")
            local health=$(check_process_health $pid "unknown")

            if [ "$health" = "dead" ] || [ "$health" = "zombie" ] || [ "$health" = "unresponsive" ]; then
                log_warning "Found unhealthy process (PID: $pid, Health: $health)"
                log_warning "Command: $cmdline"

                # Kill the process
                if kill -15 $pid 2>/dev/null; then
                    log_success "Sent SIGTERM to PID $pid"
                    # Wait a moment for graceful shutdown
                    sleep 2
                    if kill -0 $pid 2>/dev/null; then
                        kill -9 $pid 2>/dev/null || true
                        log_warning "Force killed PID $pid"
                    fi
                fi

                cleaned=$((cleaned + 1))
            fi
        fi
    done

    if [ $cleaned -gt 0 ]; then
        log_success "Cleaned up $cleaned orphaned process(es)"
    else
        log_info "No orphaned processes found"
    fi
}

# Function to check system resources
check_resources() {
    log_info "Checking system resources..."

    # Memory usage
    local mem_percent=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ $mem_percent -gt 90 ]; then
        log_error "CRITICAL: Memory usage at ${mem_percent}%"
    elif [ $mem_percent -gt 75 ]; then
        log_warning "WARNING: High memory usage at ${mem_percent}%"
    else
        log_success "Memory usage: ${mem_percent}%"
    fi

    # Disk usage
    local disk_percent=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $disk_percent -gt 95 ]; then
        log_error "CRITICAL: Disk usage at ${disk_percent}%"
    elif [ $disk_percent -gt 85 ]; then
        log_warning "WARNING: High disk usage at ${disk_percent}%"
    else
        log_success "Disk usage: ${disk_percent}%"
    fi

    # Check for NeuroInsight-specific resource issues
    if [ -d "data/outputs" ]; then
        local output_size=$(du -sm data/outputs 2>/dev/null | cut -f1 || echo "0")
        if [ "$output_size" -gt 1000 ]; then  # More than 1GB
            log_warning "Large output directory: ${output_size}MB - consider cleanup"
        fi
    fi
}

# Function to check job health
check_jobs() {
    log_info "Checking job health..."

    # Check if we can connect to the API
    if curl -s --max-time 5 http://localhost:8000/api/status > /dev/null 2>&1; then
        local status_json=$(curl -s http://localhost:8000/api/status)

        # Extract job counts
        local running=$(echo "$status_json" | python3 -c "import sys, json; print(json.load(sys.stdin).get('jobs', {}).get('running', 0))" 2>/dev/null || echo "0")
        local pending=$(echo "$status_json" | python3 -c "import sys, json; print(json.load(sys.stdin).get('jobs', {}).get('pending', 0))" 2>/dev/null || echo "0")
        local failed=$(echo "$status_json" | python3 -c "import sys, json; print(json.load(sys.stdin).get('jobs', {}).get('failed', 0))" 2>/dev/null || echo "0")

        log_info "Job status - Running: $running, Pending: $pending, Failed: $failed"

        # Check for stuck jobs
        if [ "$running" -gt 0 ]; then
            log_info "Checking for stuck running jobs..."
            # This would require database access, simplified check
            local old_jobs=$(find . -name "*.log" -mtime +1 2>/dev/null | wc -l)
            if [ "$old_jobs" -gt 0 ]; then
                log_warning "Found old log files - possible stuck jobs"
            fi
        fi

        if [ "$failed" -gt 5 ]; then
            log_warning "High number of failed jobs ($failed) - check system health"
        fi

    else
        log_error "Cannot connect to NeuroInsight API"
    fi
}

# Main monitoring logic
main() {
    echo "========================================"
    echo "   NeuroInsight Process Monitor"
    echo "========================================"
    echo

    # Parse command line arguments
    case "${1:-}" in
        "cleanup")
            cleanup_processes
            ;;
        "resources")
            check_resources
            ;;
        "jobs")
            check_jobs
            ;;
        "full"|*)
            cleanup_processes
            echo
            check_resources
            echo
            check_jobs
            ;;
    esac

    echo
    echo "========================================"
    echo "Monitor commands:"
    echo "  ./monitor.sh          # Full check"
    echo "  ./monitor.sh cleanup  # Clean orphaned processes"
    echo "  ./monitor.sh resources# Check system resources"
    echo "  ./monitor.sh jobs     # Check job health"
    echo "========================================"
}

# Run main function
main "$@"
