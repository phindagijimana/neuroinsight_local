# Troubleshooting Guide

## Quick Diagnosis

```bash
./status.sh  # Check all services
docker-compose logs  # View container logs
```

## Common Issues

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
- Run: `./check_license.sh`

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
- Check backend running: `./status.sh`
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
./stop.sh
docker-compose down -v  # Removes all data
./start.sh  # Recreates fresh database
```

### Clear Job Queue
```bash
# Stop workers first
./stop.sh

# Clear Redis queue
docker-compose exec redis redis-cli FLUSHALL

# Restart
./start.sh
```

### Full System Reset
```bash
./stop.sh
docker-compose down -v --remove-orphans
docker system prune -a  # Careful: removes all unused containers
./install.sh  # Reinstall from scratch
```

## Support

- Check logs: `tail -f neuroinsight.log`
- GitHub Issues: Report bugs
- FreeSurfer Support: https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSupport
