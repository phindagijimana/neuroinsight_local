#!/bin/bash
set -e

# NeuroInsight - Automated Startup Script
# This script handles all environment setup automatically

echo "🧠 Starting NeuroInsight..."

# Get the absolute path to this script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cat > .env << 'EOF'
# Database Configuration
POSTGRES_USER=neuroinsight
POSTGRES_PASSWORD=neuroinsight_secure_password
POSTGRES_DB=neuroinsight
POSTGRES_HOST=db
POSTGRES_PORT=5432

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379

# MinIO Configuration
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
MINIO_ENDPOINT=minio:9000
MINIO_BUCKET=neuroinsight

# Application Configuration
SECRET_KEY=your-secret-key-change-in-production
DEBUG=true
UPLOAD_DIR=/data/uploads
OUTPUT_DIR=/data/outputs

# Celery Configuration
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0
EOF
    echo "✅ Created .env file"
fi

# Auto-detect absolute paths for Docker-in-Docker
export HOST_UPLOAD_DIR="$SCRIPT_DIR/data/uploads"
export HOST_OUTPUT_DIR="$SCRIPT_DIR/data/outputs"

echo "📂 Host paths configured:"
echo "   Uploads: $HOST_UPLOAD_DIR"
echo "   Outputs: $HOST_OUTPUT_DIR"

# Create data directories if they don't exist
mkdir -p data/uploads data/outputs data/logs
echo "✅ Data directories ready"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running"
    echo "   Please start Docker Desktop and try again"
    exit 1
fi

echo "✅ Docker is running"

# Parse command line arguments
COMMAND="${1:-up}"

case "$COMMAND" in
    up|start)
        echo "🚀 Starting all services..."
        docker compose up -d
        echo ""
        echo "✅ NeuroInsight is starting!"
        echo "   Frontend:  http://localhost:3000"
        echo "   Backend:   http://localhost:8000"
        echo ""
        echo "📊 To view logs:"
        echo "   All services:    docker compose logs -f"
        echo "   Worker only:     docker compose logs -f worker"
        echo ""
        echo "🛑 To stop:"
        echo "   ./start.sh stop"
        ;;
    
    down|stop)
        echo "🛑 Stopping all services..."
        docker compose down
        echo "✅ All services stopped"
        ;;
    
    restart)
        echo "🔄 Restarting all services..."
        docker compose down
        docker compose up -d
        echo "✅ Services restarted"
        ;;
    
    logs)
        SERVICE="${2:-}"
        if [ -z "$SERVICE" ]; then
            docker compose logs -f
        else
            docker compose logs -f "$SERVICE"
        fi
        ;;
    
    rebuild)
        echo "🔨 Rebuilding all containers..."
        docker compose down
        docker compose build --no-cache
        docker compose up -d
        echo "✅ Rebuild complete"
        ;;
    
    status)
        docker compose ps
        ;;
    
    *)
        echo "Usage: ./start.sh [command]"
        echo ""
        echo "Commands:"
        echo "  up, start   - Start all services (default)"
        echo "  down, stop  - Stop all services"
        echo "  restart     - Restart all services"
        echo "  logs [svc]  - View logs (optionally for specific service)"
        echo "  rebuild     - Rebuild and restart all containers"
        echo "  status      - Show status of all services"
        exit 1
        ;;
esac

