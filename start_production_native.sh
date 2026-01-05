#!/bin/bash
# NeuroInsight Production Native Deployment
# Everything runs natively - no containers at all

set -e

echo "🖥️ Starting NeuroInsight Production (Fully Native Mode)"
echo "======================================================"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/data"
LOGS_DIR="${DATA_DIR}/logs"
PIDS_DIR="${SCRIPT_DIR}"
VENV_DIR="${SCRIPT_DIR}/venv"

# PostgreSQL Configuration
PG_VERSION="15"
PG_DATA_DIR="${DATA_DIR}/postgresql"
PG_PORT="5432"
PG_USER="neuroinsight"
PG_PASSWORD="secure_password_change_in_production"
PG_DB="neuroinsight"

# Redis Configuration
REDIS_PORT="6379"
REDIS_DATA_DIR="${DATA_DIR}/redis"
REDIS_LOG="${LOGS_DIR}/redis.log"

# MinIO Configuration
MINIO_PORT="9000"
MINIO_CONSOLE_PORT="9001"
MINIO_DATA_DIR="${DATA_DIR}/minio"
MINIO_ACCESS_KEY="neuroinsight_minio"
MINIO_SECRET_KEY="secure_minio_secret_change_in_production"

# Environment setup
export PYTHONPATH="${SCRIPT_DIR}"
export NEUROINSIGHT_ENV="production"
export ENVIRONMENT="production"
export LOG_LEVEL="INFO"

# PostgreSQL environment
export PGDATA="${PG_DATA_DIR}"
export PGPORT="${PG_PORT}"
export PGUSER="${PG_USER}"
export PGPASSWORD="${PG_PASSWORD}"

# MinIO environment
export MINIO_ROOT_USER="${MINIO_ACCESS_KEY}"
export MINIO_ROOT_PASSWORD="${MINIO_SECRET_KEY}"

# Create directories
echo "📁 Creating data directories..."
mkdir -p "${DATA_DIR}/uploads" "${DATA_DIR}/outputs" "${LOGS_DIR}"
mkdir -p "${PG_DATA_DIR}" "${REDIS_DATA_DIR}" "${MINIO_DATA_DIR}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install PostgreSQL
install_postgresql() {
    echo "🐘 Installing PostgreSQL ${PG_VERSION}..."

    if command_exists psql && command_exists pg_ctl; then
        echo "✅ PostgreSQL already installed"
        return 0
    fi

    # Detect package manager
    if command_exists apt-get; then
        # Ubuntu/Debian
        sudo apt-get update
        sudo apt-get install -y postgresql-${PG_VERSION} postgresql-contrib-${PG_VERSION}
    elif command_exists dnf; then
        # Fedora/RHEL/CentOS
        sudo dnf install -y postgresql${PG_VERSION}-server postgresql${PG_VERSION}
        sudo postgresql${PG_VERSION}-setup initdb
    elif command_exists yum; then
        # Older RHEL/CentOS
        sudo yum install -y postgresql${PG_VERSION}-server postgresql${PG_VERSION}
        sudo service postgresql-${PG_VERSION} initdb
    elif command_exists pacman; then
        # Arch Linux
        sudo pacman -S postgresql
        sudo -u postgres initdb -D /var/lib/postgres/data
    else
        echo "❌ Unsupported package manager. Please install PostgreSQL ${PG_VERSION} manually."
        return 1
    fi

    echo "✅ PostgreSQL installed successfully"
}

# Function to install Redis
install_redis() {
    echo "🔴 Installing Redis..."

    if command_exists redis-server; then
        echo "✅ Redis already installed"
        return 0
    fi

    # Detect package manager
    if command_exists apt-get; then
        # Ubuntu/Debian
        sudo apt-get update
        sudo apt-get install -y redis-server
    elif command_exists dnf || command_exists yum; then
        # Fedora/RHEL/CentOS
        sudo dnf install -y redis || sudo yum install -y redis
    elif command_exists pacman; then
        # Arch Linux
        sudo pacman -S redis
    else
        echo "❌ Unsupported package manager. Please install Redis manually."
        return 1
    fi

    echo "✅ Redis installed successfully"
}

