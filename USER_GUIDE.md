# NeuroInsight User Guide

Complete guide for deploying and using NeuroInsight for hippocampal MRI analysis.

## Prerequisites

- Ubuntu 20.04+ Linux system
- 16GB+ RAM (32GB recommended)
- 4+ CPU cores, 50GB storage
- Docker and Docker Compose
- FreeSurfer license (free for research)
- **System sleep timeout set to 2-4 hours** (critical for long-running processing)

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
# System Settings → Power → Set sleep timeout to 2-4 hours when inactive

# Start NeuroInsight
./neuroinsight start
```

**Access NeuroInsight at:** http://localhost:8000
```

## Understanding NeuroInsight

### Concurrency Limits

NeuroInsight processes one MRI scan at a time to ensure system stability and prevent resource exhaustion. This means:

- **Sequential Processing**: Jobs are queued and processed one after another
- **Queue Management**: New uploads are automatically added to the processing queue
- **Resource Allocation**: Each job gets dedicated CPU, memory, and storage resources
- **Status Monitoring**: Real-time progress updates show current job status and queue position

**Why this limitation?**
- FreeSurfer processing is computationally intensive (2-4 hours per scan)
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
   - Adjust zoom (50-500%), opacity (0-100%), and rotation (0-360°)
   - Switch between axial, coronal, and sagittal views

5. **Export & Analysis**:
   - Results are automatically saved for future access
   - Compare multiple scans in the job history
   - Re-upload or reprocess if needed

### Pipeline Logic Overview

NeuroInsight uses FreeSurfer's comprehensive neuroimaging pipeline to analyze T1-weighted MRI scans:

#### Stage 1: Input Validation
- **File Format Check**: Ensures NIfTI format (.nii/.nii.gz)
- **T1 Sequence Verification**: Validates filename contains T1 indicators
- **File Integrity**: Checks for corrupted or incomplete files

#### Stage 2: Preprocessing
- **Image Orientation**: Standardizes scan orientation using nibabel
- **Brain Extraction**: Isolates brain tissue from skull and background
- **Intensity Normalization**: Standardizes image contrast across scans

#### Stage 3: FreeSurfer Processing
- **Recon-All Pipeline**: Complete cortical reconstruction and volumetric segmentation
- **Tissue Classification**: Identifies gray matter, white matter, and CSF
- **Surface Generation**: Creates 3D cortical surface models
- **Subcortical Segmentation**: Labels thalamus, caudate, putamen, etc.

#### Stage 4: Hippocampus Analysis
- **Hippocampus Segmentation**: Automated labeling of left/right hippocampus
- **Volume Calculation**: Measures hippocampal volumes in mm³
- **Shape Analysis**: Extracts morphometric features
- **Asymmetry Assessment**: Compares left vs right hippocampus

#### Stage 5: Visualization
- **Slice Generation**: Creates anatomical slices in all three planes
- **Overlay Creation**: Combines anatomical with segmentation data
- **Interactive Viewer**: Web-based interface with zoom, rotation, opacity controls

#### Quality Assurance:
- **Error Detection**: Identifies processing failures at each stage
- **Fallback Prevention**: No mock data generation - failures are reported
- **Cleanup**: Automatic removal of intermediate files and orphaned containers

**Processing Time**: 2-4 hours per scan depending on hardware and scan complexity.

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
✅ sub-01_T1w.nii.gz
✅ patient_mprage.nii
✅ brain_t1_mprage.nii
✅ t1w_mprage.nii.gz
```

#### Invalid Examples
```
❌ brain_scan.nii      (missing T1 indicator)
❌ t2_image.nii        (T2, not T1)
❌ flair.nii          (FLAIR sequence)
❌ scan.dcm           (DICOM not supported - convert to NIfTI first)
❌ scan.zip           (ZIP archives not supported)
```

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

```bash
./neuroinsight start     # Start all services
./neuroinsight stop      # Stop all services
./neuroinsight status    # Check service status
./neuroinsight license   # Verify FreeSurfer license
./neuroinsight monitor   # Advanced monitoring
```

## Troubleshooting

### Common Issues

**Jobs stuck in pending:**
- Check `./neuroinsight status` for running services
- Ensure FreeSurfer license is valid
- Restart services: `./neuroinsight stop && ./neuroinsight start`

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
- **System Sleep/Hibernation**: FreeSurfer processing takes 30-60+ minutes and should complete within 2-4 hours. **Set sleep timeout to 2-4 hours** during processing to prevent interruptions.
- **Power Settings**: Set power management to 2-4 hours sleep when plugged in
- **Screen Lock**: Disable automatic screen lock during long processing jobs
- **Virtual Machines**: Ensure host system won't sleep while VM is running
- **Docker Containers**: Containerized processing may be interrupted by system sleep

### Important System Configuration

#### Sleep/Hibernation Prevention
**Critical for successful processing:** FreeSurfer jobs run for extended periods (30-120 minutes) and should complete within 2-4 hours. System sleep or hibernation will interrupt processing and cause job failures.

**Recommended Settings:**
- **Ubuntu**: System Settings → Power → Set to 2-4 hours sleep when inactive
- **VMWare/VirtualBox**: Host power settings to 2-4 hours sleep
- **Laptop Users**: Keep system plugged in and prevent lid close actions
- **Server Environments**: Configure power management policies for 2-4 hour timeouts

**Warning:** Jobs interrupted by sleep/hibernation cannot be resumed and must be restarted from the beginning.

## FAQ

### What is NeuroInsight?
Automated platform for hippocampal segmentation and analysis from T1-weighted MRI scans using FreeSurfer.

### System requirements?
Ubuntu 20.04+, 16GB+ RAM, 4+ CPU cores, 50GB storage, Docker, FreeSurfer license.

### How long does processing take?
30-60 minutes per scan, depending on hardware and scan quality. **Important:** Set system sleep timeout to 2-4 hours to prevent interruptions during processing.

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
