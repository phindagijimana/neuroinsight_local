# NeuroInsight Docker Deployment for Windows

Official Docker deployment for NeuroInsight on Windows systems.

## Platform Support

- **Windows 10/11** (64-bit, version 2004 or higher)
- **Docker Desktop for Windows** (required)
- **WSL2** (Windows Subsystem for Linux 2) - automatically configured by Docker Desktop

## Quick Start

### 1. Install Docker Desktop

Download and install Docker Desktop from:
https://www.docker.com/products/docker-desktop/

**Docker Desktop automatically installs and configures WSL2 for you!**

**System Requirements:**
- Windows 10/11 (64-bit, version 2004+)
- 8GB RAM minimum (16GB recommended)
- 35GB disk space (15GB app + 20GB FreeSurfer image)

**Note:** Docker Desktop installer will enable WSL2 automatically. No manual WSL2 setup needed!

### 2. Install NeuroInsight

Open **PowerShell** or **Command Prompt**:

**PowerShell (recommended):**
```powershell
.\neuroinsight-docker.ps1 install
```

**Command Prompt:**
```cmd
install.bat
```

**Both do the same thing!** The `.bat` files are shortcuts to the main CLI.

### 3. Access NeuroInsight

Open your browser to: **http://localhost:8000**

(Or the port shown during installation if 8000 is in use)

## What's Included

This Windows deployment includes:

- **PowerShell scripts** for easy management
- **Batch scripts** (.bat) for Command Prompt users
- **Docker Desktop integration** with WSL2
- **Automatic port detection** (8000-8050)
- **FreeSurfer license auto-detection**
- **Windows-friendly paths** and shortcuts

All features from the Linux version:
- Web-based UI for MRI processing
- FreeSurfer 7.4.1 brain segmentation
- 3D visualization and volume analysis
- PDF report generation
- Automatic backup and restore

## Management Commands

### Unified CLI (PowerShell)

```powershell
# Installation and control
.\neuroinsight-docker.ps1 install        # Install and start
.\neuroinsight-docker.ps1 start          # Start container
.\neuroinsight-docker.ps1 stop           # Stop container
.\neuroinsight-docker.ps1 restart        # Restart
.\neuroinsight-docker.ps1 status         # Check status
.\neuroinsight-docker.ps1 remove         # Uninstall

# Data management
.\neuroinsight-docker.ps1 clean          # Clean old jobs (30+ days)
.\neuroinsight-docker.ps1 clean 7        # Clean jobs older than 7 days
.\neuroinsight-docker.ps1 backup         # Backup all data
.\neuroinsight-docker.ps1 restore backup.tar.gz  # Restore from backup

# Monitoring
.\neuroinsight-docker.ps1 logs           # View all logs
.\neuroinsight-docker.ps1 logs backend   # Backend logs
.\neuroinsight-docker.ps1 logs worker    # Worker logs
.\neuroinsight-docker.ps1 health         # Health check
.\neuroinsight-docker.ps1 license        # Check FreeSurfer license

# Updates
.\neuroinsight-docker.ps1 update         # Update to latest

# Help
.\neuroinsight-docker.ps1 help           # Show all commands
```

### Batch Scripts (Command Prompt)

```cmd
install.bat           REM Install and start
start.bat             REM Start container
stop.bat              REM Stop container
status.bat            REM Check status
logs.bat              REM View logs
```

## File Structure

