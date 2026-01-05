#!/bin/bash
# NeuroInsight Native Services Startup Script
# Starts PostgreSQL, Redis, and MinIO natively

set -e

echo "🚀 Starting NeuroInsight Native Services"
echo "========================================"

# Load environment
if [ -f ".env.native" ]; then
    echo "📝 Loading native environment configuration..."
    set -a
    source .env.native
    set +a
else
    echo "❌ .env.native file not found. Please create it first."
    exit 1
fi

# Create data directories
echo "📁 Ensuring data directories exist..."
mkdir -p "${POSTGRES_DATA_DIR}" "${REDIS_DATA_DIR}" "${MINIO_DATA_DIR}"

# Function to check if service is already running
is_running() {
    local pid_file="$1"
    if [ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Start PostgreSQL
echo "🐘 Starting PostgreSQL..."
if is_running "${POSTGRES_DATA_DIR}/postmaster.pid" 2>/dev/null || pg_ctl status -D "${POSTGRES_DATA_DIR}" >/dev/null 2>&1; then
    echo "ℹ️ PostgreSQL already running"
else
    # Initialize if needed
    if [ ! -d "${POSTGRES_DATA_DIR}/base" ]; then
        echo "Initializing PostgreSQL data directory..."
        initdb -D "${POSTGRES_DATA_DIR}" --username="${POSTGRES_USER}" --encoding=UTF-8 --locale=en_US.UTF-8

        # Configure PostgreSQL
        cat > "${POSTGRES_DATA_DIR}/postgresql.conf" << EOF
listen_addresses = 'localhost'
port = ${POSTGRES_PORT}
max_connections = 100
shared_buffers = 128MB
effective_cache_size = 256MB
maintenance_work_mem = 32MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 2MB
EOF

        cat > "${POSTGRES_DATA_DIR}/pg_hba.conf" << EOF
local   all             ${POSTGRES_USER}                                trust
host    all             ${POSTGRES_USER}        127.0.0.1/32           trust
host    all             ${POSTGRES_USER}        ::1/128                trust
EOF
    fi

    # Start PostgreSQL
    pg_ctl start -D "${POSTGRES_DATA_DIR}" -l "${LOG_DIR}/postgresql.log"

    # Wait for startup
    echo "Waiting for PostgreSQL to start..."
    for i in {1..30}; do
        if pg_isready -p "${POSTGRES_PORT}" >/dev/null 2>&1; then
            echo "✅ PostgreSQL started successfully"
            break
        fi
        sleep 1
    done

    # Create database and user if they don't exist
    if ! psql -h localhost -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -l | grep -q "${POSTGRES_DB}"; then
        echo "Creating database and user..."
        sudo -u postgres createdb -p "${POSTGRES_PORT}" "${POSTGRES_DB}" 2>/dev/null || createdb -p "${POSTGRES_PORT}" "${POSTGRES_DB}"
        psql -h localhost -p "${POSTGRES_PORT}" -c "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';" postgres 2>/dev/null || true
        psql -h localhost -p "${POSTGRES_PORT}" -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};" postgres 2>/dev/null || true
    fi
fi

# Start Redis
echo "🔴 Starting Redis..."
if is_running "${REDIS_PID}"; then
    echo "ℹ️ Redis already running"
elif redis-cli -p "${REDIS_PORT}" ping >/dev/null 2>&1 2>&1; then
    echo "ℹ️ Redis already running (external)"
else
    redis-server --daemonize yes \
                 --port "${REDIS_PORT}" \
                 --dir "${REDIS_DATA_DIR}" \
                 --logfile "${LOG_DIR}/redis.log" \
                 --save 900 1 \
                 --save 300 10 \
                 --save 60 10000

    # Wait for startup
    sleep 2
    if redis-cli -p "${REDIS_PORT}" ping >/dev/null 2>&1; then
        echo "✅ Redis started successfully"
    else
        echo "❌ Redis failed to start"
        exit 1
    fi
fi

# Start MinIO
echo "📦 Starting MinIO..."
if is_running "${MINIO_PID}"; then
    echo "ℹ️ MinIO already running"
elif curl -f "http://localhost:${MINIO_PORT}/minio/health/live" >/dev/null 2>&1 2>&1; then
    echo "ℹ️ MinIO already running (external)"
else
    nohup minio server "${MINIO_DATA_DIR}" \
          --address ":${MINIO_PORT}" \
          --console-address ":9001" \
          > "${LOG_DIR}/minio.log" 2>&1 &
    echo $! > "${MINIO_PID}"

    # Wait for startup
    echo "Waiting for MinIO to start..."
    for i in {1..30}; do
        if curl -f "http://localhost:${MINIO_PORT}/minio/health/live" >/dev/null 2>&1; then
            echo "✅ MinIO started successfully"
            break
        fi
        sleep 2
    done

    if ! curl -f "http://localhost:${MINIO_PORT}/minio/health/live" >/dev/null 2>&1; then
        echo "❌ MinIO failed to start"
        exit 1
    fi
fi

echo ""
echo "🎉 All Native Services Started!"
echo "==============================="
echo "🐘 PostgreSQL: localhost:${POSTGRES_PORT}"
echo "🔴 Redis: localhost:${REDIS_PORT}"
echo "📦 MinIO: localhost:${MINIO_PORT}"
echo "   Console: http://localhost:9001"
echo ""
echo "📝 Logs:"
echo "   PostgreSQL: ${LOG_DIR}/postgresql.log"
echo "   Redis: ${LOG_DIR}/redis.log"
echo "   MinIO: ${LOG_DIR}/minio.log"
echo ""
echo "🛑 To stop services: ./stop_native_services.sh"








