# NeuroInsight-AutoHS User Guide

Hub for deploying and operating **NeuroInsight-AutoHS** — the application for the **AutoHS** workflow on the **NeuroInsight** platform ([`neuroinsight_local`](https://github.com/phindagijimana/neuroinsight_local)).

- **Documentation map (all repos):** [DOCUMENTATION.md](DOCUMENTATION.md) · [NeuroInsight landing](https://phindagijimana.github.io/neuroinsight_landing_web/) · [Software from the paper](https://phindagijimana.github.io/neuroinsight_landing_web/#publication)
- **AutoHS pipeline (BIDS CLI, methods, citation):** [AutoHS Read the Docs](https://autohs.readthedocs.io/en/latest/) — not duplicated here.

## Quick links

| I want to… | Document |
|------------|----------|
| Set up Windows (WSL) | [deploy/wsl-setup.md](deploy/wsl-setup.md) |
| Install Docker (Linux / WSL) | [deploy/docker-installation.md](deploy/docker-installation.md) |
| Choose native vs Docker vs desktop | [Deployment options](#deployment-options) (below) |
| Diagnose failures | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| Docker-only deploy details | [deploy/README_DOCKER.md](../deploy/README_DOCKER.md) |
| Desktop builds | [electron/README.md](../electron/README.md) |

## Prerequisites

- Ubuntu 20.04+ Linux system (or WSL2 on Windows — see [WSL setup](deploy/wsl-setup.md))
- 16GB+ RAM (32GB recommended), 4+ CPU cores, 50GB storage
- Docker and Docker Compose ([install guide](deploy/docker-installation.md))
- FreeSurfer license (`license.txt`) for real MRI processing
- **System sleep timeout set to 7+ hours** during long FreeSurfer jobs

```bash
nproc && free -h && df -h / && lsb_release -a
```

---
## Deployment Options

NeuroInsight-AutoHS offers four deployment methods:

| Type | Best For | Requirements |
|------|----------|--------------|
| **Desktop App** | Researchers, clinicians | Windows 10/11 or Linux, Docker Desktop |
| **Native Linux** | Direct Ubuntu/Debian installation | Ubuntu 20.04+, systemd |
| **Linux Docker** | Isolated containerized environment | Docker + Docker Compose |
| **Windows Docker** | Windows 10/11 systems | Docker Desktop + WSL2 |

**New to NeuroInsight-AutoHS?** Start with the [Desktop App](https://github.com/phindagijimana/neuroinsight_local/releases) for the easiest installation.

Choose Docker/Native deployment for servers, HPC clusters, or multi-user environments.

---

## Installation

### Option 0: Desktop Application (Recommended for Most Users)

**Best for:** Researchers, clinicians, desktop users wanting the easiest setup

**Download:** [NeuroInsight-AutoHS Desktop releases](https://github.com/phindagijimana/neuroinsight_local/releases) (tags `desktop-v*`, e.g. [`desktop-v1.1.0`](https://github.com/phindagijimana/neuroinsight_local/releases/tag/desktop-v1.1.0))

**Platforms:**
- macOS Apple Silicon (`.dmg` or `.zip`)
- Windows 10/11 (`.exe` NSIS installer)
- Linux (`.AppImage` or `.deb`)

**Prerequisites:**
- Docker Desktop installed (see Docker Installation section above)
- 16GB+ RAM, 50GB+ disk space

**Quick Start:**

**Windows:**
1. Download the latest `.exe` from [Releases](https://github.com/phindagijimana/neuroinsight_local/releases)
2. Run installer and follow wizard
3. Launch from Start Menu

**macOS:**
1. Download the `.dmg` from [Releases](https://github.com/phindagijimana/neuroinsight_local/releases)
2. Open the DMG and drag **NeuroInsight-AutoHS** to Applications
3. Launch from Applications (requires Docker Desktop)

**macOS first launch (Gatekeeper):** The desktop app is not notarized yet. If macOS blocks the app, use one of these workarounds:
- **Right-click** **NeuroInsight-AutoHS** → **Open**, or
- Install from the release **`.dmg`**, then approve the app in **System Settings → Privacy & Security**.

**Linux (AppImage):**
```bash
# Replace VERSION with the release tag, e.g. desktop-v1.1.0
wget https://github.com/phindagijimana/neuroinsight_local/releases/download/desktop-v1.1.0/NeuroInsight-AutoHS-1.1.0.AppImage
chmod +x NeuroInsight-AutoHS-1.1.0.AppImage
./NeuroInsight-AutoHS-1.1.0.AppImage
```

**Linux (DEB - Ubuntu/Debian):**
```bash
wget https://github.com/phindagijimana/neuroinsight_local/releases/download/desktop-v1.1.0/neuroinsight-autohs-desktop_1.1.0_amd64.deb
sudo dpkg -i neuroinsight-autohs-desktop_1.1.0_amd64.deb
```

**First Run:**
1. Ensure Docker Desktop is running
2. Launch NeuroInsight-AutoHS
3. First run downloads FreeSurfer image (~7GB, one-time)
4. Upload T1-weighted MRI files and start processing

**Documentation:** See [electron/README.md](https://github.com/phindagijimana/neuroinsight_local/blob/master/electron/README.md) for build details, troubleshooting, and advanced features.

**Note:** Desktop App uses Docker containers under the hood. For server deployments or advanced configurations, use the options below.

---

### Option 1: Native Linux Installation

**Best for:** Direct Ubuntu/Debian systems with systemd

**Prerequisites:** 
- Docker installed (see Docker Installation section above)
- Ubuntu 20.04+ with systemd

### 1. Clone Repository

```bash
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local
```

### 2. Get FreeSurfer License

**REQUIRED:** FreeSurfer requires a free license for research use.

1. Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
2. Complete the registration form
3. Save the license file as `license.txt` in the project directory

### 3. Verify Docker Installation (REQUIRED)

```bash
docker --version  # Should show Docker version
docker run hello-world  # Should run successfully
```

### 4. Install Docker (if not already installed)

#### Ubuntu/Debian Installation:

```bash
# Update package index
sudo apt update

# Install required packages
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
sudo apt update

# Install Docker Engine
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker service:
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (optional, avoids using sudo):
sudo usermod -aG docker $USER
# Log out and back in, or run: newgrp docker

# Verify Docker works:
docker --version
docker run hello-world
```

### 5. WSL (Windows Subsystem for Linux) Users

If you're using WSL on Windows, Docker installation is different:

#### Install Docker Desktop on Windows:
1. **Download Docker Desktop for Windows**: Visit https://www.docker.com/products/docker-desktop
2. **Install the .exe file** and follow the installation wizard
3. **Enable WSL Integration**:
   - Open Docker Desktop
   - Go to Settings → Resources → WSL Integration
   - Enable integration with your WSL distribution
   - Click "Apply & Restart"

#### Verify WSL Docker Access:
```bash
# In your WSL terminal, verify Docker works:
docker --version
docker run hello-world

# If you get connection errors, restart WSL:
exit
# Then reopen WSL terminal
```

#### Important Notes for WSL:
- **File permissions**: WSL files are accessible at `/mnt/c/` from Windows
- **Performance**: Docker volumes work better when files are inside WSL, not `/mnt/c/`
- **Memory**: Docker Desktop may need memory allocation in Windows settings
- **Updates**: Keep both Windows Docker Desktop and WSL distribution updated

### 5. Troubleshooting

For installation issues on WSL or native Linux, see the **Troubleshooting** section at the end of this guide or refer to `docs/TROUBLESHOOTING.md`.

**Common WSL issues:**

- **Upload directory missing** - Run `./neuroinsight-autohs install` to create directories
- **Docker permission denied** - Log out and back in after adding to docker group
- **Database schema errors** - Run `alembic upgrade head` in backend folder
- **systemd services not starting** - Reinstall services with `./systemd/install_systemd.sh`

**For detailed solutions:** See `docs/TROUBLESHOOTING.md`

---

### Option 2: Linux Docker Installation

**Best for:** Isolated containerized environment on Linux/WSL2

**Prerequisites:**
- Docker Engine 20.10+ or Docker Desktop (see Docker Installation above)
- Docker Compose 2.0+
- 16GB+ RAM, 50GB disk space
- Ubuntu 20.04+ or WSL2

#### Installation Steps

```bash
# 1. Clone repository
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local/deploy

# 2. Install and start
./neuroinsight-autohs-docker install

# Access at http://localhost:8000
```

The install command will:
- Auto-detect FreeSurfer license in parent directory
- Pull Docker image from Docker Hub
- Create Docker volume for data persistence
- Start all services in one container

#### Docker Management Commands

```bash
cd neuroinsight_local/deploy

# Service management
./neuroinsight-autohs-docker start            # Start services
./neuroinsight-autohs-docker stop             # Stop services
./neuroinsight-autohs-docker restart          # Restart services
./neuroinsight-autohs-docker status           # Check status

# Maintenance
./neuroinsight-autohs-docker logs             # View logs
./neuroinsight-autohs-docker backup           # Backup data
./neuroinsight-autohs-docker restore backup.tar.gz  # Restore from backup
./neuroinsight-autohs-docker update           # Update to latest version

# Advanced
./neuroinsight-autohs-docker shell            # Access container shell
./neuroinsight-autohs-docker clean            # Remove container and data
```

#### What's Included

The Docker container includes all components:
- PostgreSQL 15 (database)
- Redis 7 (task queue)
- MinIO (S3-compatible storage)
- FastAPI backend (port 8000)
- Celery worker (MRI processing)
- React frontend

#### Data Persistence

All data is stored in Docker volume `neuroinsight-autohs-data`:
- MRI uploads
- Processing results
- Database
- Logs

Use `./neuroinsight-autohs-docker backup` for regular backups.

---

### Option 3: Windows Docker Installation

**Best for:** Windows 10/11 users

**Prerequisites:**
- Windows 10/11 (64-bit, version 2004+)
- Docker Desktop for Windows (see Docker Installation above)
- 16GB+ RAM, 50GB disk space
- WSL2 (auto-installed by Docker Desktop)

#### Installation Steps

**1. Install Docker Desktop**
- Download: https://www.docker.com/products/docker-desktop/
- Install and restart if prompted
- Docker Desktop automatically configures WSL2

**2. Install NeuroInsight-AutoHS**

```powershell
# Clone repository
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local\neuroinsight_windows

# Install and start
.\neuroinsight-autohs-docker.ps1 install

# Access at http://localhost:8000
```

The install command will:
- Auto-detect FreeSurfer license
- Pull Docker image
- Create volume for data
- Start container

**3. Verify Installation**

Open browser and navigate to: http://localhost:8000

#### Windows Management Commands

**PowerShell:**
```powershell
cd neuroinsight_windows

# Service management
.\neuroinsight-autohs-docker.ps1 start        # Start services
.\neuroinsight-autohs-docker.ps1 stop         # Stop services  
.\neuroinsight-autohs-docker.ps1 restart      # Restart services
.\neuroinsight-autohs-docker.ps1 status       # Check status

# Maintenance
.\neuroinsight-autohs-docker.ps1 logs         # View logs
.\neuroinsight-autohs-docker.ps1 backup       # Backup data
.\neuroinsight-autohs-docker.ps1 restore backup.tar.gz  # Restore
.\neuroinsight-autohs-docker.ps1 update       # Update to latest

# Advanced
.\neuroinsight-autohs-docker.ps1 shell        # Access container
.\neuroinsight-autohs-docker.ps1 clean        # Remove all data
```

**Batch Scripts (Alternative):**
```cmd
cd neuroinsight_windows\scripts

start.bat          # Start services
stop.bat           # Stop services
status.bat         # Check status
logs.bat           # View logs
```

#### Docker Desktop Configuration

Recommended settings (Docker Desktop → Settings):

**Resources:**
- Memory: 16GB (minimum 8GB)
- CPUs: 4-8 cores
- Disk: 50GB+

**General:**
- Use WSL2 based engine
- Start Docker Desktop when you log in

#### Windows-Specific Notes
- Uses same Linux Docker image via WSL2
- No separate Windows image needed
- Automatic port detection (8000-8050)
- FreeSurfer license auto-detection
- PowerShell scripts provide colored output

---

### Deployment Comparison

| Feature | Native Linux | Linux Docker | Windows Docker | Desktop App |
|---------|--------------|--------------|----------------|-------------|
| **Installation** | Direct on system | Containerized | Containerized via WSL2 | One-click installer |
| **Updates** | Manual | One command | One command | Auto-update |
| **Backup/Restore** | Manual | Built-in | Built-in | Built-in |
| **Isolation** | System-wide | Containerized | Containerized | Containerized |
| **Performance** | Direct | Minimal overhead | WSL2 overhead | Minimal overhead |
| **Portability** | System-specific | Portable | Portable | Portable |
| **Dependencies** | Manual install | Pre-packaged | Pre-packaged | Pre-packaged |

---

## Quick Docker Deployment (Direct Pull)

For advanced users who want to pull and run the Docker image directly without installation scripts:

### Linux

```bash
# Pull image
docker pull phindagijimana321/neuroinsight-autohs:latest

# Run container
docker run -d \
  --name neuroinsight-autohs \
  -p 8000:8000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v neuroinsight-autohs-data:/data \
  -v $(pwd)/license.txt:/app/license.txt:ro \
  phindagijimana321/neuroinsight-autohs:latest

# Access at http://localhost:8000
```

### Windows (PowerShell)

```powershell
# Pull image
docker pull phindagijimana321/neuroinsight-autohs:latest

# Run container
docker run -d `
  --name neuroinsight-autohs `
  -p 8000:8000 `
  -v /var/run/docker.sock:/var/run/docker.sock `
  -v neuroinsight-autohs-data:/data `
  -v ${PWD}/license.txt:/app/license.txt:ro `
  phindagijimana321/neuroinsight-autohs:latest

# Access at http://localhost:8000
```

**Note:** For full features and easier management, use the installation methods above (Option 0, 2, or 3).

---

## Configuration

### Environment Variables

NeuroInsight-AutoHS can be configured using the `.env` file in the project root (Native Linux deployment) or through environment variables passed to Docker containers.

**Key Configuration Options:**

**Processing:**
- `CELERY_WORKER_CONCURRENCY` - Number of concurrent MRI processing jobs (default: 1)
- `FREESURFER_LICENSE_PATH` - Path to FreeSurfer license file

**Storage:**
- `HOST_UPLOAD_DIR` - Directory for uploaded MRI files
- `HOST_OUTPUT_DIR` - Directory for processing outputs
- `MINIO_ENDPOINT` - S3-compatible storage endpoint (optional)

**Resources:**
- `MAX_WORKERS` - Maximum parallel Celery workers
- `MEMORY_LIMIT` - Container memory limit (Docker deployments)

**Network:**
- `BACKEND_PORT` - API server port (default: 8000)
- `CORS_ORIGINS` - Allowed CORS origins for API access

For detailed configuration, see your deployment's specific documentation:
- **Option 0 (Desktop App)**: Uses default configuration, customizable through UI
- **Option 1 (Native Linux)**: Edit `.env` in project root
- **Option 2/3 (Docker)**: Configuration embedded in container, customize via docker-compose.yml or Docker run parameters

---

## Understanding NeuroInsight-AutoHS

### Concurrency Limits

NeuroInsight-AutoHS processes one MRI scan at a time to ensure system stability and prevent resource exhaustion. This means:

- **Sequential Processing**: Jobs are queued and processed one after another
- **Queue Management**: New uploads are automatically added to the processing queue
- **Resource Allocation**: Each job gets dedicated CPU, memory, and storage resources
- **Status Monitoring**: Real-time progress updates show current job status and queue position

**Why this limitation?**
- FreeSurfer processing is computationally intensive (3-7 hours per scan depending on image characteristics)
- Prevents system overload and ensures accurate results
- Maintains data integrity during parallel filesystem operations

### User Workflow

#### Typical User Journey:

1. **Preparation**:
   - Ensure T1-weighted MRI files are in NIfTI format (.nii or .nii.gz)
   - Verify filenames contain T1 indicators (t1, mprage, etc.)
   - Confirm file sizes are under 500MB limit

2. **Upload**:
   - Access NeuroInsight-AutoHS at http://localhost:8000
   - Enter patient name in the upload form
   - Select and upload your T1 NIfTI file
   - Job automatically enters processing queue

3. **Monitoring**:
   - View job status in the main dashboard
   - Track progress through FreeSurfer pipeline stages
   - Monitor for any error messages or failed jobs

4. **Results**:
   - Successful jobs show anatomical and segmentation overlays
   - View hippocampus regions with interactive controls
   - Adjust zoom (50-500%), opacity (0-100%), and rotation (0-360 degrees)
   - Switch between axial, coronal, and sagittal views

5. **Export & Analysis**:
   - Results are automatically saved for future access
   - Compare multiple scans in the job history
   - Re-upload or reprocess if needed

## Usage

### File Requirements

#### Supported File Formats
NeuroInsight-AutoHS accepts NIfTI files for T1-weighted MRI scans:

1. **NIfTI Uncompressed** (`.nii`) - Direct processing
2. **NIfTI Compressed** (`.nii.gz`) - Direct processing

**Note:** DICOM files must be converted to NIfTI format before upload. We recommend using **MRIcron** (free, cross-platform tool available at https://www.nitrc.org/projects/mricron).

#### T1 Filename Requirements
**All uploaded files must have T1-related keywords in their filenames.** This ensures only appropriate T1-weighted images are processed for accurate hippocampus analysis.

**Required T1 Indicators (one of these must be in the filename):**
- Basic: `t1`, `t1w`, `t1-weighted`
- Sequences: `mprage`, `spgr`, `tfl`, `tfe`, `fspgr`, `mpr`
- Compound: `t1_mprage`, `t1_spgr`, `t1_tfe`, `fspgr_t1`, `t1w_mprage`

#### File Size Limits
- Maximum file size: **500MB**
- Recommended: Scans under 100MB for optimal processing

#### Valid Examples
```
- sub-01_T1w.nii.gz
- patient_mprage.nii
- brain_t1_mprage.nii
- t1w_mprage.nii.gz
```

#### Invalid Examples
```
- brain_scan.nii      (missing T1 indicator)
- t2_image.nii        (T2, not T1)
- flair.nii          (FLAIR sequence)
- scan.dcm           (DICOM not supported - convert to NIfTI first)
- scan.zip           (ZIP archives not supported)
```

#### File Selection Tips

**Mac Users:**

If your NIfTI files are not selectable in the file picker dialog:

1. **Click "Options"** in the file selection dialog (bottom-left)
2. **Change from "Custom Files" to "All Files"** in the dropdown
3. **Select your T1-weighted NIfTI image** (.nii or .nii.gz)

This issue occurs because macOS may not recognize the NIfTI file extension by default. Using "All Files" allows you to select any file regardless of extension.

**Windows Users:**

If your NIfTI files are not visible in the file picker dialog:

1. **Click the file type dropdown** at the bottom of the dialog (shows "Custom Files" or similar)
2. **Select "All Files (*.*)"** from the dropdown menu
3. **Select your T1-weighted NIfTI image** (.nii or .nii.gz)

Windows may filter out unrecognized file extensions by default. Switching to "All Files" displays all files in the directory.

### Detailed File Format Guide

#### NIfTI Files (.nii, .nii.gz)
- **Recommended format** for NeuroInsight-AutoHS
- Direct processing without conversion
- Must contain T1-weighted MRI data
- Filename must include T1 indicators


#### Processing Pipeline
1. **NIfTI files**: Direct FreeSurfer processing
2. **Output**: Hippocampal volumes, asymmetry analysis, visualizations

### Web Interface
1. **Upload**: Select T1-weighted MRI files
2. **Monitor**: Track processing progress in real-time
3. **View Results**: Examine hippocampal volumes and asymmetry
4. **Generate Reports**: Download PDF reports with visualizations

## Management Commands

### Start Services
```bash
./neuroinsight-autohs start
```
**What it does:** Launches all NeuroInsight-AutoHS services including the web interface, Celery workers, Redis cache, and database. The system will be accessible at http://localhost:8000 once fully started.

### Stop Services
```bash
./neuroinsight-autohs stop
```
**What it does:** Gracefully shuts down all NeuroInsight-AutoHS services and **disables no‑sleep mode** if it is active. This ensures proper cleanup of running processes and returns the system to normal sleep behavior. Wait for confirmation that all services have stopped.

**Container handling:** Stopping the app stops any running FreeSurfer containers, but does not immediately remove stopped containers. Maintenance cleans stopped FreeSurfer containers older than 5 days.

**Note:** The stop script removes the PostgreSQL/Redis/MinIO containers. If you want job data to persist across restarts, configure persistent volumes or external services.

### Check Status
```bash
./neuroinsight-autohs status
```
**What it does:** Displays the current state of all services including:
- Web server (FastAPI) status
- Celery worker processes
- Redis cache connectivity
- Database availability
- Docker containers status
- Current job queue information

### Verify License
```bash
./neuroinsight-autohs license
```
**What it does:** Validates your FreeSurfer license file. Checks that `license.txt` exists in the project directory and contains valid FreeSurfer credentials. Required before processing any MRI scans.

### Delete Specific Job
```bash
./neuroinsight-autohs delete <job_id>
```
**What it does:** Permanently deletes a specific job by ID, including:
- Database record
- Uploaded MRI file
- Output directory and all results
- Associated metrics

**Examples:**
```bash
# Interactive deletion (asks for confirmation)
./neuroinsight-autohs delete d1a2c36e

# Force deletion (no confirmation)
./neuroinsight-autohs delete d1a2c36e --force
```

**Finding Job IDs:**
- View job IDs in web interface (in URL or job details)
- Or list jobs: `./neuroinsight-autohs status` shows active jobs

**Docker deployments:**
```bash
# Linux/WSL Docker
./neuroinsight-autohs-docker delete d1a2c36e

# Windows Docker
.\neuroinsight-autohs-docker.ps1 delete d1a2c36e
```

**Note:** This only deletes COMPLETED or FAILED jobs. Running/pending jobs should be cancelled through the web interface first.

### Advanced Monitoring
```bash
./neuroinsight-autohs monitor
```
**What it does:** Provides detailed system monitoring including:
- Real-time resource usage (CPU, memory, disk)
- Active job progress and queue status
- Docker container health
- System logs and error tracking
- Performance metrics and alerts

### Failure Handling and Queue Behavior
When a job fails:
- The job is marked **failed** with an error message.
- The FreeSurfer container is **stopped** (not removed).
- The queue immediately starts the next pending job if capacity allows.

Stopped FreeSurfer containers are cleaned up automatically by maintenance after **5 days**. Job result cleanup is still controlled by the user via `./neuroinsight-autohs clean`.

### Prevent System Sleep
```bash
./neuroinsight-autohs nosleep
```
**What it does:** Uses `systemd-inhibit` to prevent the machine from sleeping while jobs run. Run this after `./neuroinsight-autohs start`. It will be stopped automatically when you run `./neuroinsight-autohs stop`.

### Clean Old Jobs
```bash
./neuroinsight-autohs clean
```
Use the default 90-day retention when you want routine cleanup without fine-tuning.

```bash
./neuroinsight-autohs clean --days 30
```
Use a short retention window when storage is tight or you only need recent results.

```bash
./neuroinsight-autohs clean --months 6
```
Use month-based retention for scheduled or quarterly cleanup policies.

```bash
./neuroinsight-autohs clean --days 30 --keep d56a321c
```
Use this when you want aggressive cleanup but must preserve a specific job.

**What it does:** Removes completed/failed jobs older than the retention window and deletes their files. Also cleans orphaned job directories (files on disk without database records). Use `--keep` to preserve specific jobs.

**Additional Examples:**

```bash
# Keep specific jobs (comma-separated):
./neuroinsight-autohs clean --days 30 --keep job1,job2,job3

# Or use multiple --keep flags:
./neuroinsight-autohs clean --days 30 --keep job1 --keep job2 --keep job3

# Clean by months:
./neuroinsight-autohs clean --months 3 --keep important_job

# Default (90 days):
./neuroinsight-autohs clean

# Clean both database AND orphaned files (default):
./neuroinsight-autohs clean --days 30 --keep 912e32e7,e3463efb

# Clean ONLY orphaned files (skip database):
./neuroinsight-autohs clean --days 30 --orphaned-only --keep 912e32e7,e3463efb

# Clean ONLY database jobs (skip orphaned):
./neuroinsight-autohs clean --days 30 --skip-orphaned --keep 912e32e7,e3463efb
```

**Options:**
- `--days N`: Retention period in days (default: 90)
- `--months N`: Retention period in months (alternative to --days)
- `--keep ID`: Job IDs to preserve (comma-separated or repeatable)
- `--orphaned-only`: Only clean orphaned files on disk, skip database jobs
- `--skip-orphaned`: Only clean database jobs, skip orphaned files on disk

### Recover a Completed Job
```bash
./neuroinsight-autohs bring <job_id>
```
**What it does:** Reconstructs a completed job from on-disk output files. If no outputs exist for the ID, the script reports that it cannot recover the job.

### View System Logs
```bash
./neuroinsight-autohs logs
```
**What it does:** Provides a unified interface to view logs from different NeuroInsight-AutoHS components. You can view logs interactively through a menu or directly specify which component logs to view.

**Interactive Menu (no arguments):**
```bash
./neuroinsight-autohs logs
```
Displays an interactive menu where you can select:
1. **backend** - Backend API server logs (FastAPI requests, responses, errors)
2. **celery** - Celery worker logs (job processing, task execution)
3. **beat** - Celery beat scheduler logs (periodic tasks, scheduling)
4. **monitor** - Job monitoring service logs (progress tracking, status updates)
5. **freesurfer** - FreeSurfer processing logs (requires job ID, recon-all logs)
6. **database** - PostgreSQL database logs (queries, connections, errors)
7. **redis** - Redis message broker logs (queue operations, cache)
8. **All logs** - Show all available logs sequentially

**Direct Log Access (specify component):**
```bash
# View backend API logs
./neuroinsight-autohs logs backend

# View Celery worker logs
./neuroinsight-autohs logs celery

# View database logs
./neuroinsight-autohs logs database

# View Redis logs
./neuroinsight-autohs logs redis

# View FreeSurfer logs for specific job (requires job ID)
./neuroinsight-autohs logs freesurfer --job-id abc123
```

**Options:**

**Follow mode** (`-f` or `--follow`): Stream logs in real-time (like `tail -f`)
```bash
# Follow backend logs in real-time
./neuroinsight-autohs logs backend --follow

# Follow Celery worker logs
./neuroinsight-autohs logs celery -f
```

**Line limit** (`-n` or `--lines N`): Show last N lines (default: 100)
```bash
# Show last 50 lines of backend logs
./neuroinsight-autohs logs backend -n 50

# Show last 200 lines of Celery logs
./neuroinsight-autohs logs celery --lines 200
```

**Job-specific FreeSurfer logs** (`--job-id ID`): View FreeSurfer processing logs for a specific job
```bash
# View FreeSurfer logs for job abc123
./neuroinsight-autohs logs freesurfer --job-id abc123

# Follow FreeSurfer logs in real-time
./neuroinsight-autohs logs freesurfer --job-id abc123 --follow

# Show last 500 lines of FreeSurfer logs
./neuroinsight-autohs logs freesurfer --job-id abc123 -n 500
```

**Combine options:**
```bash
# Follow last 50 lines of backend logs
./neuroinsight-autohs logs backend -f -n 50

# Show last 20 lines of Celery logs
./neuroinsight-autohs logs celery --lines 20
```

**Common Use Cases:**

1. **Troubleshooting failed jobs:**
   ```bash
   # Check Celery worker logs for errors
   ./neuroinsight-autohs logs celery -n 100
   
   # View FreeSurfer logs for failed job
   ./neuroinsight-autohs logs freesurfer --job-id <failed_job_id>
   ```

2. **Monitoring active processing:**
   ```bash
   # Follow backend logs in real-time
   ./neuroinsight-autohs logs backend --follow
   
   # Follow FreeSurfer progress for running job
   ./neuroinsight-autohs logs freesurfer --job-id <running_job_id> --follow
   ```

3. **Checking system health:**
   ```bash
   # Check database logs
   ./neuroinsight-autohs logs database -n 50
   
   # Check Redis broker logs
   ./neuroinsight-autohs logs redis -n 50
   ```

4. **Debugging API issues:**
   ```bash
   # View recent backend API requests
   ./neuroinsight-autohs logs backend -n 100
   
   # Follow backend logs while testing
   ./neuroinsight-autohs logs backend --follow
   ```

**Help:**
```bash
./neuroinsight-autohs logs --help
```

**Notes:**
- Log files are stored in the NeuroInsight-AutoHS project directory
- Database and Redis logs are retrieved from Docker containers
- FreeSurfer logs are job-specific and stored in each job's output directory
- Press `Ctrl+C` to exit follow mode or interrupt log viewing
- All output is plain text without emojis for better compatibility with log parsers

### Additional Commands

#### Reinstall (for troubleshooting)
```bash
./neuroinsight-autohs reinstall
```
**Use when:** Persistent issues with services or corrupted installations. This command provides step-by-step guidance to completely remove and reinstall NeuroInsight-AutoHS, including backup of user data when possible.

**Note:** All management commands should be run from the NeuroInsight-AutoHS project root directory where the `neuroinsight-autohs` script is located.


## Troubleshooting

Use the canonical **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** for desktop, Docker, Celery, FreeSurfer, and job issues.

Quick checks:

```bash
./neuroinsight-autohs status
./neuroinsight-autohs health
```

## FAQ

| Question | Answer |
|----------|--------|
| What is NeuroInsight-AutoHS? | Local web/desktop app that runs the [AutoHS](https://github.com/phindagijimana/AutoHS) workflow (hippocampal asymmetry from T1w MRI). |
| System requirements? | See [Prerequisites](#prerequisites). |
| How long per scan? | Typically 3–7 hours; prevent system sleep during processing. |
| License? | Research use under [LICENSE](../LICENSE); commercial use — [COMMERCIAL.md](../COMMERCIAL.md). FreeSurfer requires its own license. |
| FDA cleared? | No — research software only. |

## Support

- **GitHub Issues:** [neuroinsight_local/issues](https://github.com/phindagijimana/neuroinsight_local/issues)
- **AutoHS pipeline:** [AutoHS issues](https://github.com/phindagijimana/AutoHS/issues) · [RTD FAQ](https://autohs.readthedocs.io/en/latest/faq.html)
- **FreeSurfer:** https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSupport

---

© 2025 University of Rochester. All rights reserved.
