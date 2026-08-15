# Troubleshooting Guide

## Quick Diagnosis

```bash
# Basic system check
./neuroinsight-autohs status        # Check all services
./neuroinsight-autohs health        # Quick health overview

# Docker diagnostics
./fix_docker.sh             # Comprehensive Docker check
./quick_docker_fix.sh       # Quick Docker fix

# Detailed logs
docker-compose logs          # View container logs
tail -f neuroinsight-autohs.log     # Follow application logs
```

## Deployment-Specific Issues

### Desktop Application Issues

#### App Won't Start or Crashes

**Symptoms:**
- Desktop app doesn't launch
- App opens then immediately closes
- Error message about Docker

**Solutions:**

**Check Docker is Running:**
```bash
# Linux
docker ps

# Windows
# Check Docker Desktop system tray icon (should be green)
```

**Restart Docker:**
```bash
# Linux
sudo systemctl restart docker

# Windows
# Right-click Docker Desktop icon → Restart
```

**Check App Logs:**

Linux AppImage:
```bash
# Run from terminal to see errors
./NeuroInsight-AutoHS-1.0.0.AppImage
```

Windows:
- Check logs in: `%APPDATA%\NeuroInsight-AutoHS\logs\`

**Reinstall:**
- Delete app and download fresh installer from [releases](https://github.com/phindagijimana/neuroinsight_desktop/releases)

#### Port Already in Use (Desktop App)

**Symptoms:**
- App shows "Port 8000 in use"
- Can't access web interface

**Solution:**

Desktop app automatically finds available ports (8000-8050). If all ports are in use:

```bash
# Linux - Find what's using ports
sudo netstat -tlnp | grep :800

# Windows - Find processes
netstat -ano | findstr :800

# Stop conflicting services
docker stop neuroinsight-autohs  # If another instance running
```

#### Docker Image Download Fails

**Symptoms:**
- App stuck on "Pulling NeuroInsight-AutoHS image"
- Download very slow or fails

**Solutions:**
- Check internet connection
- Image is large (~2GB for NeuroInsight-AutoHS container)
- First FreeSurfer image is ~7GB (one-time download)
- Retry: Restart the app

**For more Desktop App issues:** See [Desktop App Repository](https://github.com/phindagijimana/neuroinsight_desktop/issues)

---

### Docker Deployment Issues

#### Container Won't Start

**Symptoms:**
- `docker ps` shows no neuroinsight container
- Installation completes but container exits
- `neuroinsight-autohs-docker status` shows "not running"

**Diagnosis:**
```bash
# Check container status
docker ps -a | grep neuroinsight

# View container logs
docker logs neuroinsight

# Check Docker daemon
systemctl status docker  # Linux
# or Docker Desktop status icon (Windows)
```

**Solutions:**

**For Linux Docker:**
```bash
# Restart Docker daemon
sudo systemctl restart docker

# Remove and recreate container
cd neuroinsight_local/deploy
./neuroinsight-autohs-docker stop
docker rm -f neuroinsight-autohs
./neuroinsight-autohs-docker install

# Check logs for errors
./neuroinsight-autohs-docker logs
```

**For Windows Docker:**
```powershell
# Restart Docker Desktop
# System tray → Docker → Restart

# Remove and recreate
cd neuroinsight_windows
.\neuroinsight-autohs-docker.ps1 stop
docker rm -f neuroinsight-autohs
.\neuroinsight-autohs-docker.ps1 install
```

#### Port Already in Use

**Symptoms:**
- Installation fails with "port 8000 already in use"
- Container starts but not accessible

**Solutions:**

**Linux Docker:**
```bash
# Find what's using port 8000
sudo netstat -tlnp | grep :8000

# Stop conflicting service
sudo systemctl stop <service-name>

# Or use different port
./neuroinsight-autohs-docker install --port 8001
```

**Windows Docker:**
```powershell
# Find what's using port
netstat -ano | findstr :8000

# Kill process (use PID from output)
taskkill /PID <pid> /F

# Or install on different port
.\neuroinsight-autohs-docker.ps1 install -Port 8001
```

#### License Not Detected

**Symptoms:**
- Container logs show "WARNING: FreeSurfer license not found"
- Jobs fail with license errors

**Solutions:**

**Linux Docker:**
```bash
# Check license location
ls -la ../license.txt

