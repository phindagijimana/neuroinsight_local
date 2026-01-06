#!/bin/bash
# NeuroInsight Production Startup Script

# Set environment
export PYTHONPATH="$(pwd)"
export NEUROINSIGHT_ENV="production"

# Check FreeSurfer license
echo "Checking FreeSurfer license..."
if [ ! -f "license.txt" ]; then
    echo "ERROR: license.txt not found!"
    echo "Please set up your FreeSurfer license:"
    echo "   1. Copy license.txt.example to license.txt"
    echo "   2. Edit license.txt with your actual license"
    echo "   3. Run ./check_license.sh to verify"
    echo
    echo "Get your free license at: https://surfer.nmr.mgh.harvard.edu/registration.html"
    exit 1
fi

if grep -q "REPLACE THIS EXAMPLE CONTENT" license.txt; then
    echo "ERROR: license.txt contains example content!"
    echo "Please replace with your actual FreeSurfer license"
    echo "   Run ./check_license.sh for detailed instructions"
    exit 1
fi

echo "FreeSurfer license found"

# Activate virtual environment
source venv/bin/activate

# Start application with proper logging
exec python3 backend/main.py > neuroinsight.log 2>&1 &
echo $! > neuroinsight.pid
echo "NeuroInsight started with PID: $(cat neuroinsight.pid)"
