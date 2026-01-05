#!/bin/bash
# NeuroInsight Native Services Stop Script
# Stops PostgreSQL, Redis, and MinIO cleanly

set -e

echo "🛑 Stopping NeuroInsight Native Services"
echo "========================================"

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

# Stop MinIO
safe_kill "${MINIO_PID}" "MinIO"

# Stop Redis
echo "🔴 Stopping Redis..."
if redis-cli -p "${REDIS_PORT}" ping >/dev/null 2>&1 2>&1; then
    redis-cli -p "${REDIS_PORT}" shutdown
    echo "✅ Redis stopped successfully"
else
    echo "ℹ️ Redis not running"
fi

# Stop PostgreSQL
echo "🐘 Stopping PostgreSQL..."
if pg_ctl status -D "${POSTGRES_DATA_DIR}" >/dev/null 2>&1; then
    pg_ctl stop -D "${POSTGRES_DATA_DIR}" -m fast
    echo "✅ PostgreSQL stopped successfully"
else
    echo "ℹ️ PostgreSQL not running"
fi

echo ""
echo "✅ All Native Services Stopped"
echo "==============================="

# Show final status
echo "📊 Final Service Status:"
echo "   • PostgreSQL: $(pg_ctl status -D "${POSTGRES_DATA_DIR}" >/dev/null 2>&1 && echo 'Stopped' || echo 'Not running')"
echo "   • Redis: $(redis-cli -p "${REDIS_PORT}" ping >/dev/null 2>&1 && echo 'Running' || echo 'Stopped')"
echo "   • MinIO: $(pgrep -f 'minio server' >/dev/null && echo 'Running' || echo 'Stopped')"

echo ""
echo "💾 Data preserved in:"
echo "   • PostgreSQL: ${POSTGRES_DATA_DIR}"
echo "   • Redis: ${REDIS_DATA_DIR}"
echo "   • MinIO: ${MINIO_DATA_DIR}"
echo ""
echo "🚀 To restart services: ./start_native_services.sh"








