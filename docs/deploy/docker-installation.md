# Docker installation

← [NeuroInsight-AutoHS User Guide](../USER_GUIDE.md)

## Docker Installation

Docker is required for NeuroInsight-AutoHS to run PostgreSQL, Redis, and MinIO services. Choose the appropriate installation method for your platform.

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

#### Step 1: Install Docker Desktop for Windows

1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
2. Run the installer: `Docker Desktop Installer.exe`
3. During installation, ensure "Use WSL 2 instead of Hyper-V" is checked
4. Complete installation and restart if prompted

#### Step 2: Configure Docker Desktop for WSL

After Docker Desktop starts:

1. Click the Docker icon in the system tray
2. Go to Settings (gear icon)
3. Navigate to: **Resources** → **WSL Integration**
4. Enable: "Enable integration with my default WSL distro"
5. Enable your Ubuntu distribution
6. Click "Apply & Restart"

#### Step 3: Enable Systemd in WSL (REQUIRED)

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

#### Step 4: Verify Docker in WSL

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

#### Step 5: Configure WSL Resources (Optional but Recommended)

Create/edit `C:\Users\YourUsername\.wslconfig` in Windows:

```ini
[wsl2]
memory=12GB
processors=6
swap=4GB
localhostForwarding=true
```

Restart WSL:
```powershell
wsl --shutdown
```

### Verification Checklist

Before installing NeuroInsight-AutoHS, verify:

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

