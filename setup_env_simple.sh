#!/bin/bash
# Simplified NeuroInsight Environment Setup Script
# Automatically configures environment for production deployment

set -e

echo "🔧 NeuroInsight Environment Setup (Simplified)"
echo "============================================="

# Generate secure passwords
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/")
MINIO_SECRET=$(openssl rand -base64 32 | tr -d "=+/")
SECRET_KEY=$(openssl rand -hex 64)

# Choose deployment type
if [ "$1" = "native" ]; then
    DEPLOYMENT_TYPE="native"
    CONFIG_FILE=".env.native"
else
    DEPLOYMENT_TYPE="hybrid"
    CONFIG_FILE=".env.production"
fi

echo "📋 Deployment Type: $DEPLOYMENT_TYPE"
echo "📁 Config File: $CONFIG_FILE"
echo ""

# Backup existing file
if [ -f ".env" ]; then
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backed up existing .env file"
fi

# Create configuration
cat > "$CONFIG_FILE" << ENV_EOF
# NeuroInsight $DEPLOYMENT_TYPE Production Configuration
# Auto-generated on $(date)

# Application
APP_NAME=NeuroInsight
APP_VERSION=1.0.0
ENVIRONMENT=production
LOG_LEVEL=INFO

# API
API_HOST=0.0.0.0
API_PORT=8000
CORS_ORIGINS=http://localhost:8000

# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=neuroinsight
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=neuroinsight

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Celery
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# MinIO
MINIO_ACCESS_KEY=neuroinsight_minio
MINIO_SECRET_KEY=${MINIO_SECRET}
MINIO_ENDPOINT=localhost:9000
MINIO_BUCKET=neuroinsight
MINIO_USE_SSL=false

# Storage
UPLOAD_DIR=./data/uploads
OUTPUT_DIR=./data/outputs
LOG_DIR=./data/logs

# Security
SECRET_KEY=${SECRET_KEY}

# Processing
MAX_CONCURRENT_JOBS=2
PROCESSING_TIMEOUT=18000

# Metadata
DEPLOYMENT_TYPE=${DEPLOYMENT_TYPE}
GENERATED_AT=$(date)
GENERATED_BY=setup_env_simple.sh
ENV_EOF

# Copy to active .env
cp "$CONFIG_FILE" .env

echo "✅ Environment configuration created!"
echo ""
echo "🔐 Generated Credentials:"
echo "========================"
echo "PostgreSQL Password: ${POSTGRES_PASSWORD}"
echo "MinIO Secret Key:    ${MINIO_SECRET}"
echo "Application Secret:  ${SECRET_KEY}"
echo ""
echo "⚠️  SAVE THESE PASSWORDS SECURELY!"
echo ""
echo "📁 Files Created:"
echo "  • $CONFIG_FILE (template)"
echo "  • .env (active configuration)"
echo ""
echo "🚀 Next Steps:"
if [ "$DEPLOYMENT_TYPE" = "native" ]; then
    echo "  1. sudo ./setup_native_services.sh"
    echo "  2. ./start_production_native.sh"
else
    echo "  1. ./start_production_hybrid.sh"
fi
echo "  3. curl http://localhost:8000/health"
