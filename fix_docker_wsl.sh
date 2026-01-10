#!/bin/bash
# WSL Docker Fix Script
# Run this from within WSL to fix Docker connectivity issues

echo "🔧 WSL Docker Connectivity Fix"
echo "=============================="
echo

# Check if we're in WSL
if [ -z "$WSL_DISTRO_NAME" ]; then
    echo "❌ This script should be run from within WSL"
    exit 1
fi

echo "✅ Running in WSL environment: $WSL_DISTRO_NAME"
echo

# Stop all Docker-related processes
echo "1. Stopping Docker processes..."
sudo service docker stop 2>/dev/null || true
pkill -f docker 2>/dev/null || true
pkill -f containerd 2>/dev/null || true

# Reset Docker daemon
echo "2. Resetting Docker daemon..."
sudo systemctl stop docker 2>/dev/null || true
sudo systemctl reset-failed docker 2>/dev/null || true

# Clean up Docker resources
echo "3. Cleaning up Docker resources..."
docker system prune -a --volumes -f 2>/dev/null || echo "Docker not accessible, skipping cleanup"

# Restart WSL networking
echo "4. Restarting WSL networking..."
sudo service networking restart 2>/dev/null || true
sudo dhclient -r 2>/dev/null || true
sudo dhclient 2>/dev/null || true

# Wait for Docker Desktop to be ready
echo "5. Waiting for Docker Desktop..."
echo "   Make sure Docker Desktop is running on Windows"
echo "   This may take 1-2 minutes..."
sleep 10

# Test Docker connectivity
echo "6. Testing Docker connectivity..."
max_attempts=12
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo "   Attempt $attempt/$max_attempts..."
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker is accessible!"
        break
    fi

    if docker run --rm hello-world >/dev/null 2>&1; then
        echo "✅ Docker test successful!"
        break
    fi

    sleep 10
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ Docker is still not accessible after $max_attempts attempts"
    echo
    echo "🔧 Additional troubleshooting:"
    echo "1. Ensure Docker Desktop is running on Windows"
    echo "2. Check Docker Desktop settings > Resources > WSL Integration"
    echo "3. Try restarting Docker Desktop completely"
    echo "4. Run the PowerShell fix script on Windows: fix_wsl_docker.ps1"
    exit 1
fi

echo
echo "🎉 SUCCESS: Docker is working in WSL!"
echo
echo "You can now restart NeuroInsight:"
echo "  ./neuroinsight start"
echo
echo "To verify everything works:"
echo "  docker ps"
echo "  ./neuroinsight status"
