# NeuroInsight

Automated hippocampal segmentation and analysis from T1-weighted MRI scans using FreeSurfer.

## Features

- Automated MRI processing with FreeSurfer
- Web-based interface for easy access
- Real-time progress monitoring
- Containerized deployment
- Multi-format support (NIfTI, DICOM, ZIP)
- Strict T1-weighted validation

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
- Ubuntu 20.04+ Linux
- 16GB+ RAM (32GB recommended)
- 4+ CPU cores, 50GB storage
- Docker and Docker Compose
- FreeSurfer license (free for research)

### Installation

```bash
# Clone repository
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local

# Run installation (one-time setup)
./install.sh

# Get FreeSurfer license first
# Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
# Save license.txt in project directory
# See: [FreeSurfer License Setup](FREESURFER_LICENSE_README.md) for detailed instructions

# Quick start
./neuroinsight license  # Check/setup FreeSurfer license
./neuroinsight start    # Start the complete system


# Management commands (Terminal-Agnostic)
./neuroinsight start     # Start all services (avoids terminal issues)
./neuroinsight stop      # Stop all services gracefully
./neuroinsight stop --clear-stuck  # Stop and clear stuck jobs
./neuroinsight status    # Check system status and health
./neuroinsight monitor   # Run system health checks and cleanup
./neuroinsight license   # Check/setup FreeSurfer license
./neuroinsight monitor status  # Show items being tracked for cleanup


# Automatic Maintenance (runs every 60 seconds)
# - Orphaned processes cleaned up after 3 hour grace period
# - Stuck jobs cleaned up after 3 hour grace period
# - System health monitoring and resource checks
# - Automatic queue processing for pending jobs
```

## File Requirements

NeuroInsight only processes T1-weighted MRI scans. Filenames must contain T1 indicators:

**Required indicators:** `t1`, `t1w`, `t1-weighted`, `mprage`, `spgr`, `tfl`, `tfe`, `fspgr`

**Supported formats:** NIfTI (`.nii`, `.nii.gz`), DICOM (`.dcm`), ZIP archives

**Examples:** `patient001_T1w.nii`, `subject_01_mprage.nii.gz`

### Mock Data Usage

NeuroInsight uses synthetic data when FreeSurfer license is missing or processing fails. Jobs show "(Mock Data)" suffix. **Never use mock data for clinical decisions.**

## Windows Installation

Windows users can run NeuroInsight using WSL2:

```powershell
# Install WSL2
wsl --install -d Ubuntu
wsl --set-default-version 2
```

Then follow Linux installation steps within WSL2 terminal. Access at `http://localhost:8000`.
```

## Documentation

- [User Guide](USER_GUIDE.md) - Complete usage instructions
- [Troubleshooting](TROUBLESHOUTING.md) - Common issues
- [FreeSurfer License](FREESURFER_LICENSE_README.md) - License setup

## License

MIT License. FreeSurfer requires separate license for research use.

© 2025 University of Rochester. All rights reserved.