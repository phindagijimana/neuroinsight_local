#!/bin/bash
export USE_REAL_FREESURFER=true
export NEUROINSIGHT_ALLOW_MOCK_FALLBACK=false
export PYTHONPATH=/home/ubuntu/src/desktop_alone_web_1

echo "Starting NeuroInsight with FreeSurfer processing enabled..."
echo "USE_REAL_FREESURFER=$USE_REAL_FREESURFER"
echo "NEUROINSIGHT_ALLOW_MOCK_FALLBACK=$NEUROINSIGHT_ALLOW_MOCK_FALLBACK"

# Start backend
python3 backend/main.py > backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend started (PID: $BACKEND_PID)"

# Wait a bit for backend to start
sleep 5

# Start Celery worker with explicit environment
USE_REAL_FREESURFER=true NEUROINSIGHT_ALLOW_MOCK_FALLBACK=false PYTHONPATH=/home/ubuntu/src/desktop_alone_web_1 python3 -m celery -A workers.tasks.processing_web worker --loglevel=info --concurrency=1 > celery.log 2>&1 &
CELERY_PID=$!
echo "Celery worker started (PID: $CELERY_PID)"

echo "NeuroInsight started successfully!"
echo "Backend PID: $BACKEND_PID"
echo "Celery PID: $CELERY_PID"
