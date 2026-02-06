# NeuroInsight Windows Docker Deployment - Changelog

## v1.0.13 (2026-02-06)

### Critical Fixes - Docker-in-Docker Support

**Docker Socket Integration:**
- ✅ Docker socket mount for FreeSurfer container spawning
- ✅ HOST_UPLOAD_DIR and HOST_OUTPUT_DIR environment variables
- ✅ Automatic license detection and mounting

**FreeSurfer Processing:**
- ✅ Fixed path mounting for Docker-in-Docker architecture
- ✅ Added mri_segstats step for statistics generation
- ✅ Automatic license host path detection

**Scripts Added:**
- ✅ `scripts/clean.ps1` - Clean old jobs
- ✅ `scripts/backup.ps1` - Backup all data
- ✅ `scripts/restore.ps1` - Restore from backup
- ✅ `scripts/health.ps1` - System health check
- ✅ `scripts/license.ps1` - License management

**Batch Scripts Added:**
- ✅ `start.bat`, `stop.bat`, `status.bat`, `logs.bat`, `restart.bat`

### Features

**Automatic Port Detection:**
- Finds available port in range 8000-8050
- No manual configuration needed

**License Auto-Detection:**
- Checks current directory
- Checks user home directory
- Checks Desktop and Documents folders

**Data Persistence:**
- Docker volume: `neuroinsight-data`
- Survives container restarts and updates

**Windows-Friendly:**
- PowerShell scripts with color output
- Batch scripts for Command Prompt
- Windows path handling
- Docker Desktop integration

---

## Previous Versions

### v1.0.0 - v1.0.12
- Initial Windows deployment development
- Basic Docker configuration
- PowerShell script foundation

---

## Compatibility

- **OS:** Windows 10/11 (64-bit, version 2004+)
- **Docker:** Docker Desktop 4.0+ with WSL2
- **RAM:** 8GB minimum, 16GB recommended
- **Storage:** 35GB (15GB app + 20GB FreeSurfer)

---

## Deployment Architecture

```
Windows → Docker Desktop (WSL2) → NeuroInsight Container → FreeSurfer Containers
```

**Same functionality as Linux deployment:**
- Docker-in-Docker FreeSurfer processing
- Automatic license detection
- Job monitoring and auto-start
- Health checks and cleanup

---

## Notes

- Uses same Docker image as Linux: `phindagijimana321/neuroinsight:v1.0.13`
- Compatible with Linux and macOS deployments
- No platform-specific modifications needed in container
- Windows-specific scripts handle path conversions
