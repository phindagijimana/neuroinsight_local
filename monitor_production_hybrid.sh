#!/bin/bash
# Monitor NeuroInsight Production Hybrid Deployment

echo "📊 NeuroInsight Production Monitor"
echo "=================================="

# Check backend
if [ -f backend.pid ]; then
    PID=$(cat backend.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "✅ Backend running (PID: $PID)"
        # Test health endpoint
        if curl -s http://localhost:8000/health > /dev/null 2>&1; then
            echo "   ✅ Health check passed"
        else
            echo "   ❌ Health check failed"
        fi
    else
        echo "❌ Backend not running (stale PID)"
        rm -f backend.pid
    fi
else
    echo "❌ Backend PID file not found"
fi

# Check worker
if [ -f worker.pid ]; then
    PID=$(cat worker.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "✅ Worker running (PID: $PID)"
    else
        echo "❌ Worker not running (stale PID)"
        rm -f worker.pid
    fi
else
    echo "❌ Worker PID file not found"
fi

# Check Redis
if pgrep redis-server > /dev/null 2>&1; then
    echo "✅ Redis running"
else
    echo "❌ Redis not running"
fi

echo ""
echo "📝 Recent logs:"
echo "tail -f data/logs/backend.log"
echo "tail -f data/logs/celery.log"
