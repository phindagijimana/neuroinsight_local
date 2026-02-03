# NeuroInsight

Automated hippocampal segmentation and analysis from T1-weighted MRI scans using FreeSurfer.

## Platform Support

- **Linux:** Ubuntu 20.04+ (native installation)
- **Windows:** WSL2 with systemd (full support - see Docker Installation section below)
- **Docker:** Full containerized deployment available

## Requirements

- Ubuntu 20.04+ Linux (or WSL2 on Windows)
- Docker and Docker Compose
- Redis (message broker for job processing)
- 16GB+ RAM (32GB recommended)
- 4+ CPU cores, 50GB storage
- FreeSurfer license (free for research)

## Docker Installation

Docker is required for NeuroInsight to run PostgreSQL, Redis, and MinIO services. Choose the appropriate installation method for your platform.

### For Linux (Native Ubuntu/Debian)

#### Step 1: Install Docker Engine

```bash
# Download Docker installation script
curl -fsSL https://get.docker.com -o get-docker.sh

# Run installation script
sudo sh get-docker.sh

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

#### Step 2: Add User to Docker Group (REQUIRED)

```bash
# Add current user to docker group
sudo usermod -aG docker $USER

# Verify you were added
groups $USER
```

**IMPORTANT:** You MUST log out and log back in for the group change to take effect.

```bash
# Log out
exit

# Then log back in and verify Docker works without sudo
docker ps
```

#### Step 3: Verify Installation

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker compose version

# Test Docker (should work without sudo)
docker run hello-world
```

**Troubleshooting:**

If you get "permission denied" errors:
```bash
# Verify you're in docker group
groups

# If "docker" is not listed, you haven't logged out/in yet
# Log out completely and log back in
```

### For Windows (WSL2)

#### Step 1: Install WSL2

Open PowerShell as Administrator:

```powershell
# Install WSL with Ubuntu
wsl --install

# Or install Ubuntu specifically
wsl --install -d Ubuntu

# Restart your computer when prompted
```

#### Step 2: Install Docker Desktop for Windows

1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
2. Run the installer: `Docker Desktop Installer.exe`
3. During installation, ensure "Use WSL 2 instead of Hyper-V" is checked
4. Complete installation and restart if prompted

#### Step 3: Configure Docker Desktop for WSL

After Docker Desktop starts:

1. Click the Docker icon in the system tray
2. Go to Settings (gear icon)
3. Navigate to: **Resources** → **WSL Integration**
4. Enable: "Enable integration with my default WSL distro"
5. Enable your Ubuntu distribution
6. Click "Apply & Restart"

#### Step 4: Enable Systemd in WSL (REQUIRED)

Open Ubuntu from Start Menu:

```bash
# Create/edit WSL configuration
sudo nano /etc/wsl.conf

# Add these lines:
[boot]
systemd=true

# Save and exit (Ctrl+O, Enter, Ctrl+X)
```

**IMPORTANT:** Shutdown WSL completely for changes to take effect.

Exit Ubuntu terminal, then in PowerShell:

```powershell
# Shutdown WSL
wsl --shutdown

# Wait 10 seconds, then reopen Ubuntu from Start Menu
```

#### Step 5: Verify Docker in WSL

Open Ubuntu terminal:

```bash
# Check Docker version
docker --version

# Check Docker Compose
docker compose version

# Test Docker connectivity
docker ps

# Run test container
docker run hello-world
```

**Troubleshooting:**

If you get "permission denied":
```bash
# Add user to docker group in WSL
sudo usermod -aG docker $USER

# Exit WSL terminal completely
exit
```

Then in PowerShell:
```powershell
wsl --shutdown
```

Reopen Ubuntu and test again.

#### Step 6: Configure WSL Resources (Optional but Recommended)

Create/edit `C:\Users\YourUsername\.wslconfig` in Windows:

```ini
[wsl2]
memory=8GB
processors=4
swap=4GB
localhostForwarding=true
```

Restart WSL:
```powershell
wsl --shutdown
```

### Verification Checklist

Before installing NeuroInsight, verify:

**Linux:**
- `docker --version` shows v20.10+ or v24.0+
- `docker compose version` shows v2.0+
- `docker ps` works WITHOUT sudo
- `docker run hello-world` succeeds
- You logged out and back in after adding user to docker group

**WSL:**
- Docker Desktop is running (green icon in Windows system tray)
- `wsl --list --verbose` shows VERSION 2 for Ubuntu
- Systemd enabled: `systemctl --version` works in Ubuntu
- WSL was shut down after systemd configuration
- `docker ps` works in Ubuntu terminal without errors

## FreeSurfer Setup

NeuroInsight requires a FreeSurfer license for MRI processing. FreeSurfer is free for research use.

### Get FreeSurfer License

1. Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
2. Complete the registration form
3. Save the license file as `license.txt` in your NeuroInsight project directory

### License File Location

The license file must be named `license.txt` and placed in the root directory of the NeuroInsight project.

Example structure:
```
neuroinsight_local/
├── neuroinsight
├── license.txt
├── data/
└── ...
```

## Quick Start

### Linux / WSL Installation

```bash
# Clone repository
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local

# For WSL users: Check environment first (optional but recommended)
./neuroinsight check-wsl

# Install (one-time setup - auto-detects Linux/WSL)
./neuroinsight install

# Setup FreeSurfer license
./neuroinsight license

# Start NeuroInsight
./neuroinsight start

# Access at http://localhost:8000

# Verify installation
./neuroinsight status
```

## File Requirements

NeuroInsight processes T1-weighted MRI scans only. Filenames must contain:
`t1`, `t1w`, `t1-weighted`, `mprage`, `spgr`, `tfl`, `tfe`, `fspgr`

Supported formats: NIfTI (`.nii`, `.nii.gz`) only.

## Management Commands

```bash
./neuroinsight install   # Install NeuroInsight (one-time setup)
./neuroinsight reinstall # Full reinstall instructions
./neuroinsight start     # Start all services
./neuroinsight stop      # Stops services + no-sleep
./neuroinsight status    # Check system health
./neuroinsight monitor   # Advanced monitoring
./neuroinsight nosleep   # Prevent system sleep while jobs run
./neuroinsight clean     # Clean old completed/failed jobs
./neuroinsight bring <job_id>  # Recover a completed job by ID
./neuroinsight license   # FreeSurfer license setup
./neuroinsight logs      # View system logs
```

## Further Documentation

- [User Guide](USER_GUIDE.md) - Complete usage instructions
- [Troubleshooting](TROUBLESHOUTING.md) - Common issues
- [FreeSurfer License](FREESURFER_LICENSE_README.md) - License setup

## License

MIT License. FreeSurfer requires separate license for research use.

© 2025 University of Rochester. All rights reserved.
