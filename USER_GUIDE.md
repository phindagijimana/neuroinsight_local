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
./neuroinsight install  # One-time installation
./neuroinsight license  # Verify license
./neuroinsight start    # Start NeuroInsight

# Access at http://localhost:8000
```

## Usage

### File Requirements

#### Supported File Formats
NeuroInsight accepts three file formats for T1-weighted MRI scans:

1. **NIfTI Uncompressed** (`.nii`) - Direct processing
2. **NIfTI Compressed** (`.nii.gz`) - Direct processing
3. **ZIP Archive** (`.zip`) - Must contain DICOM slices for T1 images

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
✅ scan_t1_spgr.zip
✅ mprage_series.zip
```

#### Invalid Examples
```
❌ brain_scan.nii      (missing T1 indicator)
❌ t2_image.nii        (T2, not T1)
❌ flair.nii          (FLAIR sequence)
❌ scan.dcm           (individual DICOM not supported)
❌ invalid_scan.zip   (missing T1 indicator)
```

### Detailed File Format Guide

#### NIfTI Files (.nii, .nii.gz)
- **Recommended format** for NeuroInsight
- Direct processing without conversion
- Must contain T1-weighted MRI data
- Filename must include T1 indicators

#### ZIP Archives (.zip)
- Must contain **DICOM slices** for T1 images
- DICOM files should be in `.dcm` or `.dicom` format
- Supports nested folder structures (e.g., `resources/DICOM/files/*.dcm`)
- ZIP filename must include T1 indicators
- Automatic DICOM-to-NIfTI conversion using `dcm2niix`

#### Processing Pipeline
1. **NIfTI files**: Direct FreeSurfer processing
2. **ZIP files**: Extract DICOM → Convert to NIfTI → FreeSurfer processing
3. **Output**: Hippocampal volumes, asymmetry analysis, visualizations

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
- **File Format**: Only .nii, .nii.gz, or .zip (with DICOM slices) accepted
- **File Size**: Must be under 500MB limit
- Check RAM (16GB+ required)
- Ensure license.txt is present

**Web interface won't load:**
- Confirm services are running (`./neuroinsight status`)
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
NIfTI (.nii, .nii.gz) recommended, ZIP archives containing DICOM slices for T1 images. Individual DICOM files (.dcm) are not supported.

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
