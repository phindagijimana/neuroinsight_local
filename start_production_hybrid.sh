#!/bin/bash
# NeuroInsight Production Hybrid Deployment
# Everything runs natively except FreeSurfer in containers

echo "🧠 Starting NeuroInsight Production (Hybrid Mode)"
echo "================================================="

# Set production environment
export PYTHONPATH="/mnt/nfs/home/urmc-sh.rochester.edu/pndagiji/hippo/desktop_alone_web"
export NEUROINSIGHT_ENV="production"
export ENVIRONMENT="production"
export LOG_LEVEL="INFO"

# Ensure virtual environment is active
if [ -z "$VIRTUAL_ENV" ]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
fi

# Create necessary directories
mkdir -p data/uploads data/outputs data/logs

# Start Redis (if not already running)
echo "Starting Redis..."
redis-server --daemonize yes --port 6379 --logfile data/logs/redis.log

# Start PostgreSQL (if using local instance)
# Note: In production, you'd typically use a managed PostgreSQL service
echo "PostgreSQL should be running externally..."

# Start Celery worker
echo "Starting Celery worker..."
PYTHONPATH=/mnt/nfs/home/urmc-sh.rochester.edu/pndagiji/hippo/desktop_alone_web \
celery -A workers.tasks.processing_web worker \
    --loglevel=info --concurrency=1 \
    > data/logs/celery.log 2>&1 &
echo $! > worker.pid

# Wait a moment for services to start
sleep 3

# Start the main application
echo "Starting NeuroInsight backend..."
PYTHONPATH=/mnt/nfs/home/urmc-sh.rochester.edu/pndagiji/hippo/desktop_alone_web \
python backend/main.py > data/logs/backend.log 2>&1 &
echo $! > backend.pid

echo ""
echo "🎉 NeuroInsight Production Hybrid Started!"
echo "=========================================="
echo "• Backend: http://localhost:8000"
echo "• API Docs: http://localhost:8000/docs"
echo "• Worker PID: $(cat worker.pid)"
echo "• Backend PID: $(cat backend.pid)"
echo ""
echo "📊 Check logs:"
echo "  tail -f data/logs/backend.log"
echo "  tail -f data/logs/celery.log"
echo ""
echo "🛑 To stop: ./stop_production_hybrid.sh"
