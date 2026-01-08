# NeuroInsight User Guide

Complete guide for deploying and using NeuroInsight for hippocampal MRI analysis.

## Prerequisites

- Ubuntu 20.04+ Linux system
- 16GB+ RAM (32GB recommended)
- 4+ CPU cores, 50GB storage
- Docker and Docker Compose
- FreeSurfer license (free for research)

## Installation

## Installation

```bash
# Clone repository
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local

# Get FreeSurfer license first
# Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
# Save as license.txt in project directory

# Install and start
./install.sh
./check_license.sh  # Verify license
./start.sh

# Access at http://localhost:8000
```

## Usage

### File Requirements
- **T1-weighted MRI scans only**
- Filenames must contain: `t1`, `t1w`, `t1-weighted`, `mprage`, `spgr`, `tfl`, `tfe`, `fspgr`
- Supported formats: NIfTI (.nii, .nii.gz), DICOM (.dcm), ZIP archives

### Web Interface
1. **Upload**: Select T1-weighted MRI files
2. **Monitor**: Track processing progress in real-time
3. **View Results**: Examine hippocampal volumes and asymmetry
4. **Generate Reports**: Download PDF reports with visualizations

## Management Commands

```bash
./start.sh      # Start all services
./stop.sh       # Stop all services  
./status.sh     # Check service status
./check_license.sh  # Verify FreeSurfer license
```

## Troubleshooting

### Common Issues

**Jobs stuck in pending:**
- Check `./status.sh` for running services
- Ensure FreeSurfer license is valid
- Restart services: `./stop.sh && ./start.sh`

**Processing fails:**
- Verify T1 indicators in filename
- Check RAM (16GB+ required)
- Ensure license.txt is present

**Web interface won't load:**
- Confirm services are running (`./status.sh`)
- Check port 8000 availability
- Clear browser cache

### Mock Data Warning
Jobs show "(Mock Data)" when FreeSurfer license is missing. **Never use for clinical decisions.**

## FAQ

### What is NeuroInsight?
Automated platform for hippocampal segmentation and analysis from T1-weighted MRI scans using FreeSurfer.

### System requirements?
Ubuntu 20.04+, 16GB+ RAM, 4+ CPU cores, 50GB storage, Docker, FreeSurfer license.

### How long does processing take?
30-60 minutes per scan, depending on hardware and scan quality.

### Is it free?
Yes, MIT licensed. FreeSurfer license is free for research use.

### Can I process multiple scans?
Yes, supports queuing system with configurable concurrency limits.

### What's processed?
Hippocampal volume measurements, shape analysis, asymmetry calculations, quality metrics.

### File formats supported?
NIfTI (.nii, .nii.gz) recommended, DICOM (.dcm), ZIP archives.

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
