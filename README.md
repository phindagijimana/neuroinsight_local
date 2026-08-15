# NeuroInsight-AutoHS

**NeuroInsight-AutoHS** is the name for this web application ([neuroinsight_local](https://github.com/phindagijimana/neuroinsight_local)) — automated hippocampal segmentation and analysis from T1-weighted MRI with dashboard, job queue, PDF reports, and deployment tooling.

It uses the **[AutoHS pipeline](https://github.com/phindagijimana/AutoHS)** for processing: a two-step workflow (FreeSurfer processing → AI-compute post-processing and reporting) defined in the separate [AutoHS repository](https://github.com/phindagijimana/AutoHS).

| Name | Repository | What it is |
|------|------------|------------|
| **NeuroInsight-AutoHS** | This repo (`neuroinsight_local`) | Web UI, API, Celery workers, deployment |
| **AutoHS** | [AutoHS](https://github.com/phindagijimana/AutoHS) | Pipeline specification, CLI, and BIDS App (not the same as this app) |

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

NeuroInsight-AutoHS requires a FreeSurfer license for MRI processing. FreeSurfer is free for research use.

### Get FreeSurfer License

1. Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
2. Complete the registration form
3. Save the license file as `license.txt` in your project directory

### License File Location

The license file must be named `license.txt` and placed in the root directory of the project.

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
./neuroinsight-autohs check-wsl

# Install (one-time setup - auto-detects Linux/WSL)
./neuroinsight-autohs install

# Setup FreeSurfer license
./neuroinsight-autohs license

# Start NeuroInsight-AutoHS
./neuroinsight-autohs start

# Access at http://localhost:8000
```

**Best for:** Direct Ubuntu/Debian installation with systemd services

---

### Docker (Linux & macOS)

Only manual step: place your FreeSurfer `license.txt` before install.

```bash
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local/deploy

# Place license in the neuroinsight_local folder (recommended):
#   ../license.txt
# Or: ~/Documents/license.txt  or  ~/license.txt

./neuroinsight-autohs-docker check     # verify license, Docker, ports (no install)
./neuroinsight-autohs-docker setup     # install + start (non-interactive)
./neuroinsight-autohs-docker status    # web URL and service health
```

If anything is missing, `check` runs 9 step-by-step checks and prints all blockers at once (license path, Docker, ports, etc.).

`install` / `setup` automatically:
- Verifies Docker is running
- Pulls `phindagijimana321/neuroinsight-autohs:latest` and `freesurfer/freesurfer:7.4.1`
- Picks free ports (web 8000–8050, MinIO 9000–9050)
- Mounts Docker socket (FreeSurfer jobs) and patched entrypoint (macOS Docker Desktop)
- Uses `--platform linux/amd64` on Apple Silicon
- Waits for the web UI before finishing

**Best for:** macOS, shared servers, or anyone who prefers a single container

### Desktop app — NeuroInsight-AutoHS (Electron)

```bash
cd electron
npm install
npm start          # dev
npm run dist:mac   # macOS .dmg
npm run dist:linux # Linux AppImage + .deb
npm run dist:win   # Windows NSIS installer
```

See [`electron/README.md`](electron/README.md) for build details. Requires Docker Desktop.

---

## File Requirements

NeuroInsight-AutoHS processes T1-weighted MRI scans only. Filenames must contain:
`t1`, `t1w`, `t1-weighted`, `mprage`, `spgr`, `tfl`, `tfe`, `fspgr`

Supported formats: NIfTI (`.nii`, `.nii.gz`) only.

## Commands Management (Native Linux)

| Command | `./neuroinsight-autohs` |
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
./neuroinsight-autohs install          # One-time setup
./neuroinsight-autohs start            # Start services
./neuroinsight-autohs status           # Check health
./neuroinsight-autohs logs             # View logs
./neuroinsight-autohs clean            # Clean old jobs
./neuroinsight-autohs bring <job_id>   # Recover completed job
```

### Command Notes

- **Native Linux:** Uses systemd services, runs directly on Linux

## Hippocampal asymmetry & HS classification

NeuroInsight-AutoHS applies the same thresholds as the AutoHS pipeline:

**Volume laterality** (±0.05): Left > Right if AI > 0.05; Right > Left if AI < −0.05; symmetric between.

**HS classification:** Right HS suspected if AI > 0.046915816971433; Left HS suspected if AI < −0.070839747728063; otherwise Balanced (No HS).

See the [AutoHS repository](https://github.com/phindagijimana/AutoHS) for the full pipeline specification and citation.

## Further Documentation

- [User Guide](docs/USER_GUIDE.md) — complete usage instructions
- [Troubleshooting](docs/TROUBLESHOOTING.md) — common issues
- [AutoHS pipeline](https://github.com/phindagijimana/AutoHS) — workflow spec and CLI reference
- [FreeSurfer License Setup](https://surfer.nmr.mgh.harvard.edu/registration.html) — get your license

## License

MIT License. FreeSurfer requires separate license for research use.

© 2025 University of Rochester. All rights reserved.
