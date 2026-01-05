#!/bin/bash
# Setup NeuroInsight Production Environment with Docker

set -e

echo "🧠 NeuroInsight Production Setup with Docker"
echo "============================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first:"
    echo "   Ubuntu: sudo apt install docker.io docker-compose"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Create necessary directories
echo "📁 Creating data directories..."
mkdir -p data/{uploads,outputs,freesurfer,logs}
mkdir -p backups/{postgres,minio}
mkdir -p pipeline

# Generate secure passwords if .env doesn't exist
if [ ! -f ".env.production.services" ]; then
    echo "🔐 Generating secure passwords..."
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    MINIO_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    SECRET_KEY=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-64)

    cat > .env.production.services << ENV_EOF
# Production Services Configuration - Auto-generated $(date)

# PostgreSQL
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
DATABASE_URL=postgresql://neuroinsight:${POSTGRES_PASSWORD}@postgres:5432/neuroinsight

# Redis
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0
CELERY_BROKER_URL=redis://:${REDIS_PASSWORD}@redis:6379/0
CELERY_RESULT_BACKEND=redis://:${REDIS_PASSWORD}@redis:6379/0

# MinIO
MINIO_ROOT_USER=neuroinsight_minio
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=neuroinsight_minio
MINIO_SECRET_KEY=${MINIO_ROOT_PASSWORD}
MINIO_BUCKET=neuroinsight
MINIO_USE_SSL=false

# FreeSurfer
FREESURFER_HOME=/usr/local/freesurfer
SUBJECTS_DIR=/data/freesurfer/subjects

# Application
ENVIRONMENT=production
LOG_LEVEL=INFO
SECRET_KEY=${SECRET_KEY}
API_HOST=0.0.0.0
API_PORT=8000

# Processing
MAX_CONCURRENT_JOBS=4
PROCESSING_TIMEOUT=3600
ENV_EOF

    echo "✅ Generated secure passwords in .env.production.services"
else
    echo "ℹ️  Using existing .env.production.services"
fi

# Check FreeSurfer license
if [ ! -f "freesurfer_license.txt" ] || grep -q "placeholder" freesurfer_license.txt; then
    echo ""
    echo "⚠️  FreeSurfer License Required"
    echo "=============================="
    echo "FreeSurfer requires a license to process MRI data."
    echo ""
    echo "📖 READ: FREESURFER_LICENSE_README.md for detailed instructions"
    echo ""
    echo "1. Register at: https://surfer.nmr.mgh.harvard.edu/registration.html"
    echo "2. Download your license.txt file"
    echo "3. Replace the content in: ./freesurfer_license.txt"
    echo ""
    echo "❌ Without a valid license, MRI processing will fail."
    echo "📁 License file location: ./freesurfer_license.txt"
    echo ""
    echo "After getting your license, run this setup again."
            exit 1
    else
    echo "✅ FreeSurfer license found"
fi

echo ""
echo "🚀 Starting NeuroInsight Production Services..."
echo "=============================================="

# Start services
docker-compose -f docker-compose.production.yml up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check service health
echo ""
echo "📊 Service Status:"
echo "=================="

# PostgreSQL
if docker-compose -f docker-compose.production.yml exec -T postgres pg_isready -U neuroinsight >/dev/null 2>&1; then
    echo "✅ PostgreSQL: Running"
else
    echo "❌ PostgreSQL: Not responding"
fi

# Redis
if docker-compose -f docker-compose.production.yml exec -T redis redis-cli --raw incr ping >/dev/null 2>&1; then
    echo "✅ Redis: Running"
else
    echo "❌ Redis: Not responding"
fi

# MinIO
if curl -f http://localhost:9000/minio/health/live >/dev/null 2>&1; then
    echo "✅ MinIO: Running"
else
    echo "❌ MinIO: Not responding"
fi

# FreeSurfer
if docker-compose -f docker-compose.production.yml exec -T freesurfer which recon-all >/dev/null 2>&1; then
    echo "✅ FreeSurfer: Available"
else
    echo "❌ FreeSurfer: Not available"
fi

echo ""
echo "🌐 Access URLs:"
echo "==============="
echo "📱 NeuroInsight API:    http://localhost:8000"
echo "📚 API Documentation:   http://localhost:8000/docs"
echo "📦 MinIO Console:       http://localhost:9001"
echo "  Username: neuroinsight_minio"
echo "  Password: (see .env.production.services)"
echo ""
echo "🔧 Management Commands:"
echo "======================"
echo "View logs:     docker-compose -f docker-compose.production.yml logs -f"
echo "Stop services: docker-compose -f docker-compose.production.yml down"
echo "Restart:       docker-compose -f docker-compose.production.yml restart"
echo ""
echo "📁 Data Locations:"
echo "=================="
echo "PostgreSQL data: ./backups/postgres/"
echo "MinIO data:      ./backups/minio/"
echo "MRI uploads:     ./data/uploads/"
echo "Processing results: ./data/outputs/"
echo ""
echo "🎉 Setup complete! NeuroInsight is ready for medical imaging analysis."
