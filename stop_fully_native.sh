#!/bin/bash
# NeuroInsight Fully Native Deployment Stop Script
# Stops Python application and all native services

set -e

echo "🛑 Stopping NeuroInsight Fully Native Deployment"
echo "================================================"

# Load environment
if [ -f ".env.native" ]; then
    set -a
    source .env.native
    set +a
fi

# Function to safely kill process
safe_kill() {
    local pid_file="$1"
    local service_name="$2"

    if [ -f "${pid_file}" ] && kill -0 "$(cat "${pid_file}")" 2>/dev/null; then
        echo "🛑 Stopping ${service_name} (PID: $(cat "${pid_file}"))..."
        kill "$(cat "${pid_file}")"

        # Wait for process to stop
        local count=0
        while kill -0 "$(cat "${pid_file}")" 2>/dev/null && [ $count -lt 10 ]; do
            sleep 1
            count=$((count + 1))
        done

        if kill -0 "$(cat "${pid_file}")" 2>/dev/null; then
            echo "⚠️ ${service_name} didn't stop gracefully, force killing..."
            kill -9 "$(cat "${pid_file}")" 2>/dev/null || true
        else
            echo "✅ ${service_name} stopped successfully"
        fi
        rm -f "${pid_file}"
    else
        echo "ℹ️ ${service_name} not running or PID file missing"
    fi
}

# Phase 1: Stop Python Application
echo "🐍 Stopping Python Application..."
safe_kill "${BACKEND_PID}" "FastAPI Backend"
safe_kill "${CELERY_PID}" "Celery Worker"

# Phase 2: Stop Native Services
echo ""
echo "🔧 Stopping Native Services..."
./stop_native_services.sh

echo ""
echo "✅ Fully Native Deployment Stopped"
echo "==================================="

# Show final status
echo "📊 Final Status:"
echo "   • FastAPI Backend: $(pgrep -f 'uvicorn.*backend.main:app' >/dev/null && echo 'Running' || echo 'Stopped')"
echo "   • Celery Worker: $(pgrep -f 'celery.*processing_web' >/dev/null && echo 'Running' || echo 'Stopped')"
echo "   • PostgreSQL: $(pg_ctl status -D "${POSTGRES_DATA_DIR}" >/dev/null 2>&1 && echo 'Running' || echo 'Stopped')"
echo "   • Redis: $(redis-cli -p "${REDIS_PORT}" ping >/dev/null 2>&1 && echo 'Running' || echo 'Stopped')"
echo "   • MinIO: $(pgrep -f 'minio server' >/dev/null && echo 'Running' || echo 'Stopped')"

echo ""
echo "💾 Data preserved in:"
echo "   • PostgreSQL: ${POSTGRES_DATA_DIR}"
echo "   • Redis: ${REDIS_DATA_DIR}"
echo "   • MinIO: ${MINIO_DATA_DIR}"
echo "   • Uploads: ${UPLOAD_DIR}"
echo "   • Outputs: ${OUTPUT_DIR}"
echo ""
echo "🚀 To restart: ./start_fully_native.sh"