```
neuroinsight_windows/
├── README.md                   # This file
├── install.ps1                 # Main installation (PowerShell)
├── install.bat                 # Main installation (Batch)
├── scripts/
│   ├── start.ps1               # Start container
│   ├── stop.ps1                # Stop container
│   ├── restart.ps1             # Restart container
│   ├── status.ps1              # Status check
│   ├── logs.ps1                # View logs
│   ├── clean.ps1               # Clean old jobs
│   ├── backup.ps1              # Backup data
│   ├── restore.ps1             # Restore data
│   ├── update.ps1              # Update image
│   ├── health.ps1              # Health check
│   ├── license.ps1             # License management
│   └── uninstall.ps1           # Uninstall
├── docs/
│   ├── INSTALLATION.md         # Detailed installation guide
│   ├── DOCKER_DESKTOP_SETUP.md # Docker Desktop configuration
│   ├── TROUBLESHOOTING.md      # Common issues
│   └── WSL2_GUIDE.md           # WSL2 setup and tips
└── docker-compose.yml          # Docker Compose configuration

```

## Docker Desktop Configuration

### Recommended Settings

Open Docker Desktop → Settings:

**General:**
- ✅ Use WSL2 based engine
- ✅ Start Docker Desktop when you log in

**Resources:**
- **Memory:** 8GB minimum (16GB recommended)
- **CPUs:** 4 minimum (8 recommended)
- **Disk:** 50GB minimum
- **Swap:** 2GB

**Docker Engine (docker-compose.yml):**
```json
{
  "experimental": false,
  "features": {
    "buildkit": true
  }
}
```

## FreeSurfer License

NeuroInsight requires a FreeSurfer license (free for research).

### Get License

1. Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
2. Complete registration form
3. Save license as `license.txt`

### License Placement

Place `license.txt` in one of these locations:
- Current directory (where you run scripts)
- `C:\Users\YourName\license.txt`
- Same folder as install script

The installation will auto-detect it.

## First Run Experience

### Initial Setup (First Job)

When you process your first MRI scan:

1. **FreeSurfer Image Download** (~20GB)
   - Happens automatically
   - Takes 5-20 minutes (depends on internet speed)
   - Progress shown in Docker Desktop or logs
   - **One-time download** - cached for all future jobs

2. **Processing Begins**
   - FreeSurfer segmentation (3-7 hours)
   - Progress updates every 5 seconds
   - Can close browser - processing continues

3. **Subsequent Jobs**
   - No download needed
   - Processing starts immediately
   - Same 3-7 hour timeline

## Common Tasks

### Check if Docker is Running

```powershell
docker ps
# Should show running containers
```

### View NeuroInsight Container

```powershell
docker ps | findstr neuroinsight
```

### Check FreeSurfer Image

```powershell
docker images | findstr freesurfer
# Should show: freesurfer/freesurfer  7.4.1  20GB
```

### Open Docker Desktop Dashboard

- Click Docker icon in system tray
- Click "Dashboard"
- See all containers, images, volumes

## Data Persistence

All your data is stored in a Docker volume and persists across:
- Container restarts
- NeuroInsight updates
- System reboots

**Data includes:**
- Uploaded MRI scans
- Processing results
- Visualizations
- Database
- Logs

**Backup recommended before updates!**

## Port Configuration

NeuroInsight automatically finds an available port:

- **Preferred:** 8000
- **Range:** 8000-8050
- **Shown during install:** Check terminal output

To use a specific port:
```powershell
.\install.ps1 -Port 8080
```

## Windows-Specific Features

### PowerShell Integration
- Color-coded output (info, success, warning, error)
- Tab completion for commands
- Progress bars for long operations

### Windows Paths
- Automatic conversion of Windows paths to Docker format
- Support for `C:\Users\...` style paths
- Network drive support (limited)

### System Tray
Docker Desktop icon shows container status:
- Green: Running
- Yellow: Starting/Stopping
- Red: Error

## Troubleshooting

### Docker Desktop not starting?

1. Enable WSL2:
   ```powershell
   # Run as Administrator
   wsl --install
   wsl --set-default-version 2
   ```

2. Enable Virtualization in BIOS
   - Restart computer
   - Enter BIOS (F2/F12/Del)
   - Enable VT-x/AMD-V

3. Restart Docker Desktop

### Port already in use?

