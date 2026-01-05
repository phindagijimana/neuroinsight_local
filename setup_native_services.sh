#!/bin/bash
# NeuroInsight Native Services Setup Script
# Sets up PostgreSQL, Redis, and MinIO as system services
# WARNING: Requires root privileges for system service installation

set -e

echo "🔧 NeuroInsight Native Services Setup"
echo "======================================"
echo "⚠️  WARNING: This script requires root privileges!"
echo "   It will install and configure system services."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this script as root (sudo)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="${PROJECT_DIR}/data"
LOGS_DIR="${DATA_DIR}/logs"

# Service configuration
PG_USER="neuroinsight"
PG_PASSWORD="secure_password_change_in_production"
REDIS_PASSWORD=""
MINIO_USER="neuroinsight_minio"
MINIO_PASSWORD="secure_minio_secret_change_in_production"

echo "📍 Project Directory: ${PROJECT_DIR}"
echo "📁 Data Directory: ${DATA_DIR}"
echo ""

# Function to create system user
create_system_user() {
    local username="$1"
    local description="$2"

    if ! id "$username" &>/dev/null; then
        useradd -r -s /bin/false -d /nonexistent -c "$description" "$username"
        echo "✅ Created system user: $username"
    else
        echo "ℹ️ System user already exists: $username"
    fi
}

# Function to install service file
install_service_file() {
    local service_name="$1"
    local service_file="$2"

    cp "$service_file" "/etc/systemd/system/"
    chmod 644 "/etc/systemd/system/${service_name}.service"
    systemctl daemon-reload
    echo "✅ Installed service: $service_name"
}

# Function to create PostgreSQL configuration
setup_postgresql() {
    echo "🐘 Setting up PostgreSQL..."

    # Install PostgreSQL if not present
    if ! command -v psql &> /dev/null; then
        if command -v dnf &> /dev/null; then
            dnf install -y postgresql15-server postgresql15 postgresql15-contrib
        elif command -v apt-get &> /dev/null; then
            apt-get update
            apt-get install -y postgresql postgresql-contrib
        else
            echo "❌ Unsupported package manager. Please install PostgreSQL manually."
            return 1
        fi
    fi

    # Initialize PostgreSQL if not already done
    if [ ! -d "${DATA_DIR}/postgresql/base" ]; then
        mkdir -p "${DATA_DIR}/postgresql"
        chown postgres:postgres "${DATA_DIR}/postgresql"

        # Initialize database cluster
        su - postgres -c "initdb -D ${DATA_DIR}/postgresql"

        # Create configuration files
        cat > "${DATA_DIR}/postgresql/postgresql.conf" << EOF
listen_addresses = 'localhost'
port = 5432
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
log_destination = 'stderr'
logging_collector = on
log_directory = '${LOGS_DIR}'
log_filename = 'postgresql.log'
log_rotation_age = 1d
log_rotation_size = 10MB
EOF

        cat > "${DATA_DIR}/postgresql/pg_hba.conf" << EOF
local   all             postgres                                peer
local   all             ${PG_USER}                              md5
host    all             ${PG_USER}        127.0.0.1/32          md5
host    all             ${PG_USER}        ::1/128               md5
EOF
    fi

    # Create neuroinsight user and database
    su - postgres -c "psql -c \"CREATE USER ${PG_USER} WITH PASSWORD '${PG_PASSWORD}';\" 2>/dev/null || true"
    su - postgres -c "createdb -O ${PG_USER} neuroinsight 2>/dev/null || true"
    su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE neuroinsight TO ${PG_USER};\" 2>/dev/null || true"

    echo "✅ PostgreSQL setup complete"
}

# Function to setup Redis
setup_redis() {
    echo "🔴 Setting up Redis..."

    # Install Redis if not present
    if ! command -v redis-server &> /dev/null; then
        if command -v dnf &> /dev/null; then
            dnf install -y redis
        elif command -v apt-get &> /dev/null; then
            apt-get update
            apt-get install -y redis-server
        else
            echo "❌ Unsupported package manager. Please install Redis manually."
            return 1
        fi
    fi

    # Create Redis configuration
    mkdir -p "${DATA_DIR}/redis"
    chown redis:redis "${DATA_DIR}/redis"

    cat > "${DATA_DIR}/redis/redis.conf" << EOF
bind 127.0.0.1
port 6379
timeout 0
tcp-keepalive 300
daemonize no
supervised systemd
loglevel notice
logfile "${LOGS_DIR}/redis.log"
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir "${DATA_DIR}/redis"
slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
slave-priority 100
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes
EOF

    echo "✅ Redis setup complete"
}

# Function to setup MinIO
setup_minio() {
    echo "📦 Setting up MinIO..."

    # Download MinIO if not present
    if [ ! -f "/usr/local/bin/minio" ]; then
        curl -s https://dl.min.io/server/minio/release/linux-amd64/minio -o /tmp/minio
        chmod +x /tmp/minio
        mv /tmp/minio /usr/local/bin/minio
    fi

    # Create MinIO user if it doesn't exist
    if ! id "neuroinsight" &>/dev/null; then
        useradd -r -s /bin/false -d /nonexistent -c "NeuroInsight Service User" neuroinsight
    fi

    # Create data directory
    mkdir -p "${DATA_DIR}/minio"
    chown neuroinsight:neuroinsight "${DATA_DIR}/minio"

    echo "✅ MinIO setup complete"
}

