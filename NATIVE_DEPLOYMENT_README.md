# NeuroInsight Fully Native Deployment Guide

## Overview

This guide covers the **Fully Native Deployment** architecture where PostgreSQL, Redis, and MinIO all run natively on the host system alongside the Python application and FreeSurfer processing.

```
┌─────────────────────────────────────────────────┐
│         FULLY NATIVE DEPLOYMENT                 │
│    (PostgreSQL + Redis + MinIO ALL Native)     │
├─────────────────────────────────────────────────┤
│  Frontend (Static Files)                      │
│   ├── React Application (Built)                │
│   ├── Served by FastAPI Backend                │
│   └── Static Assets (CSS, JS, Images)          │
├─────────────────────────────────────────────────┤
│ 🐍 Python Application (Native)                   │
│   ├── FastAPI Backend                           │
│   │   └── 🌐 Serves Frontend Static Files       │
│   ├── Celery Workers                            │
│   └── Processing Pipeline                       │
├─────────────────────────────────────────────────┤
│ 🐘 PostgreSQL Database (Native)                 │
│   └── Runs directly on host system              │
├─────────────────────────────────────────────────┤
│ 🔴 Redis Message Broker (Native)                │
│   └── Runs directly on host system              │
├─────────────────────────────────────────────────┤
│  MinIO Object Storage (Native)                │
│   └── Runs directly as native binary            │
├─────────────────────────────────────────────────┤
│  FreeSurfer (Containerized on-demand)         │
│   └── Docker/Apptainer for MRI processing       │
│      + Native FreeSurfer fallback               │
├─────────────────────────────────────────────────┤
│ 🖥️ Host System (Linux)                          │
│   ├── Ubuntu 20.04/22.04 LTS                    │
│   ├── Native PostgreSQL, Redis, MinIO           │
│   └── Python Environment                        │
└─────────────────────────────────────────────────┘
```

##  Quick Start

### Prerequisites
- Linux system (Ubuntu 20.04+, RHEL/CentOS 8+, Fedora)
- Root/sudo access for service installation
- Python 3.9+ with virtual environment

### One-Command Setup
```bash
# 1. Install system services (requires sudo)
sudo ./setup_native_services.sh

# 2. Update passwords in configuration
nano .env.native  # Change default passwords

# 3. Migrate from SQLite (if upgrading)
python migrate_sqlite_to_postgresql.py

# 4. Start the fully native deployment
./start_production_native.sh
```

##  Detailed Installation Steps

### Phase 1: System Service Installation

**Requires root privileges:**
```bash
sudo ./setup_native_services.sh
```

This script will:
-  Install PostgreSQL, Redis, MinIO system packages
-  Create system users (`postgres`, `redis`, `neuroinsight`)
-  Initialize databases and configure services
-  Install systemd service files for auto-startup
-  Enable and start all services

### Phase 2: Configuration Setup

**Update passwords and settings:**
```bash
# Edit the native environment configuration
nano .env.native

# Required changes:
POSTGRES_PASSWORD=your_secure_postgres_password
MINIO_SECRET_KEY=your_secure_minio_secret
SECRET_KEY=your_secure_app_secret
```

### Phase 3: Database Migration (if upgrading)

**Migrate existing SQLite data to PostgreSQL:**
```bash
# Backup your current data first!
cp neuroinsight_web.db neuroinsight_web.db.backup

# Run migration
python migrate_sqlite_to_postgresql.py
```

### Phase 4: Start Deployment

**Launch the complete native system:**
```bash
./start_production_native.sh
```

## 🏗️ Architecture Components

### System Services (Native)

| Service | Port | Data Directory | System User | Systemd Service |
|---------|------|----------------|-------------|-----------------|
| PostgreSQL | 5432 | `./data/postgresql/` | postgres | `neuroinsight-postgresql.service` |
| Redis | 6379 | `./data/redis/` | redis | `neuroinsight-redis.service` |
| MinIO | 9000/9001 | `./data/minio/` | neuroinsight | `neuroinsight-minio.service` |

### Application Components

| Component | Technology | Startup Method |
|-----------|------------|----------------|
| FastAPI Backend | Python + Uvicorn | Manual (`uvicorn`) |
| Celery Workers | Python + Celery | Manual (`celery worker`) |
| Frontend | React (Static) | Served by FastAPI |
| FreeSurfer | Docker/Apptainer | On-demand containers |

##  Configuration Files

### Environment Configuration
- **`.env.native`** - Native deployment settings
- **`.env.production`** - Production environment template
- **`.env.updated`** - Development with PostgreSQL support

### System Service Files
- **`systemd-services/neuroinsight-postgresql.service`**
- **`systemd-services/neuroinsight-redis.service`**
- **`systemd-services/neuroinsight-minio.service`**

### Startup Scripts
- **`start_production_native.sh`** - Complete native deployment
- **`stop_production_native.sh`** - Clean shutdown
- **`monitor_production_native.sh`** - Service monitoring
- **`setup_native_services.sh`** - System service installation

##  Service Management

### Systemd Service Control
```bash
# Check status
sudo systemctl status neuroinsight-postgresql
sudo systemctl status neuroinsight-redis
sudo systemctl status neuroinsight-minio

# Start/stop individual services
sudo systemctl start neuroinsight-postgresql
sudo systemctl stop neuroinsight-postgresql

# Enable/disable auto-startup
sudo systemctl enable neuroinsight-postgresql
sudo systemctl disable neuroinsight-postgresql
```

