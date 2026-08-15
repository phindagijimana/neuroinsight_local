#!/bin/bash
set -e

echo "======================================"
echo "NeuroInsight-AutoHS All-in-One Container"
echo "======================================"

# ============================================
# Docker Socket Permission Fix (Universal)
# ============================================
# Automatically configure Docker access for FreeSurfer container spawning
# Works on Linux, WSL2, and Docker Desktop (macOS/Windows) by detecting socket GID at runtime

if [ -S /var/run/docker.sock ]; then
    echo ""
    echo "Configuring Docker socket access..."
    # Do not abort startup if group membership tweaks fail on a specific platform
    set +e

    # Get the actual GID of the Docker socket
    DOCKER_SOCKET_GID=$(stat -c '%g' /var/run/docker.sock 2>/dev/null)
    if [ -z "$DOCKER_SOCKET_GID" ]; then
        DOCKER_SOCKET_GID=$(stat -f '%g' /var/run/docker.sock 2>/dev/null)
    fi
    echo "  Docker socket GID: ${DOCKER_SOCKET_GID:-unknown}"
    
    # Check if docker group exists and get its current GID
    if getent group docker > /dev/null 2>&1; then
        CURRENT_DOCKER_GID=$(getent group docker | cut -d: -f3)
        echo "  Current docker group GID: $CURRENT_DOCKER_GID"
        
        # If GIDs don't match, update the docker group
        if [ "$DOCKER_SOCKET_GID" != "$CURRENT_DOCKER_GID" ]; then
            echo "  Updating docker group GID to match socket..."
            if [ "$DOCKER_SOCKET_GID" = "0" ]; then
                # Docker Desktop (macOS/Windows): socket is root-owned; GID 0 is the root group
                echo "  Docker socket owned by root (GID 0) — adding neuroinsight to root group"
                usermod -aG root neuroinsight 2>/dev/null || true
            elif groupmod -g "$DOCKER_SOCKET_GID" docker 2>/dev/null; then
                echo "  [OK] Docker group updated to GID $DOCKER_SOCKET_GID"
            else
                echo "  [WARNING] Could not set docker group to GID $DOCKER_SOCKET_GID; continuing"
            fi
        else
            echo "  [OK] Docker group GID already matches socket"
        fi
    else
        # Docker group doesn't exist, create it with correct GID (skip GID 0 — root group exists)
        if [ "$DOCKER_SOCKET_GID" = "0" ]; then
            echo "  Docker socket GID 0 — using root group for Docker Desktop"
            usermod -aG root neuroinsight 2>/dev/null || true
        else
            echo "  Creating docker group with GID $DOCKER_SOCKET_GID..."
            groupadd -g "$DOCKER_SOCKET_GID" docker
            echo "  [OK] Docker group created"
        fi
    fi
    
    # Ensure neuroinsight user is in docker group
    if ! id -nG neuroinsight | grep -qw docker; then
        echo "  Adding neuroinsight user to docker group..."
        usermod -aG docker neuroinsight
        echo "  [OK] User added to docker group"
    else
        echo "  [OK] User already in docker group"
    fi
    
    # Verify Docker access
    if su - neuroinsight -c "docker ps > /dev/null 2>&1"; then
        echo "  [OK] Docker access verified - FreeSurfer spawning enabled"
    else
        echo "  [WARNING] Warning: Docker access test failed"
        echo "  FreeSurfer container spawning may not work"
        echo "  This is usually fine if Docker daemon is starting up"
    fi

    set -e
    echo "Docker configuration complete"
    echo ""
else
    echo ""
    echo "[WARNING] Warning: Docker socket not found at /var/run/docker.sock"
    echo "FreeSurfer container spawning will not be available"
    echo "Application will run in demo mode with mock processing"
    echo ""
fi

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL to be ready..."
    for i in {1..30}; do
        if su - postgres -c "pg_isready -U neuroinsight" > /dev/null 2>&1; then
            echo "PostgreSQL is ready!"
            return 0
        fi
        echo "Attempt $i/30: PostgreSQL not ready yet, waiting..."
        sleep 2
    done
    echo "ERROR: PostgreSQL failed to start"
    return 1
}

# Function to wait for Redis to be ready
wait_for_redis() {
    echo "Waiting for Redis to be ready..."
    for i in {1..30}; do
        if redis-cli -a redis_secure_password ping > /dev/null 2>&1; then
            echo "Redis is ready!"
            return 0
        fi
        echo "Attempt $i/30: Redis not ready yet, waiting..."
        sleep 1
    done
    echo "ERROR: Redis failed to start"
    return 1
}

# Initialize PostgreSQL if needed
if [ ! -f /data/postgresql/PG_VERSION ]; then
    echo "Initializing PostgreSQL database..."
    mkdir -p /data/postgresql
    chown -R postgres:postgres /data/postgresql
    chmod 700 /data/postgresql
    
    su - postgres -c "/usr/lib/postgresql/15/bin/initdb -D /data/postgresql"
    
    # Configure PostgreSQL
    echo "host all all 0.0.0.0/0 md5" >> /data/postgresql/pg_hba.conf
    echo "listen_addresses = '*'" >> /data/postgresql/postgresql.conf
    
    # Start PostgreSQL temporarily to create database
    su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl -D /data/postgresql -l /tmp/postgres.log start"
    
    sleep 5
    
    # Create database and user
    su - postgres -c "psql -c \"CREATE USER neuroinsight WITH PASSWORD 'neuroinsight_secure_password';\""
    su - postgres -c "psql -c \"CREATE DATABASE neuroinsight OWNER neuroinsight;\""
    su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE neuroinsight TO neuroinsight;\""
    
    # Stop PostgreSQL
    su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl -D /data/postgresql stop"
    
    echo "PostgreSQL initialized successfully"
