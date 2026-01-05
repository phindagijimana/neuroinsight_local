#!/bin/bash
# NeuroInsight Production Native Stop Script
# Stops all native services cleanly

set -e

echo "🛑 Stopping NeuroInsight Production Native Deployment"
echo "==================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIDS_DIR="${SCRIPT_DIR}"
DATA_DIR="${SCRIPT_DIR}/data"
PG_DATA_DIR="${DATA_DIR}/postgresql"

# Function to safely kill process
safe_kill() {
    local pid_file="$1"
    local service_name="$2"

    if [ -f "${pid_file}" ]; then
        local pid=$(cat "${pid_file}")
        if kill -0 "${pid}" 2>/dev/null; then
            echo "🛑 Stopping ${service_name} (PID: ${pid})..."
            kill "${pid}"

            # Wait for process to stop
            local count=0
            while kill -0 "${pid}" 2>/dev/null && [ $count -lt 10 ]; do
                sleep 1
                count=$((count + 1))
            done

            if kill -0 "${pid}" 2>/dev/null; then
                echo "⚠️ ${service_name} didn't stop gracefully, force killing..."
                kill -9 "${pid}" 2>/dev/null || true
            else
                echo "✅ ${service_name} stopped successfully"
            fi
        else
            echo "ℹ️ ${service_name} process not running"
        fi
        rm -f "${pid_file}"
    else
        echo "ℹ️ ${service_name} PID file not found"
    fi
}

# Stop FastAPI backend
safe_kill "${PIDS_DIR}/backend.pid" "FastAPI Backend"

# Stop Celery worker
safe_kill "${PIDS_DIR}/celery.pid" "Celery Worker"

# Stop MinIO
safe_kill "${PIDS_DIR}/minio.pid" "MinIO"

# Stop Redis
echo "🔴 Stopping Redis..."
if redis-cli ping >/dev/null 2>&1; then
    redis-cli shutdown
    echo "✅ Redis stopped successfully"
else
    echo "ℹ️ Redis not running"
fi

# Stop PostgreSQL
echo "🐘 Stopping PostgreSQL..."
if pg_ctl status -D "${PG_DATA_DIR}" >/dev/null 2>&1; then
    pg_ctl stop -D "${PG_DATA_DIR}" -m fast
    echo "✅ PostgreSQL stopped successfully"
else
    echo "ℹ️ PostgreSQL not running"
fi

# Clean up any remaining processes
echo "🧹 Cleaning up any remaining NeuroInsight processes..."
pkill -f "uvicorn.*backend.main:app" || true
pkill -f "celery.*processing_web" || true
pkill -f "minio server" || true

echo ""
echo "✅ NeuroInsight Production Native Deployment Stopped"
echo "======================================================"

# Show final status
echo "📊 Final Service Status:"
echo "   • PostgreSQL: $(pg_ctl status -D "${PG_DATA_DIR}" >/dev/null 2>&1 && echo 'Stopped' || echo 'Not running')"
echo "   • Redis: $(redis-cli ping >/dev/null 2>&1 && echo 'Running' || echo 'Stopped')"
echo "   • MinIO: $(pgrep -f 'minio server' >/dev/null && echo 'Running' || echo 'Stopped')"
echo "   • FastAPI Backend: $(pgrep -f 'uvicorn.*backend.main:app' >/dev/null && echo 'Running' || echo 'Stopped')"
echo "   • Celery Worker: $(pgrep -f 'celery.*processing_web' >/dev/null && echo 'Running' || echo 'Stopped')"

echo ""
echo "💾 Data preserved in: ${DATA_DIR}"
echo "📝 Logs available in: ${DATA_DIR}/logs"
echo ""
echo "🚀 To restart: ./start_production_native.sh"








