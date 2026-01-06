# NeuroInsight

*Automated Hippocampal Analysis Platform for Neuroscience Research*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://docker.com)

NeuroInsight provides automated hippocampal segmentation and analysis from T1-weighted MRI scans using FreeSurfer.

## Features

- Automated MRI processing with FreeSurfer
- Web-based interface for easy access
- Real-time progress monitoring
- Containerized deployment

## Quick Start

### Prerequisites
- Ubuntu 20.04+ or compatible Linux
- 16GB+ RAM, 4+ CPU cores, 50GB+ storage
- Docker and Docker Compose
- FreeSurfer license (free for research)

### FreeSurfer License Setup

**Before installation, you must obtain and set up a FreeSurfer license:**

1. **Get Free License**: Visit https://surfer.nmr.mgh.harvard.edu/registration.html
2. **Register**: Create account with your research institution email
3. **Download License**: Save the license file as `license.txt`
4. **Place License**: Put `license.txt` in the same directory as NeuroInsight

```bash
# Example: Place license.txt in the project directory
# The license.txt file should contain your email and license codes
head -3 license.txt
# Should show something like:
# your.email@institution.edu
# license_number
# license_code
```

### Installation

```bash
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local
./install.sh
./start.sh
```

Visit `http://localhost:8000` to access NeuroInsight.

## Post-Installation Commands

After installation, use these essential commands to manage NeuroInsight:

### Application Management
```bash
# Start NeuroInsight services
./start.sh

# Stop all services gracefully
./stop.sh

# Check status of all services and ports
./status.sh
```

### License & Testing
```bash
# Verify FreeSurfer license is properly configured
./check_license.sh

# Run comprehensive performance tests
./test_performance.sh
```

### Maintenance
```bash
# Create full system backup (database, configs, data)
./backup_neuroinsight.sh
```

**Tip**: All scripts provide helpful output and error messages to guide you through any issues.

## Documentation

- **[Installation Guide](INSTALL.md)**: Detailed setup
- **[User Guide](USER_GUIDE.md)**: Complete usage tutorial
- **[Troubleshooting](TROUBLESHOUTING.md)**: Common issues

## License

MIT License. FreeSurfer requires separate license for research use.