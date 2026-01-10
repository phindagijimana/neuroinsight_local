#!/bin/bash
# NeuroInsight Docker Diagnostic and Fix Script

set -e

echo "🔧 NeuroInsight Docker Diagnostic & Fix Tool"
echo "============================================"
echo

# Check if running as root or with sudo
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Running as root - this is fine for Docker diagnostics"
    SUDO=""
else
    echo "ℹ️  Running as regular user - will use sudo when needed"
    SUDO="sudo"
fi

echo
echo "1. 🔍 CHECKING DOCKER STATUS"
echo "-----------------------------"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    echo "   Install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "✅ Docker is installed: $(docker --version)"

# Check Docker daemon status
echo
echo "2. 🔍 CHECKING DOCKER DAEMON"
echo "----------------------------"

if systemctl is-active --quiet docker; then
    echo "✅ Docker daemon is running"
else
    echo "❌ Docker daemon is not running"
    echo "   Attempting to start Docker daemon..."
    $SUDO systemctl start docker
    sleep 2

    if systemctl is-active --quiet docker; then
        echo "✅ Docker daemon started successfully"
    else
        echo "❌ Failed to start Docker daemon"
        echo "   Try: $SUDO systemctl status docker"
        exit 1
    fi
fi

# Check Docker permissions
echo
echo "3. 🔍 CHECKING DOCKER PERMISSIONS"
echo "----------------------------------"

if groups $USER | grep -q docker; then
    echo "✅ User '$USER' is in docker group"
else
    echo "⚠️  User '$USER' is not in docker group"
    echo "   Adding user to docker group..."
    $SUDO usermod -aG docker $USER
    echo "   ✅ Added user to docker group"
    echo "   🔄 You may need to log out and back in for changes to take effect"
fi

# Test Docker functionality
echo
echo "4. 🔍 TESTING DOCKER FUNCTIONALITY"
echo "-----------------------------------"

echo "Testing basic Docker command..."
if docker run --rm hello-world &> /dev/null; then
    echo "✅ Docker basic functionality: Working"
else
    echo "❌ Docker basic functionality: Failed"
    echo "   Trying alternative test..."

    # Try a simpler test
    if docker ps &> /dev/null; then
        echo "✅ Docker daemon communication: Working"
    else
        echo "❌ Docker daemon communication: Failed"
        echo "   Error details:"
        docker ps 2>&1 | head -5
        exit 1
    fi
fi

# Check Docker daemon logs for recent errors
echo
echo "5. 🔍 CHECKING DOCKER DAEMON LOGS"
echo "----------------------------------"

echo "Recent Docker daemon logs:"
$SUDO journalctl -u docker --since "1 hour ago" --no-pager -n 10 | grep -v "level=info" || echo "No recent error logs found"

# Check system resources
echo
echo "6. 🔍 CHECKING SYSTEM RESOURCES"
echo "--------------------------------"

echo "Memory usage: $(free -h | awk 'NR==2{print $3"/"$2 " (" int($3/$2*100) "%)"}')"
echo "Disk usage: $(df -h / | awk 'NR==2{print $3"/"$2 " (" $5 ")"}')"

# Check if Docker daemon is responsive
echo
echo "7. 🔍 FINAL DOCKER HEALTH CHECK"
echo "--------------------------------"

if docker info &> /dev/null; then
    echo "✅ Docker daemon is healthy and responsive"
    echo "✅ All Docker checks passed!"

    echo
    echo "🎉 SUCCESS: Docker is ready for NeuroInsight!"
    echo
    echo "You can now retry the NeuroInsight installation:"
    echo "  ./neuroinsight install"
    echo
    echo "If you still encounter issues, check:"
    echo "• System has sufficient memory (16GB+ recommended)"
    echo "• Sufficient disk space available"
    echo "• No conflicting processes using Docker"

else
    echo "❌ Docker daemon health check failed"
    echo
    echo "🔧 TROUBLESHOOTING STEPS:"
    echo "1. Restart Docker daemon: $SUDO systemctl restart docker"
    echo "2. Check system resources: free -h && df -h"
    echo "3. Reboot system if issues persist"
    echo "4. Check Docker logs: $SUDO journalctl -u docker --no-pager -n 50"
    exit 1
fi
