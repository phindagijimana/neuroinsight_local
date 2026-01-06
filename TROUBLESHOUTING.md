# Troubleshooting Guide

Comprehensive guide to diagnosing and resolving common NeuroInsight issues.

## Quick Diagnosis

### System Health Check

Run this first when encountering issues:

```bash
# Check overall system status
./status.sh

# Expected healthy output:
# Backend: RUNNING (PID: 12345)
# Worker: RUNNING (PID: 12346)
# Database: RUNNING
# Redis: RUNNING
# MinIO: RUNNING
# FreeSurfer License: VALID
```

### Log Analysis

```bash
# View recent application logs
./logs.sh

# Check specific service logs
docker-compose logs backend
docker-compose logs worker
docker-compose logs db
```

## Critical Errors

### Application Won't Start

**Error**: `ModuleNotFoundError: No module named 'backend'`

**Symptoms**: Backend fails to start with Python import errors

**Solutions**:

1. **Check Python Path**:
```bash
   # Verify you're in the correct directory
   pwd
   # Should show: /path/to/neuroinsight

   # Check PYTHONPATH
   echo $PYTHONPATH
   # Should include current directory
   ```

2. **Fix PYTHONPATH**:
   ```bash
   export PYTHONPATH="$(pwd)"
   source venv/bin/activate
   python3 backend/main.py
   ```

3. **Reinstall Dependencies**:
```bash
   # Remove and recreate virtual environment
   rm -rf venv
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

### Database Connection Failed

**Error**: `Database connection failed after 3 attempts`

**Symptoms**: API calls fail, jobs don't update

**Solutions**:

1. **Check Database Service**:
   ```bash
   docker-compose ps db
   # Should show: Up
   ```

2. **Restart Database**:
   ```bash
   docker-compose restart db
   sleep 10
   ```

3. **Check Database Logs**:
   ```bash
   docker-compose logs db
   ```

4. **Reset Database** (if corrupted):
```bash
   docker-compose down
   rm -rf data/postgres
   docker-compose up -d db
   ```

### Redis Connection Issues

**Error**: `NOAUTH Authentication required`

**Symptoms**: Celery worker can't connect, jobs stuck in pending

**Solutions**:

1. **Verify Redis Password**:
   ```bash
   # Check .env file
   grep REDIS_PASSWORD .env
   ```

2. **Restart Redis**:
   ```bash
   docker-compose restart redis
   ```

3. **Test Redis Connection**:
```bash
   docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping
   # Should return: PONG
```

## Processing Issues

### Jobs Stuck in Pending

**Symptoms**: Jobs remain in PENDING status, no processing starts

**Causes & Solutions**:

1. **Worker Not Running**:
```bash
./status.sh
   # Check if worker shows RUNNING
   ```

2. **Redis Connection Issue**:
   ```bash
# Check worker logs
   docker-compose logs worker | tail -20
   ```

3. **Queue Full**:
   - Maximum 1 running + 5 pending jobs
   - Failed jobs don't count toward limit
   - Delete completed/failed jobs to free slots

4. **Restart Worker**:
   ```bash
   ./restart.sh
```

### FreeSurfer Processing Fails

**Error**: `FreeSurfer Docker failed (exit code: X)`

**Symptoms**: Jobs fail during processing stage

**Common Causes**:

1. **License Issues**:
```bash
   # Check license file exists
   ls -la license.txt

   # Verify license content
   head -5 license.txt
   # Should show your email and license codes
   ```

2. **Docker Issues**:
   ```bash
   # Check Docker is running
   docker ps

# Check disk space
   df -h /
   # Should have >20GB free
   ```

3. **Memory Issues**:
```bash
   # Check available memory
free -h
   # Should have >8GB available
   ```

4. **File Format Issues**:
   ```bash
   # Verify input file
   file data/uploads/your_file.nii.gz
   # Should be: gzip compressed data
   ```

### Progress Bar Stuck

**Symptoms**: Progress shows 17% and doesn't update

**Solutions**:

1. **Check Processing Logs**:
   ```bash
   # View worker logs
   docker-compose logs worker | tail -50
   ```

2. **Verify FreeSurfer Status**:
   ```bash
   # Check if FreeSurfer container is running
   docker ps | grep freesurfer
   ```

3. **Restart Job**:
   - Delete the stuck job
   - Re-upload the file

## File Upload Issues

### Upload Fails Immediately

**Error**: `Upload failed: Invalid file format`

**Solutions**:

1. **Check File Format**:
```bash
   # Verify file type
   file your_file.nii.gz
   # Should show: NIfTI-1 format

   # Check file size
   ls -lh your_file.nii.gz
   # Should be <1GB
   ```

2. **Convert File Format**:
   ```bash
   # Use dcm2niix for DICOM
   dcm2niix -z y -f output input_directory/

   # Use mriconvert for other formats
   mriconvert input_file output_file.nii.gz
```

### Large File Upload Timeout

**Symptoms**: Upload starts but fails after some time

**Solutions**:

1. **Compress File**:
```bash
   # If not already compressed
   gzip your_file.nii
   ```

2. **Check Network**:
   ```bash
   # Test upload speed
   speedtest-cli
   ```

3. **Increase Timeout** (advanced):
   ```bash
   # Edit nginx config if using reverse proxy
   # Or increase FastAPI timeout settings