# Function to install services
install_services() {
    echo "🔧 Installing system services..."

    # Create system users
    create_system_user "postgres" "PostgreSQL Database Server"
    create_system_user "redis" "Redis Database Server"
    create_system_user "neuroinsight" "NeuroInsight Application"

    # Setup each service
    setup_postgresql
    setup_redis
    setup_minio

    # Install service files
    install_service_file "neuroinsight-postgresql" "${SCRIPT_DIR}/systemd-services/neuroinsight-postgresql.service"
    install_service_file "neuroinsight-redis" "${SCRIPT_DIR}/systemd-services/neuroinsight-redis.service"
    install_service_file "neuroinsight-minio" "${SCRIPT_DIR}/systemd-services/neuroinsight-minio.service"

    echo "✅ Services installed successfully"
}

# Function to enable and start services
enable_services() {
    echo "🚀 Enabling and starting services..."

    # Enable services to start on boot
    systemctl enable neuroinsight-postgresql
    systemctl enable neuroinsight-redis
    systemctl enable neuroinsight-minio

    # Start services
    systemctl start neuroinsight-postgresql
    systemctl start neuroinsight-redis
    systemctl start neuroinsight-minio

    # Wait for services to be ready
    echo "⏳ Waiting for services to start..."
    sleep 10

    # Check service status
    echo "📊 Service Status:"
    systemctl is-active neuroinsight-postgresql && echo "✅ PostgreSQL: Running" || echo "❌ PostgreSQL: Failed"
    systemctl is-active neuroinsight-redis && echo "✅ Redis: Running" || echo "❌ Redis: Failed"
    systemctl is-active neuroinsight-minio && echo "✅ MinIO: Running" || echo "❌ MinIO: Failed"

    echo "✅ Services started successfully"
}

# Function to create uninstall script
create_uninstall_script() {
    cat > "${SCRIPT_DIR}/uninstall_native_services.sh" << 'EOF'
#!/bin/bash
# NeuroInsight Native Services Uninstall Script
# WARNING: This will remove all NeuroInsight system services and data!

set -e

if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this script as root (sudo)"
    exit 1
fi

echo "⚠️  WARNING: This will completely remove NeuroInsight native services!"
echo "   All data in PostgreSQL, Redis, and MinIO will be lost!"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Uninstall cancelled."
    exit 0
fi

# Stop and disable services
systemctl stop neuroinsight-postgresql neuroinsight-redis neuroinsight-minio
systemctl disable neuroinsight-postgresql neuroinsight-redis neuroinsight-minio

# Remove service files
rm -f /etc/systemd/system/neuroinsight-*.service
systemctl daemon-reload

# Remove data directories (CAUTION!)
PROJECT_DIR="/mnt/nfs/home/urmc-sh.rochester.edu/pndagiji/hippo/desktop_alone_web"
rm -rf "${PROJECT_DIR}/data/postgresql"
rm -rf "${PROJECT_DIR}/data/redis"
rm -rf "${PROJECT_DIR}/data/minio"

# Remove system users
userdel neuroinsight 2>/dev/null || true

echo "✅ NeuroInsight native services uninstalled"
EOF

    chmod +x "${SCRIPT_DIR}/uninstall_native_services.sh"
    echo "✅ Created uninstall script: uninstall_native_services.sh"
}

# Main installation process
main() {
    echo "Starting NeuroInsight Native Services Installation..."
    echo ""

    # Confirm installation
    echo "This will install:"
    echo "  • PostgreSQL database server"
    echo "  • Redis message broker"
    echo "  • MinIO object storage server"
    echo "  • Systemd services for automatic startup"
    echo ""
    read -p "Do you want to continue? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Installation cancelled."
        exit 0
    fi

    install_services
    enable_services
    create_uninstall_script

    echo ""
    echo "🎉 NeuroInsight Native Services Installation Complete!"
    echo "======================================================"
    echo ""
    echo "Services installed:"
    echo "  • PostgreSQL (port 5432)"
    echo "  • Redis (port 6379)"
    echo "  • MinIO (ports 9000/9001)"
    echo ""
    echo "Service management:"
    echo "  • Start: sudo systemctl start neuroinsight-{postgresql,redis,minio}"
    echo "  • Stop: sudo systemctl stop neuroinsight-{postgresql,redis,minio}"
    echo "  • Status: sudo systemctl status neuroinsight-{postgresql,redis,minio}"
    echo ""
    echo "Next steps:"
    echo "  1. Update passwords in your .env.native file"
    echo "  2. Run database migration: python migrate_sqlite_to_postgresql.py"
    echo "  3. Start NeuroInsight: ./start_production_native.sh"
    echo ""
    echo "⚠️  To uninstall: sudo ./uninstall_native_services.sh"
}

main "$@"








