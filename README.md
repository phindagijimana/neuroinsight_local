# NeuroInsight

Automated hippocampal segmentation and analysis from T1-weighted MRI scans using FreeSurfer.

## Platform Support

- **Linux:** Ubuntu 20.04+ (native installation)
- **Windows:** WSL2 with systemd (full support - see Docker Installation section below)
- **Docker:** Full containerized deployment available

## Requirements

- Ubuntu 20.04+ Linux (or WSL2 on Windows)
- Docker and Docker Compose
- Redis (message broker for job processing)
- 16GB+ RAM (32GB recommended)
- 4+ CPU cores, 50GB storage
- FreeSurfer license (free for research)

## Docker Installation

Docker is required for NeuroInsight. If you need help installing Docker:

**See USER_GUIDE.md for detailed Docker installation instructions for:**
- Linux (Ubuntu/Debian)
- Windows (WSL2)
- Docker Desktop configuration
- Troubleshooting common issues

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

### Native Linux/WSL Installation

```bash
# Clone repository
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local

# For WSL users: Check environment first (optional but recommended)
./neuroinsight check-wsl

# Install (one-time setup - auto-detects Linux/WSL)
./neuroinsight install

# Setup FreeSurfer license
./neuroinsight license

# Start NeuroInsight
./neuroinsight start

# Access at http://localhost:8000

# Verify installation
./neuroinsight status
```

### Docker Linux/WSL Installation

```bash
# Clone repository
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local/deploy

# Build Docker image
./build.sh v1.0.0

# Install and run (auto-detects port and license)
./neuroinsight-docker install

# Access at http://localhost:8000 (or shown port)

# Check status
./neuroinsight-docker status

# View logs
./neuroinsight-docker logs

# Stop
./neuroinsight-docker stop
```

## File Requirements

NeuroInsight processes T1-weighted MRI scans only. Filenames must contain:
`t1`, `t1w`, `t1-weighted`, `mprage`, `spgr`, `tfl`, `tfe`, `fspgr`

Supported formats: NIfTI (`.nii`, `.nii.gz`) only.

## Native Commands Management

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

## Docker Commands Management

```bash
# From deploy/ directory - cd neuroinsight_local/deploy
./neuroinsight-docker install      # Install and run (auto-detects port and license)
./neuroinsight-docker start        # Start the container
./neuroinsight-docker stop         # Stop the container
./neuroinsight-docker restart      # Restart all services
./neuroinsight-docker status       # Check overall status
./neuroinsight-docker health       # Check service health
./neuroinsight-docker logs         # View logs (add backend/worker for specific logs)
./neuroinsight-docker clean        # Clean old jobs (use --days N for custom)
./neuroinsight-docker bring <job_id>  # Recover a completed job by ID
./neuroinsight-docker license      # FreeSurfer license status
./neuroinsight-docker update       # Update to latest version
```

## Further Documentation

- [User Guide](USER_GUIDE.md) - Complete usage instructions
- [Troubleshooting](TROUBLESHOUTING.md) - Common issues
- [FreeSurfer License](FREESURFER_LICENSE_README.md) - License setup

## License

MIT License. FreeSurfer requires separate license for research use.

© 2025 University of Rochester. All rights reserved.