```

## User Interface Issues

### Cannot Access Web Interface

**Symptoms**: Browser shows "Connection refused" or "Site cannot be reached"

**Solutions**:

1. **Check Application Status**:
```bash
   ./status.sh
   # Backend should show RUNNING with correct port
   ```

2. **Verify Port Configuration**:
   ```bash
   # Check what port NeuroInsight is using
   ./status.sh | grep "Port:"
   ```

3. **Check Firewall**:
   ```bash
   sudo ufw status
   # Allow the configured port if blocked
   ```

4. **Restart Application**:
   ```bash
   ./restart.sh
```

### Port Conflicts (Rare with Auto-Selection)

**Note**: NeuroInsight now automatically finds available ports (8000-8050), so port conflicts are rare!

**Symptoms**: Startup shows "No available ports found in range 8000-8050!"

**Solutions**:

1. **Free Up Ports in Range**:
   ```bash
   # Find what's using ports
   sudo netstat -tulpn | grep :80[0-4][0-9]
   sudo lsof -i :8000-8050
   ```

2. **Stop Conflicting Services**:
```bash
   # Stop other web servers
   sudo systemctl stop apache2 nginx

   # Stop other NeuroInsight instances
   ./stop.sh
   ```

3. **Use Custom Port Range**:
   ```bash
   export PORT=9000  # Use port outside 8000-8050 range
   ./start.sh
   ```

4. **Force Specific Port** (advanced):
   ```bash
   sudo fuser -k 8000/tcp  # Free port 8000 (use with caution!)
   ./start.sh
```

**Prevention**: NeuroInsight's auto-selection prevents most port conflicts automatically.

### Dashboard Shows No Results

**Symptoms**: Dashboard loads but shows no data or visualizations

**Solutions**:

1. **Check Job Completion**:
   - Go to Jobs page
   - Verify jobs show COMPLETED status

2. **Check Metrics Data**:
```bash
   # Check if metrics files exist
   ls -la data/outputs/*/metrics/
   ```

3. **Verify Database**:
   ```bash
   # Check job records in database
   docker-compose exec db psql -U neuroinsight -d neuroinsight -c "SELECT id, status, result_path FROM jobs;"
   ```

4. **Reprocess Job**:
   - Delete failed job
   - Re-upload and process file

## Performance Issues

### Slow Processing

**Symptoms**: Jobs take longer than expected (over 1 hour)

**Solutions**:

1. **Check System Resources**:
```bash
   # Monitor CPU usage
   top -n 1

   # Check memory usage
   free -h

   # Monitor disk I/O
   iotop -n 1
   ```

2. **Optimize System**:
   ```bash
   # Close unnecessary applications
   # Ensure 16GB+ RAM available
   # Use SSD storage if possible
   ```

3. **Check Docker Resources**:
   ```bash
   # View Docker stats
   docker stats --no-stream
```

### High Memory Usage

**Symptoms**: System becomes slow or unresponsive

**Solutions**:

1. **Limit Concurrent Jobs**:
   - Process only 1 job at a time
   - Wait for completion before starting new jobs

2. **Monitor Memory Usage**:
```bash
   # Check memory consumption
   free -h
   ps aux --sort=-%mem | head -10
   ```

3. **Restart Services**:
   ```bash
   ./restart.sh
```

## Docker Issues

### Docker Containers Not Starting

**Error**: `docker-compose up` fails

**Solutions**:

1. **Check Docker Service**:
```bash
   sudo systemctl status docker
sudo systemctl start docker
   ```

2. **Check Disk Space**:
```bash
   df -h /
   # Need >10GB free for Docker
```

3. **Clean Docker System**:
```bash
   docker system prune -a
   docker volume prune
   ```

### Container Health Check Failures

**Symptoms**: Services show unhealthy status

**Solutions**:

1. **Check Container Logs**:
```bash
   docker-compose logs unhealthy_service
   ```

2. **Restart Specific Service**:
```bash
   docker-compose restart unhealthy_service
   ```

3. **Rebuild Containers**:
```bash
   docker-compose build unhealthy_service
   ```

## Getting Additional Help

### Diagnostic Information

When reporting issues, include:

```bash
# System information
uname -a
lsb_release -a

# Application status
./status.sh

# Recent logs
./logs.sh | tail -50

# Docker status
docker-compose ps
docker stats --no-stream
```

### Log Files Location

- **Application Logs**: `logs/neuroinsight.log`
- **Worker Logs**: `docker-compose logs worker`
- **Database Logs**: `docker-compose logs db`
- **System Logs**: `/var/log/syslog`

### Support Channels

1. **Documentation**: Check this troubleshooting guide
2. **FAQ**: Review [FAQ.md](FAQ.md) for common questions
3. **GitHub Issues**: Report bugs with diagnostic information
4. **Community**: Join discussions for peer support

### Emergency Recovery

If all else fails:

```bash
# Complete system reset
./stop.sh
docker-compose down -v
rm -rf data/ venv/
./install.sh
```

---

**Still having issues?** Create a GitHub issue with your diagnostic information and we'll help!