#!/usr/bin/env python3
"""
NeuroInsight Start Script - Python-based for reliability
Bypasses terminal corruption issues by using Python directly
"""

import os
import sys
import subprocess
import time
import signal
import psutil
import requests
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

def find_and_kill_processes():
    """Aggressively find and kill all NeuroInsight processes"""
    killed_count = 0

    # Kill by command patterns
    patterns = [
        "python3.*backend/main.py",
        "python3.*celery.*processing_web",
        "python3.*job_monitor"
    ]

    for pattern in patterns:
        try:
            # Use pgrep to find processes
            result = subprocess.run(['pgrep', '-f', pattern],
                                  capture_output=True, text=True)
            if result.returncode == 0:
                pids = result.stdout.strip().split('\n')
                for pid in pids:
                    if pid.strip():
                        try:
                            os.kill(int(pid), signal.SIGKILL)
                            killed_count += 1
                            log_info(f"Killed process {pid}")
                        except (ProcessLookupError, OSError):
                            pass  # Process already dead
        except Exception as e:
            log_warning(f"Error killing {pattern}: {e}")

    # Also try pkill as fallback
    try:
        subprocess.run(['pkill', '-9', '-f', 'neuroinsight'], check=False)
        subprocess.run(['pkill', '-9', '-f', 'celery'], check=False)
        subprocess.run(['pkill', '-9', '-f', 'backend/main.py'], check=False)
    except Exception:
        pass

    if killed_count > 0:
        log_success(f"Cleaned up {killed_count} existing processes")
        time.sleep(2)  # Wait for cleanup

    return killed_count

def check_port_available(port):
    """Check if a port is available"""
    import socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        result = sock.connect_ex(('localhost', port))
        return result != 0  # True if available

def find_available_port(start_port=8000, end_port=8050):
    """Find an available port in the range"""
    for port in range(start_port, end_port + 1):
        if check_port_available(port):
            return port
    return None

def start_docker_services():
    """Start Docker services individually (bypassing docker-compose issues)"""
    try:
        log_info("Starting Docker services individually...")

        services_started = []

        # Start PostgreSQL
        log_info("Starting PostgreSQL...")
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

        result = subprocess.run(postgres_cmd, capture_output=True, text=True)
        if result.returncode == 0:
            log_success("PostgreSQL started")
            services_started.append('postgres')
        else:
            log_error(f"PostgreSQL startup failed: {result.stderr}")
            return False

        # Start Redis
        log_info("Starting Redis...")
        redis_cmd = [
            'docker', 'run', '-d',
            '--name', 'neuroinsight-redis',
            '-p', '6379:6379',
            '--restart', 'unless-stopped',
            'redis:7-alpine',
            'redis-server', '--appendonly', 'yes', '--requirepass', 'redis_secure_password'
        ]

        result = subprocess.run(redis_cmd, capture_output=True, text=True)
        if result.returncode == 0:
            log_success("Redis started")
            services_started.append('redis')
        else:
            log_error(f"Redis startup failed: {result.stderr}")
            return False

        # Start MinIO
        log_info("Starting MinIO...")
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

        result = subprocess.run(minio_cmd, capture_output=True, text=True)
        if result.returncode == 0:
            log_success("MinIO started")
            services_started.append('minio')
        else:
            log_error(f"MinIO startup failed: {result.stderr}")
            return False

        log_success(f"All Docker services started: {', '.join(services_started)}")
        return True

    except Exception as e:
        log_error(f"Docker error: {e}")
        return False

