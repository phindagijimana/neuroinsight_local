# NeuroInsight User Guide

Complete guide for deploying and using NeuroInsight for hippocampal MRI analysis.

## Prerequisites

- Ubuntu 20.04+ Linux system
- 16GB+ RAM (32GB recommended)
- 4+ CPU cores, 50GB storage
- Docker and Docker Compose
- FreeSurfer license (free for research)
- **System sleep timeout set to 7+ hours** (critical for long-running processing)

### System Verification Commands

Check if your system meets the requirements:

```bash
# Check CPU cores
nproc

# Check available RAM (in GB)
free -h

# Check available storage (in GB)
df -h /

# Check Ubuntu version
lsb_release -a
```

## WSL Setup (Windows Users)

If you're using Windows, you can run NeuroInsight using Windows Subsystem for Linux (WSL). Here's how to set it up:

### Enable WSL Feature

1. **Open PowerShell as Administrator**:
   - Press `Win + X` and select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Enable WSL feature**:
   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   ```

3. **Enable Virtual Machine Platform** (required for WSL 2):
   ```powershell
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

4. **Restart your computer** when prompted.

### Install WSL and Ubuntu

1. **Open PowerShell/Terminal as Administrator** again after restart.

2. **Set WSL 2 as default version**:
   ```powershell
   wsl --set-default-version 2
   ```

3. **Install Ubuntu distribution**:
   ```powershell
   wsl --install -d Ubuntu
   ```

4. **Set up Ubuntu**:
   - The Ubuntu installation will start automatically
   - Create a username and password when prompted
   - Wait for installation to complete

### Verify WSL Installation

1. **Open Ubuntu from Start Menu** or run `wsl` in PowerShell/Terminal.

2. **Update Ubuntu packages**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

3. **Verify WSL version**:
   ```bash
   wsl --version
   ```

### Important WSL Notes

- **File Access**: Windows files are accessible at `/mnt/c/` from WSL
- **Performance**: Keep project files inside WSL for better Docker performance
- **Memory**: WSL may need memory allocation adjustments in `.wslconfig`
- **Integration**: Docker Desktop integrates with WSL for container operations

Once WSL is set up, continue with the Docker installation instructions below.

## Installation

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

### 6. Install and Start NeuroInsight

```bash
# Install NeuroInsight (one-time setup)
./neuroinsight install

# Verify FreeSurfer license
./neuroinsight license

# IMPORTANT: Configure system sleep settings to prevent processing interruptions
# System Settings → Power → Set sleep timeout to 7+ hours when inactive

# Start NeuroInsight
./neuroinsight start
```

**Access NeuroInsight at:** http://localhost:8000

## Understanding NeuroInsight

### Concurrency Limits

NeuroInsight processes one MRI scan at a time to ensure system stability and prevent resource exhaustion. This means:

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
   - Access NeuroInsight at http://localhost:8000
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
NeuroInsight accepts NIfTI files for T1-weighted MRI scans:

1. **NIfTI Uncompressed** (`.nii`) - Direct processing
2. **NIfTI Compressed** (`.nii.gz`) - Direct processing

**Note:** DICOM files must be converted to NIfTI format before upload using tools like `dcm2niix`.

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
- **Recommended format** for NeuroInsight
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
./neuroinsight start
```
**What it does:** Launches all NeuroInsight services including the web interface, Celery workers, Redis cache, and database. The system will be accessible at http://localhost:8000 once fully started.

### Stop Services
```bash
./neuroinsight stop
```
**What it does:** Gracefully shuts down all NeuroInsight services and **disables no‑sleep mode** if it is active. This ensures proper cleanup of running processes and returns the system to normal sleep behavior. Wait for confirmation that all services have stopped.

**Container handling:** Stopping the app stops any running FreeSurfer containers, but does not immediately remove stopped containers. Maintenance cleans stopped FreeSurfer containers older than 5 days.

**Note:** The stop script removes the PostgreSQL/Redis/MinIO containers. If you want job data to persist across restarts, configure persistent volumes or external services.

### Check Status
```bash
./neuroinsight status
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
./neuroinsight license
```
**What it does:** Validates your FreeSurfer license file. Checks that `license.txt` exists in the project directory and contains valid FreeSurfer credentials. Required before processing any MRI scans.

### Advanced Monitoring
```bash
./neuroinsight monitor
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

Stopped FreeSurfer containers are cleaned up automatically by maintenance after **5 days**. Job result cleanup is still controlled by the user via `./neuroinsight clean`.

### Prevent System Sleep
```bash
./neuroinsight nosleep
```
**What it does:** Uses `systemd-inhibit` to prevent the machine from sleeping while jobs run. Run this after `./neuroinsight start`. It will be stopped automatically when you run `./neuroinsight stop`.

### Clean Old Jobs
```bash
./neuroinsight clean
```
Use the default 90-day retention when you want routine cleanup without fine-tuning.

```bash
./neuroinsight clean --days 30
```
Use a short retention window when storage is tight or you only need recent results.

