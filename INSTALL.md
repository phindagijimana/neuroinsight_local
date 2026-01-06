# Installation Guide

Complete step-by-step instructions for installing NeuroInsight on Linux systems.

## Prerequisites Checklist

Before installation, ensure your system meets these requirements:

### Hardware Requirements
- **CPU**: 4+ cores (Intel/AMD x64 architecture)
- **RAM**:
  - **Installation Minimum**: 7 GB (allows basic UI functionality)
  - **Processing Minimum**: 16 GB (required for MRI processing)
  - **Recommended**: 32 GB (optimal for research workflows)
- **Storage**: 50 GB free disk space
- **Network**: Stable internet connection

### Memory Usage Guidelines

**8GB Systems (Installation Only):**
- ✅ Can install and run the web interface
- ✅ Can view results and manage jobs
- ❌ MRI processing likely to fail due to insufficient RAM
- ⚠️  Suitable only for evaluation/demo purposes

**16GB+ Systems (Full Functionality):**
- ✅ Reliable MRI processing and segmentation
- ✅ FreeSurfer pipeline execution
- ✅ Visualization generation
- ✅ Recommended for actual research use

**32GB+ Systems (Optimal Performance):**
- ✅ Multiple concurrent processing jobs
- ✅ Large dataset handling
- ✅ Batch processing workflows
- ✅ Production research environments

### Operating System
- **Ubuntu 20.04 LTS** or later (recommended)
- **Ubuntu 18.04 LTS** (minimum, with backports)
- **Red Hat Enterprise Linux 8+**
- **Fedora 35+**
- **Other Debian-based distributions**

### Software Dependencies
- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 2.0 or later
- **Git**: For cloning the repository
- **curl/wget**: For downloading files

### User Permissions
- **sudo access**: Required for Docker operations
- **User in docker group**: For running Docker without sudo

## Quick Installation

### Option 1: Automated Installation (Recommended)

   ```bash
# Clone the repository
git clone https://github.com/yourusername/neuroinsight.git
cd neuroinsight

# Make install script executable
chmod +x install.sh

# Run automated installation
./install.sh
   ```

The automated installer will:
- Check system compatibility
- Install missing dependencies
- Configure Docker permissions
- Set up the application environment
- Guide you through FreeSurfer license setup

### Option 2: Manual Installation

If automated installation fails, follow these manual steps:

## Manual Installation Steps

### Step 1: System Preparation

```bash
# Update your system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git python3 python3-pip docker.io docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

### Step 2: Clone Repository

   ```bash
# Clone the NeuroInsight repository
git clone https://github.com/yourusername/neuroinsight.git
   cd neuroinsight

# Make scripts executable
chmod +x *.sh
   ```

### Step 3: Python Environment Setup

   ```bash
# Create virtual environment
   python3 -m venv venv

# Activate virtual environment
   source venv/bin/activate

# Install Python dependencies
   pip install -r requirements.txt
   ```

### Step 4: FreeSurfer License Setup

NeuroInsight requires a FreeSurfer license for MRI processing:

```bash
# Get your free license at: https://surfer.nmr.mgh.harvard.edu/registration.html

# Copy the license to the correct location
# Place your license.txt file in this directory (same folder as NeuroInsight)

# Edit the license file with your actual license content
nano license.txt

# Verify license format (should contain your email and license codes)
head -5 license.txt
```

### Step 5: Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit configuration (optional - defaults are usually fine)
nano .env
```

### Step 6: Initial Application Setup

```bash
# Create required directories
mkdir -p data/uploads data/outputs logs

# Start supporting services (database, Redis, etc.)
docker-compose up -d db redis minio

# Wait for services to be ready
sleep 30

# Run database migrations (if any)
# [Database setup commands would go here]
```

## Post-Installation Verification

### Test 1: Docker Services

```bash
# Check if Docker services are running
docker-compose ps

# Expected output should show:
# neuroinsight-db        Up
# neuroinsight-redis     Up
# neuroinsight-minio     Up
```

### Test 2: Application Startup

```bash
# Start the application
./start.sh

# Check if services are running
./status.sh

# Expected output:
# Backend: RUNNING (PID: 12345)
# Worker: RUNNING (PID: 12346)
# Database: RUNNING
# Redis: RUNNING
# MinIO: RUNNING
```

### Test 3: Web Interface Access

```bash
# Test web interface
curl -I http://localhost:8000

# Expected: HTTP/1.1 200 OK
```

Visit `http://localhost:8000` (or your configured port) in your web browser to access NeuroInsight.

**Note:** If port 8000 is already in use, NeuroInsight will detect this and provide instructions for using an alternative port.

### Test 4: Basic Functionality

```bash
# Test API health endpoint
curl http://localhost:8000/health

# Expected: {"status": "healthy", "services": {...}}
```

## Troubleshooting Installation

### Docker Issues

**Problem**: `docker: command not found`
```bash
# Install Docker
sudo apt install docker.io
sudo systemctl start docker
sudo usermod -aG docker $USER
# Logout and login again
```

**Problem**: `docker-compose: command not found`
```bash
# Install Docker Compose
sudo apt install docker-compose-plugin
```

**Problem**: Permission denied when running Docker
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Logout and login again, or run: newgrp docker
```

### Python Issues

**Problem**: `python3: command not found`
```bash
# Install Python 3
sudo apt install python3 python3-pip python3-venv
```

**Problem**: Virtual environment issues
```bash
# Remove and recreate virtual environment
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### FreeSurfer License Issues

**Problem**: License file not found
```bash
# Ensure license.txt exists in the project root
ls -la license.txt

# Check license content (first few lines should show your email)
head -5 license.txt
```

**Problem**: Invalid license format
```bash
# License should contain:
# your.email@institution.edu
# license_number
# license_code
cat license.txt
```

### Network Issues

**Problem**: Cannot access web interface
```bash
# Check if application is running
./status.sh

# Check firewall settings
sudo ufw status

# Test local connectivity
curl http://localhost:8000
```

## System Compatibility Matrix

| Distribution | Version | Status | Notes |
|-------------|---------|--------|-------|
| Ubuntu | 22.04 LTS | Fully Supported | Recommended |
| Ubuntu | 20.04 LTS | Supported | Tested |
| Ubuntu | 18.04 LTS | Minimal | May require backports |
| RHEL | 8.x | Supported | Requires EPEL repository |
| Fedora | 35+ | Supported | Tested |
| Debian | 11+ | Supported | May need backports |

## Next Steps

After successful installation:

1. **Upload Test Data**: Try processing a sample MRI scan
2. **Review User Guide**: Read [USER_GUIDE.md](USER_GUIDE.md) for detailed usage
3. **Configure Settings**: Adjust application settings in `.env`
4. **Monitor Performance**: Use `./status.sh` and `./logs.sh` for monitoring

## Getting Help

- **Installation Issues**: Check [TROUBLESHOUTING.md](TROUBLESHOUTING.md)
- **Usage Questions**: See [USER_GUIDE.md](USER_GUIDE.md)
- **Bug Reports**: Create GitHub issues
- **Community Support**: Join our discussions

---

**Need help?** Visit our [troubleshooting guide](TROUBLESHOUTING.md) or create an issue on GitHub.