def start_backend(port):
    """Start the NeuroInsight backend"""
    try:
        log_info(f"Starting NeuroInsight backend on port {port}...")

        # Set environment
        env = os.environ.copy()
        env['PYTHONPATH'] = str(Path.cwd())
        env['API_PORT'] = str(port)
        env['PORT'] = str(port)
        # Force PostgreSQL usage for production
        env['DATABASE_URL'] = 'postgresql://neuroinsight:JkBTFCoM0JepvhEjvoWtQlfuy4XBXFTnzwExLxe1rg@localhost:5432/neuroinsight'

        # Start backend
        proc = subprocess.Popen([
            sys.executable, 'backend/main.py'
        ], env=env, stdout=open('neuroinsight.log', 'w'),
           stderr=subprocess.STDOUT)

        # Save PID
        with open('neuroinsight.pid', 'w') as f:
            f.write(str(proc.pid))

        log_success(f"Backend started (PID: {proc.pid})")

        # Wait for health check
        log_info("Waiting for backend to be ready...")
        for i in range(30):  # 30 second timeout
            try:
                response = requests.get(f'http://localhost:{port}/health', timeout=2)
                if response.status_code == 200:
                    log_success("Backend health check passed!")
                    return proc
            except:
                pass
            time.sleep(1)

        log_error("Backend failed to respond to health checks")
        proc.kill()
        return None

    except Exception as e:
        log_error(f"Backend startup failed: {e}")
        return None

def start_celery():
    """Start Celery worker"""
    try:
        log_info("Starting Celery worker...")

        # Set environment
        env = os.environ.copy()
        env['PYTHONPATH'] = str(Path.cwd())

        # Start celery
        proc = subprocess.Popen([
            sys.executable, '-m', 'celery',
            '-A', 'workers.tasks.processing_web',
            'worker', '--loglevel=info', '--concurrency=1'
        ], env=env, stdout=open('celery_worker.log', 'w'),
           stderr=subprocess.STDOUT)

        # Save PID
        with open('celery.pid', 'w') as f:
            f.write(str(proc.pid))

        log_success(f"Celery worker started (PID: {proc.pid})")
        return proc

    except Exception as e:
        log_warning(f"Celery startup failed: {e}")
        return None

def start_job_monitor():
    """Start job monitoring service"""
    try:
        log_info("Starting job monitor...")

        # Set environment
        env = os.environ.copy()
        env['PYTHONPATH'] = str(Path.cwd())

        # Start monitor
        proc = subprocess.Popen([
            sys.executable, '-c',
            """
import sys
sys.path.insert(0, '.')
from backend.services.job_monitor import JobMonitor
monitor = JobMonitor()
monitor.start_background_monitoring()
"""
        ], env=env, stdout=open('job_monitor.log', 'w'),
           stderr=subprocess.STDOUT)

        # Save PID
        with open('job_monitor.pid', 'w') as f:
            f.write(str(proc.pid))

        log_success(f"Job monitor started (PID: {proc.pid})")
        return proc

    except Exception as e:
        log_warning(f"Job monitor startup failed: {e}")
        return None

def main():
    print("=" * 50)
    print("   NeuroInsight Startup (Python-based)")
    print("=" * 50)
    print()

    # Change to script directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)

    # Clean up existing processes
    log_info("Cleaning up any existing NeuroInsight processes...")
    killed = find_and_kill_processes()

    # Start Docker services
    if not start_docker_services():
        log_error("Failed to start Docker services")
        sys.exit(1)

    # Find available port
    port = find_available_port()
    if not port:
        log_error("No available ports found in range 8000-8050")
        sys.exit(1)

    log_success(f"Selected port: {port}")

    # Start backend
    backend_proc = start_backend(port)
    if not backend_proc:
        log_error("Failed to start backend")
        sys.exit(1)

    # Start Celery worker
    celery_proc = start_celery()
    if not celery_proc:
        log_warning("Celery worker failed to start - continuing anyway")

    # Start job monitor
    monitor_proc = start_job_monitor()
    if not monitor_proc:
        log_warning("Job monitor failed to start - continuing anyway")

    print()
    print("=" * 50)
    log_success("NeuroInsight is running!")
    print(f"   Web Interface: http://localhost:{port}")
    print(f"   API Docs: http://localhost:{port}/docs")
    print(f"   Health Check: http://localhost:{port}/health")
    print()
    print("Management commands:")
    print("  ./status.sh    # Check system status")
    print("  ./stop.sh      # Stop all services")
    print("  ./monitor.sh   # Advanced monitoring")
    print("=" * 50)

if __name__ == "__main__":
    main()