# License should be in neuroinsight_local/ (parent of deploy/)
# Not in deploy/ folder

# Verify mount in logs
./neuroinsight-autohs-docker logs | grep license

# Restart after adding license
./neuroinsight-autohs-docker restart
```

**Windows Docker:**
```powershell
# Place license.txt in neuroinsight_windows/ folder
# Same location as neuroinsight-autohs-docker.ps1

# Check detection
.\neuroinsight-autohs-docker.ps1 license

# Restart container
.\neuroinsight-autohs-docker.ps1 restart
```

#### Docker Permissions (Linux)

**Symptoms:**
- "permission denied" when running docker commands
- Must use sudo for docker

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or:
newgrp docker

# Verify
docker ps
```

#### WSL2 Issues (Windows)

**Symptoms:**
- Docker Desktop shows "WSL integration failed"
- "There was a problem with WSL" error
- Containers become unresponsive

**Solutions:**

**Quick Fix:**
```powershell
# PowerShell as Administrator
wsl --shutdown
# Wait 10 seconds
# Restart Docker Desktop
```

**Enable WSL Integration:**
1. Docker Desktop → Settings
2. Resources → WSL Integration
3. Enable for your Ubuntu distribution
4. Apply & Restart

**Enable Systemd (if needed):**
```bash
# In WSL terminal
sudo nano /etc/wsl.conf

# Add:
[boot]
systemd=true

# Save, then:
exit
```

```powershell
# PowerShell
wsl --shutdown
wsl
```

#### Docker Volume Issues

**Symptoms:**
- Data not persisting between restarts
- "volume not found" errors

**Solutions:**

**Linux Docker:**
```bash
# List volumes
docker volume ls | grep neuroinsight

# Inspect volume
docker volume inspect neuroinsight-autohs-data

# Recreate if corrupted
./neuroinsight-autohs-docker stop
docker volume rm neuroinsight-autohs-data
./neuroinsight-autohs-docker install
```

**Windows Docker:**
```powershell
# Same commands work in PowerShell
docker volume ls | Select-String neuroinsight
.\neuroinsight-autohs-docker.ps1 stop
docker volume rm neuroinsight-autohs-data
.\neuroinsight-autohs-docker.ps1 install
```

#### FreeSurfer Container Spawn Failures

**Symptoms:**
- Jobs fail with: "No container runtimes available"
- Jobs fail with: "Failed to spawn FreeSurfer container"
- Error: "FreeSurfer processing failed"
- Works during install but fails when processing jobs

**This is a Docker-in-Docker (DinD) permission issue** - the NeuroInsight-AutoHS container can't access Docker to spawn FreeSurfer containers.

**Quick Fix:**

```bash
cd /path/to/neuroinsight_local/deploy

# Run automated fix script
./fix-docker-access.sh

# This will:
# 1. Diagnose the issue
# 2. Detect your Docker group ID
# 3. Recreate container with proper permissions
# 4. Verify Docker access
```

**Manual Diagnosis:**

```bash
# 1. Check Docker socket permissions
ls -la /var/run/docker.sock

# 2. Get Docker group ID
getent group docker | cut -d: -f3

# 3. Test if container can access Docker
docker exec neuroinsight-autohs docker ps

# If this fails → DinD is broken, follow fix below
```

**Manual Fix for Linux/WSL:**

```bash
cd neuroinsight_local/deploy

# Stop and remove container
./neuroinsight-autohs-docker stop
./neuroinsight-autohs-docker remove

# Get Docker group ID
DOCKER_GID=$(getent group docker | cut -d: -f3)
echo "Docker GID: $DOCKER_GID"

# Reinstall (script now auto-adds docker group)
./neuroinsight-autohs-docker install

# Verify Docker access from inside container
docker exec neuroinsight-autohs docker ps
# Should show running containers if working
```

**For WSL2 Specific Issues:**

```bash
# Ensure Docker Desktop integration is enabled
# 1. Docker Desktop → Settings → Resources → WSL Integration
# 2. Enable for your Ubuntu distribution
# 3. Apply & Restart

# Restart WSL completely (in PowerShell as Admin)
wsl --shutdown

# Restart Docker Desktop
# Reopen WSL and try again
```

