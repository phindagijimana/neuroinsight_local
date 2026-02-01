# NeuroInsight - Production Deployment Guide

## ✅ Production Ready - Local Linux Deployment

This guide is for deploying NeuroInsight on a local Linux machine as a standalone web application.

---

## 📋 System Requirements

### Hardware
- **CPU**: 4+ cores (8+ recommended for concurrent processing)
- **RAM**: 16GB minimum (32GB recommended)
- **Storage**: 50GB minimum (100GB+ recommended for multiple jobs)
- **OS**: Ubuntu 20.04+ or similar Linux distribution

### Software Prerequisites
- **Docker**: Version 20.10+ (for PostgreSQL, Redis, MinIO)
- **Docker Compose**: Version 2.0+ (or legacy docker-compose)
- **Python**: 3.8+ (included in Ubuntu 20.04+)
- **Git**: For cloning and updates

### Required Accounts
- **FreeSurfer License**: Free for research use
  - Register at: https://surfer.nmr.mgh.harvard.edu/registration.html
  - You'll receive `license.txt` via email

---

## 🚀 Quick Start Installation

### 1. Clone Repository

```bash
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local
```

### 2. Install Docker (if not already installed)

```bash
# Quick install script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group (logout/login required after this)
sudo usermod -aG docker $USER

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

### 3. Add FreeSurfer License

```bash
# Copy your license.txt to the project root
cp /path/to/your/license.txt ./license.txt
```

### 4. Run Installation

```bash
# Make scripts executable
chmod +x install.sh neuroinsight

# Run installation (takes 5-10 minutes)
./neuroinsight install
```

**What it does:**
- Installs Python dependencies
- Sets up Docker infrastructure (PostgreSQL, Redis, MinIO)
- Creates systemd services for auto-restart
- Initializes database schema
- Starts all services
- Validates installation

### 5. Verify Installation

```bash
./neuroinsight status
```

You should see all services running:
- ✅ Backend (API server on port 8000)
- ✅ Worker (Celery job processor)
- ✅ Beat (Scheduler)
- ✅ Monitor (Job monitor)
- ✅ Docker containers (PostgreSQL, Redis, MinIO)

### 6. Access Web Interface

Open your browser to:
```
http://localhost:8000
```

---

## 🎛️ System Management

### Service Control

```bash
# Start all services
./neuroinsight start

# Stop all services (keeps Docker infrastructure running)
./neuroinsight stop

# Restart all services
./neuroinsight restart

# Check status
./neuroinsight status

# View logs
./neuroinsight logs

# View specific service logs
./neuroinsight logs backend
./neuroinsight logs worker
```

### Docker Infrastructure

The installation creates three Docker containers:
- **neuroinsight-db**: PostgreSQL database (port 5432)
- **neuroinsight-redis**: Redis message broker (port 6379)
- **neuroinsight-minio**: MinIO object storage (ports 9000-9001)

These containers persist between service restarts and only need to be recreated if you run `./neuroinsight install` again.

---

## 📁 System Architecture

### Directory Structure

```
neuroinsight_local/
├── backend/              # FastAPI backend application
│   ├── api/             # API endpoints
│   ├── core/            # Configuration, database, logging
│   ├── models/          # Database models
│   ├── services/        # Business logic
│   └── main.py          # Application entry point
├── workers/             # Celery workers for job processing
│   └── tasks/           # Processing tasks
├── frontend/            # React/TypeScript frontend
│   └── src/             # Frontend source code
├── pipeline/            # MRI processing pipeline
│   └── processors/      # FreeSurfer integration
├── systemd/             # Service definitions
├── docker/              # Dockerfiles
├── data/                # PostgreSQL data (persisted)
├── install.sh           # Installation script
├── neuroinsight         # Management script
├── license.txt          # FreeSurfer license (you provide)
└── .env                 # Configuration (auto-created)
```

### Data Storage

**Local Storage**:
- **Uploads**: `~/.local/share/neuroinsight/uploads/`
- **Results**: `~/.local/share/neuroinsight/results/`
- **Database**: `./data/postgresql/`

**MinIO/S3 Storage** (optional, for backups):
- Accessible at: http://localhost:9001
- Default credentials: `minioadmin` / `minioadmin`

---

## 🔧 Configuration

### Environment Variables

The `.env` file is auto-created during installation. Key settings:

```bash
# Database
POSTGRES_USER=neuroinsight
POSTGRES_PASSWORD=neuroinsight_secure_password
POSTGRES_DB=neuroinsight

# Redis (no password for local deployment)
REDIS_URL=redis://localhost:6379/0

# MinIO/S3
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
MINIO_ENDPOINT=localhost:9000

# Application
ENVIRONMENT=production
DEBUG=false
```

### Job Limits

Current production limits (configurable in `backend/api/upload_simple.py`):
- **Max concurrent running jobs**: 1
- **Max pending jobs**: 5
- **Total active jobs**: 6
- **Max file size**: 500MB (soft limit)

### Processing Configuration

FreeSurfer processing runs in isolated Docker containers:
- **One job at a time** (sequential processing)
- **Automatic cleanup** after completion
- **Progress tracking** with step updates
- **Auto-restart** on worker failure

---

## 🧪 Testing the System

### 1. Upload Test File

```bash
# Create a test NIfTI file
python3 << 'EOF'
import nibabel as nib
import numpy as np
img = nib.Nifti1Image(np.random.rand(64, 64, 64), np.eye(4))
nib.save(img, 'test_subject_T1w.nii.gz')
EOF

# Upload via API
curl -X POST "http://localhost:8000/api/upload/" \
  -F "file=@test_subject_T1w.nii.gz" \
  -F 'patient_data={"patient_name":"Test Subject","patient_id":"TEST001"}'