else
    echo "PostgreSQL already initialized"
fi

# Create Redis data directory
mkdir -p /data/redis
chown -R neuroinsight:neuroinsight /data/redis

# Create MinIO data directory
mkdir -p /data/minio
chown -R neuroinsight:neuroinsight /data/minio

# Create upload/output directories
mkdir -p /data/uploads /data/outputs /data/logs
chown -R neuroinsight:neuroinsight /data/uploads /data/outputs /data/logs

# ============================================
# Auto-detect Host Paths for Docker-in-Docker
# ============================================
# For FreeSurfer container spawning to work, we need to mount host paths
# not container paths. Detect them from our own container's volume mounts.

echo ""
echo "Detecting host paths for Docker-in-Docker..."

# Try to get our own container name/ID
SELF_CONTAINER=$(cat /proc/self/cgroup | grep -o -P '(?<=docker/).*' | head -n 1 | cut -d'/' -f1)
if [ -z "$SELF_CONTAINER" ]; then
    # Try alternative method (hostname is often the container ID)
    SELF_CONTAINER=$(hostname)
fi

echo "  Container ID: $SELF_CONTAINER"

# Inspect our own container to find host mount paths
if [ -n "$SELF_CONTAINER" ] && docker inspect "$SELF_CONTAINER" > /dev/null 2>&1; then
    echo "  Inspecting container mounts..."
    
    # Extract host paths for /data volume using docker inspect --format
    # This is more reliable than grep as it directly queries the mount structure
    HOST_DATA_DIR=$(docker inspect --format '{{range .Mounts}}{{if eq .Destination "/data"}}{{.Source}}{{end}}{{end}}' "$SELF_CONTAINER")
    
    if [ -n "$HOST_DATA_DIR" ]; then
        export HOST_UPLOAD_DIR="$HOST_DATA_DIR/uploads"
        export HOST_OUTPUT_DIR="$HOST_DATA_DIR/outputs"
        echo "  [OK] Detected host data directory: $HOST_DATA_DIR"
        echo "  [OK] Host upload directory: $HOST_UPLOAD_DIR"
        echo "  [OK] Host output directory: $HOST_OUTPUT_DIR"
    else
        echo "  [WARNING] Could not detect host data directory"
        echo "  [WARNING] FreeSurfer processing may fail due to volume mount issues"
    fi
else
    echo "  [WARNING] Could not inspect container"
    echo "  [WARNING] Docker-in-Docker path detection failed"
fi

echo "Docker-in-Docker configuration complete"
echo ""

# Create .env file if it doesn't exist
if [ ! -f /app/.env ]; then
    echo "Creating .env configuration file..."
    cat > /app/.env << EOF
# PostgreSQL Database
POSTGRES_USER=neuroinsight
POSTGRES_PASSWORD=neuroinsight_secure_password
POSTGRES_DB=neuroinsight
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
DATABASE_URL=postgresql://neuroinsight:neuroinsight_secure_password@localhost:5432/neuroinsight

# Redis
REDIS_PASSWORD=redis_secure_password
REDIS_URL=redis://:redis_secure_password@localhost:6379/0

# MinIO/S3 Storage
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin_secure
MINIO_ENDPOINT=localhost:9000
MINIO_BUCKET_NAME=neuroinsight-autohs-data
MINIO_USE_SSL=false

# API Configuration
API_PORT=8000
CORS_ORIGINS=http://localhost:8000

# File Storage
UPLOAD_DIR=/data/uploads
OUTPUT_DIR=/data/outputs

# Docker-in-Docker Host Paths (auto-detected for FreeSurfer container spawning)
HOST_UPLOAD_DIR=${HOST_UPLOAD_DIR:-}
HOST_OUTPUT_DIR=${HOST_OUTPUT_DIR:-}

# Environment
ENVIRONMENT=production
EOF
    chown neuroinsight:neuroinsight /app/.env
else
    echo ".env file already exists"
fi

# Always update HOST paths in .env (even if file existed before)
# This ensures they reflect current container mount configuration
if [ -n "$HOST_UPLOAD_DIR" ] && [ -n "$HOST_OUTPUT_DIR" ]; then
    echo "Updating HOST paths in .env file..."
    # Remove old HOST path lines if they exist
    sed -i '/^HOST_UPLOAD_DIR=/d' /app/.env
    sed -i '/^HOST_OUTPUT_DIR=/d' /app/.env
    # Append current HOST paths
    echo "HOST_UPLOAD_DIR=$HOST_UPLOAD_DIR" >> /app/.env
    echo "HOST_OUTPUT_DIR=$HOST_OUTPUT_DIR" >> /app/.env
    echo "  [OK] Updated .env with detected host paths"
fi

# Check for FreeSurfer license
if [ -f /app/license.txt ]; then
    echo "FreeSurfer license found"
elif [ -f /data/license.txt ]; then
    echo "FreeSurfer license found in /data"
    cp /data/license.txt /app/license.txt
else
    echo "WARNING: FreeSurfer license not found"
    echo "Application will run in demo mode with mock processing"
    echo "To enable full FreeSurfer functionality:"
    echo "  1. Place license.txt in the container at /app/license.txt"
    echo "  2. Or mount it: -v /path/to/license.txt:/app/license.txt"
fi

echo ""
echo "======================================"
echo "Starting NeuroInsight-AutoHS Services"
echo "======================================"
echo ""

# Execute the command (supervisord)
exec "$@"
