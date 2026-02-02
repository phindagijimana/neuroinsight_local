# NeuroInsight WSL Installation Guide

Complete guide for installing NeuroInsight on Windows Subsystem for Linux (WSL).

## Prerequisites

### 1. Install WSL2

```powershell
# From PowerShell (Administrator)
wsl --install
```

Or update to WSL2:
```powershell
wsl --set-default-version 2
wsl --set-version Ubuntu 2
```

### 2. Enable systemd in WSL

Edit `/etc/wsl.conf` in your WSL terminal:

```bash
sudo tee /etc/wsl.conf > /dev/null <<EOF
[boot]
systemd=true

[user]
default=your_username
EOF
```

Then restart WSL from PowerShell/CMD:
```powershell
wsl --shutdown
wsl
```

### 3. Install Docker Desktop for Windows

Download and install: https://www.docker.com/products/docker-desktop/

**Important:** Enable "Use the WSL 2 based engine" in Docker Desktop settings.

### 4. Configure WSL Memory (Optional but Recommended)

Create/edit `C:\Users\YourName\.wslconfig`:

```ini
[wsl2]
memory=16GB          # NeuroInsight needs 16GB for MRI processing
processors=4         # Use 4 CPU cores
swap=8GB             # Swap space
localhostForwarding=true
```

Then restart WSL:
```powershell
wsl --shutdown
wsl
```

## Installation Steps

### 1. Run Pre-Flight Check

```bash
cd ~
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local

# Check your WSL environment
./check_wsl.sh
```

This will verify:
- ✓ WSL2 is running
- ✓ systemd is enabled
- ✓ Docker is available
- ✓ Sufficient memory and disk space
- ✓ Python and development tools

### 2. Get FreeSurfer License

1. Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
2. Register (free for research)
3. Download `license.txt`
4. Copy to WSL:
   ```bash
   # From WSL terminal
   cp /mnt/c/Users/YourName/Downloads/license.txt ~/neuroinsight_local/
   ```

### 3. Run Installation

```bash
./neuroinsight install
```

The installation will:
- Auto-detect WSL environment
- Install missing dependencies (python3-venv, build-essential, etc.)
- Handle Docker permissions automatically
- Configure systemd services with correct paths
- Set up database containers (PostgreSQL, Redis, MinIO)

### 4. Start NeuroInsight

```bash
./neuroinsight start
```

### 5. Access Web Interface

Open browser on Windows:
```
http://localhost:8000
```

## WSL-Specific Features

### Auto-Detection
- NeuroInsight automatically detects WSL environments
- Provides WSL-specific installation guidance
- Handles path differences between WSL and Windows

### Docker Integration
- Uses Docker Desktop's WSL2 backend automatically
- No need for separate Docker installation in WSL
- `sg docker` wrapper for permission handling

### Systemd Services
- Auto-configures user-level systemd services
- Services auto-restart on failure
- Works with WSL2 systemd support

## Common WSL Issues and Solutions

### Issue 1: "systemd is not available"

**Solution:**
```bash
# Edit wsl.conf
sudo nano /etc/wsl.conf

# Add:
[boot]
systemd=true

# Restart WSL from PowerShell
wsl --shutdown
wsl
```

### Issue 2: "Docker daemon not running"

**Solution:**
1. Start Docker Desktop for Windows
2. Enable WSL integration in Docker Desktop settings
3. Check "Enable integration with my default WSL distro"

### Issue 3: "Permission denied" for Docker

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login, or run:
newgrp docker
```

### Issue 4: "Out of memory" during processing

**Solution:**
Edit `C:\Users\YourName\.wslconfig`:
```ini
[wsl2]
memory=18GB
```

Then restart WSL:
```powershell
wsl --shutdown
wsl
```

### Issue 5: "Failed to load environment files"

**Solution:**
The systemd services can't find `.env` file.

```bash
# Reinstall systemd services with correct paths
./systemd/install_systemd.sh

# Verify .env exists
ls -la .env

# Restart services
./neuroinsight start
```

## Performance Tips for WSL

### 1. Store Files in WSL Filesystem
Install NeuroInsight in WSL filesystem (`~/neuroinsight_local/`), not Windows filesystem (`/mnt/c/...`). WSL filesystem is 5-10x faster.

### 2. Allocate Sufficient Memory
Set at least 16GB in `.wslconfig` for MRI processing.

### 3. Enable Sparse VHD
Allows WSL disk to shrink when files are deleted:
```powershell
# From PowerShell (Administrator)
Optimize-VHD -Path "$env:LOCALAPPDATA\Packages\CanonicalGroupLimited.Ubuntu_*\LocalState\ext4.vhdx" -Mode Full
```

### 4. Disable Windows Antivirus for WSL
Add WSL directory to Windows Defender exclusions:
```
C:\Users\YourName\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu*
```

## Verifying Installation

### Check Services Status
```bash
./neuroinsight status
```

### Check Docker Containers
```bash
docker ps
```

Should show:
- neuroinsight-db (PostgreSQL)
- neuroinsight-redis
- neuroinsight-minio

### Check Logs
```bash
./neuroinsight logs backend
./neuroinsight logs worker
```

### Test with Sample Data
Upload a sample MRI scan through the web interface and monitor processing.

## Uninstallation

```bash
# Stop all services
./neuroinsight stop

# Remove Docker containers
docker rm -f $(docker ps -aq --filter 'name=neuroinsight')

# Remove systemd services
systemctl --user disable neuroinsight-backend neuroinsight-worker neuroinsight-beat neuroinsight-monitor
rm ~/.config/systemd/user/neuroinsight-*.service
systemctl --user daemon-reload

# Remove installation directory
cd ~
rm -rf neuroinsight_local
```

## Getting Help

If you encounter issues:

1. Run the WSL check script:
   ```bash
   ./check_wsl.sh
   ```

2. Check logs:
   ```bash
   ./neuroinsight logs
   ```

3. Check systemd status:
   ```bash
   systemctl --user status neuroinsight-backend
   journalctl --user -u neuroinsight-backend -n 50
   ```

4. Report issues on GitHub with:
   - WSL version (`wsl --version`)
   - Output of `./check_wsl.sh`
   - Relevant log files

## Additional Resources

- [WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [Docker Desktop WSL Integration](https://docs.docker.com/desktop/wsl/)
- [FreeSurfer Registration](https://surfer.nmr.mgh.harvard.edu/registration.html)
- [NeuroInsight GitHub](https://github.com/phindagijimana/neuroinsight_local)
