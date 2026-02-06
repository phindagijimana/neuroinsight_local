## Release v1.0.14

## 🎉 Desktop Application Now Available!

**NEW:** NeuroInsight is now available as a native desktop application!

- **One-click installers** for Windows and Linux
- **Easy setup** - No command line needed  
- **Same powerful FreeSurfer processing**
- **Perfect for researchers and clinicians**

👉 **[Download Desktop App v1.0.0](https://github.com/phindagijimana/neuroinsight_desktop/releases/tag/v1.0.0)**

Choose **Desktop App** for easiest setup, or **Docker Deployment** (below) for servers and advanced users.

---

### Major Features

#### Windows Docker Deployment
- PowerShell unified CLI (neuroinsight-docker.ps1) for Windows management
- Batch script shortcuts (.bat files) for Command Prompt compatibility
- Automatic WSL2 integration via Docker Desktop
- Port auto-detection (8000-8050)
- FreeSurfer license auto-detection
- Complete Windows documentation (README.md, INSTALL.md)

#### Documentation Improvements
- Comprehensive USER_GUIDE.md with Docker deployment sections
- Enhanced TROUBLESHOOTING.md with Docker-specific issues
- Reorganized main README with Quick Start tables
- Commands management tables comparing all deployment types

#### Linux Docker Improvements
- Updated docker-compose.yml to use Docker Hub image
- Simplified container naming (neuroinsight)
- Docker-in-Docker support for FreeSurfer processing
- FreeSurfer license auto-detection

### Deployment Options

This release supports three deployment methods:

1. **Native Linux** - Direct Ubuntu/Debian installation with systemd
2. **Linux Docker** - Containerized deployment using docker-compose
3. **Windows Docker** - Docker Desktop with WSL2 backend (NEW!)

### Quick Start

#### Linux Docker
```bash
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local/deploy
./neuroinsight-docker install
```

#### Windows Docker
```powershell
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local\neuroinsight_windows
.\neuroinsight-docker.ps1 install
```

### Docker Image

- **Image**: phindagijimana321/neuroinsight:v1.0.14
- **Docker Hub**: https://hub.docker.com/r/phindagijimana321/neuroinsight
- **Size**: 1.65GB
- **FreeSurfer**: 7.4.1

### What's Changed

#### Added
- Windows Docker deployment with full CLI
- Windows-specific documentation (README.md, INSTALL.md)
- Docker deployment sections in USER_GUIDE.md
- Docker troubleshooting in TROUBLESHOOTING.md
- Quick Start comparison tables
- Commands management tables

#### Changed
- Updated docker-compose.yml to pull from Docker Hub
- Simplified container naming
- Improved documentation structure
- Enhanced installation paths clarity

#### Fixed
- Docker image name consistency
- Windows installation path instructions
- License file detection in Docker

### System Requirements

#### All Platforms
- 16GB+ RAM (32GB recommended)
- 50GB+ free disk space
- Docker Desktop or Docker Engine
- FreeSurfer license (free for research)

#### Platform-Specific
- **Windows**: Windows 10 (2004+) or Windows 11, Docker Desktop
- **Linux**: Ubuntu 20.04+, Docker Engine or Desktop
- **WSL2**: Automatically configured by Docker Desktop

### Documentation

- [Main README](https://github.com/phindagijimana/neuroinsight_local/blob/master/README.md)
- [User Guide](https://github.com/phindagijimana/neuroinsight_local/blob/master/docs/USER_GUIDE.md)
- [Troubleshooting](https://github.com/phindagijimana/neuroinsight_local/blob/master/docs/TROUBLESHOUTING.md)
- [Windows Docker](https://github.com/phindagijimana/neuroinsight_local/tree/master/neuroinsight_windows)

---

**Full Changelog**: https://github.com/phindagijimana/neuroinsight_local/compare/v1.0.3...v1.0.14
