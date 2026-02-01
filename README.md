# NeuroInsight

Automated hippocampal segmentation and analysis from T1-weighted MRI scans using FreeSurfer.

## Requirements

- Ubuntu 20.04+ Linux
- Docker and Docker Compose
- Redis (message broker for job processing)
- 16GB+ RAM (32GB recommended)
- 4+ CPU cores, 50GB storage
- FreeSurfer license (free for research)

## Docker Installation

### Option 1: Quick Install (Recommended for beginners)

```bash
# Download and run Docker installation script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Optional: Add your user to docker group
sudo usermod -aG docker $USER

# Test installation
docker --version
docker run hello-world
```

### Option 2: Docker Desktop (GUI Installation)

1. Visit: https://docs.docker.com/desktop/install/ubuntu/
2. Download the `.deb` package for Ubuntu
3. Install using: `sudo dpkg -i docker-desktop-*-amd64.deb`
4. Launch Docker Desktop from your applications menu
5. Follow the setup wizard

## FreeSurfer Setup

NeuroInsight requires a FreeSurfer license for MRI processing. FreeSurfer is free for research use.

### Get FreeSurfer License

1. Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
2. Complete the registration form
3. Save the license file as `license.txt` in your NeuroInsight project directory

### License File Location

The license file must be named `license.txt` and placed in the root directory of the NeuroInsight project.

Example structure:
```
neuroinsight_local/
├── neuroinsight
├── license.txt
├── data/
└── ...
```

## Quick Start

```bash
# Clone repository
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local

# Install (one-time setup)
./neuroinsight install

# Setup FreeSurfer license
./neuroinsight license

# Start NeuroInsight
./neuroinsight start

# Access at http://localhost:8000

# Verify installation
./neuroinsight status
```

## File Requirements

NeuroInsight processes T1-weighted MRI scans only. Filenames must contain:
`t1`, `t1w`, `t1-weighted`, `mprage`, `spgr`, `tfl`, `tfe`, `fspgr`

Supported formats: NIfTI (`.nii`, `.nii.gz`) only.

## Management Commands

```bash
./neuroinsight install   # Install NeuroInsight (one-time setup)
./neuroinsight reinstall # Full reinstall instructions
./neuroinsight start     # Start all services
./neuroinsight stop      # Stops services + no-sleep
./neuroinsight status    # Check system health
./neuroinsight monitor   # Advanced monitoring
./neuroinsight nosleep   # Prevent system sleep while jobs run
./neuroinsight clean     # Clean old completed/failed jobs
./neuroinsight bring <job_id>  # Recover a completed job by ID
./neuroinsight license   # FreeSurfer license setup
./neuroinsight logs      # View system logs
```

## Further Documentation

- [User Guide](USER_GUIDE.md) - Complete usage instructions
- [Troubleshooting](TROUBLESHOUTING.md) - Common issues
- [FreeSurfer License](FREESURFER_LICENSE_README.md) - License setup

## License

MIT License. FreeSurfer requires separate license for research use.

© 2025 University of Rochester. All rights reserved.
