# NeuroInsight Windows Docker Deployment - Project Summary

## Overview

Windows-native Docker deployment for NeuroInsight brain MRI analysis platform.

**Target Platform:** Windows 10/11 with Docker Desktop  
**Deployment Method:** All-in-one Docker container  
**Management:** PowerShell scripts + Batch scripts  

---

## What's Included

### Core Files

| File | Purpose | Status |
|------|---------|--------|
| `README.md` | Main documentation | ✅ Created |
| `QUICK_START.md` | Quick start guide | ✅ Created |
| `install.ps1` | PowerShell installer | ✅ Created |
| `install.bat` | Batch installer wrapper | ✅ Created |
| `docker-compose.yml` | Docker Compose config | ✅ Created |

### Management Scripts (PowerShell)

Located in `scripts/`:

| Script | Function | Status |
|--------|----------|--------|
| `start.ps1` | Start container | ✅ Created |
| `stop.ps1` | Stop container | ✅ Created |
| `restart.ps1` | Restart container | ✅ Created |
| `status.ps1` | Check status | ✅ Created |
| `logs.ps1` | View logs | ✅ Created |
| `update.ps1` | Update image | ✅ Created |
| `uninstall.ps1` | Remove everything | ✅ Created |

### Documentation (To Be Created)

Located in `docs/`:

| Document | Purpose | Status |
|----------|---------|--------|
| `INSTALLATION.md` | Detailed install guide | ⏳ Pending |
| `DOCKER_DESKTOP_SETUP.md` | Docker Desktop config | ⏳ Pending |
| `TROUBLESHOOTING.md` | Common issues | ⏳ Pending |
| `WSL2_GUIDE.md` | WSL2 setup tips | ⏳ Pending |

---

## Key Features

### Windows-Optimized

✅ **PowerShell Scripts**
- Color-coded output (Info, Success, Warning, Error)
- Parameter support (`-Port`, `-LicensePath`, etc.)
- Help system (`-Help` flag)
- Error handling

✅ **Batch Script Wrappers**
- Command Prompt compatibility
- Simple syntax for basic users
- PowerShell execution wrapper

✅ **Windows Path Handling**
- Automatic C:\Users\... → /c/Users/... conversion
- License file auto-detection in common Windows locations
- Volume mounting with Windows paths

✅ **Docker Desktop Integration**
- WSL2 backend compatibility
- System tray integration
- Dashboard access
- Resource configuration guidance

### Automated Installation

✅ **Pre-flight Checks**
- Docker Desktop installation
- Docker running status
- WSL2 availability
- Administrator privileges (optional)

✅ **Port Management**
- Auto-detect available port (8000-8050)
- Configurable via `-Port` parameter
- Conflict resolution

✅ **License Detection**
- Multiple search locations
- Example file filtering
- Manual path specification

✅ **Docker Configuration**
- Docker socket mounting (FreeSurfer spawning)
- Volume creation and management
- Environment variable setup
- Host path mapping

### User Experience

✅ **Colored Output**
- Blue: Information
- Green: Success
- Yellow: Warning
- Red: Error

✅ **Progress Indicators**
- Image pulling
- Container starting
- Service initialization

✅ **Automatic Browser Launch**
- Opens web interface after install
- Port auto-detected

---

## Technical Architecture

```
Windows 10/11
    │
    ├─ Docker Desktop (WSL2 Backend)
    │   │
    │   ├─ NeuroInsight Container (phindagijimana321/neuroinsight:latest)
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
    └─ PowerShell Management Scripts
```

---

## Comparison with Linux Deployment

| Feature | Windows Deployment | Linux Deployment |
|---------|-------------------|------------------|
| **Scripts** | PowerShell + Batch | Bash |
| **Package Manager** | Docker Desktop | Docker Engine |
| **Paths** | C:\Users\... | /home/... |
| **Service Manager** | Docker Desktop | docker-compose / systemd |
| **WSL2** | Required | N/A |
| **Functionality** | Identical | Identical |

---

## Installation Flow

```
1. User runs install.ps1
    ↓
2. Check Docker Desktop installed
    ↓
3. Check Docker running
    ↓
4. Find available port (8000-8050)
    ↓
5. Search for FreeSurfer license
    ↓
6. Pull Docker image
    ↓
7. Create data volume
    ↓
8. Start container with:
   - Port mapping
   - Docker socket mount
   - Volume mount
   - License mount (if found)
   - Environment variables
    ↓
9. Wait for services (30s)
    ↓
10. Open browser
    ↓
11. Installation complete!
```

---

