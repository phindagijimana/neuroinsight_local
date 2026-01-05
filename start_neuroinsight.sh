#!/bin/bash
# NeuroInsight Production Startup Script

# Set environment
export PYTHONPATH="/mnt/nfs/home/urmc-sh.rochester.edu/pndagiji/hippo/desktop_alone_web"
export NEUROINSIGHT_ENV="production"

# Activate virtual environment
source venv/bin/activate

# Start application with proper logging
exec python backend/main.py > neuroinsight.log 2>&1 &
echo $! > neuroinsight.pid
echo "NeuroInsight started with PID: $(cat neuroinsight.pid)"
