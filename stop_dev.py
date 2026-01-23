#!/usr/bin/env python3
"""
NeuroInsight Development Stop Script
Stops dev backend services without touching production.
"""

import os
import signal
import time
import psutil
from pathlib import Path

# Colors for output
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'


def log_info(msg):
    print(f"{BLUE}[INFO]{NC} {msg}")


def log_success(msg):
    print(f"{GREEN}[SUCCESS]{NC} {msg}")


def log_warning(msg):
    print(f"{YELLOW}[WARNING]{NC} {msg}")


def log_error(msg):
    print(f"{RED}[ERROR]{NC} {msg}")


def kill_process_by_pid_file(pid_file, process_name):
    """Kill process using PID file (dev-only)"""
    if not os.path.exists(pid_file):
        log_info(f"No {process_name} PID file found")
        return False

    try:
        with open(pid_file, 'r') as f:
            pid = int(f.read().strip())

        if psutil.pid_exists(pid):
            log_info(f"Stopping {process_name} (PID: {pid})...")
            try:
                os.kill(pid, signal.SIGTERM)
                for _ in range(10):
                    if not psutil.pid_exists(pid):
                        break
                    time.sleep(1)
                if psutil.pid_exists(pid):
                    log_warning(f"{process_name} didn't stop gracefully, forcing...")
                    os.kill(pid, signal.SIGKILL)
                else:
                    log_success(f"{process_name} stopped")
            except OSError:
                log_warning(f"{process_name} already stopped")
        else:
            log_warning(f"{process_name} PID file exists but process not running")
    except (ValueError, IOError) as e:
        log_warning(f"Error reading {process_name} PID file: {e}")

    try:
        os.remove(pid_file)
    except OSError:
        pass
    return True


def main():
    print("=" * 50)
    print("   NeuroInsight Dev Stop")
    print("=" * 50)
    print()

    script_dir = Path(__file__).parent
    os.chdir(script_dir)

    log_info("Stopping dev services...")
    kill_process_by_pid_file("dev_backend.pid", "dev backend")
    kill_process_by_pid_file("dev_celery.pid", "dev Celery worker")
    kill_process_by_pid_file("dev_job_monitor.pid", "dev job monitor")
    kill_process_by_pid_file("dev_job_queue_processor.pid", "dev job queue processor")

    print()
    log_success("Dev services stopped")
    print("=" * 50)


if __name__ == "__main__":
    main()

