#!/bin/bash
# Stop NeuroInsight Production Hybrid Deployment

echo "🛑 Stopping NeuroInsight Production (Hybrid Mode)"
echo "================================================="

# Stop backend
if [ -f backend.pid ]; then
    PID=$(cat backend.pid)
    if ps -p $PID > /dev/null; then
        echo "Stopping backend (PID: $PID)..."
        kill $PID
    fi
    rm -f backend.pid
fi

# Stop worker
if [ -f worker.pid ]; then
    PID=$(cat worker.pid)
    if ps -p $PID > /dev/null; then
        echo "Stopping worker (PID: $PID)..."
        kill $PID
    fi
    rm -f worker.pid
fi

# Stop Redis
echo "Stopping Redis..."
pkill redis-server

echo "✅ NeuroInsight stopped"