```bash
./neuroinsight clean --months 6
```
Use month-based retention for scheduled or quarterly cleanup policies.

```bash
./neuroinsight clean --days 30 --keep d56a321c
```
Use this when you want aggressive cleanup but must preserve a specific job.

**What it does:** Removes completed/failed jobs older than the retention window and deletes their files. Also cleans orphaned job directories (files on disk without database records). Use `--keep` to preserve specific jobs.

**Additional Examples:**

```bash
# Keep specific jobs (comma-separated):
./neuroinsight clean --days 30 --keep job1,job2,job3

# Or use multiple --keep flags:
./neuroinsight clean --days 30 --keep job1 --keep job2 --keep job3

# Clean by months:
./neuroinsight clean --months 3 --keep important_job

# Default (90 days):
./neuroinsight clean

# Clean both database AND orphaned files (default):
./neuroinsight clean --days 30 --keep 912e32e7,e3463efb

# Clean ONLY orphaned files (skip database):
./neuroinsight clean --days 30 --orphaned-only --keep 912e32e7,e3463efb

# Clean ONLY database jobs (skip orphaned):
./neuroinsight clean --days 30 --skip-orphaned --keep 912e32e7,e3463efb
```

**Options:**
- `--days N`: Retention period in days (default: 90)
- `--months N`: Retention period in months (alternative to --days)
- `--keep ID`: Job IDs to preserve (comma-separated or repeatable)
- `--orphaned-only`: Only clean orphaned files on disk, skip database jobs
- `--skip-orphaned`: Only clean database jobs, skip orphaned files on disk

### Recover a Completed Job
```bash
./neuroinsight bring <job_id>
```
**What it does:** Reconstructs a completed job from on-disk output files. If no outputs exist for the ID, the script reports that it cannot recover the job.

### View System Logs
```bash
./neuroinsight logs
```
**What it does:** Provides a unified interface to view logs from different NeuroInsight components. You can view logs interactively through a menu or directly specify which component logs to view.

**Interactive Menu (no arguments):**
```bash
./neuroinsight logs
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
./neuroinsight logs backend

# View Celery worker logs
./neuroinsight logs celery

# View database logs
./neuroinsight logs database

# View Redis logs
./neuroinsight logs redis

# View FreeSurfer logs for specific job (requires job ID)
./neuroinsight logs freesurfer --job-id abc123
```

**Options:**

**Follow mode** (`-f` or `--follow`): Stream logs in real-time (like `tail -f`)
```bash
# Follow backend logs in real-time
./neuroinsight logs backend --follow

# Follow Celery worker logs
./neuroinsight logs celery -f
```

**Line limit** (`-n` or `--lines N`): Show last N lines (default: 100)
```bash
# Show last 50 lines of backend logs
./neuroinsight logs backend -n 50

# Show last 200 lines of Celery logs
./neuroinsight logs celery --lines 200
```

**Job-specific FreeSurfer logs** (`--job-id ID`): View FreeSurfer processing logs for a specific job
```bash
# View FreeSurfer logs for job abc123
./neuroinsight logs freesurfer --job-id abc123

# Follow FreeSurfer logs in real-time
./neuroinsight logs freesurfer --job-id abc123 --follow

# Show last 500 lines of FreeSurfer logs
./neuroinsight logs freesurfer --job-id abc123 -n 500
```

**Combine options:**
```bash
# Follow last 50 lines of backend logs
./neuroinsight logs backend -f -n 50

# Show last 20 lines of Celery logs
./neuroinsight logs celery --lines 20
```

**Common Use Cases:**

1. **Troubleshooting failed jobs:**
   ```bash
   # Check Celery worker logs for errors
   ./neuroinsight logs celery -n 100
   
   # View FreeSurfer logs for failed job
   ./neuroinsight logs freesurfer --job-id <failed_job_id>
   ```

2. **Monitoring active processing:**
   ```bash
   # Follow backend logs in real-time
   ./neuroinsight logs backend --follow
   
   # Follow FreeSurfer progress for running job
   ./neuroinsight logs freesurfer --job-id <running_job_id> --follow
   ```

3. **Checking system health:**
   ```bash
   # Check database logs
   ./neuroinsight logs database -n 50
   
   # Check Redis broker logs
   ./neuroinsight logs redis -n 50
   ```

4. **Debugging API issues:**
   ```bash
   # View recent backend API requests
   ./neuroinsight logs backend -n 100
   
   # Follow backend logs while testing
   ./neuroinsight logs backend --follow
   ```

**Help:**
```bash
./neuroinsight logs --help
```

**Notes:**
- Log files are stored in the NeuroInsight project directory
- Database and Redis logs are retrieved from Docker containers
- FreeSurfer logs are job-specific and stored in each job's output directory
- Press `Ctrl+C` to exit follow mode or interrupt log viewing
- All output is plain text without emojis for better compatibility with log parsers

### Additional Commands

#### Reinstall (for troubleshooting)
```bash
./neuroinsight reinstall
```
**Use when:** Persistent issues with services or corrupted installations. This command provides step-by-step guidance to completely remove and reinstall NeuroInsight, including backup of user data when possible.

