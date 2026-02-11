# NeuroInsight

Automated hippocampal segmentation and analysis from T1-weighted MRI scans using FreeSurfer.

## Platform Support

- **Linux:** Ubuntu 20.04+ (native installation)

## Requirements

- Ubuntu 20.04+ Linux (or WSL2 on Windows for native install)
- Docker and Docker Compose
- Redis (message broker for job processing)
- 16GB+ RAM (32GB recommended)
- 4+ CPU cores, 50GB storage
- FreeSurfer license (free for research)

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

### Native Linux (Ubuntu 20.04+)

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
```

**Best for:** Direct Ubuntu/Debian installation with systemd services

---

## File Requirements

NeuroInsight processes T1-weighted MRI scans only. Filenames must contain:
`t1`, `t1w`, `t1-weighted`, `mprage`, `spgr`, `tfl`, `tfe`, `fspgr`

Supported formats: NIfTI (`.nii`, `.nii.gz`) only.

## Commands Management (Native Linux)

| Command | `./neuroinsight` |
|---------|-------------------|
| **Installation** | `install` |
| **Start** | `start` |
| **Stop** | `stop` |
| **Restart** | _(stop + start)_ |
| **Status** | `status` |
| **Health Check** | `monitor` |
| **View Logs** | `logs` |
| **Clean Jobs** | `clean` |
| **Recover Job** | `bring <job_id>` |
| **License** | `license` |
| **Sleep Prevention** | `nosleep` |

### Command Examples

```bash
cd neuroinsight_local
./neuroinsight install          # One-time setup
./neuroinsight start            # Start services
./neuroinsight status           # Check health
./neuroinsight logs             # View logs
./neuroinsight clean            # Clean old jobs
./neuroinsight bring <job_id>   # Recover completed job
```

### Command Notes

- **Native Linux:** Uses systemd services, runs directly on Linux

## Further Documentation

- [User Guide](docs/USER_GUIDE.md) - Complete usage instructions
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues
- [FreeSurfer License Setup](https://surfer.nmr.mgh.harvard.edu/registration.html) - Get your license

## License

MIT License. FreeSurfer requires separate license for research use.

© 2025 University of Rochester. All rights reserved.