**For docker-compose users:**

Before running `docker-compose up`, set the Docker GID:

```bash
# Export Docker group ID
export DOCKER_GID=$(getent group docker | cut -d: -f3)

# Now run docker-compose
docker-compose up -d

# Verify
docker exec neuroinsight-autohs docker ps
```

**Verification:**

After applying the fix, test:

```bash
# 1. Check container can access Docker
docker exec neuroinsight-autohs docker ps

# 2. Check container can pull images
docker exec neuroinsight-autohs docker pull hello-world

# 3. Submit a test job through the web interface
```

**Why This Happens:**

The NeuroInsight-AutoHS container needs to spawn FreeSurfer containers for processing. This requires:
1. Docker socket mounted: `/var/run/docker.sock:/var/run/docker.sock` [OK]
2. Container user has permission to access socket [X] (missing)

The fix adds the Docker group to the container, giving it permission to use Docker.

#### Update Failures

**Symptoms:**
- `update` command fails
- New version not pulling

**Solutions:**

**Linux Docker:**
```bash
# Backup first
./neuroinsight-autohs-docker backup

# Force pull new image
docker pull phindagijimana321/neuroinsight-autohs:latest

# Reinstall
./neuroinsight-autohs-docker stop
docker rm -f neuroinsight-autohs
./neuroinsight-autohs-docker install
```

**Windows Docker:**
```powershell
# Backup first
.\neuroinsight-autohs-docker.ps1 backup

# Force pull
docker pull phindagijimana321/neuroinsight-autohs:latest

# Reinstall
.\neuroinsight-autohs-docker.ps1 stop
docker rm -f neuroinsight-autohs
.\neuroinsight-autohs-docker.ps1 install
```

---

## Common Issues

### Jobs Stuck in "Pending" Status

#### Symptom
- Jobs remain in "pending" status indefinitely
- Upload completes successfully but processing never starts
- Frontend continuously polls but status never changes from "pending"
- Jobs appear in queue but never transition to "running"

#### Diagnosis Steps

1. **Check if Celery worker is running:**
   ```bash
   ps aux | grep celery
   # Should show celery worker processes
   ```

2. **Check Redis connection:**
   ```bash
   redis-cli ping
   # Should respond with "PONG"
   ```

3. **Check Celery worker logs:**
   ```bash
   tail -f celery_worker.log
   # Look for connection errors or task pickup messages
   ```

4. **Test Celery connectivity:**
   ```bash
   # Activate virtual environment first
   source venv/bin/activate

   # Test task submission
   python -c "
   from workers.tasks.processing_web import celery_app
   result = celery_app.send_task('process_mri_task', args=['test-job-id'])
   print('Task sent successfully - check worker logs')
   "
   ```

#### Common Solutions

**Solution 1: Start Celery Worker**
If Celery worker is not running:
```bash
# Navigate to NeuroInsight-AutoHS directory
cd neuroinsight_local

# Activate virtual environment
source venv/bin/activate

# Start Celery worker (run in background or separate terminal)
celery -A workers.tasks.processing_web worker --loglevel=info --concurrency=1

# Or use the NeuroInsight-AutoHS management script
./neuroinsight-autohs start
```

**Solution 2: Redis Connection Issues**
If Redis is not running or accessible:
```bash
# Check if Redis is installed and running
sudo systemctl status redis-server

# If not running, start it
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Or install Redis if missing
sudo apt update && sudo apt install redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Test connection
redis-cli ping
```

**Solution 3: Environment Variables**
Ensure proper environment variables are set:
```bash
# Check current settings
echo $REDIS_URL
echo $REDIS_PASSWORD

# Set defaults if needed
export REDIS_URL="redis://:redis_secure_password@localhost:6379/0"
export REDIS_PASSWORD="redis_secure_password"

# Restart services after changing environment
./neuroinsight-autohs stop
./neuroinsight-autohs start
```

**Solution 4: Restart All Services**
If nothing else works, restart the entire NeuroInsight-AutoHS stack:
```bash
./neuroinsight-autohs stop
sleep 5
./neuroinsight-autohs start
```

#### Prevention
- Always check `./neuroinsight-autohs status` after installation
- Ensure Redis is running before starting NeuroInsight-AutoHS
- Monitor Celery worker logs during initial testing
- Keep Celery worker running continuously

