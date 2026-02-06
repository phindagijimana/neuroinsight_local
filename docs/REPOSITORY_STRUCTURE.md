# NeuroInsight Repository Structure

Clean and organized repository structure for better maintainability.

## Root Directory

```
neuroinsight_local/
├── README.md              # Main documentation
├── LICENSE                # Project license
├── requirements.txt       # Python dependencies
├── license.txt           # FreeSurfer license (user-provided)
├── neuroinsight          # Main CLI entry point
├── env.example           # Environment configuration template
├── docker-compose.yml    # Docker Compose configuration
└── docker-compose.hybrid.yml
```

## Source Code Directories

```
├── backend/              # FastAPI backend application
│   ├── api/             # API endpoints
│   ├── core/            # Core configuration
│   ├── models/          # Database models
│   ├── schemas/         # Pydantic schemas
│   └── services/        # Business logic
├── frontend/            # React frontend application
│   └── src/
│       ├── components/  # React components
│       ├── pages/       # Page components
│       └── services/    # API client
├── pipeline/            # MRI processing pipeline
│   ├── processors/      # Image processors
│   └── utils/           # Processing utilities
├── workers/             # Celery workers
│   └── tasks/           # Background tasks
└── bridge/              # API bridge utilities
```

## Deployment Directories

```
├── deploy/              # All-in-one Docker deployment (production)
│   ├── Dockerfile       # Single container definition
│   ├── build.sh         # Build versioned images
│   ├── release.sh       # Publish to Docker Hub
│   ├── neuroinsight-docker  # User CLI
│   ├── README_DOCKER.md
│   └── DEPLOYMENT_GUIDE.md
├── docker/              # Hybrid deployment (development/testing)
│   ├── Dockerfile.backend
│   ├── Dockerfile.worker
│   └── ...
└── systemd/             # Native systemd deployment
    ├── install_systemd.sh
    └── *.service
```

## Scripts Directory

All executable scripts organized in one location:

```
scripts/
├── install.sh           # Installation script
├── start.py            # Start services
├── stop.py             # Stop services
├── status.sh           # Check status
├── monitor.sh          # Advanced monitoring
├── logs.py             # View logs
├── clean.py            # Clean old jobs
├── bring_job.py        # Recover jobs
├── nosleep.py          # Prevent system sleep
├── check_health.sh     # Health checks
├── check_license.sh    # License verification
├── check_wsl.sh        # WSL environment check
├── fix_wsl_paths.sh    # Fix WSL paths
├── start_dev.py        # Development mode
├── stop_dev.py
├── status_dev.sh
└── test_processing.py  # Testing utilities
```

## Documentation Directory

All documentation in one location:

```
docs/
├── USER_GUIDE.md                    # Complete user guide
├── TROUBLESHOUTING.md               # Troubleshooting guide
├── FREESURFER_LICENSE_README.md     # License setup
├── WSL_INSTALLATION.md              # WSL setup guide
├── SETUP_SUMMARY.txt                # Setup summary
├── PUSH_TO_GITHUB.md                # Git instructions
└── REPOSITORY_STRUCTURE.md          # This file
```

## Data Directories

```
├── data/                # Application data
│   ├── uploads/        # Uploaded MRI files
│   ├── outputs/        # Processing results
│   └── postgresql/     # Database files
├── logs/               # Application logs
└── sample_reports/     # Example reports
```

## Static Assets

```
├── ssl/                # SSL certificates
└── static/             # Static web assets
    └── js/
```

## Benefits of This Structure

### Cleaner Root Directory
- Only essential files in root
- Easy to navigate
- Professional appearance

### Better Organization
- Scripts in `scripts/` folder
- Docs in `docs/` folder
- Clear separation of concerns

### Easier Maintenance
- Find files quickly
- Update scripts in one location
- Documentation centralized

### Development Workflow
- Main CLI (`neuroinsight`) in root for easy access
- All implementation scripts in `scripts/`
- All deployment methods in separate folders

## Usage

### Main CLI Commands

```bash
# From root directory
./neuroinsight install
./neuroinsight start
./neuroinsight status
./neuroinsight logs
```

The `neuroinsight` CLI automatically references scripts from the `scripts/` folder.

### Direct Script Access

```bash
# If needed, scripts can be run directly
python3 scripts/start.py
./scripts/status.sh
./scripts/install.sh
```

### Documentation

```bash
# All documentation in docs/
cat docs/USER_GUIDE.md
cat docs/TROUBLESHOOTING.md
```

### Deployment

```bash
# Production Docker deployment
cd deploy/
./build.sh v1.0.0
./release.sh publish v1.0.0

# Development Docker deployment
docker-compose up -d

# Native systemd deployment
./systemd/install_systemd.sh
```

## Migration Notes

All script references in the `neuroinsight` CLI have been updated to use the new paths:
- `start.py` → `scripts/start.py`
- `install.sh` → `scripts/install.sh`
- etc.

Git history is preserved with proper file renames (not delete+add).

## Summary

**Root:** Clean and minimal  
**Scripts:** Organized in `scripts/`  
**Docs:** Centralized in `docs/`  
**Code:** Logical module structure  
**Deploy:** Multiple deployment methods

This structure supports both development and production deployment while maintaining a clean, professional appearance.

---

© 2025 University of Rochester. All rights reserved.
