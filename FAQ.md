# Frequently Asked Questions

Common questions and answers about NeuroInsight.

## Getting Started

### What is NeuroInsight?

NeuroInsight is a web-based platform for automated hippocampal segmentation and analysis from T1-weighted MRI scans. It provides researchers with an easy-to-use interface for processing brain imaging data using FreeSurfer and advanced segmentation algorithms.

### Who can use NeuroInsight?

NeuroInsight is designed for:
- **Neuroscience researchers** studying brain structure
- **Clinical researchers** conducting neuroimaging studies
- **Medical professionals** analyzing patient scans
- **Students and educators** learning neuroimaging techniques

### What are the system requirements?

**Minimum Requirements:**
- Ubuntu 18.04+ Linux distribution
- 4 CPU cores, 16GB RAM, 50GB storage
- Docker and Docker Compose installed

**Recommended:**
- Ubuntu 20.04+ LTS
- 8 CPU cores, 32GB RAM, 100GB SSD storage

### Is NeuroInsight free?

Yes! NeuroInsight is open-source software released under the MIT license. However, it requires a FreeSurfer license, which is free for research use.

## Data and Processing

### What file formats does NeuroInsight support?

- **NIfTI** (`.nii`, `.nii.gz`) - Recommended format
- **DICOM** directories containing `.dcm` files
- **Compressed archives** (`.zip`, `.tar.gz`)

### How long does processing take?

Typical processing time: **30-60 minutes** per scan, depending on:
- Scan resolution and quality
- System hardware specifications
- Current system load

### What's processed during analysis?

NeuroInsight performs comprehensive analysis including:
- **Cortical reconstruction** and surface generation
- **Subcortical segmentation** (hippocampus, thalamus, etc.)
- **Volume measurements** and morphometric analysis
- **Shape analysis** and asymmetry calculations
- **Quality metrics** and processing validation

### Can I process multiple scans at once?

Yes! NeuroInsight supports:
- **Queue system**: Up to 5 pending + 1 running job
- **Batch processing**: Upload multiple files sequentially
- **Automatic queuing**: Next job starts when current completes

## Technical Questions

### Do I need a FreeSurfer license?

Yes. FreeSurfer requires a license for processing. It's free for research use - register at: https://surfer.nmr.mgh.harvard.edu/registration.html

### How does NeuroInsight work?

NeuroInsight uses:
- **FreeSurfer 7.4.1** running in Docker containers
- **FastAPI backend** for web services
- **React frontend** for user interface
- **Celery** for background job processing
- **PostgreSQL** for data storage
- **Redis** for job queuing

### Is my data secure?

NeuroInsight processes data locally on your machine. No data is sent to external servers. However, always follow your institution's data security protocols.

### Can I run NeuroInsight on Windows/Mac?

Currently, NeuroInsight requires Linux due to FreeSurfer and Docker dependencies. Windows users can use WSL2, and Mac users can use Docker Desktop with Linux containers.

## Results and Analysis

### What metrics does NeuroInsight provide?

Hippocampal analysis includes:
- **Volume measurements** (left/right hippocampus in mm³)
- **Shape indices** and morphological features
- **Asymmetry calculations** (left-right differences)
- **Age-adjusted norms** and percentiles
- **Quality scores** and processing reliability

### How accurate are the results?

Accuracy depends on input scan quality, but NeuroInsight typically achieves:
- **90-95%** segmentation accuracy for high-quality T1 scans
- **Reliable volume measurements** within 5% of manual tracing
- **Consistent results** across repeated processing

### Can I export my results?

Yes! Export options include:
- **PDF reports** with visualizations and metrics
- **CSV files** with raw measurements
- **PNG/PDF images** of brain visualizations
- **Raw data** for further statistical analysis

## Troubleshooting

### Why is my job stuck in "pending"?

Common causes:
- **Worker not running**: Check `./status.sh`
- **Queue full**: Maximum 1 running + 5 pending jobs
- **Redis issues**: Restart Redis service
- **System overload**: Wait for current job to complete

