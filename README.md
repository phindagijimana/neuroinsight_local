# NeuroInsight

*Advanced Hippocampal Analysis Platform for Neuroscience Research*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://docker.com)
[![Ubuntu 20.04+](https://img.shields.io/badge/ubuntu-20.04+-orange.svg)](https://ubuntu.com)

NeuroInsight is a comprehensive web-based platform for automated hippocampal segmentation and analysis from T1-weighted MRI scans. Built for neuroscience researchers, it provides a user-friendly interface for processing, visualizing, and analyzing brain imaging data using FreeSurfer and advanced segmentation algorithms.

## Features

- **Web-Based Interface**: Clean, intuitive web application accessible from any browser
- **Automated Processing**: End-to-end MRI processing pipeline with FreeSurfer integration
- **Real-Time Monitoring**: Live progress tracking and detailed processing logs
- **Advanced Analytics**: Comprehensive hippocampal metrics and statistical analysis
- **Interactive Visualization**: 3D brain visualizations and segmentation overlays
- **Automated Reports**: Professional PDF reports with findings and metrics
- **Queue Management**: Intelligent job queuing with concurrency control
- **Containerized**: Docker-based deployment for easy installation and scaling

## Screenshots

### Home Page
*Professional landing page with navigation and overview*
![NeuroInsight Home Page](screenshots/home_page.png)

### Jobs Page
*Job management interface showing processing queue with sample jobs*
![NeuroInsight Jobs Page](screenshots/jobs_page.png)

### Dashboard Page
*Real-time processing dashboard with metrics and system status*
![NeuroInsight Dashboard Page](screenshots/dashboard_page.png)

### Viewer Page
*3D brain visualization viewer showing hippocampal segmentation results*
![NeuroInsight Viewer Page](screenshots/viewer_page.png)

*Note: Screenshots show NeuroInsight interface with realistic sample data*

## Quick Start

### Prerequisites
- Ubuntu 20.04+ or compatible Linux distribution
- 16GB+ RAM, 4+ CPU cores, 50GB+ free disk space
- Docker and Docker Compose installed
- FreeSurfer license (free for research)

### One-Command Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/neuroinsight.git
cd neuroinsight

# Run the automated installer
./install.sh

# Start the application
./start.sh
```

Visit `http://localhost:8000` (or the auto-selected port) and start processing your MRI data!

**Port Selection:**
- **Default**: NeuroInsight automatically uses port 8000 if available
- **Auto-selection**: If 8000 is occupied, automatically finds available port (8000-8050)
- **Custom**: Override with `export PORT=8001 && ./start.sh`
- **Check**: Use `./status.sh` to see which port is being used

## System Requirements

### Minimum Hardware
- **CPU**: 4 cores (Intel/AMD x64)
- **RAM**: 16 GB
- **Storage**: 50 GB free space
- **Network**: Stable internet connection

### Recommended Hardware
- **CPU**: 8+ cores (Intel/AMD x64)
- **RAM**: 32 GB
- **Storage**: 100+ GB SSD
- **GPU**: NVIDIA GPU (optional, for accelerated processing)

### Software Requirements
- **Operating System**: Ubuntu 20.04 LTS or later
- **Container Runtime**: Docker 20.10+
- **Python**: 3.10 or later
- **Web Browser**: Chrome 90+, Firefox 88+, Safari 14+

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Frontend  │    │  FastAPI Backend │    │   Celery Worker │
│   (React)       │◄──►│   (Python)       │◄──►│   (Python)       │
│                 │    │                 │    │                 │
│ • File Upload   │    │ • Job Management │    │ • MRI Processing │
│ • Progress UI   │    │ • API Endpoints  │    │ • FreeSurfer     │
│ • Results View  │    │ • Database Ops   │    │ • Docker Mgmt    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Services      │
                    │ • PostgreSQL    │
                    │ • Redis         │
                    │ • MinIO         │
                    │ • Docker Engine │
                    └─────────────────┘
```

## Documentation

- **[Installation Guide](INSTALL.md)**: Detailed setup instructions
- **[User Guide](USER_GUIDE.md)**: Complete usage tutorial
- **[Troubleshooting](TROUBLESHOUTING.md)**: Common issues and solutions
- **[FAQ](FAQ.md)**: Frequently asked questions

## Key Technologies

- **Frontend**: React 18, Tailwind CSS, Recharts
- **Backend**: FastAPI, SQLAlchemy, Pydantic
- **Processing**: FreeSurfer 7.4.1, Docker containers
- **Database**: PostgreSQL with SQLAlchemy ORM
- **Queue**: Celery with Redis broker
- **Storage**: MinIO S3-compatible object storage
- **Deployment**: Docker Compose, automated scripts

## Use Cases

- **Research Institutions**: Automated hippocampal analysis for neuroscience studies
- **Clinical Trials**: Standardized processing for multi-site neuroimaging studies
- **Medical Research**: High-throughput processing of large MRI datasets
- **Education**: Teaching platform for neuroimaging analysis techniques

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**FreeSurfer License**: FreeSurfer requires a license for research use. Get your free license at: https://surfer.nmr.mgh.harvard.edu/registration.html

## Contributing

We welcome contributions! Please see our contributing guidelines and code of conduct.

## Support

- **Documentation**: Check the [troubleshooting guide](TROUBLESHOUTING.md)
- **Issues**: Report bugs via GitHub Issues
- **Discussions**: Join community discussions
- **Email**: support@neuroinsight.org

## Acknowledgments

- **FreeSurfer Team**: For the comprehensive neuroimaging analysis suite
- **FastAPI Community**: For the excellent web framework
- **Docker Community**: For containerization technology
- **Neuroscience Research Community**: For advancing brain science

---

**NeuroInsight** - *Accelerating Neuroscience Discovery Through Automation*