```

### 2. Check Job Status

```bash
# Via API
curl http://localhost:8000/api/jobs/ | python3 -m json.tool

# Via web interface
# Open: http://localhost:8000
```

### 3. Monitor Progress

Jobs typically take 4-8 hours depending on:
- CPU speed
- Available RAM
- Input file quality

Check progress in the web interface or via API.

---

## 🛠️ Troubleshooting

### Common Issues

**1. Docker Not Running**
```bash
sudo systemctl start docker
docker ps  # Should show containers
```

**2. Services Not Starting**
```bash
# Reload systemd
systemctl --user daemon-reload

# Check logs
journalctl --user -u neuroinsight-backend -n 50
```

**3. Jobs Stuck in PENDING**
```bash
# Check worker is running
systemctl --user status neuroinsight-worker

# Check Redis connection
redis-cli ping  # Should return "PONG"

# Restart services
./neuroinsight restart
```

**4. Database Connection Errors**
```bash
# Check PostgreSQL container
docker ps | grep neuroinsight-db

# Restart if needed
docker restart neuroinsight-db
./neuroinsight restart
```

**5. Port Already in Use**
```bash
# Check what's using port 8000
sudo lsof -i :8000

# Kill the process or change port in systemd service
```

### Complete Troubleshooting Guide

See `TROUBLESHOUTING.md` for detailed troubleshooting steps.

---

## 🔄 Updates and Upgrades

### Updating the Application

```bash
# Stop services
./neuroinsight stop

# Pull latest code
git pull origin master

# Update dependencies
source venv/bin/activate
pip install -r backend/requirements.txt

# Restart services
./neuroinsight start
```

### Database Migrations

```bash
# If database schema changes are needed
cd backend
alembic upgrade head
```

---

## 📊 Monitoring and Logs

### View Real-time Logs

```bash
# All services
./neuroinsight logs

# Specific service
journalctl --user -u neuroinsight-backend -f
journalctl --user -u neuroinsight-worker -f
```

### Check System Resources

```bash
# CPU and Memory
htop

# Disk usage
df -h

# Docker container resources
docker stats
```

---

## 🔒 Security Considerations

### For Local Deployment

✅ **Already Secured:**
- Services bind to localhost only
- No external network exposure
- Docker containers isolated

⚠️ **Additional Recommendations:**
- Change default MinIO credentials in `.env`
- Keep system updated: `sudo apt update && sudo apt upgrade`
- Backup data directory regularly
- Don't expose port 8000 externally without authentication

### For Production Internet Deployment

If you plan to expose this to the internet:
1. Add authentication (JWT tokens, OAuth, etc.)
2. Enable HTTPS with SSL certificates
3. Use nginx reverse proxy
4. Enable firewall (ufw/iptables)
5. Regular security updates
6. Implement rate limiting
7. Add CORS restrictions
8. Secure MinIO with strong credentials

---

## 📦 Backup and Recovery

### What to Backup

1. **Database**: `./data/postgresql/`
2. **Uploaded Files**: `~/.local/share/neuroinsight/uploads/`
3. **Results**: `~/.local/share/neuroinsight/results/`
4. **Configuration**: `./.env`, `./license.txt`

### Backup Script

```bash
#!/bin/bash
BACKUP_DIR="/backup/neuroinsight-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Stop services
./neuroinsight stop

# Backup database
cp -r ./data/postgresql "$BACKUP_DIR/"

# Backup files
cp -r ~/.local/share/neuroinsight "$BACKUP_DIR/"

# Backup config
cp .env license.txt "$BACKUP_DIR/"

# Restart services
./neuroinsight start

echo "Backup completed: $BACKUP_DIR"
```

---

## 🎯 Production Checklist

Before going live, verify:

- [ ] Docker installed and running
- [ ] FreeSurfer license in place (`./license.txt`)
- [ ] Installation completed: `./neuroinsight install`
- [ ] All services running: `./neuroinsight status`
- [ ] Web interface accessible: http://localhost:8000
- [ ] Test job completes successfully
- [ ] Logs show no errors: `./neuroinsight logs`
- [ ] Disk space adequate: 50GB+ free
- [ ] RAM adequate: 16GB+ total
- [ ] Backup strategy in place
- [ ] Documentation reviewed: `USER_GUIDE.md`

---

## 📞 Support

### Resources

- **User Guide**: `USER_GUIDE.md` - Detailed usage instructions
- **Troubleshooting**: `TROUBLESHOUTING.md` - Common issues and solutions
- **API Documentation**: http://localhost:8000/docs (when running)
- **GitHub Issues**: Report bugs and request features

### Getting Help

1. Check `./neuroinsight status` for service status
2. Review logs: `./neuroinsight logs`
3. Consult `TROUBLESHOUTING.md`
4. Open GitHub issue with logs and system info

---

## ✅ System Verification

Run these commands to verify everything is working:

```bash
# 1. Check services
./neuroinsight status

# 2. Check Docker
docker ps | grep neuroinsight

# 3. Test API
curl http://localhost:8000/api/health

# 4. Check database connection
python3 -c "from backend.core.database import engine; engine.connect(); print('✅ Database OK')"

# 5. Check Redis
redis-cli ping

# 6. Check disk space
df -h | grep -E "Filesystem|/$"
```

All checks should pass before processing real data.

---

## 🎉 Ready for Production!

If all checks pass, your NeuroInsight system is ready for production use!

**Next Steps:**
1. Process test data to familiarize yourself
2. Review `USER_GUIDE.md` for detailed usage
3. Set up regular backups
4. Monitor system resources during processing
5. Keep the system updated

**Happy analyzing! 🧠**
