#!/bin/bash
# Start NeuroInsight with Production Services

set -e

echo "🧠 Starting NeuroInsight with Production Services"

# Load production environment
if [ -f ".env.production.services" ]; then
    echo "📝 Loading production configuration..."
    set -a
    source .env.production.services
    set +a
fi

# Activate virtual environment
source venv/bin/activate

# Run database migrations
echo "🗄️ Running database migrations..."
PYTHONPATH=. alembic upgrade head

# Start Celery workers
echo "⚙️ Starting Celery workers..."
PYTHONPATH=. celery -A workers.tasks.processing_web worker \
    --loglevel=info \
    --concurrency=4 \
    --hostname=neuroinsight-worker@%h \
    --logfile=data/logs/celery.log &
echo $! > data/celery-worker.pid

# Start Celery beat (scheduler)
echo "📅 Starting Celery beat..."
PYTHONPATH=. celery -A workers.tasks.processing_web beat \
    --loglevel=info \
    --scheduler celery.beat.PersistentScheduler \
    --logfile=data/logs/celery-beat.log &
echo $! > data/celery-beat.pid

# Start FastAPI application
echo "🚀 Starting NeuroInsight API..."
PYTHONPATH=. uvicorn backend.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 2 \
    --log-level info \
    --access-log \
    --log-config backend/core/logging.py &
echo $! > data/neuroinsight.pid

echo "✅ NeuroInsight started successfully!"
echo ""
echo "🌐 Services:"
echo "   API: http://localhost:8000"
echo "   Docs: http://localhost:8000/docs"
echo "   MinIO: http://localhost:9001"
echo ""
echo "📊 Process IDs:"
echo "   API: $(cat data/neuroinsight.pid)"
echo "   Celery Worker: $(cat data/celery-worker.pid)"
echo "   Celery Beat: $(cat data/celery-beat.pid)"
echo ""
echo "🛑 To stop: ./stop-production-services.sh"