**Note:** All management commands should be run from the NeuroInsight project root directory where the `neuroinsight` script is located.

## Troubleshooting

### Common Issues

**Jobs stuck in pending:**
- Check `./neuroinsight status` to verify all services are running (including Celery workers)
- Ensure Redis is running: `redis-cli ping`
- Check Celery worker logs: `ps aux | grep celery`
- If workers not running, restart services: `./neuroinsight stop && ./neuroinsight start`
- For detailed troubleshooting, see [TROUBLESHOUTING.md](TROUBLESHOUTING.md#jobs-stuck-in-pending-status)

**Processing fails:**
- **T1 Validation**: Ensure filename contains T1 indicators (t1, mprage, spgr, etc.)
- **File Format**: Only .nii and .nii.gz files accepted
- **File Size**: Must be under 500MB limit
- Check RAM (16GB+ required)
- Ensure license.txt is present
- **Failed jobs display detailed error messages** explaining exactly what went wrong (FreeSurfer issues, validation failures, etc.)

**Web interface won't load:**
- Confirm services are running (`./neuroinsight status`)
- Check port 8000 availability
- Clear browser cache

**Jobs interrupted or fail unexpectedly:**
- **System Sleep/Hibernation**: FreeSurfer processing takes 3-7 hours depending on image characteristics. **Set sleep timeout to 7+ hours** during processing to prevent interruptions.
- **Power Settings**: Set power management to 7+ hours sleep when plugged in
- **Screen Lock**: Disable automatic screen lock during long processing jobs
- **Virtual Machines**: Ensure host system won't sleep while VM is running
- **Docker Containers**: Containerized processing may be interrupted by system sleep

### Important System Configuration

#### Sleep/Hibernation Prevention
**Critical for successful processing:** FreeSurfer jobs run for extended periods (3-7 hours) depending on image resolution and quality. System sleep or hibernation will interrupt processing and cause job failures.

**Recommended Settings:**
- **Ubuntu**: System Settings → Power → Set to 7+ hours sleep when inactive
- **VMWare/VirtualBox**: Host power settings to 7+ hours sleep
- **Laptop Users**: Keep system plugged in and prevent lid close actions
- **Server Environments**: Configure power management policies for 7+ hour timeouts

**Warning:** Jobs interrupted by sleep/hibernation cannot be resumed and must be restarted from the beginning.

#### Memory Stability Tuning (Recommended)
These host-level tweaks reduce memory spikes and improve stability during CA Reg and other heavy FreeSurfer steps.

**1) Allow overcommit (helps large allocations succeed):**
```bash
sudo sysctl -w vm.overcommit_memory=1
```

Persist across reboot:
```bash
echo 'vm.overcommit_memory=1' | sudo tee /etc/sysctl.d/99-neuroinsight.conf
sudo sysctl --system
```

**2) Lower swappiness (use swap only when needed):**
```bash
sudo sysctl -w vm.swappiness=10
```

Persist across reboot:
```bash
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.d/99-neuroinsight.conf
sudo sysctl --system
```

**3) Disable Transparent Huge Pages (reduces fragmentation stalls):**
Immediate (runtime):
```bash
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
```

Persist via systemd:
```bash
sudo tee /etc/systemd/system/disable-thp.service >/dev/null <<'EOF'
[Unit]
Description=Disable Transparent Huge Pages (THP)

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled; echo never > /sys/kernel/mm/transparent_hugepage/defrag'

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now disable-thp
```

**Notes:**
- `vm.swappiness` is a 0-100 tuning value (not GB or %); 10-20 is a balanced range.
- Use `sudo sysctl vm.overcommit_memory vm.swappiness` to verify active values.

## FAQ

### What is NeuroInsight?
Automated platform for hippocampal segmentation and analysis from T1-weighted MRI scans using FreeSurfer.

### System requirements?
Ubuntu 20.04+, 16GB+ RAM, 4+ CPU cores, 50GB storage, Docker, FreeSurfer license.

### How long does processing take?
3-7 hours per scan, depending on hardware, scan quality, and image resolution. **Important:** Set system sleep timeout to 7+ hours to prevent interruptions during processing.

### Is it free?
Yes, MIT licensed. FreeSurfer license is free for research use.

### Can I process multiple scans?
Yes, supports queuing system with configurable concurrency limits.

### What's processed?
Hippocampal volume measurements, shape analysis, asymmetry calculations, quality metrics.

### File formats supported?
NIfTI (.nii, .nii.gz) only. DICOM files must be converted to NIfTI format before upload using tools like `dcm2niix`.

### Can I export results?
Yes: PDF reports, CSV data, PNG/PDF images.

### Is it FDA approved?
No, research software only. Not for clinical diagnosis.


## Support

- **GitHub Issues**: Report bugs and request features
- **Documentation**: Check troubleshooting guide
- **FreeSurfer**: https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSupport


---

© 2025 University of Rochester. All rights reserved.