```powershell
# Find what's using port 8000
netstat -ano | findstr :8000

# Install on different port
.\install.ps1 -Port 8001
```

### Container won't start?

```powershell
# Check logs
.\logs.ps1

# Check Docker Desktop logs
# Settings → Troubleshoot → Show logs
```

### FreeSurfer license issues?

```powershell
# Check license status
.\license.ps1

# Manually specify license
.\install.ps1 -LicensePath "C:\Users\YourName\Desktop\license.txt"
```

## Performance Tips

### For Large MRI Scans:

1. **Increase Docker Memory**
   - Docker Desktop → Settings → Resources
   - Set Memory to 16GB or more

2. **Close Unnecessary Programs**
   - FreeSurfer needs 8GB+ RAM
   - Close browsers, IDEs during processing

3. **Use SSD Storage**
   - Docker Desktop → Settings → Resources → Disk image location
   - Move to SSD for faster processing

### For Multiple Jobs:

- NeuroInsight can process multiple scans simultaneously
- Each job spawns its own FreeSurfer container
- Memory requirement: 8GB × number of concurrent jobs
- Recommended: Process 1-2 jobs at a time on 16GB RAM

## Updates

### Check for Updates

```powershell
.\update.ps1 --check
```

### Install Updates

```powershell
# Backup first (recommended)
.\backup.ps1

# Update
.\update.ps1

# Verify
.\status.ps1
```

## Uninstallation

### Remove Everything

```powershell
.\uninstall.ps1
```

This removes:
- NeuroInsight container
- Docker volume (data)
- Downloaded images

**Backup first if you want to keep data!**

### Keep Data, Remove Container

```powershell
docker stop neuroinsight
docker rm neuroinsight
# Volume remains - reinstall will reuse it
```

## Support

### Documentation
- [Installation Guide](docs/INSTALLATION.md)
- [Docker Desktop Setup](docs/DOCKER_DESKTOP_SETUP.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [WSL2 Guide](docs/WSL2_GUIDE.md)

### Issues
- Check Docker Desktop logs
- Run `.\logs.ps1` for NeuroInsight logs
- Review [Troubleshooting](docs/TROUBLESHOOTING.md)

### Community
- GitHub Issues: https://github.com/phindagijimana/neuroinsight_local/issues
- Docker Hub: https://hub.docker.com/r/phindagijimana321/neuroinsight

## System Requirements Summary

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Windows 10 (2004+) | Windows 11 |
| **RAM** | 8GB | 16GB+ |
| **CPU** | 4 cores | 8 cores |
| **Storage** | 35GB free | 100GB free |
| **Docker** | Docker Desktop 4.0+ | Latest version |
| **WSL2** | Required | Required |
| **Internet** | For first-time setup | Faster = better |

## What Makes This Windows-Specific?

- **PowerShell scripts** optimized for Windows
- **Batch scripts** for Command Prompt compatibility
- **Docker Desktop** integration and configuration
- **Windows path handling** (C:\Users\... → /c/Users/...)
- **WSL2 integration** for best performance
- **Windows-style documentation** and troubleshooting
- **System tray integration** via Docker Desktop

## Architecture

```
Windows 10/11
    │
    ├─ Docker Desktop (WSL2 Backend)
    │   │
    │   ├─ NeuroInsight Container
    │   │   ├─ PostgreSQL 15
    │   │   ├─ Redis 7
    │   │   ├─ MinIO
    │   │   ├─ FastAPI Backend
    │   │   ├─ Celery Workers
    │   │   └─ React Frontend
    │   │
    │   └─ FreeSurfer Containers (spawned per job)
    │       └─ freesurfer/freesurfer:7.4.1
    │
    └─ PowerShell Scripts (Management)
```

## License

MIT License. FreeSurfer requires separate license for research use.

© 2025 University of Rochester. All rights reserved.

---

**Ready to get started?** Run `.\install.ps1` in PowerShell!
