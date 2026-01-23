#!/usr/bin/env python3
"""
NeuroInsight Development Start Script
Starts a dev backend on port 8001 with Celery/Redis enabled, without touching prod.
"""

import os
import sys
import subprocess
import time
import signal
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


def check_port_available(port):
    """Check if a port is available"""
    import socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        result = sock.connect_ex(('localhost', port))
        return result != 0


def ensure_docker_service(name, run_cmd):
    """Ensure Docker container is running; start or run as needed."""
    try:
        running = subprocess.run(
            ['docker', 'ps', '-q', '-f', f'name={name}'],
            capture_output=True, text=True, check=False
        )
        if running.returncode == 0 and running.stdout.strip():
            log_success(f"{name} already running")
            return True

        exists = subprocess.run(
            ['docker', 'ps', '-a', '-q', '-f', f'name={name}'],
            capture_output=True, text=True, check=False
        )
        if exists.returncode == 0 and exists.stdout.strip():
            log_info(f"Starting existing {name} container...")
            start_result = subprocess.run(['docker', 'start', name], capture_output=True, text=True)
            if start_result.returncode == 0:
                log_success(f"{name} started")
                return True
            log_error(f"Failed to start {name}: {start_result.stderr}")
            return False

        log_info(f"Creating and starting {name}...")
        result = subprocess.run(run_cmd, capture_output=True, text=True)
        if result.returncode == 0:
            log_success(f"{name} started")
            return True
        log_error(f"{name} startup failed: {result.stderr}")
        return False
    except Exception as e:
        log_error(f"Docker error for {name}: {e}")
        return False


def start_docker_services():
    """Start Docker services if not already running (dev-safe)."""
    log_info("Ensuring Docker services are running...")

    postgres_cmd = [
        'docker', 'run', '-d',
        '--name', 'neuroinsight-postgres',
        '-e', 'POSTGRES_DB=neuroinsight',
        '-e', 'POSTGRES_USER=neuroinsight',
        '-e', 'POSTGRES_PASSWORD=JkBTFCoM0JepvhEjvoWtQlfuy4XBXFTnzwExLxe1rg',
        '-p', '5432:5432',
        '--restart', 'unless-stopped',
        'postgres:15-alpine'
    ]

    redis_cmd = [
        'docker', 'run', '-d',
        '--name', 'neuroinsight-redis',
        '-p', '6379:6379',
        '--restart', 'unless-stopped',
        'redis:7-alpine',
        'redis-server', '--appendonly', 'yes', '--requirepass', 'redis_secure_password'
    ]

    minio_cmd = [
        'docker', 'run', '-d',
        '--name', 'neuroinsight-minio',
        '-e', 'MINIO_ROOT_USER=neuroinsight_minio',
        '-e', 'MINIO_ROOT_PASSWORD=minio_secure_password',
        '-p', '9000:9000',
        '-p', '9001:9001',
        '--restart', 'unless-stopped',
        'minio/minio:latest',
        'server', '/data', '--console-address', ':9001'
    ]

    ok = True
    ok &= ensure_docker_service('neuroinsight-postgres', postgres_cmd)
    ok &= ensure_docker_service('neuroinsight-redis', redis_cmd)
    ok &= ensure_docker_service('neuroinsight-minio', minio_cmd)
    return ok


def start_backend(port):
    """Start the NeuroInsight backend (dev)"""
    try:
        log_info(f"Starting dev backend on port {port}...")

        env = os.environ.copy()
        env['PYTHONPATH'] = str(Path.cwd())
        env['API_PORT'] = str(port)
        env['PORT'] = str(port)
        env['ENVIRONMENT'] = 'development'
        env['FORCE_CELERY'] = 'true'
        env['MAX_CONCURRENT_JOBS'] = '1'
        env['DATABASE_URL'] = 'postgresql://neuroinsight:JkBTFCoM0JepvhEjvoWtQlfuy4XBXFTnzwExLxe1rg@localhost:5432/neuroinsight'

        proc = subprocess.Popen(
            [sys.executable, 'backend/main.py'],
            env=env,
            stdout=open('dev_backend.log', 'w'),
            stderr=subprocess.STDOUT
        )

        with open('dev_backend.pid', 'w') as f:
            f.write(str(proc.pid))

        log_success(f"Dev backend started (PID: {proc.pid})")

        log_info("Waiting for dev backend to be ready...")
        for _ in range(30):
            try:
                import requests
                response = requests.get(f'http://localhost:{port}/health', timeout=2)
                if response.status_code == 200:
                    log_success("Dev backend health check passed!")
                    return proc
            except Exception:
                pass
            time.sleep(1)

        log_error("Dev backend failed health checks")
        proc.kill()
        return None
    except Exception as e:
        log_error(f"Dev backend startup failed: {e}")
        return None