## System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Windows 10 (2004+) | Windows 11 |
| **RAM** | 8GB | 16GB+ |
| **CPU** | 4 cores | 8 cores |
| **Storage** | 35GB free | 100GB free |
| **Docker Desktop** | 4.0+ | Latest |
| **WSL2** | Required | Required |

---

## Usage Examples

### Basic Installation

```powershell
# Default installation (port 8000)
.\install.ps1

# Custom port
.\install.ps1 -Port 8080

# Specify license
.\install.ps1 -LicensePath "C:\Users\John\Desktop\license.txt"

# Combined
.\install.ps1 -Port 8080 -LicensePath "C:\license.txt"
```

### Management

```powershell
# Start/Stop
.\scripts\start.ps1
.\scripts\stop.ps1
.\scripts\restart.ps1

# Monitoring
.\scripts\status.ps1
.\scripts\logs.ps1
.\scripts\logs.ps1 -Service backend -Follow

# Maintenance
.\scripts\update.ps1
.\scripts\uninstall.ps1
```

### Docker Compose

```powershell
# Start
docker-compose up -d

# Stop
docker-compose down

# View logs
docker-compose logs -f

# Remove everything
docker-compose down -v
```

---

## Next Steps

### Immediate (Ready to Use)

✅ Core installation scripts created  
✅ Management scripts created  
✅ Docker Compose configuration  
✅ Main documentation written  

### Short-term (Documentation)

⏳ Create detailed installation guide  
⏳ Write Docker Desktop setup guide  
⏳ Create troubleshooting document  
⏳ Write WSL2 configuration guide  

### Long-term (Enhancements)

⬜ Add backup/restore scripts  
⬜ Add health check script  
⬜ Add clean (job cleanup) script  
⬜ Create Windows installer (.exe or .msi)  
⬜ Add GUI management tool (optional)  

---

## Testing Checklist

### Pre-release Testing

- [ ] Test on Windows 10 (2004, 21H2, 22H2)
- [ ] Test on Windows 11
- [ ] Test with Docker Desktop 4.x
- [ ] Test with/without license file
- [ ] Test port conflicts (8000 in use)
- [ ] Test WSL2 integration
- [ ] Test all management scripts
- [ ] Test update process
- [ ] Test uninstall process
- [ ] Test MRI processing end-to-end
- [ ] Test FreeSurfer image download
- [ ] Verify data persistence

---

## Known Issues/Limitations

### Windows-Specific

1. **Docker Desktop Required**
   - Cannot use Docker Engine directly
   - Must use WSL2 backend

2. **Path Conversions**
   - Windows paths need conversion for Docker
   - Network drives may not work reliably

3. **Performance**
   - WSL2 adds slight overhead
   - I/O slower than native Linux

4. **Firewall**
   - May need to allow Docker Desktop
   - Port forwarding through WSL2

### General

1. **First Job Download**
   - FreeSurfer image is 20GB
   - Initial download takes time

2. **Resource Usage**
   - FreeSurfer needs 8GB+ RAM
   - Multiple jobs need more resources

---

## Distribution

### Package Contents

For end-user distribution:

```
neuroinsight_windows.zip
├── README.md
├── QUICK_START.md
├── install.ps1
├── install.bat
├── docker-compose.yml
├── scripts/
│   ├── start.ps1
│   ├── stop.ps1
│   ├── restart.ps1
│   ├── status.ps1
│   ├── logs.ps1
│   ├── update.ps1
│   └── uninstall.ps1
└── docs/
    ├── INSTALLATION.md
    ├── DOCKER_DESKTOP_SETUP.md
    ├── TROUBLESHOOTING.md
    └── WSL2_GUIDE.md
```

### Installation Instructions

1. Download `neuroinsight_windows.zip`
2. Extract to desired location
3. Open PowerShell in extracted folder
4. Run `.\install.ps1`

---

## Maintenance

### Update Frequency

- **Scripts:** As needed for bugs/features
- **Documentation:** With each release
- **Docker Image:** Follows main NeuroInsight releases

### Version Sync

Windows deployment version matches NeuroInsight Docker image version:
- Scripts: Independent versioning
- Image: Tracks phindagijimana321/neuroinsight:latest

---

## Support Resources

### Documentation
- README.md - Main documentation
- QUICK_START.md - Quick start guide
- docs/* - Detailed guides

### External Resources
- Docker Desktop: https://docs.docker.com/desktop/windows/
- WSL2: https://docs.microsoft.com/en-us/windows/wsl/
- NeuroInsight: https://github.com/phindagijimana/neuroinsight_local

---

## License

MIT License (same as NeuroInsight)  
FreeSurfer requires separate license for research use

© 2025 University of Rochester. All rights reserved.
