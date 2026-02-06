# 🪟 NeuroInsight for Windows - Start Here!

## What is This?

**NeuroInsight** is a medical imaging analysis tool that processes MRI brain scans using FreeSurfer.

This is the **Windows Docker deployment** - everything runs in Docker containers for easy installation.

---

## ⚡ Quick Start (5 Minutes)

### Prerequisites

1. **Windows 10/11** (64-bit, version 2004 or higher)
2. **Docker Desktop** - [Download here](https://www.docker.com/products/docker-desktop/)
   - Automatically installs and configures WSL2
   - No manual WSL2 setup needed!
3. **8GB RAM minimum** (16GB recommended)
4. **35GB disk space** (15GB app + 20GB FreeSurfer image)

### Installation Steps

1. **Install Docker Desktop** (if not already installed)
   - Download from link above
   - Run installer
   - Restart computer if prompted
   - Launch Docker Desktop and wait for it to start

2. **Open PowerShell** in this folder
   - Right-click in folder → "Open in Terminal"
   - Or: `cd C:\path\to\neuroinsight_windows`

3. **Run Installation**
   ```powershell
   .\neuroinsight-docker.ps1 install
   ```
   
   Or use the shortcut:
   ```cmd
   install.bat
   ```

4. **Wait ~30 seconds** for services to start

5. **Done!** Browser opens automatically to http://localhost:8000

---

## 📁 FreeSurfer License (Required)

FreeSurfer requires a license file (free for research use).

### Get Your License

1. Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
2. Fill out registration (takes 2 minutes)
3. Receive license via email
4. Save as `license.txt` in this folder

### Where to Place License

Place `license.txt` in any of these locations:
- ✅ This folder (neuroinsight_windows/)
- ✅ Your home folder (C:\Users\YourName\)
- ✅ Desktop or Documents folder

**The installer will auto-detect it!**

---

## 🎮 Management Commands

### Quick Commands (Batch Scripts)

```cmd
start.bat        REM Start NeuroInsight
stop.bat         REM Stop NeuroInsight
status.bat       REM Check status
logs.bat         REM View logs
restart.bat      REM Restart everything
```

### All Commands (PowerShell)

```powershell
.\neuroinsight-docker.ps1 start          # Start
.\neuroinsight-docker.ps1 stop           # Stop
.\neuroinsight-docker.ps1 status         # Status
.\neuroinsight-docker.ps1 logs           # Logs
.\neuroinsight-docker.ps1 health         # Health check
.\neuroinsight-docker.ps1 backup         # Backup
.\neuroinsight-docker.ps1 clean          # Clean old jobs
.\neuroinsight-docker.ps1 help           # Show all commands
```

**See [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for complete command list.**

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| **README_FIRST.md** (this file) | Start here! |
| [README.md](README.md) | Complete documentation |
| [QUICK_START.md](QUICK_START.md) | Quick start guide |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Command reference |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

---

## ⚠️ First Job Note

When you process your **first MRI scan**:

1. **FreeSurfer Image Download** (~20GB)
   - Happens automatically
   - Takes 5-20 minutes (depends on internet)
   - Shows progress in Docker Desktop
   - **One-time only** - cached for future jobs

2. **Processing Begins** (3-7 hours)
   - Progress updates every 5 seconds
   - Can close browser - processing continues
   - Check status anytime with `status.bat`

3. **Subsequent Jobs**
   - No download needed
   - Processing starts immediately
   - Same 3-7 hour processing time

---

## 🔧 Troubleshooting

### Docker Desktop Not Starting?

1. **First Time Setup Only - Enable WSL2** (if Docker Desktop asks)
   - Docker Desktop usually does this automatically
   - If needed, run PowerShell as Administrator:
   ```powershell
   wsl --install
   wsl --set-default-version 2
   # Then restart computer
   ```

2. **Enable Virtualization in BIOS**
   - Restart computer
   - Enter BIOS (F2/F12/Del during boot)
   - Enable Intel VT-x or AMD-V
   - Save and restart

3. **Restart Docker Desktop**
   - Right-click Docker icon in system tray
   - Click "Restart"

### Port 8000 Already in Use?

```powershell
# Install on different port
.\neuroinsight-docker.ps1 install 8080
```

### Container Won't Start?

```powershell
# Check logs
.\neuroinsight-docker.ps1 logs

# Or in Docker Desktop
# Containers → neuroinsight → Logs
```

---

## 🎯 What Can You Do?

### Upload MRI Scans
- Drag & drop .nii, .nii.gz, or .dcm files
- Automatic format detection
- DICOM series support

### Process with FreeSurfer
- Automatic brain segmentation
- Hippocampal volume analysis
- Subcortical structure identification

### Visualize Results
- 3D brain visualization
- Interactive slice viewer (Axial, Coronal, Sagittal)
- Volume measurements and statistics

### Generate Reports
- PDF reports with findings
- Volume tables and charts
- Downloadable results

---

## 💡 Tips

### Performance
- Close unnecessary programs during processing
- Use SSD storage for faster processing
- Allocate 16GB RAM in Docker Desktop settings

### Data Management
- Backup before updates: `.\scripts\backup.ps1`
- Clean old jobs monthly: `.\scripts\clean.ps1 -Days 30`
- Check disk space: `.\scripts\health.ps1`

### Monitoring
- View real-time progress in web UI
- Check logs: `.\scripts\logs.ps1 -Follow`
- System health: `.\scripts\health.ps1`

---

## 🆘 Need Help?

1. **Check logs:** `.\scripts\logs.ps1`
2. **Check health:** `.\scripts\health.ps1`
3. **Check license:** `.\scripts\license.ps1`
4. **Read full docs:** [README.md](README.md)
5. **GitHub Issues:** https://github.com/phindagijimana/neuroinsight_local/issues

---

## ✅ Ready to Start?

```powershell
# Install (one-time)
.\install.ps1

# Access web interface
# Browser opens automatically to: http://localhost:8000
```

**That's it! Upload an MRI scan and start processing!**

---

**Version:** v1.0.13  
**Platform:** Windows 10/11 with Docker Desktop  
**Last Updated:** 2026-02-06