### Insufficient Disk Space

**"Insufficient disk space" during installation:**
```bash
# Error: Insufficient disk space. NeuroInsight-AutoHS requires at least 45GB free.
# Error: Detected: XXgB available
```

**Impact:**
- NeuroInsight-AutoHS requires 45GB+ free disk space
- FreeSurfer processing needs substantial temporary storage
- Docker images (FreeSurfer 7.4.1) require ~20GB
- Job outputs can accumulate over time

**Solutions:**

**Quick Fix - Free Up Space:**
```bash
# 1. Clean Docker resources (most effective)
docker system prune -af --volumes
# This removes:
# - All stopped containers
# - Unused images
# - Unused networks
# - Dangling build cache
# Typically frees: 15-25GB

# 2. Check space after cleanup
df -h /

# 3. Retry installation
./neuroinsight-autohs install
```

**Additional Cleanup Options:**
```bash
# Clean old job outputs (if previously installed)
rm -rf ~/.local/share/neuroinsight-autohs/outputs/old-job-*

# Clean system caches
sudo apt clean
sudo apt autoclean

# Clean journal logs (keeps last 7 days)
sudo journalctl --vacuum-time=7d

# Clean pip cache
rm -rf ~/.cache/pip
```

**Check Disk Usage:**
```bash
# Overall disk usage
df -h /

# Find large directories
du -h ~ | sort -rh | head -20

# Docker space usage
docker system df
```

**Prevention:**
```bash
# Regular maintenance (run monthly)
docker system prune -a --volumes

# Monitor disk usage
df -h /
```

### Docker Installation Issues

**"Input/output error" during installation:**
```bash
# Error: /usr/bin/docker: Input/output error
# Error: Docker test failed. Please check Docker installation.
```

**Causes:**
- Docker daemon not running
- Docker daemon crashed or unresponsive
- User not in docker group
- Permission issues with Docker socket

**Solutions:**

**Option 1: Quick Fix Script (Recommended)**
```bash
# Get latest fixes
git pull origin master

# Run comprehensive diagnostic
./fix_docker.sh

# Or use quick fix
./quick_docker_fix.sh

# Then retry installation
./neuroinsight-autohs install
```

**Option 2: Manual Fix**
```bash
# 1. Restart Docker daemon
sudo systemctl restart docker
sudo systemctl enable docker

# 2. Add user to docker group
sudo usermod -aG docker $USER

# 3. Apply group changes (or logout/login)
newgrp docker

# 4. Test Docker
docker run --rm hello-world

# 5. Retry installation
./neuroinsight-autohs install
```

**Option 3: Temporary Bypass (if Docker works manually)**
```bash
# If Docker works but install check fails
sed -i '473,477s/^/# /' scripts/install.sh  # Comment out Docker test
./neuroinsight-autohs install                       # Run installation
git checkout scripts/install.sh              # Restore original file
```

**Verification:**
```bash
# Test Docker is working
docker --version
docker run --rm hello-world
sudo systemctl status docker
```

### WSL/Docker Desktop Issues

**"There was a problem with WSL" or "wsl.exe --unmount docker_data.vhdx" errors:**
```bash
# Error symptoms:
# - Docker Desktop shows WSL integration errors
# - wsl.exe --unmount docker_data.vhdx: exit status 0xffffffff
# - Docker becomes unresponsive during processing
# - NeuroInsight-AutoHS jobs fail mid-processing
```

**Causes:**
- Docker Desktop WSL integration becomes unstable
- Virtual hard disk (VHDX) unmount failures
- Resource conflicts during heavy processing
- Windows/WSL updates interrupting Docker

**Solutions:**

**Option 1: Automated Fix Scripts (Recommended)**
```bash
# Get latest fixes
git pull origin master

# Windows PowerShell (run as Administrator):
.\fix_wsl_docker.ps1

# Then in WSL terminal:
./fix_docker_wsl.sh

# Restart NeuroInsight-AutoHS
./neuroinsight-autohs start
```

**Option 2: Windows PowerShell Reset**
```powershell
# Run in PowerShell as Administrator
Stop-Process -Name "*docker*" -Force
wsl --shutdown
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

**Option 3: Complete WSL Reset**
```bash
# On Windows - PowerShell as Administrator
wsl --shutdown
wsl --unregister docker-desktop  # Removes Docker data - use carefully!