### Application Management
```bash
# Start complete system
./start_production_native.sh

# Stop complete system
./stop_production_native.sh

# Monitor all services
./monitor_production_native.sh
```

##  Monitoring & Health Checks

### Built-in Monitoring
The `monitor_native_services.sh` script provides:
-  Service health status (PostgreSQL, Redis, MinIO)
-  Database connection counts and sizes
-  Redis memory usage and performance
-  MinIO storage and API status
-  Log file monitoring
-  Performance recommendations

### Access Points
- **Web Application:** http://localhost:8000
- **API Documentation:** http://localhost:8000/docs
- **MinIO Console:** http://localhost:9001
- **Health Checks:** http://localhost:8000/health

## 🛠️ Troubleshooting

### Service Startup Issues

**PostgreSQL fails to start:**
```bash
# Check logs
tail -f data/logs/postgresql.log

# Check data directory permissions
ls -la data/postgresql/

# Manual start for debugging
pg_ctl start -D data/postgresql/ -l data/logs/postgresql.log
```

**Redis connection issues:**
```bash
# Test Redis connectivity
redis-cli ping

# Check Redis logs
tail -f data/logs/redis.log

# Check Redis configuration
cat data/redis/redis.conf
```

**MinIO access problems:**
```bash
# Check MinIO logs
tail -f data/logs/minio.log

# Test MinIO health
curl http://localhost:9000/minio/health/live

# Check data directory permissions
ls -la data/minio/
```

### Database Migration Issues

**Migration fails:**
```bash
# Check SQLite database
sqlite3 neuroinsight_web.db ".schema"

# Test PostgreSQL connection
python -c "
import psycopg2
conn = psycopg2.connect('postgresql://neuroinsight:password@localhost:5432/neuroinsight')
print('PostgreSQL connected')
conn.close()
"

# Run migration with debug output
python migrate_sqlite_to_postgresql.py
```

## 🔒 Security Considerations

### Password Management
-  Change default passwords in `.env.native`
-  Use strong, unique passwords for each service
-  Rotate passwords periodically

### Service Isolation
-  Services run as separate system users
-  Restricted file permissions
-  Network access limited to localhost

### Data Protection
-  Automated backup scripts available (`backup_neuroinsight.sh`)
-  Database files have restricted permissions
-  Service accounts have minimal privileges

##  Performance Optimization

### Database Tuning
```sql
-- PostgreSQL optimizations (run as postgres user)
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '512MB';
ALTER SYSTEM SET work_mem = '4MB';
SELECT pg_reload_conf();
```

### Redis Configuration
- Configured for persistence with RDB snapshots
- Memory limits and eviction policies set
- Connection pooling enabled

### MinIO Optimization
- Local filesystem storage for best performance
- Appropriate permissions for data directories
- Console access for administration

##  Backup & Recovery

### Automated Backups
```bash
# Run automated backup
./backup_neuroinsight.sh

# Backup includes:
# - PostgreSQL database dump
# - Redis RDB file
# - MinIO data directory
# - Configuration files
```

### Manual Backup
```bash
# Stop services
./stop_production_native.sh

# Backup data directories
tar -czf backup_$(date +%Y%m%d).tar.gz data/

# Backup database separately
pg_dump neuroinsight > neuroinsight_backup.sql

# Restart services
./start_production_native.sh
```

##  Emergency Procedures

### Complete System Reset
```bash
# Stop everything
./stop_production_native.sh

# Remove data directories (CAUTION: destroys all data)
sudo ./uninstall_native_services.sh

# Reinstall from scratch
sudo ./setup_native_services.sh
./start_production_native.sh
```

### Service Recovery
```bash
# Restart individual services
sudo systemctl restart neuroinsight-postgresql
sudo systemctl restart neuroinsight-redis
sudo systemctl restart neuroinsight-minio

# Check service status
./monitor_production_native.sh
```

## 📚 Advanced Configuration

### Custom PostgreSQL Settings
Edit `data/postgresql/postgresql.conf`:
```ini
# Performance tuning
shared_buffers = 256MB
effective_cache_size = 512MB
work_mem = 4MB

# Connection settings
max_connections = 100
listen_addresses = 'localhost'
```

### Redis Optimization
Edit `data/redis/redis.conf`:
```ini
# Memory management
maxmemory 256mb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000
```

### MinIO Configuration
Environment variables in systemd service:
```bash
MINIO_ROOT_USER=custom_user
MINIO_ROOT_PASSWORD=custom_password
MINIO_REGION=us-east-1
```

##  Production Deployment Checklist

- [ ] System services installed and running
- [ ] Passwords changed from defaults
- [ ] Database migration completed (if upgrading)
- [ ] Firewall configured for required ports
- [ ] SSL certificates configured (optional)
- [ ] Backup procedures tested
- [ ] Monitoring alerts configured
- [ ] Log rotation configured
- [ ] Performance baseline established

##  Support

### Common Issues
1. **Permission denied** → Check file ownership and sudo access
2. **Port conflicts** → Change default ports in configuration
3. **Memory issues** → Reduce service memory limits
4. **Storage full** → Clean up old data or expand storage

### Logs to Check
- `data/logs/postgresql.log`
- `data/logs/redis.log`
- `data/logs/minio.log`
- `data/logs/backend.log`
- `data/logs/celery.log`

### Getting Help
1. Run `./monitor_production_native.sh` for status
2. Check individual service logs
3. Verify configuration files
4. Test service connectivity manually

---

**The Fully Native Deployment provides enterprise-grade performance and reliability while maintaining simplicity of management.** 








