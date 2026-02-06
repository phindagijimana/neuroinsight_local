# NeuroInsight Windows - Quick Reference

## Installation

```powershell
# Pull image and install
docker pull phindagijimana321/neuroinsight:latest
.\install.ps1

# Or with custom port
.\install.ps1 -Port 8080
```

## Management Commands

### PowerShell (Recommended)

```powershell
.\scripts\start.ps1        # Start
.\scripts\stop.ps1         # Stop
.\scripts\restart.ps1      # Restart
.\scripts\status.ps1       # Status
```

### Batch Scripts (Command Prompt)

```cmd
start.bat        REM Start
stop.bat         REM Stop
status.bat       REM Status
logs.bat         REM Logs
restart.bat      REM Restart
```

## Data Management

```powershell
# Backup
.\scripts\backup.ps1

# Restore
.\scripts\restore.ps1 backup-file.tar.gz

# Clean old jobs
.\scripts\clean.ps1 -Days 30
```

## Monitoring

```powershell
# System health
.\scripts\health.ps1

# View logs
.\scripts\logs.ps1
.\scripts\logs.ps1 -Service backend
.\scripts\logs.ps1 -Follow

# Check license
.\scripts\license.ps1
```

## Troubleshooting

### Port Already in Use?

```powershell
# Find process using port 8000
netstat -ano | findstr :8000

# Install on different port
.\install.ps1 -Port 8080
```

### Docker Not Running?

```powershell
# Start Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Wait and check
docker ps
```

### Container Won't Start?

```powershell
# Check logs
docker logs neuroinsight

# Or detailed service logs
.\scripts\logs.ps1
```

### License Issues?

```powershell
# Check license status
.\scripts\license.ps1

# Place license.txt in current directory
# Then restart
.\scripts\restart.ps1
```

## Docker Desktop Configuration

**Settings → Resources:**
- Memory: 16GB (minimum 8GB)
- CPUs: 8 (minimum 4)
- Disk: 50GB free

**Settings → General:**
- ✅ Use WSL2 based engine
- ✅ Start Docker Desktop when you log in

## File Locations

### NeuroInsight Files

```
C:\Users\YourName\neuroinsight_windows\
├── install.ps1              # Main installer
├── install.bat              # Batch wrapper
├── *.bat                    # Quick batch scripts
├── scripts\                 # PowerShell scripts
│   ├── start.ps1
│   ├── stop.ps1
│   ├── status.ps1
│   ├── logs.ps1
│   ├── clean.ps1
│   ├── backup.ps1
│   └── ...
└── license.txt              # Place FreeSurfer license here
```

### Docker Data

```
Docker Volume: neuroinsight-data
WSL2 Location: \\wsl$\docker-desktop-data\data\docker\volumes\neuroinsight-data\_data\
```

**Access via:**
```powershell
# View in Docker Desktop
# Containers → neuroinsight → Files → /data

# Or through container
docker exec neuroinsight ls /data
```

## URLs

- **Web Interface:** http://localhost:8000
- **API Docs:** http://localhost:8000/docs
- **MinIO Console:** http://localhost:9001
- **Health Check:** http://localhost:8000/health

## Common Tasks

### Update to Latest Version

```powershell
.\scripts\backup.ps1         # Backup first!
.\scripts\update.ps1         # Pull and restart
```

### View Running Jobs

Open browser: http://localhost:8000

### Check Processing Progress

```powershell
.\scripts\logs.ps1 -Service worker -Follow
```

### Clean Old Test Jobs

```powershell
.\scripts\clean.ps1 -Days 7
```

### Uninstall Everything

```powershell
.\scripts\backup.ps1         # Backup first!
.\scripts\uninstall.ps1      # Remove all
```

## Performance

### Recommended for MRI Processing

- **1 concurrent job:** 8GB RAM
- **2 concurrent jobs:** 16GB RAM
- **3+ concurrent jobs:** 24GB+ RAM

Each FreeSurfer job needs ~4-6GB RAM during processing.

### Processing Times

- **FreeSurfer:** 3-7 hours per scan
- **FastSurfer:** 5-15 minutes per scan (if implemented)

## Support

- **Documentation:** See README.md
- **License:** https://surfer.nmr.mgh.harvard.edu/registration.html
- **GitHub:** https://github.com/phindagijimana/neuroinsight_local
- **Docker Hub:** https://hub.docker.com/r/phindagijimana321/neuroinsight