# Restart Docker Desktop
# Re-enable WSL integration in Docker Desktop settings
```

**Option 4: Factory Reset (Last Resort)**
- Docker Desktop → Settings → Reset to Factory Defaults
- Restart Docker Desktop completely
- Re-enable WSL integration

**Prevention:**
```bash
# Regular maintenance
docker system prune -a --volumes

# Monitor WSL resources
wsl --list --verbose

# Keep Docker Desktop updated
# Avoid Windows updates during processing
```

**Verification:**
```bash
# Test Docker in WSL
docker run --rm hello-world

# Check WSL integration
wsl --list --verbose

# Restart NeuroInsight-AutoHS
./neuroinsight-autohs status
```

### Memory Limitations

**"LIMITED MEMORY DETECTED" warning during installation:**
```
[WARNING] LIMITED MEMORY DETECTED: 7GB
[WARNING] MRI processing requires 16GB+ RAM
```

**Impact:**
- Web interface works with 8GB+ RAM
- MRI processing requires 16GB+ minimum
- Large datasets need 32GB+ RAM
- Processing may fail or crash with insufficient memory

**Solutions:**

**For Evaluation/Testing (8GB+ RAM):**
```bash
# Continue with installation despite warnings
# Web interface and basic features work
./neuroinsight-autohs install  # Answer 'y' to continue
```

**For Production MRI Processing (16GB+ RAM):**
```bash
# Upgrade system RAM
# Or use cloud instance with adequate memory
# AWS: t3.large (16GB), c5.xlarge (32GB)
# GCP: n1-standard-4 (15GB), n1-standard-8 (30GB)
```

**Memory Monitoring:**
```bash
# Check current usage
free -h
docker stats  # Container memory usage

# Monitor during processing
./neuroinsight-autohs monitor
```

### Application Won't Start

**Backend fails with import errors:**
```bash
# Ensure you're in correct directory
pwd  # Should show neuroinsight_local

# Check Python virtual environment
source venv/bin/activate
pip list | grep fastapi
```

**Database connection failed:**
```bash
# Check PostgreSQL container
docker-compose ps postgres

# Reset database
docker-compose down -v
docker-compose up -d db
```

### FreeSurfer License Issues

**License not found:**
- Verify `license.txt` exists in project root
- Check file permissions: `ls -la license.txt`
- Run: `./neuroinsight-autohs license`

**Processing shows mock data:**
- License file missing or invalid
- FreeSurfer container cannot access license
- Check container logs: `docker-compose logs freesurfer`

### MRI Processing Issues

**Jobs stuck in pending:**
- See "Jobs Stuck in 'Pending' Status" section above
- Check worker status: `./neuroinsight-autohs status`
- Verify Redis running: `redis-cli ping`
- Restart workers: `./neuroinsight-autohs stop && ./neuroinsight-autohs start`

**Processing fails:**
- Verify T1 indicators in filename (t1, mprage, etc.)
- Check RAM (16GB+ required, 32GB+ recommended)
- Ensure file format supported (.nii, .nii.gz only)
- Check FreeSurfer license: `./neuroinsight-autohs license` (native) or `./neuroinsight-autohs-docker license` (Docker)
- **Docker:** Ensure FreeSurfer container can spawn: `docker ps -a | grep freesurfer`

**Out of memory errors:**
- Increase system RAM to 32GB+ for large datasets
- Process one job at a time
- Close other applications during processing
- Monitor memory usage: `free -h`

**File format issues:**
- Only NIfTI files (.nii, .nii.gz) are supported
- DICOM files must be converted to NIfTI first using MRIcron (https://www.nitrc.org/projects/mricron)
- Verify T1 sequence indicators in filename

### Web Interface Issues

**Interface won't load:**
- Confirm port 8000 available: `netstat -tlnp | grep 8000`
- Check backend running: `./neuroinsight-autohs status`
- Clear browser cache, try different browser

**Upload fails:**
- Verify file size < 1GB
- Check T1 indicators in filename
- Ensure supported format (.nii, .nii.gz only)

### Performance Issues

**Processing slow:**
- Check CPU usage: `top`
- Verify adequate RAM (32GB+ recommended)
- Ensure SSD storage for data directory

**System unresponsive:**
- Limit concurrent jobs to 1
- Monitor resources: `docker stats`
- Restart services during off-peak hours

## Recovery Procedures

### Reset Database
```bash
./neuroinsight-autohs stop
docker-compose down -v  # Removes all data
./neuroinsight-autohs start  # Recreates fresh database
```

### Clear Job Queue
```bash
# Stop workers first
./neuroinsight-autohs stop

