# User Guide

Complete guide for using NeuroInsight to process and analyze hippocampal MRI data.

## Getting Started

### First Time Setup

1. **Access the Application**
   - Open your web browser
   - Navigate to `http://localhost:8000`
   - You should see the NeuroInsight homepage

2. **Verify System Status**
   ```bash
   # Check if all services are running
   ./status.sh
   ```

3. **Test with Sample Data** (Optional)
   - Download a sample T1-weighted MRI scan
   - Use it to test the processing pipeline

## Uploading MRI Data

### Supported File Formats

NeuroInsight supports:
- **NIfTI** (`.nii`, `.nii.gz`) - Recommended
- **DICOM** directories (`.dcm` files)
- **Compressed archives** (`.zip`, `.tar.gz`)

### Upload Process

1. **Navigate to the Homepage**
   - Click "Get Started" or "Upload Data"

2. **Prepare Your File**
   - Ensure file is under 1GB
   - Verify it's a T1-weighted anatomical scan
   - Remove any sensitive patient information if needed

3. **Fill Patient Information**
   ```
   Required Fields:
   - Age: Patient age in years
   - Sex: Male (M) or Female (F)
   - Name: Patient identifier or name

   Optional Fields:
   - Patient ID: Medical record number
   - Notes: Additional clinical information
   ```

4. **Upload and Process**
   - Click "Choose File" and select your MRI scan
   - Fill in patient details
   - Click "Upload and Process"
   - Monitor progress in real-time

### Upload Tips

- **File Size**: Keep under 1GB for best performance
- **Quality**: Use high-resolution T1-weighted scans (1mm isotropic)
- **Orientation**: Standard radiological orientation preferred
- **Compression**: `.nii.gz` files are smaller and faster to upload

## Monitoring Processing

### Real-Time Progress Tracking

After upload, you'll see:

1. **Job Status**: PENDING → RUNNING → COMPLETED/FAILED
2. **Progress Bar**: Shows completion percentage
3. **Current Step**: Description of what's being processed
4. **Elapsed Time**: How long processing has taken

### Processing Stages

NeuroInsight processes your MRI through these stages:

1. **Input Validation** (2-5 minutes)
   - File format verification
   - Image quality assessment
   - Orientation correction

2. **Preprocessing** (5-10 minutes)
   - Skull stripping
   - Intensity normalization
   - Registration to template space

3. **FreeSurfer Analysis** (20-45 minutes)
   - Cortical reconstruction
   - Subcortical segmentation
   - Hippocampal parcellation

4. **Postprocessing** (5-15 minutes)
   - Volume calculations
   - Shape analysis
   - Quality metrics computation

5. **Report Generation** (2-5 minutes)
   - PDF report creation
   - Statistical summaries
   - Visualization rendering

### Job Management

#### Viewing Active Jobs

1. **Go to Jobs Page**: Click "Jobs" in the navigation
2. **See All Jobs**: View running, completed, and failed jobs
3. **Job Details**: Click on any job to see full details

#### Managing Job Queue

- **Maximum Concurrent Jobs**: 1 running job at a time
- **Queue Limit**: Up to 5 pending jobs
- **Automatic Processing**: Next job starts when current one completes

## Viewing Results

### Dashboard Overview

The Dashboard shows:

1. **Job Summary**
   - Total jobs processed
   - Success/failure rates
   - Processing statistics

2. **Hippocampal Metrics**
   - Left and right hippocampal volumes
   - Shape indices
   - Asymmetry measures
   - Quality metrics

3. **Processing Timeline**
   - Job completion times
   - Processing efficiency
   - Resource utilization

### Detailed Results Viewer

1. **Access Viewer**: Click "View Results" on any completed job
2. **Available Visualizations**:
   - **3D Brain Surface**: Interactive brain rendering
   - **Segmentation Overlay**: Hippocampal regions highlighted
   - **Volume Measurements**: Detailed morphometric data
   - **Statistical Plots**: Distribution charts and comparisons

3. **Export Options**
   - Download raw data (CSV format)
   - Save visualizations (PNG/PDF)
   - Generate PDF reports

## Report Generation

### Automatic Reports

NeuroInsight generates comprehensive PDF reports including:

- **Patient Information**: Demographics and clinical details
- **Processing Summary**: Timeline and quality metrics
- **Hippocampal Analysis**:
  - Volume measurements (mm³)
  - Shape analysis
  - Asymmetry indices
  - Age-adjusted norms
- **Quality Assessment**: Processing reliability scores
- **Visualizations**: Key brain images with annotations

### Downloading Reports

