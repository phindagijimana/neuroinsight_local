#!/bin/bash
# Setup automated health monitoring for NeuroInsight

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up automated NeuroInsight health monitoring..."
echo ""

# Check if cron is available
if ! command -v crontab &> /dev/null; then
    echo "❌ Cron not available on this system"
    exit 1
fi

# Create cron job for health checks every 5 minutes
CRON_JOB="*/5 * * * * $SCRIPT_DIR/check_health.sh"

# Check if the cron job already exists
if crontab -l 2>/dev/null | grep -q "$SCRIPT_DIR/check_health.sh"; then
    echo "✅ Health monitoring cron job already exists"
else
    # Add the cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ Added health monitoring cron job (runs every 5 minutes)"
fi

# Setup systemd service (optional)
read -p "Do you want to set up NeuroInsight as a systemd service for automatic startup? (y/n): " setup_systemd

if [[ $setup_systemd =~ ^[Yy]$ ]]; then
    if [ -f "$SCRIPT_DIR/neuroinsight.service" ]; then
        sudo cp "$SCRIPT_DIR/neuroinsight.service" /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable neuroinsight.service
        echo "✅ NeuroInsight systemd service configured"
        echo "   Use: sudo systemctl start neuroinsight"
        echo "   Use: sudo systemctl stop neuroinsight"
    else
        echo "❌ neuroinsight.service file not found"
    fi
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Monitoring features now active:"
echo "• Health checks every 5 minutes via cron"
echo "• Automatic service restart if containers fail"
echo "• Resource monitoring and alerts"
echo "• Orphaned process cleanup"
echo ""
echo "View health logs: tail -f /tmp/neuroinsight_health.log"
echo "Manual health check: ./check_health.sh"