# Function to install MinIO
install_minio() {
    echo "📦 Installing MinIO..."

    if command_exists minio; then
        echo "✅ MinIO already installed"
        return 0
    fi

    # Download and install MinIO
    echo "Downloading MinIO..."
    curl -s https://dl.min.io/server/minio/release/linux-amd64/minio -o /tmp/minio
    chmod +x /tmp/minio

    # Move to system location
    if [ -w /usr/local/bin ]; then
        sudo mv /tmp/minio /usr/local/bin/
    else
        sudo mv /tmp/minio /usr/local/bin/
    fi

    echo "✅ MinIO installed successfully"
}

# Install dependencies
echo "📦 Checking and installing system dependencies..."
install_postgresql
install_redis
install_minio

# Initialize PostgreSQL if needed
echo "🐘 Initializing PostgreSQL..."
if [ ! -d "${PG_DATA_DIR}/base" ]; then
    echo "Initializing PostgreSQL data directory..."
    initdb -D "${PG_DATA_DIR}" --username="${PG_USER}" --encoding=UTF-8 --locale=en_US.UTF-8

    # Configure PostgreSQL
    cat >> "${PG_DATA_DIR}/postgresql.conf" << EOF
listen_addresses = 'localhost'
port = ${PG_PORT}
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

    cat >> "${PG_DATA_DIR}/pg_hba.conf" << EOF
local   all             ${PG_USER}                                trust
host    all             ${PG_USER}        127.0.0.1/32           trust
host    all             ${PG_USER}        ::1/128                trust
EOF
else
    echo "PostgreSQL data directory already exists"
fi

# Check for system services first
echo "🔍 Checking for system services..."

# Function to check if system service is running
check_system_service() {
    local service_name="$1"
    local display_name="$2"

    if systemctl is-active --quiet "$service_name" 2>/dev/null; then
        echo "✅ $display_name: Running (systemd service)"
        return 0
    else
        return 1
    fi
}

# Check each NeuroInsight system service
postgres_systemd=false
redis_systemd=false
minio_systemd=false

if check_system_service "neuroinsight-postgresql" "PostgreSQL"; then
    postgres_systemd=true
fi

if check_system_service "neuroinsight-redis" "Redis"; then
    redis_systemd=true
fi

if check_system_service "neuroinsight-minio" "MinIO"; then
    minio_systemd=true
fi

echo ""

# Start PostgreSQL
echo "🐘 Starting PostgreSQL..."
if [ "$postgres_systemd" = true ]; then
    echo "  Using system PostgreSQL service"
elif ! pg_ctl status -D "${PG_DATA_DIR}" >/dev/null 2>&1; then
    pg_ctl start -D "${PG_DATA_DIR}" -l "${LOGS_DIR}/postgresql.log"
    sleep 3

    # Create database and user
    if ! psql -l | grep -q "${PG_DB}"; then
        createdb "${PG_DB}"
        psql -c "CREATE USER ${PG_USER} WITH PASSWORD '${PG_PASSWORD}';" || true
        psql -c "GRANT ALL PRIVILEGES ON DATABASE ${PG_DB} TO ${PG_USER};" || true
    fi
else
    echo "PostgreSQL already running"
fi

# Start Redis
echo "🔴 Starting Redis..."
if [ "$redis_systemd" = true ]; then
    echo "  Using system Redis service"
elif ! redis-cli ping >/dev/null 2>&1; then
    redis-server --daemonize yes \
                 --port ${REDIS_PORT} \
                 --dir "${REDIS_DATA_DIR}" \
                 --logfile "${REDIS_LOG}" \
                 --save 900 1 \
                 --save 300 10 \
                 --save 60 10000

    sleep 2
    if redis-cli ping >/dev/null 2>&1; then
        echo "✅ Redis started successfully"
    else
        echo "❌ Redis failed to start"
        exit 1
    fi
