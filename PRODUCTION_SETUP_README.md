#  NeuroInsight Production Setup

Complete production deployment with Docker containers for PostgreSQL, Redis, MinIO, FreeSurfer, and Celery.

##  Prerequisites

- **Docker & Docker Compose** installed
- **4GB+ RAM** available
- **FreeSurfer License** (required for MRI processing)

##  Quick Start

### 1. Initial Setup
```bash
# Clone repository and enter directory
cd neuroinsight

# Run automated setup
./setup-production-environment.sh
```

This will:
-  Generate secure passwords
-  Create all necessary directories
-  Prompt for FreeSurfer license
-  Start all Docker services
-  Verify service health

### 2. Database Initialization
```bash
# Initialize PostgreSQL database and run migrations
./initialize-production-database.sh
```

### 3. Access Your Application
- **NeuroInsight**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **MinIO Console**: http://localhost:9001

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   NeuroInsight  │────│   PostgreSQL    │
│     FastAPI     │    │   (Database)    │
└─────────────────┘    └─────────────────┘
          │                       │
          │                       │
┌─────────────────┐    ┌─────────────────┐
│     Celery      │────│      Redis      │
│    Workers      │    │  (Message Queue)│
└─────────────────┘    └─────────────────┘
          │                       │
          │                       │
┌─────────────────┐    ┌─────────────────┐
│   FreeSurfer    │    │     MinIO       │
│ (MRI Processing)│    │ (Object Storage)│
└─────────────────┘    └─────────────────┘
```

##  Services Overview

| Service | Purpose | Port | Access |
|---------|---------|------|--------|
| **NeuroInsight API** | Main application | 8000 | http://localhost:8000 |
| **PostgreSQL** | Database | 5432 | Internal only |
| **Redis** | Cache/Message Queue | 6379 | Internal only |
| **MinIO** | Object Storage | 9000/9001 | http://localhost:9001 |
| **FreeSurfer** | MRI Processing | N/A | Internal only |
| **Celery** | Background Tasks | N/A | Internal only |

## 🔐 Security Configuration

### Environment Variables
All sensitive data is configured via `.env.production.services`:

```bash
# Database
POSTGRES_PASSWORD=secure_password_here

# Redis
REDIS_PASSWORD=redis_secure_password

# MinIO
MINIO_ROOT_USER=neuroinsight_minio
MINIO_ROOT_PASSWORD=minio_secure_password

# Application
SECRET_KEY=your-super-secure-secret-key
```

### Network Security
- Services communicate via Docker networks
- Only necessary ports exposed externally
- Redis requires password authentication
- MinIO uses secure object storage

##  FreeSurfer Setup

### Getting Your License
1. Register at: https://surfer.nmr.mgh.harvard.edu/registration.html
2. Download `license.txt`
3. Place in: `pipeline/freesurfer_license.txt`

### FreeSurfer Container
- Uses official `freesurfer/freesurfer:7.4.1` image
- Persistent data in `./data/freesurfer/`
- License mounted at runtime
- Health checks ensure availability

##  Monitoring & Maintenance

### View Logs
```bash
# All services
docker-compose -f docker-compose.production.yml logs -f

# Specific service
docker-compose -f docker-compose.production.yml logs -f postgres
docker-compose -f docker-compose.production.yml logs -f celery-worker
```

### Service Management
```bash
# Restart all services
docker-compose -f docker-compose.production.yml restart

# Stop everything
docker-compose -f docker-compose.production.yml down

# Start specific service
docker-compose -f docker-compose.production.yml up -d postgres
```

### Backup Strategy
```bash
# Database backup
docker-compose -f docker-compose.production.yml exec postgres pg_dump -U neuroinsight neuroinsight > backup.sql

# MinIO data
# Data automatically persisted in Docker volumes
# Use MinIO console for object storage management
```

## 🐛 Troubleshooting

### Common Issues

**FreeSurfer Processing Fails**
```bash
# Check FreeSurfer license
cat pipeline/freesurfer_license.txt

# Verify FreeSurfer container
docker-compose -f docker-compose.production.yml logs freesurfer
```

**Database Connection Issues**
```bash
# Check PostgreSQL health
docker-compose -f docker-compose.production.yml exec postgres pg_isready -U neuroinsight

# View database logs
docker-compose -f docker-compose.production.yml logs postgres
```

**MinIO Not Accessible**
```bash
# Check MinIO status
curl http://localhost:9000/minio/health/live

# View MinIO logs
docker-compose -f docker-compose.production.yml logs minio
```

### Performance Tuning

**Increase Worker Concurrency**
```yaml
# In docker-compose.production.yml
celery-worker:
  environment:
    - MAX_CONCURRENT_JOBS=8  # Increase from 4
```

**Database Connection Pooling**
```python
# In backend/core/config.py
# Add SQLAlchemy connection pooling settings
```

##  Scaling

### Horizontal Scaling
```bash
# Add more Celery workers
docker-compose -f docker-compose.production.yml up -d --scale celery-worker=3

# Load balancer for multiple API instances
# Add nginx or traefik for load balancing
```

### Vertical Scaling
- Increase Docker resource limits
- Add more CPU cores
- Increase RAM allocation
- Use faster storage (SSD)

##  Updates & Upgrades

### Service Updates
```bash
# Update all images
docker-compose -f docker-compose.production.yml pull

# Rolling update
docker-compose -f docker-compose.production.yml up -d

# Update specific service
docker-compose -f docker-compose.production.yml up -d postgres
```

### Database Migrations
```bash
# Run new migrations
docker-compose -f docker-compose.production.yml run --rm celery-worker alembic upgrade head
```

##  Support

### Health Checks
- API Health: http://localhost:8000/health
- Service Status: `docker-compose -f docker-compose.production.yml ps`
- Resource Usage: `docker stats`

### Logs Location
- Application: `./data/logs/`
- Docker: `docker-compose -f docker-compose.production.yml logs`
- Database: Container logs

---

** Medical Software Notice**: This setup is designed for research and clinical environments. Ensure compliance with relevant regulations (HIPAA, GDPR, etc.) before production use.
