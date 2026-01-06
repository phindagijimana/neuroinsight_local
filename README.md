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

### Installation

```bash
git clone https://github.com/phindagijimana/neuroinsight_app.git
cd neuroinsight_app
./install.sh
./start.sh
```

Visit `http://localhost:8000` to access NeuroInsight.

## Documentation

- **[Installation Guide](INSTALL.md)**: Detailed setup
- **[User Guide](USER_GUIDE.md)**: Complete usage tutorial
- **[Troubleshooting](TROUBLESHOUTING.md)**: Common issues

## License

MIT License. FreeSurfer requires separate license for research use.