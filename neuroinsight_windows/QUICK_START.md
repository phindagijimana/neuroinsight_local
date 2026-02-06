# NeuroInsight Windows - Quick Start Guide

## Step 1: Install Docker Desktop

1. Download Docker Desktop: https://www.docker.com/products/docker-desktop/
2. Run installer
3. Restart computer
4. Open Docker Desktop (whale icon in system tray)

## Step 2: Install NeuroInsight

### Option A: PowerShell (Recommended)

1. Open **PowerShell**
2. Navigate to this folder:
   ```powershell
   cd path\to\neuroinsight_windows
   ```
3. Run installation:
   ```powershell
   .\install.ps1
   ```

### Option B: Command Prompt

1. Open **Command Prompt**
2. Navigate to this folder:
   ```cmd
   cd path\to\neuroinsight_windows
   ```
3. Run installation:
   ```cmd
   install.bat
   ```

### Option C: Docker Compose

```powershell
docker-compose up -d
```

## Step 3: Access NeuroInsight

Open browser to: **http://localhost:8000**

## Common Commands

```powershell
# Start
.\scripts\start.ps1

# Stop
.\scripts\stop.ps1

# Status
.\scripts\status.ps1

# View logs
.\scripts\logs.ps1

# Restart
.\scripts\restart.ps1
```

## FreeSurfer License

Required for MRI processing (free for research):

1. Get license: https://surfer.nmr.mgh.harvard.edu/registration.html
2. Save as `license.txt` in this folder
3. Restart: `.\scripts\restart.ps1`

## First Job Note

- First MRI processing downloads FreeSurfer image (~20GB)
- Takes 5-20 minutes (one-time only)
- Subsequent jobs are instant (no download)

## Need Help?

- Full documentation: [README.md](README.md)
- Troubleshooting: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- Docker Desktop: [docs/DOCKER_DESKTOP_SETUP.md](docs/DOCKER_DESKTOP_SETUP.md)