### Why did processing fail?

Common reasons:
- **Invalid file format**: Use NIfTI format
- **FreeSurfer license issue**: Verify `license.txt`
- **Insufficient resources**: Check RAM/disk space
- **Corrupted input file**: Verify scan integrity

### How do I restart the application?

```bash
# Stop all services
./stop.sh

# Start all services
./start.sh

# Check status
./status.sh
```

### My web interface won't load

Check:
- Application is running: `./status.sh`
- Browser cache cleared
- Firewall not blocking port 8000
- Correct URL: `http://localhost:8000`

## Configuration

### How do I change application settings?

Edit the `.env` file in the NeuroInsight directory:

```bash
nano .env
```

Common settings:
- `POSTGRES_PASSWORD`: Database password
- `REDIS_PASSWORD`: Redis password
- `MAX_WORKERS`: Number of processing workers

### Can I customize the processing pipeline?

Currently, the pipeline is optimized for hippocampal analysis. Advanced users can modify the MRI processor code, but this requires Python/Docker knowledge.

### How do I backup my data?

```bash
# Backup configuration
cp .env .env.backup

# Backup database
docker-compose exec db pg_dump -U neuroinsight neuroinsight > backup.sql

# Backup processed data
cp -r data data.backup
```

## Updates and Maintenance

### How do I update NeuroInsight?

```bash
# Pull latest changes
git pull origin main

# Update dependencies
source venv/bin/activate
pip install -r requirements.txt

# Restart services
./restart.sh
```

### How do I clean up old data?

```bash
# Remove completed job files (be careful!)
rm -rf data/outputs/job_id_*

# Clean Docker system
docker system prune -a

# Clear old logs
./logs.sh --clean
```

## Clinical Use

### Is NeuroInsight FDA approved?

No. NeuroInsight is research software and should not be used for clinical diagnosis without proper validation and regulatory approval.

### Can I use it for patient data?

Yes, but:
- Follow HIPAA and institutional privacy policies
- Remove protected health information before processing
- Validate results against clinical standards
- Use appropriate security measures

### What scan parameters work best?

**Optimal T1-weighted scan parameters:**
- **Resolution**: 1mm isotropic voxels
- **Orientation**: Standard radiological (RAS)
- **Field strength**: 3T preferred, 1.5T acceptable
- **Sequence**: MPRAGE or similar T1-weighted sequence

## 🤝 Support

### Where can I get help?

- **Documentation**: Check [USER_GUIDE.md](USER_GUIDE.md) and [TROUBLESHOUTING.md](TROUBLESHOUTING.md)
- **GitHub Issues**: Report bugs and request features
- **Community Discussions**: Join the conversation
- **Email**: For sensitive support inquiries

### How do I report a bug?

When reporting issues, include:
- Operating system and version
- Docker and Docker Compose versions
- Error messages and logs
- Steps to reproduce the issue
- Sample data (if possible, anonymized)

### Can I contribute to NeuroInsight?

Yes! Contributions are welcome:
- **Bug fixes**: Create pull requests
- **Features**: Discuss in GitHub Issues first
- **Documentation**: Improve guides and tutorials
- **Testing**: Help test on different systems

## 📈 Performance

### Why is processing slow?

Factors affecting speed:
- **Hardware**: More CPU cores and RAM = faster processing
- **Scan quality**: High-resolution scans take longer
- **System load**: Close other applications
- **Storage**: SSD storage significantly faster than HDD

### Can I speed up processing?

Optimization tips:
- Use SSD storage for data directories
- Ensure 16GB+ RAM available
- Process during off-peak hours
- Use high-quality scans (not necessarily highest resolution)

### What's the maximum file size?

- **Upload limit**: 1GB per file
- **Recommended**: Keep under 500MB for best performance
- **Processing**: Requires ~2-3x file size in temporary space

---

**Didn't find your question?** Check the [troubleshooting guide](TROUBLESHOUTING.md) or create a GitHub issue!
