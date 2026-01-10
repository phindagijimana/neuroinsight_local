# NeuroInsight

Automated hippocampal segmentation and analysis from T1-weighted MRI scans using FreeSurfer.

## Quick Start

```bash
# Clone repository
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local

# Install (one-time setup)
./neuroinsight install

# Setup FreeSurfer license
./neuroinsight license

# Start NeuroInsight
./neuroinsight start

# Access at http://localhost:8000
```

## Requirements

- Ubuntu 20.04+ Linux
- 16GB+ RAM (32GB recommended)
- 4+ CPU cores, 50GB storage
- FreeSurfer license (free for research)

## File Requirements

NeuroInsight processes T1-weighted MRI scans only. Filenames must contain:
`t1`, `t1w`, `t1-weighted`, `mprage`, `spgr`, `tfl`, `tfe`, `fspgr`

Supported formats: NIfTI (.nii, .nii.gz), DICOM (.dcm), ZIP archives

## Management Commands

```bash
./neuroinsight start     # Start all services
./neuroinsight stop      # Stop all services
./neuroinsight status    # Check system health
./neuroinsight monitor   # Advanced monitoring
./neuroinsight license   # FreeSurfer license setup
```

## Documentation

- [User Guide](USER_GUIDE.md) - Complete usage instructions
- [Troubleshooting](TROUBLESHOUTING.md) - Common issues
- [FreeSurfer License](FREESURFER_LICENSE_README.md) - License setup

## License

MIT License. FreeSurfer requires separate license for research use.

© 2025 University of Rochester. All rights reserved.