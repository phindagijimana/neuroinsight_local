#!/bin/bash
# NeuroInsight Fully Native Deployment Startup
# Starts PostgreSQL + Redis + MinIO + Python Application

set -e

echo "🖥️ Starting NeuroInsight Fully Native Deployment"
echo "================================================"

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Load native environment
if [ -f ".env.native" ]; then
    echo "📝 Loading native environment configuration..."
    set -a
    source .env.native
    set +a
else
    echo "❌ .env.native file not found."
    echo "   Please create it from the template or run the installation script."
    exit 1
fi

# Make scripts executable
chmod +x start_native_services.sh stop_native_services.sh monitor_native_services.sh

# Activate Python virtual environment
if [ -d "venv" ]; then
    echo "🐍 Activating Python virtual environment..."
    source venv/bin/activate
else
    echo "❌ Virtual environment not found. Please run installation first."
    exit 1
fi

# Phase 1: Start Native Services
echo ""
echo "🔧 Phase 1: Starting Native Services"
echo "===================================="
./start_native_services.sh

# Phase 2: Run Database Migrations (if needed)
echo ""
echo "🗄️ Phase 2: Database Setup"
echo "=========================="

# Check if database needs migration
if [ -f "neuroinsight_web.db" ] && [ ! -f ".migration_completed" ]; then
    echo "📋 SQLite database detected. Checking if migration is needed..."

    # Check if PostgreSQL is empty
    JOB_COUNT=$(python -c "
import os
os.environ['DATABASE_URL'] = '${DATABASE_URL}'
try:
    from backend.database import get_db
    from backend.models import Job
    from sqlalchemy.orm import Session
    db: Session = next(get_db())
    count = db.query(Job).count()
    db.close()
    print(count)
except:
    print('0')
" 2>/dev/null)

    if [ "${JOB_COUNT}" = "0" ] || [ "${JOB_COUNT}" = "" ]; then
        echo "🔄 Running database migration from SQLite to PostgreSQL..."
        python migrate_sqlite_to_postgresql.py

        if [ $? -eq 0 ]; then
            echo "✅ Migration completed successfully"
            touch .migration_completed
        else
            echo "❌ Migration failed. Please check logs and resolve issues."
            exit 1
        fi
    else
        echo "ℹ️ PostgreSQL database already has data. Skipping migration."
        touch .migration_completed
    fi
else
    echo "ℹ️ No SQLite database found or migration already completed."
fi

# Phase 3: Start Python Application
echo ""
echo "🐍 Phase 3: Starting Python Application"
echo "======================================="

# Start Celery worker
echo "⚙️ Starting Celery worker..."
PYTHONPATH="${SCRIPT_DIR}" \
celery -A workers.tasks.processing_web worker \
    --loglevel=info \
    --concurrency=1 \
    --hostname=neuroinsight-worker@%h \
    > "${LOG_DIR}/celery.log" 2>&1 &
echo $! > "${CELERY_PID}"
echo "✅ Celery worker started (PID: $(cat "${CELERY_PID}"))"

# Wait for services to be ready
sleep 3

# Start FastAPI application
echo "🚀 Starting NeuroInsight FastAPI backend..."
PYTHONPATH="${SCRIPT_DIR}" \
uvicorn backend.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 1 \
    --log-level info \
    > "${LOG_DIR}/backend.log" 2>&1 &
echo $! > "${BACKEND_PID}"
echo "✅ FastAPI backend started (PID: $(cat "${BACKEND_PID}"))"

# Phase 4: Health Checks
echo ""
echo "🔍 Phase 4: Health Verification"
echo "==============================="

echo "Waiting for application to start..."
sleep 5

# Check backend health
if curl -f http://localhost:8000/health >/dev/null 2>&1; then
    echo "✅ FastAPI backend is responding"
else
    echo "❌ FastAPI backend health check failed"
    exit 1
fi

# Check API endpoints
if curl -f http://localhost:8000/api/jobs >/dev/null 2>&1; then
    echo "✅ API endpoints are accessible"
else
    echo "❌ API endpoints not accessible"
    exit 1
fi

echo ""
echo "🎉 NeuroInsight Fully Native Deployment Started!"
echo "================================================"
echo ""
echo "🌐 Access your application:"
echo "   • Web Interface: http://localhost:8000"
echo "   • API Documentation: http://localhost:8000/docs"
echo "   • MinIO Console: http://localhost:9001"
echo ""
echo "📊 Service Status:"
echo "   • PostgreSQL: localhost:${POSTGRES_PORT}"
echo "   • Redis: localhost:${REDIS_PORT}"
echo "   • MinIO: localhost:${MINIO_PORT}"
echo "   • FastAPI Backend: PID $(cat "${BACKEND_PID}")"
echo "   • Celery Worker: PID $(cat "${CELERY_PID}")"
echo ""
echo "📝 Logs Location: ${LOG_DIR}"
echo "   • Backend: tail -f ${LOG_DIR}/backend.log"
echo "   • Celery: tail -f ${LOG_DIR}/celery.log"
echo "   • PostgreSQL: tail -f ${LOG_DIR}/postgresql.log"
echo "   • Redis: tail -f ${LOG_DIR}/redis.log"
echo "   • MinIO: tail -f ${LOG_DIR}/minio.log"
echo ""
echo "🛑 To stop everything: ./stop_fully_native.sh"
echo "📊 To monitor: ./monitor_native_services.sh"
echo ""
echo "💾 Data Locations:"
echo "   • PostgreSQL: ${POSTGRES_DATA_DIR}"
echo "   • Redis: ${REDIS_DATA_DIR}"
echo "   • MinIO: ${MINIO_DATA_DIR}"
echo "   • Uploads: ${UPLOAD_DIR}"
echo "   • Outputs: ${OUTPUT_DIR}"








