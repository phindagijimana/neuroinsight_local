# NeuroInsight User Guide

Complete guide for deploying and using NeuroInsight for hippocampal MRI analysis.

## Prerequisites

- Ubuntu 20.04+ Linux system
- 16GB+ RAM (32GB recommended)
- 4+ CPU cores, 50GB storage
- Docker and Docker Compose
- FreeSurfer license (free for research)
- **System sleep timeout set to 2-4 hours** (critical for long-running processing)

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

# Install and start
./neuroinsight install  # One-time installation
./neuroinsight license  # Verify license

# IMPORTANT: Configure system sleep settings to prevent processing interruptions
# System Settings → Power → Set sleep timeout to 2-4 hours when inactive

./neuroinsight start    # Start NeuroInsight

# Access at http://localhost:8000
```

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
