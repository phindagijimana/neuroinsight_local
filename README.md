# NeuroInsight 🧠

**Automated MRI Brain Segmentation & Analysis Platform**

A modern web application for automated MRI brain segmentation and hippocampal analysis using FreeSurfer. Built for neuroimaging researchers and clinicians.

[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3.9+-blue)](https://www.python.org/)
[![React](https://img.shields.io/badge/React-18+-blue)](https://reactjs.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## ✨ Features

- 🔬 **Automated MRI Processing** - Upload NIfTI/DICOM files for brain segmentation
- 🧠 **FreeSurfer Integration** - Advanced cortical reconstruction & subcortical segmentation  
- 📊 **Hippocampal Analysis** - Automated volumetric measurements & asymmetry calculations
- 🌐 **Modern Web Interface** - React frontend with real-time progress tracking
- 🔌 **REST API** - Full programmatic access to processing capabilities
- ⚡ **Asynchronous Processing** - Celery job queue with Redis backend

## 🗄️ Database Architecture

### SQLite for Sequential Processing

**NeuroInsight uses SQLite as the primary database** for job management and metadata storage, which is optimal for the current sequential processing workflow:

#### ✅ Why SQLite Works Perfectly

- **Sequential FreeSurfer Processing**: Only one MRI scan is processed at a time, eliminating SQLite's concurrency limitations
- **Redis Queue Management**: Redis handles job queuing and background task distribution, while SQLite stores job metadata
- **Controlled User Load**: Designed for research environments with limited concurrent users
- **Simple Deployment**: Zero-configuration database that works immediately

#### 📊 Current Architecture Benefits

```
User Upload → Redis Queue → Sequential Processing → SQLite Results
     ↓             ↓               ↓               ↓
  Fast API     Job Distribution  One-at-a-time   Metadata Store
  Response     (No Conflicts)    (SQLite Safe)   (ACID Compliant)
```

- **Database Size**: Small (< 100KB) with metadata only
- **Performance**: Fast reads/writes for job status and results
- **Reliability**: ACID compliance for single-writer scenarios
- **Backup**: Simple file copy operations

### 🚀 PostgreSQL for Future Scaling

Consider PostgreSQL when your needs exceed SQLite's limitations:

#### When to Upgrade

- **>10 concurrent users** actively using the platform
- **High-frequency uploads** requiring concurrent database writes
- **Database size >500MB** with extensive metadata/results
- **Multi-user permissions** and access control needed
- **High availability** and automated backup requirements
- **Advanced analytics** on processing results

#### PostgreSQL Advantages

- **Concurrent Writes**: Multiple users can upload/process simultaneously
- **Advanced Features**: User authentication, row-level security, stored procedures
- **Enterprise Ready**: Hot backups, replication, monitoring
- **Scalability**: Handles hundreds of concurrent users
- **Data Integrity**: Enhanced ACID compliance and crash recovery

#### Migration Path

```bash
# When ready to scale:
1. Install PostgreSQL (see NATIVE_DEPLOYMENT_README.md)
2. Run migration script: python migrate_sqlite_to_postgresql.py
3. Update environment: export POSTGRES_HOST=localhost
4. Restart services
```

**Current Setup**: SQLite provides reliable, simple database operations for sequential MRI processing
**Future Scaling**: PostgreSQL ready for multi-user, high-concurrency environments

## 💾 Storage Architecture

### Local Storage for Current Scale

**NeuroInsight currently uses local filesystem storage** for MRI files and processing results, which is optimal for research environments:

#### ✅ Why Local Storage Works Perfectly

- **Research-Scale Data**: Handles <2TB neuroimaging datasets efficiently
- **Sequential Processing**: Perfect for one-at-a-time MRI analysis workflows
- **Maximum Performance**: Local I/O eliminates network overhead
- **Simple Backup**: Standard tools (rsync, tar) for data preservation
- **Cost Effective**: Zero additional infrastructure costs
- **Security**: Full control over data location and access

#### 📊 Current Storage Benefits

```
MRI Upload → Local Storage → FreeSurfer Processing → Local Results
     ↓            ↓                    ↓               ↓
Fast Validation  Immediate Access    High Performance  Quick Retrieval
Zero Network     No API Calls        Maximum Speed     Direct File Access
```

- **Current Usage**: ~429MB across 8 processed scans
- **Performance**: Sub-millisecond file access
- **Backup**: Simple `rsync` to external storage
- **Reliability**: No network dependencies or API failures

### 🚀 MinIO Object Storage for Scaling

**MinIO will be integrated for larger-scale deployments** when local storage limitations are reached:

#### When to Enable MinIO

- **>500GB total data** requiring advanced storage management
- **Multiple concurrent users** accessing shared datasets
- **Cloud backup/sharing** needs (AWS S3, Google Cloud Storage)
- **Geographic distribution** of data across multiple sites
- **Enterprise compliance** requirements (HIPAA, GDPR)
- **High availability** and automated backup needs

#### MinIO Advantages

- **S3-Compatible API**: Drop-in replacement for cloud storage
- **Multi-Site Replication**: Automatic data synchronization
- **Web Management Interface**: File browser and access controls
- **Enterprise Security**: Advanced authentication and encryption
- **Cost Effective**: Self-hosted alternative to cloud storage
- **Docker Native**: Perfect fit for containerized deployments

#### Implementation Status

```bash
# MinIO infrastructure is pre-configured
✅ MinIO server ready in docker-compose.yml
✅ Python client integrated in storage service
⚠️  Credential alignment needed (currently uses local fallback)
🔄 Will activate when scaling requirements met
```

#### Migration Strategy

```bash
# When ready to scale:
1. Align MinIO credentials in environment
2. Test file operations with MinIO backend
3. Migrate existing data (optional)
4. Enable advanced features (sharing, versioning)
```

**Current Setup**: Local storage provides optimal performance for research workflows
**Future Scaling**: MinIO ready for enterprise-grade storage when data scale demands it

## 🚀 Quick Start

### Prerequisites
- 🐧 Linux (Ubuntu 20.04+, RHEL/CentOS 8+, Fedora)
- 🐳 Docker & Docker Compose  
- 💾 16GB+ RAM (32GB recommended)
- 📄 FreeSurfer license ([get here](https://surfer.nmr.mgh.harvard.edu/registration.html))

### Install & Run
```bash
git clone https://github.com/your-org/neuroinsight.git
cd neuroinsight/desktop_alone_web

# Auto-setup with secure passwords
./setup_env_simple.sh hybrid

# Deploy complete platform  
./start_production_hybrid.sh

# Open application
open http://localhost:8000
```

**Upload `test_data/test_brain.nii.gz` to test MRI processing!**

## 📚 Documentation

- 📖 **[Complete Setup Guide](NATIVE_DEPLOYMENT_README.md)** - Detailed installation & configuration
- 🔧 **[API Docs](http://localhost:8000/docs)** - Interactive API documentation  
- 🧪 **[Testing Guide](tests/README.md)** - Comprehensive testing workflow
- 🚨 **[Troubleshooting](NATIVE_DEPLOYMENT_README.md#troubleshooting)** - Common issues & solutions

## 🤝 Contributing

We welcome contributions! See [Contributing Guide](CONTRIBUTING.md) for details.

### Quick Development Setup
```bash
pip install -r requirements.txt
npm install && npm run build
docker compose -f docker-compose.yml up -d
```

## 📄 License

Licensed under MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Built with FreeSurfer, FastAPI, React, SQLite, Redis & MinIO.

---

**NeuroInsight** - Transforming neuroimaging research through automated analysis.