# Clear Redis queue
docker-compose exec redis redis-cli FLUSHALL

# Restart
./neuroinsight-autohs start
```

### Full System Reset
```bash
./neuroinsight-autohs stop
docker-compose down -v --remove-orphans
docker system prune -a  # Careful: removes all unused containers
./neuroinsight-autohs reinstall  # Get complete reinstallation guide
```

## Quick Diagnostic Commands

### Native Linux
```bash
./neuroinsight-autohs status        # Overall status
./neuroinsight-autohs logs          # View logs
./neuroinsight-autohs license       # Check license
ps aux | grep celery         # Check workers
docker ps                    # Check containers
```

### Linux Docker
```bash
./neuroinsight-autohs-docker status      # Container status
./neuroinsight-autohs-docker health      # Health check
./neuroinsight-autohs-docker logs        # View logs
./neuroinsight-autohs-docker logs worker # Worker logs
docker ps -a | grep neuroinsight  # Container list
```

### Windows Docker
```powershell
.\neuroinsight-autohs-docker.ps1 status       # Container status
.\neuroinsight-autohs-docker.ps1 health       # Health check
.\neuroinsight-autohs-docker.ps1 logs         # View logs
docker ps -a | Select-String neuroinsight  # Container list
```

## Support

- **Native Linux logs:** `tail -f neuroinsight-autohs.log` or `./neuroinsight-autohs logs`
- **Docker logs:** `./neuroinsight-autohs-docker logs` or `.\neuroinsight-autohs-docker.ps1 logs`
- **Docker issues (Linux):** Run `./fix_docker.sh` or `./quick_docker_fix.sh`
- **System diagnostics:** `./neuroinsight-autohs status` or `./neuroinsight-autohs-docker status`
- **GitHub Issues:** Report bugs with diagnostic output
- **FreeSurfer Support:** https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSupport

---

© 2025 University of Rochester. All rights reserved.
# Troubleshooting Guide - Recent Additions

## Additions for TROUBLESHOOTING.md

### Section: UI/Frontend Issues

#### Delete Button Not Visible for Failed Jobs

**Symptoms:**
- Failed jobs show large error message boxes
- Delete button (trash icon) is pushed off-screen or hidden
- Cannot easily delete failed jobs from UI

**Solution:**
Fixed in v1.0.28+ - Delete button now always visible regardless of error message size.

**Workaround for older versions:**
```bash
# Option 1: Use command line
./neuroinsight-autohs delete <job_id>                    # Native
./neuroinsight-autohs-docker delete <job_id>             # Docker

# Option 2: Use API directly
curl -X DELETE http://localhost:8000/api/jobs/delete/<job_id>

# Option 3: Clean all failed jobs
./neuroinsight-autohs clean --days 0                     # Native
./neuroinsight-autohs-docker clean --days 0              # Docker
```

**Verification:**
- Update to latest version: `git pull origin master`
- Rebuild Docker image or restart native deployment
- Delete button now visible in top-right corner of job cards

---

### Section: Data Management

#### Jobs Persist After Stop/Restart

**Symptoms:**
- Old jobs still visible after `./neuroinsight-autohs stop` and `./neuroinsight-autohs install`
- Previous uploads appear after container recreate
- Job count doesn't reset to zero

**This is INTENTIONAL behavior** - Data persists between restarts!

**Why:**
- **Docker:** Uses persistent volumes (`neuroinsight-autohs-data`)
- **Native:** Uses standard data directories (`~/.local/share/neuroinsight-autohs/`)
- Prevents data loss during updates/restarts

**What persists:**
```
[OK] PostgreSQL database (job records)
[OK] Uploaded MRI files
[OK] Processing outputs
[OK] Generated reports
[OK] User settings
```

**To remove old jobs:**

```bash
# Option 1: Clean specific jobs (recommended)
./neuroinsight-autohs delete <job_id>
./neuroinsight-autohs-docker delete <job_id>

