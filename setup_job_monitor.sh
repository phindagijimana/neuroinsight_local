#!/bin/bash
# Setup NeuroInsight Job Monitor for automatic system resilience

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Setting up NeuroInsight Job Monitor for automatic interruption recovery..."

# Check if systemd is available
if command -v systemctl &> /dev/null; then
    log_info "Setting up systemd service..."

    # Copy service file
    sudo cp systemd-services/neuroinsight-job-monitor.service /etc/systemd/system/
    sudo systemctl daemon-reload

    # Enable and start
    sudo systemctl enable neuroinsight-job-monitor.service
    sudo systemctl start neuroinsight-job-monitor.service

    log_success "Systemd job monitor service installed and started"
    log_info "Monitor will automatically check for interrupted jobs every 60 seconds"

elif command -v crontab &> /dev/null; then
    log_info "Setting up cron job..."

    # Create cron job that runs every minute
    CRON_JOB="* * * * * cd /home/ubuntu/src/desktop_alone_web_1 && /home/ubuntu/src/desktop_alone_web_1/venv/bin/python3 -c \"from backend.services.job_monitor import JobMonitor; m = JobMonitor(); m.check_now()\" 2>/dev/null"

    # Add to crontab (avoid duplicates)
    (crontab -l 2>/dev/null | grep -v "job_monitor\|neuroinsight.*check" ; echo "$CRON_JOB") | crontab -

    log_success "Cron job installed - will check for interrupted jobs every minute"

else
    log_warning "Neither systemd nor cron available"
    log_info "Job monitoring will only run when NeuroInsight application is started"
    log_info "For maximum resilience, consider installing systemd or cron"
fi

log_success "Job monitor setup complete!"
echo
echo "The job monitor will automatically:"
echo "• Detect jobs interrupted by system sleep/shutdown"
echo "• Mark interrupted jobs as failed"
echo "• Clean up stopped containers"
echo "• Allow failed jobs to be deleted normally"
echo
echo "This prevents stuck jobs and ensures system resilience."
