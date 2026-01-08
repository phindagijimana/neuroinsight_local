# NeuroInsight

Automated hippocampal segmentation and analysis from T1-weighted MRI scans using FreeSurfer.

## Features

- Automated MRI processing with FreeSurfer
- Web-based interface for easy access
- Real-time progress monitoring
- Containerized deployment
- Multi-format support (NIfTI, DICOM, ZIP)
- Strict T1-weighted validation

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

# Get FreeSurfer license first
# Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
# Save license.txt in project directory

# Install and start
./install.sh
./check_license.sh  # Verify license
./start.sh

# Access at http://localhost:8000
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

## Management Commands

```bash
./start.sh    # Start all services
./stop.sh     # Stop all services
./status.sh   # Check service status
./check_license.sh  # Verify FreeSurfer license
```

## Documentation

- [User Guide](USER_GUIDE.md) - Complete usage instructions
- [Troubleshooting](TROUBLESHOUTING.md) - Common issues
- [FreeSurfer License](FREESURFER_LICENSE_README.md) - License setup

## License

MIT License. FreeSurfer requires separate license for research use.