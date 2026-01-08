"""
Background job monitoring service for NeuroInsight.

This service runs in the background to detect and handle interrupted jobs,
providing resilience against system sleep/shutdown events.
"""

import threading
import time
import signal
import sys
import os
from typing import Optional

from backend.services.task_management_service import TaskManagementService
from backend.core.logging import get_logger

logger = get_logger(__name__)


class JobMonitor:
    """
    Background service that monitors for interrupted jobs.

    Runs periodic checks to detect container-job mismatches and
    handles system interruptions gracefully.
    """

    def __init__(self, check_interval: int = 60):
        """
        Initialize the job monitor.

        Args:
            check_interval: Seconds between maintenance checks (default: 60)
        """
        self.check_interval = check_interval
        self.monitor_thread: Optional[threading.Thread] = None
        self.running = False
        self.pid_file = "job_monitor.pid"

    def start_background_monitoring(self):
        """
        Start background monitoring in a separate thread.
        This allows the main application to continue while monitoring runs.
        """
        if self.monitor_thread and self.monitor_thread.is_alive():
            logger.info("job_monitor_already_running")
            return

        self.running = True
        self.monitor_thread = threading.Thread(
            target=self._monitor_loop,
            name="JobMonitor",
            daemon=True  # Exit when main thread exits
        )
        self.monitor_thread.start()

        # Save PID for process management
        with open(self.pid_file, 'w') as f:
            f.write(str(os.getpid()))

        logger.info("background_job_monitoring_started",
                   check_interval=self.check_interval)

    def stop_monitoring(self):
        """Stop the background monitoring."""
        self.running = False
        if self.monitor_thread:
            self.monitor_thread.join(timeout=5)

        # Clean up PID file
        if os.path.exists(self.pid_file):
            os.remove(self.pid_file)

        logger.info("background_job_monitoring_stopped")

    def _monitor_loop(self):
        """
        Main monitoring loop that runs in background thread.
        Performs periodic maintenance checks.
        """
        logger.info("job_monitor_loop_started")

        while self.running:
            try:
                # Run maintenance check
                result = TaskManagementService.run_maintenance()
                container_mismatches = result.get('container_mismatches', [])
                stuck_jobs = result.get('stuck_jobs', [])

                if container_mismatches or stuck_jobs:
                    logger.info("maintenance_check_found_issues",
                              container_mismatches=len(container_mismatches),
                              stuck_jobs=len(stuck_jobs))

                # Check for and process pending jobs
                try:
                    from backend.core.database import SessionLocal
                    from backend.services.job_service import JobService

                    db = SessionLocal()
                    try:
                        pending_count = JobService.count_jobs_by_status(db, ['PENDING'])
                        running_count = JobService.count_jobs_by_status(db, ['RUNNING'])

                        if pending_count > 0 and running_count == 0:
                            logger.info("monitor_found_pending_jobs_processing_queue",
                                      pending_count=pending_count)
                            JobService.process_job_queue(db)
                        elif pending_count > 0:
                            logger.debug("pending_jobs_waiting_for_running_jobs",
                                       pending_count=pending_count,
                                       running_count=running_count)
                    finally:
                        db.close()

                except Exception as queue_error:
                    logger.warning("job_queue_processing_failed_in_monitor",
                                 error=str(queue_error))

                # Sleep until next check
                time.sleep(self.check_interval)

            except Exception as e:
                logger.error("job_monitor_error", error=str(e), exc_info=True)
                # Continue monitoring despite errors
                time.sleep(min(self.check_interval, 30))  # Don't spam on errors

        logger.info("job_monitor_loop_ended")

    def check_now(self):
        """
        Perform an immediate maintenance check.
        Useful for manual triggering or testing.
        """
        logger.info("manual_maintenance_check_triggered")
        result = TaskManagementService.run_maintenance()
        logger.info("manual_maintenance_check_completed",
                   container_mismatches=len(result.get('container_mismatches', [])),
                   stuck_jobs=len(result.get('stuck_jobs', [])))
        return result


def signal_handler(signum, frame):
    """Handle shutdown signals gracefully."""
    logger.info("job_monitor_received_signal", signal=signum)
    if 'monitor' in globals():
        monitor.stop_monitoring()
    sys.exit(0)


# Global monitor instance for signal handling
monitor: Optional[JobMonitor] = None

if __name__ == "__main__":
    # Allow running as standalone service
    import argparse

    parser = argparse.ArgumentParser(description="NeuroInsight Job Monitor")
    parser.add_argument("--interval", type=int, default=60,
                       help="Check interval in seconds (default: 60)")
    parser.add_argument("--daemon", action="store_true",
                       help="Run as daemon (background)")
    parser.add_argument("--check-now", action="store_true",
                       help="Perform immediate check and exit")

    args = parser.parse_args()

    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # Create monitor
    monitor = JobMonitor(check_interval=args.interval)

    if args.check_now:
        # One-time check
        monitor.check_now()
    elif args.daemon:
        # Run as daemon
        logger.info("starting_job_monitor_daemon", interval=args.interval)
        monitor.start_background_monitoring()

        # Keep running until signal
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            pass
        finally:
            monitor.stop_monitoring()
    else:
        # Interactive mode
        logger.info("starting_job_monitor_interactive")
        monitor.start_background_monitoring()

        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("interactive_monitor_stopped")
        finally:
            monitor.stop_monitoring()