1. **From Jobs Page**: Click "Download Report" on completed jobs
2. **From Dashboard**: Access reports for all completed analyses
3. **Automatic Naming**: Reports named by patient ID and date

## Advanced Features

### Batch Processing

Process multiple scans efficiently:

1. **Prepare Files**: Organize scans in a directory
2. **Upload Sequentially**: Process one at a time
3. **Monitor Progress**: Track all jobs from the Jobs page
4. **Bulk Export**: Download all reports at once

### Quality Control

NeuroInsight provides quality metrics:

- **Processing Success Rate**: Percentage of successful segmentations
- **Volume Consistency**: Comparison with expected ranges
- **Artifact Detection**: Identification of imaging artifacts
- **Reliability Scores**: Confidence in automated measurements

### Data Export

Export your results for further analysis:

- **Raw Metrics**: CSV files with all measurements
- **Statistical Summaries**: Group-level analyses
- **Visualization Data**: Images and plots for publications
- **Processing Logs**: Detailed processing history

## Best Practices

### Data Preparation

1. **Scan Parameters**
   - Use T1-weighted anatomical scans
   - 1mm isotropic resolution preferred
   - Standard radiological orientation

2. **File Organization**
   - Use consistent naming conventions
   - Remove PHI before upload
   - Compress files when possible

3. **Quality Assurance**
   - Verify scan quality before upload
   - Check for motion artifacts
   - Ensure complete brain coverage

### Processing Optimization

1. **System Resources**
   - Ensure adequate RAM (16GB+)
   - Monitor disk space (>50GB free)
   - Close unnecessary applications

2. **Job Scheduling**
   - Process during off-peak hours
   - Limit concurrent jobs to system capacity
   - Monitor processing times

3. **Maintenance**
   - Regularly check system status
   - Clean up old job files
   - Update software when available

## Error Handling

### Common Issues and Solutions

#### Upload Failures

**Problem**: File too large
- **Solution**: Compress file or split into smaller parts

**Problem**: Invalid file format
- **Solution**: Convert to NIfTI format using tools like dcm2niix

**Problem**: Network timeout
- **Solution**: Check internet connection and retry

#### Processing Errors

**Problem**: Job stuck in pending
- **Solution**: Check system resources and restart services

**Problem**: FreeSurfer license error
- **Solution**: Verify license.txt file and restart application

**Problem**: Docker container issues
- **Solution**: Restart Docker service and check disk space

### Getting Help

1. **Check Logs**: Use `./logs.sh` to view detailed error messages
2. **System Status**: Run `./status.sh` to verify all services
3. **Restart Services**: Use `./restart.sh` for service issues
4. **Documentation**: Check [TROUBLESHOUTING.md](TROUBLESHOUTING.md) for detailed solutions

## Use Cases and Workflows

### Clinical Research Workflow

1. **Data Collection**: Gather T1 scans from study participants
2. **Quality Control**: Review scan quality before processing
3. **Batch Processing**: Upload multiple scans for automated analysis
4. **Results Review**: Examine hippocampal metrics and visualizations
5. **Report Generation**: Create standardized reports for all participants
6. **Statistical Analysis**: Export data for group-level comparisons

### Educational Use

1. **Sample Data**: Use provided sample scans for learning
2. **Step-by-Step**: Follow processing stages to understand pipeline
3. **Parameter Exploration**: Experiment with different settings
4. **Results Interpretation**: Learn to interpret hippocampal measurements
5. **Teaching Materials**: Use visualizations for presentations

### Quality Assurance

1. **Test Processing**: Regular test runs with known datasets
2. **Performance Monitoring**: Track processing times and success rates
3. **System Maintenance**: Regular cleanup and updates
4. **Backup Procedures**: Ensure data preservation and recovery

## Updates and Maintenance

### Checking for Updates

```bash
# Check current version
./status.sh | grep "Version"

# Pull latest changes
git pull origin main

# Update dependencies
pip install -r requirements.txt

# Restart services
./restart.sh
```

### System Maintenance

- **Regular Backups**: Backup important data and configurations
- **Log Rotation**: Clean old log files periodically
- **Disk Cleanup**: Remove completed job files when no longer needed
- **Performance Monitoring**: Track system resources and processing times

## Support and Resources

- **Documentation**: [TROUBLESHOUTING.md](TROUBLESHOUTING.md) for common issues
- **FAQ**: [FAQ.md](FAQ.md) for frequently asked questions
- **GitHub Issues**: Report bugs and request features
- **Community**: Join discussions and share experiences

---

**Happy analyzing!** Questions? Check the [FAQ](FAQ.md) or create an issue.