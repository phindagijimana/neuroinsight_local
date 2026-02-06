# Windows Docker Deployment Architecture

## Your Questions Answered

### 1. What does "run installer" mean?

**There is NO separate "installer executable"** - we're using the same model as Linux:

- **Linux:** `./neuroinsight-docker install`
- **Windows:** `.\neuroinsight-docker.ps1 install`

The "installer" is just a command in our CLI tool that:
1. Pulls the Docker image from Docker Hub
2. Creates a Docker container
3. Configures volumes and ports
4. Starts the services

**Not:**
- ❌ A Windows .exe installer
- ❌ A separate installation package
- ❌ Docker Desktop installer (that's separate)

**Is:**
- ✅ A CLI command that sets up the Docker container
- ✅ Part of the `neuroinsight-docker.ps1` script
- ✅ Same concept as `./neuroinsight-docker install` on Linux

### 2. Why was `install.ps1` wrong?

You were absolutely right to question this! 

**The Problem:**
```powershell
# OLD (inconsistent with Linux):
.\install.ps1              # Separate script
.\scripts\start.ps1        # Separate script
.\scripts\stop.ps1         # Separate script
# etc...
```

**Linux Pattern:**
```bash
./neuroinsight-docker install    # Unified CLI
./neuroinsight-docker start      # Same CLI tool
./neuroinsight-docker stop       # Same CLI tool
```

**The Fix:**
```powershell
# NEW (matches Linux pattern):
.\neuroinsight-docker.ps1 install   # Unified CLI
.\neuroinsight-docker.ps1 start     # Same CLI tool
.\neuroinsight-docker.ps1 stop      # Same CLI tool
```

This provides:
- ✅ **Consistency** between Linux and Windows deployments
- ✅ **Single source of truth** for all commands
- ✅ **Easier maintenance** - one file instead of many
- ✅ **Better UX** - users learn one CLI pattern

### 3. But what about the `.bat` files?

The `.bat` files are **convenience shortcuts** for Command Prompt users:

```cmd
# Batch file shortcuts (for non-PowerShell users):
install.bat    →    calls    →    .\neuroinsight-docker.ps1 install
start.bat      →    calls    →    .\neuroinsight-docker.ps1 start
stop.bat       →    calls    →    .\neuroinsight-docker.ps1 stop
```

**Why keep them?**
- Many Windows users prefer Command Prompt over PowerShell
- Double-clickable (can run by double-clicking in File Explorer)
- Simpler for beginners: `start.bat` vs `.\neuroinsight-docker.ps1 start`

**Key Point:** They're just thin wrappers! All logic is in `neuroinsight-docker.ps1`

## Architecture Overview

### Deployment Model

```
User's Computer
│
├─ Docker Desktop (with WSL2)
│  │
│  └─ Linux VM (managed by Docker)
│     │
│     └─ NeuroInsight Container
│        ├─ Backend (FastAPI)
│        ├─ Worker (Celery)
│        ├─ Monitor (Job management)
│        └─ Redis
│
└─ Management Layer
   └─ neuroinsight-docker.ps1  ←  Single source of truth
      ├─ install command
      ├─ start command
      ├─ stop command
      ├─ logs command
      ├─ etc...
      
   Convenience shortcuts:
   ├─ install.bat   (calls .ps1 install)
   ├─ start.bat     (calls .ps1 start)
   └─ stop.bat      (calls .ps1 stop)
```

### Why Same Docker Image for Linux & Windows?

**Short Answer:** Docker Desktop makes Windows run Linux containers!

**Detailed:**

1. **Docker Desktop on Windows** includes:
   - WSL2 (Windows Subsystem for Linux 2)
   - A lightweight Linux VM
   - Automatic translation layer

2. **When you run a container on Windows:**
   ```powershell
   docker run phindagijimana321/neuroinsight:latest
   ```
   
   What happens:
   - Docker Desktop starts the Linux VM (if not running)
   - Runs the **Linux container** inside the Linux VM
   - Exposes ports to Windows (8000 → localhost:8000)
   - Mounts Windows paths into the Linux container
   - Translates file systems (NTFS ↔ Linux)

3. **Benefits:**
   - ✅ **One Docker image** for all platforms (Linux, Windows, Mac)
   - ✅ **Consistent behavior** across platforms
   - ✅ **Easier maintenance** - no Windows-specific container builds
   - ✅ **Same FreeSurfer** - Linux binaries work everywhere

### WSL2 Installation

**User doesn't need to manually install WSL2!**

```
User clicks "Install Docker Desktop"
         ↓
Docker Desktop installer runs
         ↓
Automatically enables WSL2 feature
         ↓
Installs Linux kernel
         ↓
User just clicks "Next, Next, Finish"
         ↓
Done! WSL2 is ready
```

**Only exception:** Very old Windows or if automatic setup fails (rare)

## File Structure

```
neuroinsight_windows/
│
├─ neuroinsight-docker.ps1     ← Main CLI (all logic)
│
├─ Quick shortcuts (.bat files):
│  ├─ install.bat
│  ├─ start.bat
│  ├─ stop.bat
│  ├─ restart.bat
│  ├─ status.bat
│  └─ logs.bat
│
├─ Configuration:
│  ├─ docker-compose.yml       ← Docker setup (optional)
│  └─ license.txt              ← User's FreeSurfer license
│
└─ Documentation:
   ├─ README.md                ← Main documentation
   ├─ README_FIRST.md          ← Quick start guide
   ├─ QUICK_REFERENCE.md       ← Command cheat sheet
   ├─ QUICK_START.md           ← Getting started
   ├─ CHANGELOG.md             ← Version history
   └─ ARCHITECTURE.md          ← This file
```

**Note:** The `scripts/` folder is no longer needed - all commands moved to `neuroinsight-docker.ps1`

## Comparison: Linux vs Windows

### Linux Deployment

```bash
# Single CLI tool:
./neuroinsight-docker install
./neuroinsight-docker start
./neuroinsight-docker stop
./neuroinsight-docker logs
```

### Windows Deployment

**Option 1: PowerShell (mirrors Linux):**
```powershell
.\neuroinsight-docker.ps1 install
.\neuroinsight-docker.ps1 start
.\neuroinsight-docker.ps1 stop
.\neuroinsight-docker.ps1 logs
```

**Option 2: Batch shortcuts (simpler):**
```cmd
install.bat
start.bat
stop.bat
logs.bat
```

**Both options do the same thing!**

## Key Takeaways

1. **No Separate Installer:** The "install" command sets up Docker containers
2. **Unified CLI:** `neuroinsight-docker.ps1` matches Linux's `neuroinsight-docker`
3. **Same Docker Image:** Windows runs the Linux container via Docker Desktop + WSL2
4. **WSL2 Auto-Install:** Docker Desktop handles this automatically
5. **.bat Shortcuts:** Optional convenience for Command Prompt users

## For Developers

If you're maintaining this codebase:

- **Core logic:** Edit `neuroinsight-docker.ps1`
- **Quick shortcuts:** Edit `.bat` files (just thin wrappers)
- **Documentation:** Update all READMEs when commands change
- **Linux parity:** Always ensure Windows CLI matches Linux CLI

## For Users

**Simple version:**
1. Install Docker Desktop (includes WSL2)
2. Run: `install.bat` or `.\neuroinsight-docker.ps1 install`
3. Access: http://localhost:8000
4. Done!

**You don't need to understand Docker, WSL2, or containers!**
