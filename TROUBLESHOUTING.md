# Troubleshooting Guide

## Quick Diagnosis

```bash
# Basic system check
./neuroinsight status        # Check all services
./neuroinsight health        # Quick health overview

# Docker diagnostics
./fix_docker.sh             # Comprehensive Docker check
./quick_docker_fix.sh       # Quick Docker fix

# Detailed logs
docker-compose logs          # View container logs
tail -f neuroinsight.log     # Follow application logs
```

## Common Issues

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
./neuroinsight install
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
./neuroinsight install
```

**Option 3: Temporary Bypass (if Docker works manually)**
```bash
# If Docker works but install check fails
sed -i '473,477s/^/# /' install.sh  # Comment out Docker test
./neuroinsight install              # Run installation
git checkout install.sh             # Restore original file
```

**Verification:**
```bash
# Test Docker is working
docker --version
docker run --rm hello-world
sudo systemctl status docker
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
./neuroinsight install  # Answer 'y' to continue
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
./neuroinsight monitor
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
- Run: `./neuroinsight license`

**Processing shows mock data:**
- License file missing or invalid
- FreeSurfer container cannot access license
- Check container logs: `docker-compose logs freesurfer`

### MRI Processing Issues

**Jobs stuck in pending:**
- Check worker status: `docker-compose ps celery-worker`
- Verify Redis running: `docker-compose ps redis`
- Restart workers: `docker-compose restart celery-worker`

**Processing fails:**
- Verify T1 indicators in filename
- Check RAM (16GB+ required)
- Ensure file format supported (NIfTI preferred)

**Out of memory errors:**
- Increase system RAM to 32GB+
- Process one job at a time
- Close other applications

### Web Interface Issues

**Interface won't load:**
- Confirm port 8000 available: `netstat -tlnp | grep 8000`
- Check backend running: `./neuroinsight status`
- Clear browser cache, try different browser

**Upload fails:**
- Verify file size < 1GB
- Check T1 indicators in filename
- Ensure supported format (.nii, .dcm, .zip)

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
./neuroinsight stop
docker-compose down -v  # Removes all data
./neuroinsight start  # Recreates fresh database
```

### Clear Job Queue
```bash
# Stop workers first
./neuroinsight stop

# Clear Redis queue
docker-compose exec redis redis-cli FLUSHALL

# Restart
./neuroinsight start
```

### Full System Reset
```bash
./neuroinsight stop
docker-compose down -v --remove-orphans
docker system prune -a  # Careful: removes all unused containers
./neuroinsight reinstall  # Get complete reinstallation guide
```

## Support

- Check logs: `tail -f neuroinsight.log`
- Docker issues: Run `./fix_docker.sh` or `./quick_docker_fix.sh`
- System diagnostics: `./neuroinsight health` and `./neuroinsight status`
- GitHub Issues: Report bugs with diagnostic output
- FreeSurfer Support: https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSupport

---

© 2025 University of Rochester. All rights reserved.
