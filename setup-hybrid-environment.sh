#!/bin/bash
# Hybrid Setup: Docker services + Native NeuroInsight app

set -e

echo "🔄 Setting up NeuroInsight Hybrid Environment"
echo "============================================"
echo "🐳 Docker: PostgreSQL, Redis, MinIO, FreeSurfer"
echo "🐧 Native: NeuroInsight API + Celery workers"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first:"
    echo "   Ubuntu: sudo apt install docker.io docker-compose"
    exit 1
fi

# Create necessary directories
echo "📁 Creating data directories..."
mkdir -p data/{uploads,outputs,freesurfer,logs}
mkdir -p backups/{postgres,minio}

# Generate secure passwords if .env doesn't exist
if [ ! -f ".env.production.services" ]; then
    echo "🔐 Generating secure passwords..."
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    MINIO_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    SECRET_KEY=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-64)

    cat > .env.production.services << ENV_EOF
# Hybrid Environment Configuration - Auto-generated $(date)

# PostgreSQL
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
DATABASE_URL=postgresql://neuroinsight:${POSTGRES_PASSWORD}@localhost:5432/neuroinsight

# Redis
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_URL=redis://:${REDIS_PASSWORD}@localhost:6379/0
CELERY_BROKER_URL=redis://:${REDIS_PASSWORD}@localhost:6379/0
CELERY_RESULT_BACKEND=redis://:${REDIS_PASSWORD}@localhost:6379/0

# MinIO
MINIO_ROOT_USER=neuroinsight_minio
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=neuroinsight_minio
MINIO_SECRET_KEY=${MINIO_ROOT_PASSWORD}
MINIO_BUCKET=neuroinsight
MINIO_USE_SSL=false

# FreeSurfer
FREESURFER_HOME=/usr/local/freesurfer
SUBJECTS_DIR=./data/freesurfer/subjects

# Application (Native)
ENVIRONMENT=production
LOG_LEVEL=INFO
SECRET_KEY=${SECRET_KEY}
API_HOST=0.0.0.0
API_PORT=8002

# Processing
MAX_CONCURRENT_JOBS=2
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
echo "🐳 Starting Docker Services..."
docker-compose -f docker-compose.hybrid.yml up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 20

# Check service health
echo ""
echo "📊 Service Status:"
echo "=================="

# PostgreSQL
if docker-compose -f docker-compose.hybrid.yml exec -T postgres pg_isready -U neuroinsight >/dev/null 2>&1; then
    echo "✅ PostgreSQL: Running"
else
    echo "❌ PostgreSQL: Not responding"
fi

# Redis
if docker-compose -f docker-compose.hybrid.yml exec -T redis redis-cli --raw incr ping >/dev/null 2>&1; then
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
if docker-compose -f docker-compose.hybrid.yml exec -T freesurfer which recon-all >/dev/null 2>&1; then
    echo "✅ FreeSurfer: Available"
else
    echo "❌ FreeSurfer: Not available"
fi

echo ""
echo "🐧 Setting up Native NeuroInsight Environment..."
echo "==============================================="

# Setup Python virtual environment
if [ ! -d "venv" ]; then
    echo "🐍 Creating Python virtual environment..."
    python3 -m venv venv
fi

echo "📦 Installing Python dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r backend/requirements.txt

# Initialize database
echo "🗄️ Initializing database..."
PYTHONPATH=. python -c "
from backend.core.database import init_db
from backend.core.config import get_settings
print('Initializing database...')
init_db()
print('✅ Database initialized successfully')
"

echo ""
echo "🚀 NeuroInsight Hybrid Setup Complete!"
echo "======================================"
echo ""
echo "🌐 Services:"
echo "   Docker Services: PostgreSQL, Redis, MinIO, FreeSurfer"
echo "   Native App: NeuroInsight API (port 8002)"
echo ""
echo "🛠️ To start the application:"
echo "   1. Start Docker services: docker-compose -f docker-compose.hybrid.yml up -d"
echo "   2. Start native app: source venv/bin/activate && PYTHONPATH=. uvicorn backend.main:app --host 0.0.0.0 --port 8002"
echo ""
echo "📊 Access:"
echo "   NeuroInsight: http://localhost:8002"
echo "   MinIO Console: http://localhost:9001"
echo "   API Docs: http://localhost:8002/docs"
echo ""
echo "🛑 To stop:"
echo "   docker-compose -f docker-compose.hybrid.yml down"