def start_celery():
    """Start Celery worker (dev)"""
    try:
        log_info("Starting dev Celery worker...")

        env = os.environ.copy()
        env['PYTHONPATH'] = str(Path.cwd())

        proc = subprocess.Popen(
            [
                sys.executable, '-m', 'celery',
                '-A', 'workers.tasks.processing_web',
                'worker', '--loglevel=info', '--concurrency=4'
            ],
            env=env,
            stdout=open('dev_celery_worker.log', 'w'),
            stderr=subprocess.STDOUT
        )

        with open('dev_celery.pid', 'w') as f:
            f.write(str(proc.pid))

        log_success(f"Dev Celery worker started (PID: {proc.pid})")
        return proc
    except Exception as e:
        log_warning(f"Dev Celery startup failed: {e}")
        return None


def start_job_monitor():
    """Start job monitoring service (dev)"""
    try:
        log_info("Starting dev job monitor...")

        env = os.environ.copy()
        env['PYTHONPATH'] = str(Path.cwd())

        proc = subprocess.Popen(
            [
                sys.executable, '-c',
                """
import sys
sys.path.insert(0, '.')
from backend.services.job_monitor import JobMonitor
monitor = JobMonitor()
monitor.start_background_monitoring()
"""
            ],
            env=env,
            stdout=open('dev_job_monitor.log', 'w'),
            stderr=subprocess.STDOUT
        )

        with open('dev_job_monitor.pid', 'w') as f:
            f.write(str(proc.pid))

        log_success(f"Dev job monitor started (PID: {proc.pid})")
        return proc
    except Exception as e:
        log_warning(f"Dev job monitor startup failed: {e}")
        return None


def start_job_queue_processor():
    """Start job queue processor service (dev)"""
    try:
        log_info("Starting dev job queue processor...")

        env = os.environ.copy()
        env['PYTHONPATH'] = str(Path.cwd())

        proc = subprocess.Popen(
            [
                sys.executable, '-c',
                """
import sys
sys.path.insert(0, '.')
from backend.services.job_queue_processor import start_job_queue_processor
start_job_queue_processor()
import time
while True:
    time.sleep(60)
"""
            ],
            env=env,
            stdout=open('dev_job_queue_processor.log', 'w'),
            stderr=subprocess.STDOUT
        )

        with open('dev_job_queue_processor.pid', 'w') as f:
            f.write(str(proc.pid))

        log_success(f"Dev job queue processor started (PID: {proc.pid})")
        return proc
    except Exception as e:
        log_warning(f"Dev job queue processor startup failed: {e}")
        return None


def main():
    print("=" * 50)
    print("   NeuroInsight Dev Startup")
    print("=" * 50)
    print()

    script_dir = Path(__file__).parent
    os.chdir(script_dir)

    if not check_port_available(8001):
        log_error("Port 8001 is already in use. Stop the dev backend first.")
        sys.exit(1)

    # Stop any previous dev processes
    kill_process_by_pid_file("dev_backend.pid", "dev backend")
    kill_process_by_pid_file("dev_celery.pid", "dev Celery worker")
    kill_process_by_pid_file("dev_job_monitor.pid", "dev job monitor")
    kill_process_by_pid_file("dev_job_queue_processor.pid", "dev job queue processor")

    # Ensure Docker services are running
    if not start_docker_services():
        log_error("Failed to ensure Docker services")
        sys.exit(1)

    backend_proc = start_backend(8001)
    if not backend_proc:
        log_error("Failed to start dev backend")
        sys.exit(1)

    celery_proc = start_celery()
    if not celery_proc:
        log_warning("Dev Celery worker failed to start - continuing anyway")

    monitor_proc = start_job_monitor()
    if not monitor_proc:
        log_warning("Dev job monitor failed to start - continuing anyway")

    queue_proc = start_job_queue_processor()
    if not queue_proc:
        log_warning("Dev job queue processor failed to start - continuing anyway")

    print()
    print("=" * 50)
    log_success("NeuroInsight dev backend is running!")
    print("   Dev API: http://localhost:8001")
    print("   Dev API Docs: http://localhost:8001/docs")
    print("   Dev Health: http://localhost:8001/health")
    print("   Dev Frontend: http://localhost:5173")
    print("=" * 50)


if __name__ == "__main__":
    main()