# Option 2: Clean old completed/failed jobs
./neuroinsight-autohs clean --days 30              # Remove jobs older than 30 days
./neuroinsight-autohs-docker clean --days 0        # Remove all completed/failed jobs

# Option 3: Fresh start (removes ALL data)
## Docker:
./neuroinsight-autohs-docker stop
docker volume rm neuroinsight-autohs-data
./neuroinsight-autohs-docker install

## Native:
./neuroinsight-autohs stop
rm -rf ~/.local/share/neuroinsight-autohs/
./neuroinsight-autohs install
```

[WARNING] **Warning:** Option 3 deletes ALL jobs, uploads, and settings!

**See also:** `CLEANUP_GUIDE.md` for complete cleanup documentation

---

### Section: Installation Issues

#### Python 3.13 Compatibility Errors

**Symptoms:**
```bash
error: subprocess-exited-with-error
× pip failed to build wheels for pandas
ERROR: Failed building wheel for pandas
too few arguments to function '_PyLong_AsByteArray'
```

**Cause:**
Python 3.13 changed C API, breaking older versions of `pandas`, `numpy`, etc.

**Solution:**
Fixed in v1.0.26+ - Updated dependencies for Python 3.13 compatibility.

```bash
# Update to latest version
git pull origin master

# Reinstall
./neuroinsight-autohs stop
rm -rf venv/
./neuroinsight-autohs install
```

**Supported Python versions:**
- [OK] Python 3.9-3.13 (tested and supported)
- [WARNING] Python 3.13: Latest dependencies required (in v1.0.26+)
-  Recommended: Python 3.10-3.12 for best stability

**Manual fix for older versions:**
```bash
# Upgrade dependencies
pip install --upgrade pandas==2.2.3 numpy==2.2.3 scipy==1.15.2
```

---

#### Native Deployment: Environment Variable Issues

**Symptoms:**
```bash
FreeSurfer Docker failed (exit code: 125)
docker: Error response from daemon: create $HOME/.local/share/neuroinsight-autohs/...
# or
docker: Error response from daemon: create $(pwd)/data/outputs/...
```

**Cause:**
`.env` file contains literal `$HOME`, `${HOME}`, or `$(pwd)` instead of expanded paths.

**Solution:**
Fixed in v1.0.26+ with auto-detection and repair.

```bash
# Update to latest version
git pull origin master

# Reinstall (automatically fixes .env)
./neuroinsight-autohs stop
./neuroinsight-autohs install

# Or manually fix existing installation
cd /path/to/neuroinsight_local

# Backup old .env
cp .env .env.backup

# Remove problematic lines
sed -i '/HOST_UPLOAD_DIR=/d' .env
sed -i '/HOST_OUTPUT_DIR=/d' .env

# Restart
./neuroinsight-autohs restart
```

**Verification:**
```bash
# Check .env file doesn't contain literal variables
grep -E '\$HOME|\$\(pwd\)|\$\{HOME\}' .env
# Should return nothing

# Test job submission
# Upload a small MRI file and verify it starts processing
```

**Why this happened:**
- Older install scripts used shell heredocs that prevented variable expansion
- Native deployments don't need `HOST_*_DIR` variables (auto-detected at runtime)
- Fixed by removing these variables from native `.env` files

---

### Section: Image Display Issues

#### Images Appear Upside Down in Reports

**Symptoms:**
- PDF report shows brain images rotated 180 degrees
- Images appear different between web viewer and PDF
- Report text mentions "rotated 180 degrees"

**Solution:**
Fixed in v1.0.27+ - Removed duplicate image rotations.

```bash
# Update to latest version
git pull origin master

# Docker deployment
docker pull phindagijimana321/neuroinsight-autohs:latest
./neuroinsight-autohs-docker stop
docker rm neuroinsight-autohs
./neuroinsight-autohs-docker install

