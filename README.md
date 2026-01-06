# NeuroInsight

*Automated Hippocampal Analysis Platform for Neuroscience Research*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://docker.com)

NeuroInsight provides automated hippocampal segmentation and analysis from T1-weighted MRI scans using FreeSurfer.

## Features

- Automated MRI processing with FreeSurfer
- Web-based interface for easy access
- Real-time progress monitoring
- Containerized deployment

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Web Browser   │────│ NeuroInsight API │
│  (React Frontend)   │    │  (FastAPI)      │
└─────────────────┘    └─────────────────┘
         │                       │
         │                       │
┌─────────────────┐    ┌─────────────────┐
│    Celery       │────│     Redis       │
│   Workers       │    │ (Message Queue) │
└─────────────────┘    └─────────────────┘
         │                       │
         │                       │
┌─────────────────┐    ┌─────────────────┐
│  FreeSurfer     │    │   PostgreSQL    │
│ (MRI Processing)│    │   (Database)    │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────────────────┘
                │
         ┌─────────────────┐
         │     MinIO       │
         │ (File Storage)  │
         └─────────────────┘
```

**Key Components:**
- **Frontend**: React web interface for uploads and visualization
- **API**: FastAPI backend handling requests and job management
- **Workers**: Celery processes for background MRI analysis
- **Database**: PostgreSQL for storing job metadata and results
- **Queue**: Redis for task coordination and real-time updates
- **Storage**: MinIO for MRI files and generated outputs
- **Processing**: FreeSurfer for automated hippocampal segmentation

## Quick Start

### Prerequisites
- Ubuntu 20.04+ or compatible Linux
- **RAM:** 7GB minimum (16GB+ recommended for MRI processing)
- 4+ CPU cores, 50GB+ storage
- Docker and Docker Compose
- FreeSurfer license (free for research)

**⚠️ Memory Note:** While NeuroInsight installs on 8GB systems, MRI processing requires 16GB+ RAM. Systems with less than 16GB may experience processing failures.

### FreeSurfer License Setup

**Before installation, you must obtain and set up a FreeSurfer license:**

1. **Get Free License**: Visit https://surfer.nmr.mgh.harvard.edu/registration.html
2. **Register**: Create account with your research institution email
3. **Download License**: Save the license file as `license.txt`
4. **Place License**: Put `license.txt` in the same directory as the NeuroInsight application

```bash
# Place license.txt in the project root directory
# For example, if NeuroInsight is in: ~/neuroinsight_local/
# Then license.txt should be at: ~/neuroinsight_local/license.txt

# The license.txt file should contain your email and license codes
head -3 license.txt
# Should show something like:
# your.email@institution.edu
# license_number
# license_code
```

### Installation

```bash
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local
./install.sh
./start.sh
```

Visit `http://localhost:8000` to access NeuroInsight.

## Windows Installation (via WSL2)

NeuroInsight requires Linux for optimal performance. Windows users can run NeuroInsight using **Windows Subsystem for Linux 2 (WSL2)**, which provides a full Ubuntu environment.

### Prerequisites (Windows)
- Windows 10 version 2004 or higher (Build 19041+) or Windows 11
- 16GB+ RAM recommended (32GB+ optimal for MRI processing)
- Administrator privileges for WSL2 installation
- 50GB+ free disk space

### Step 1: Install WSL2 and Ubuntu

**Option A: Automated Installation (Recommended)**
```powershell
# Open PowerShell as Administrator and run:
wsl --install -d Ubuntu
wsl --set-default-version 2
```

**Option B: Manual Installation**
```powershell
# Enable WSL feature
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart computer, then run:
wsl --set-default-version 2
wsl --install -d Ubuntu
```

### Step 2: Configure Ubuntu Environment

After installation, launch Ubuntu from Start Menu and run:
```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Install additional dependencies if needed
sudo apt install -y curl wget
```

### Step 3: Install NeuroInsight

```bash
# Clone repository (within WSL2 Ubuntu terminal)
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local

# Run installation (automatically handles Python venv and dependencies)
./install.sh

# Start services
./start.sh
```

**Note:** The installer automatically detects and installs Python venv support (python3.12-venv, python3-venv, etc.) based on your Ubuntu version.

### Step 4: Access NeuroInsight

- **Web Interface:** Open browser on Windows → `http://localhost:8000`
- **API Docs:** `http://localhost:8002/docs`
- All services run within WSL2 but are accessible from Windows

### WSL2 Tips for Windows Users

- **File Access:** WSL2 files are at `\\wsl$\Ubuntu\home\yourusername\`
- **Performance:** WSL2 provides near-native Linux performance
- **Updates:** Keep both Windows and WSL2 Ubuntu updated
- **Backup:** WSL2 distributions can be exported: `wsl --export Ubuntu backup.tar`
- **Docker:** Enable WSL2 integration in Docker Desktop settings for seamless container access

**Note:** All Linux installation instructions in this guide work identically within WSL2.

## Post-Installation Commands

After installation, use these essential commands to manage NeuroInsight:

### Application Management
```bash
# Start NeuroInsight services
./start.sh

# Stop all services gracefully
./stop.sh

# Check status of all services and ports
./status.sh
```

### License & Maintenance
```bash
# Verify FreeSurfer license is properly configured
./check_license.sh

# Create full system backup (database, configs, data)
./backup_neuroinsight.sh
```

**Tip**: All scripts provide helpful output and error messages to guide you through any issues.

## Documentation

- **[Installation Guide](INSTALL.md)**: Detailed setup
- **[User Guide](USER_GUIDE.md)**: Complete usage tutorial
- **[Troubleshooting](TROUBLESHOUTING.md)**: Common issues

## License

MIT License. FreeSurfer requires separate license for research use.