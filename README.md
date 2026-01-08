# NeuroInsight

*Automated Hippocampal Analysis Platform for Neuroscience Research*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://docker.com)

NeuroInsight provides automated hippocampal segmentation and analysis from T1-weighted MRI scans using FreeSurfer.

## Features

- **Strict T1-Weighted Validation**: Only accepts MRI scans with confirmed T1-weighted indicators in filenames
- Automated MRI processing with FreeSurfer
- Web-based interface for easy access
- Real-time progress monitoring
- Containerized deployment
- Multi-format support (NIfTI, DICOM, ZIP)

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
- **Frontend**: React web interface for T1-weighted MRI uploads and visualization
- **API**: FastAPI backend handling requests, T1 validation, and job management
- **Workers**: Celery processes for background MRI analysis
- **Database**: PostgreSQL for storing job metadata and results
- **Queue**: Redis for task coordination and real-time updates
- **Storage**: MinIO for MRI files and generated outputs
- **Processing**: FreeSurfer for automated hippocampal segmentation from T1-weighted scans

## Quick Start

### Prerequisites
- Ubuntu 20.04+ or compatible Linux
- **RAM:** 7GB minimum (16GB+ recommended for MRI processing)
- 4+ CPU cores, 50GB+ storage
- Docker and Docker Compose
- FreeSurfer license (free for research)
- **T1-weighted MRI scans** (filenames must contain T1 indicators)

**Memory Warning:** While NeuroInsight installs on 8GB systems, MRI processing requires 16GB+ RAM. Systems with less than 16GB may experience processing failures.

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
# 1. Clone the repository
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local

# 2. Run automated installation
./install.sh

# 3. Check FreeSurfer license (required before starting)
./check_license.sh

# 4. Start NeuroInsight services
./start.sh
```

**Automatic Job Processing:** NeuroInsight automatically starts processing any pending jobs when the application starts. Jobs are processed according to concurrency limits (1 job at a time by default).

**System Resilience:** NeuroInsight includes automatic monitoring that detects jobs interrupted by system sleep or shutdown. Interrupted jobs are automatically marked as failed, allowing normal cleanup and preventing stuck job states.

Visit `http://localhost:8000` to access NeuroInsight.

## File Upload Requirements

**Important:** NeuroInsight only processes T1-weighted MRI scans. All uploaded files must have T1 indicators in their filenames.

### Required T1 Indicators

Your MRI scan filenames must include one of these T1-weighted indicators:

- `t1` - Basic T1 indicator
- `t1w` - T1-weighted
- `t1-weighted` - T1-weighted (full)
- `mprage` - MPRAGE sequence
- `spgr` - SPGR sequence
- `tfl` - TurboFLASH sequence
- `tfe` - Turbo Field Echo
- `fspgr` - Fast SPGR sequence

### Valid Filename Examples

**Accepted filenames:**
- `patient001_T1w.nii`
- `subject_01_mprage.nii.gz`
- `scan_t1_weighted.dcm`
- `brain_T1_spgr.nii`

**Rejected filenames:**
- `patient_scan.nii` (no T1 indicator)
- `brain_image.dcm` (no T1 indicator)
- `mri_data.nii.gz` (no T1 indicator)

### Upload Validation

NeuroInsight validates T1 requirements at multiple levels:

1. **File Selection**: Immediate feedback when selecting invalid files
2. **Form Submission**: Validation before upload begins
3. **Backend Processing**: Final validation before job creation

**Error Message:** `Filename must contain T1 indicators. Expected one of: t1, t1w, t1-weighted, mprage, spgr, tfl, tfe, fspgr`

### Supported File Formats

**Recommended:** Use NIfTI format (`.nii` or `.nii.gz`) for optimal processing and compatibility.

NeuroInsight supports the following file formats:
- **NIfTI** (Recommended): `.nii`, `.nii.gz` - Best format for MRI analysis
- **DICOM**: `.dcm`, `.dicom` - Raw scanner output
- **ZIP Archives**: `.zip` - Auto-extracted DICOM series

**Note:** While DICOM and ZIP formats are supported, NIfTI is recommended for faster processing and better compatibility with FreeSurfer analysis tools.

### File Size Limits

- **Frontend**: 500MB per file
- **Backend**: 1GB per file
- **Processing**: 16GB+ RAM recommended for MRI analysis

### Mock Data Usage

NeuroInsight transparently indicates when synthetic/mock data is used instead of real FreeSurfer analysis. This occurs in the following scenarios:

- **FreeSurfer License Missing**: When no `license.txt` file is found
- **Processing Failures**: When FreeSurfer containers fail to run or complete
- **Development/Testing**: When `NEUROINSIGHT_ALLOW_MOCK_FALLBACK=true` is set

**How to identify mock data usage:**
- Job names will display **"(Mock Data)"** suffix in the completed jobs list
- Example: `brain_scan.nii.gz (Mock Data)`
- Results will be clearly marked as simulated data

**Clinical Use Warning:**
Mock data provides realistic-looking results for testing purposes but should **never be used for clinical decisions**. Always ensure FreeSurfer license is properly installed for medical applications.

To enable full FreeSurfer analysis:
1. Obtain a FreeSurfer license from: https://surfer.nmr.mgh.harvard.edu/registration.html
2. Place `license.txt` in the NeuroInsight application directory
3. Restart the application

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

# Check FreeSurfer license (required before starting)
./check_license.sh

# Start services
./start.sh
```

**Note:** The installer automatically detects and installs Python venv support (python3.12-venv, python3-venv, etc.) based on your Ubuntu version.

### Step 4: Access NeuroInsight

- **Web Interface:** Open browser on Windows → `http://localhost:8000`
- **API Docs:** `http://localhost:8002/docs`
- All services run within WSL2 but are accessible from Windows

### Optional: Auto-Start Service (Linux)

For automatic startup on system boot:

```bash
# Copy service file to systemd directory
sudo cp neuroinsight.service /etc/systemd/system/

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable auto-start
sudo systemctl enable neuroinsight

# Start service manually
sudo systemctl start neuroinsight

# Check status
sudo systemctl status neuroinsight
```

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