# Native deployment
./neuroinsight-autohs stop
git pull origin master
./neuroinsight-autohs start
```

**What was fixed:**
- [X] Before: Images flipped twice (once in code, once in report)
- [OK] After: Single flip for correct anatomical orientation
- [OK] Removed misleading "rotated 180 degrees" text from reports

**Image orientation now:**
- **Web viewer:** Correct anatomical orientation
- **PDF reports:** Matches web viewer
- **L/R markers:** Added to indicate patient orientation
- **Color coding:** Red = Left Hippocampus, Blue = Right Hippocampus

---

#### L/R Orientation Unclear

**Symptoms:**
- Cannot tell which side is left or right hippocampus
- Color coding not explained in reports
- No orientation markers on images

**Solution:**
Fixed in v1.0.28+ - Added L/R markers and color legend.

**What's new:**
```
[OK] "L" marker at bottom-left of coronal images
[OK] "R" marker at bottom-right of coronal images
[OK] Color legend in PDF: Red = Left, Blue = Right
[OK] Radiological view convention documented
```

**Update to get these features:**
```bash
git pull origin master

# Docker
docker pull phindagijimana321/neuroinsight-autohs:v1.0.28
./neuroinsight-autohs-docker restart

# Native
./neuroinsight-autohs restart
```

**Color coding reference:**
- Red **Red (#FF3333)** = Left Hippocampus
- Blue **Blue (#3399FF)** = Right Hippocampus
- Markers show patient orientation (radiological view)

---

### Section: Cleanup & Maintenance

#### Verify Cleanup Removes Jobs from UI

**Question:**
"Does `./neuroinsight-autohs delete` or `clean` actually remove jobs from the UI?"

**Answer:**
[OK] YES - Verified and tested! Jobs are removed from:
1. PostgreSQL database
2. File system (uploads + outputs)
3. Web UI (automatic refresh)

**How it works:**
```
Delete Command
    ↓
Delete from database
    ↓
API returns updated list
    ↓
UI polls API (every 10 seconds)
    ↓
UI auto-updates (job disappears)
```

**Test it yourself:**
```bash
# 1. Check current jobs
curl http://localhost:8000/api/jobs/ | grep "total"

# 2. Delete a job
./neuroinsight-autohs delete <job_id> --force

# 3. Verify deletion (< 10 seconds)
curl http://localhost:8000/api/jobs/ | grep "total"
# Job count should decrease
```

**All deletion methods work:**
- [OK] Command line: `./neuroinsight-autohs delete <id>`
- [OK] UI delete button (trash icon)
- [OK] API call: `curl -X DELETE .../jobs/delete/<id>`
- [OK] Clean command: `./neuroinsight-autohs clean --days 0`

**Cleanup commands:**
```bash
# Delete specific job
./neuroinsight-autohs delete <job_id>

# Delete all old jobs
./neuroinsight-autohs clean --days 0          # All completed/failed
./neuroinsight-autohs clean --days 30         # Older than 30 days

# Fresh start (removes everything)
docker volume rm neuroinsight-autohs-data     # Docker
rm -rf ~/.local/share/neuroinsight-autohs/    # Native
```

**See also:**
- `CLEANUP_GUIDE.md` - Complete cleanup documentation
- `DELETE_COMMAND_VERIFICATION.md` - Test reports and verification

---

## Quick Reference

### Recent Version Changes

| Version | Key Fixes |
|---------|-----------|
| v1.0.28 | L/R markers, color legend, delete button fix |
| v1.0.27 | Image orientation fix, removed rotation text |
| v1.0.26 | Python 3.13 support, native .env auto-fix |

### Most Common Recent Issues

1. **Delete button hidden** → Update to v1.0.28+
2. **Jobs persist after restart** → Intentional! Use `clean` or `delete`
3. **Python 3.13 errors** → Update to v1.0.26+
4. **Images upside down** → Update to v1.0.27+
5. **$HOME literal in .env** → Update to v1.0.26+ or manual fix

### Quick Fixes

```bash
# Update to latest version
git pull origin master

# Docker: Rebuild and restart
docker pull phindagijimana321/neuroinsight-autohs:latest
./neuroinsight-autohs-docker stop
docker rm neuroinsight-autohs
./neuroinsight-autohs-docker install

# Native: Just restart
./neuroinsight-autohs stop
./neuroinsight-autohs start
```

---

**For complete documentation, see:**
- `README.md` - Installation and quick start
- `docs/USER_GUIDE.md` - How to use the application