else
    echo "Redis already running"
fi

# Start MinIO
echo "📦 Starting MinIO..."
if [ "$minio_systemd" = true ]; then
    echo "  Using system MinIO service"
elif ! pgrep -f "minio server" >/dev/null; then
    nohup minio server "${MINIO_DATA_DIR}" \
          --address ":${MINIO_PORT}" \
          --console-address ":${MINIO_CONSOLE_PORT}" \
          > "${LOGS_DIR}/minio.log" 2>&1 &
    echo $! > "${PIDS_DIR}/minio.pid"

    sleep 5
    if curl -f http://localhost:${MINIO_PORT}/minio/health/live >/dev/null 2>&1; then
        echo "✅ MinIO started successfully"
    else
        echo "❌ MinIO failed to start"
        exit 1
    fi
else
    echo "MinIO already running"
fi

# Activate Python virtual environment
if [ -d "${VENV_DIR}" ]; then
    echo "🐍 Activating Python virtual environment..."
    source "${VENV_DIR}/bin/activate"
else
    echo "❌ Virtual environment not found at ${VENV_DIR}"
    echo "Please create it with: python -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
    exit 1
fi

# Start Celery worker
echo "⚙️ Starting Celery worker..."
PYTHONPATH="${SCRIPT_DIR}" \
celery -A workers.tasks.processing_web worker \
    --loglevel=info \
    --concurrency=1 \
    --hostname=neuroinsight-worker@%h \
    > "${LOGS_DIR}/celery.log" 2>&1 &
echo $! > "${PIDS_DIR}/celery.pid"
echo "✅ Celery worker started (PID: $(cat "${PIDS_DIR}/celery.pid"))"

# Wait for services to be ready
sleep 3

# Start the main FastAPI application
echo "🚀 Starting NeuroInsight FastAPI backend..."
PYTHONPATH="${SCRIPT_DIR}" \
uvicorn backend.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 1 \
    --log-level info \
    > "${LOGS_DIR}/backend.log" 2>&1 &
echo $! > "${PIDS_DIR}/backend.pid"
echo "✅ FastAPI backend started (PID: $(cat "${PIDS_DIR}/backend.pid"))"

# Wait for backend to start
sleep 5

echo ""
echo "🎉 NeuroInsight Production Native Deployment Started!"
echo "===================================================="
echo "🌐 Access your application:"
echo "   • Web Interface: http://localhost:8000"
echo "   • API Documentation: http://localhost:8000/docs"
echo "   • MinIO Console: http://localhost:9001"
echo ""
echo "📊 Service Status:"
echo "   • PostgreSQL: Running on port ${PG_PORT}"
echo "   • Redis: Running on port ${REDIS_PORT}"
echo "   • MinIO: Running on ports ${MINIO_PORT}/${MINIO_CONSOLE_PORT}"
echo "   • FastAPI Backend: PID $(cat "${PIDS_DIR}/backend.pid")"
echo "   • Celery Worker: PID $(cat "${PIDS_DIR}/celery.pid")"
echo ""
echo "📝 Logs Location: ${LOGS_DIR}"
echo "   • Backend: tail -f ${LOGS_DIR}/backend.log"
echo "   • Celery: tail -f ${LOGS_DIR}/celery.log"
echo "   • PostgreSQL: tail -f ${LOGS_DIR}/postgresql.log"
echo "   • Redis: tail -f ${LOGS_DIR}/redis.log"
echo "   • MinIO: tail -f ${LOGS_DIR}/minio.log"
echo ""
echo "🛑 To stop all services: ./stop_production_native.sh"
echo ""
echo "💾 Data Locations:"
echo "   • PostgreSQL: ${PG_DATA_DIR}"
echo "   • Redis: ${REDIS_DATA_DIR}"
echo "   • MinIO: ${MINIO_DATA_DIR}"
echo "   • Uploads: ${DATA_DIR}/uploads"
echo "   • Outputs: ${DATA_DIR}/outputs"

