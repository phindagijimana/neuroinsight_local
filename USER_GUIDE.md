# NeuroInsight User Training Guide

**Complete training guide for deploying and using NeuroInsight to process and analyze hippocampal MRI data on personal Linux machines.**

## **⚡ QUICK START SUMMARY**

### **What You'll Learn**
This guide teaches you how to:
- ✅ Deploy NeuroInsight on your Linux system
- ✅ Process MRI scans safely and accurately
- ✅ Troubleshoot common issues
- ✅ Maintain system performance and security
- ✅ Follow medical data privacy best practices

### **Time Investment**
- **Basic Setup**: 2-3 hours (essential for all users)
- **Full Training**: 6-8 hours (recommended for administrators)
- **Ongoing Learning**: Regular review of updates and procedures

### **Prerequisites**
- Linux system with sudo access
- Basic command-line familiarity
- Understanding of MRI data concepts
- Web browser for interface access

### **Certification Path**
1. **Level 1 - Basic User**: Can install and run basic processing
2. **Level 2 - Power User**: Can troubleshoot and optimize performance
3. **Level 3 - Administrator**: Can maintain and customize deployment

---

**Ready to begin? Start with [Module 1: System Requirements & Setup](#module-1-system-requirements--setup)**

---

## **📚 TABLE OF CONTENTS**

### **Module 1: System Requirements & Setup**
- [System Requirements Training](#system-requirements-training)
- [Pre-Installation Checklist](#pre-installation-checklist)
- [Installation Training](#installation-training)
- [FreeSurfer License Setup](#freesurfer-license-setup-required)
- [System Validation Training](#system-validation-training)

### **Module 2: Safety & Best Practices Training**
- [Data Privacy and Security Training](#data-privacy-and-security-training)
- [Quality Assurance Training](#quality-assurance-training)
- [Performance Optimization Training](#performance-optimization-training)

### **Module 3: Troubleshooting & Problem Solving Training**
- [Systematic Troubleshooting Methodology](#systematic-troubleshooting-methodology)
- [Installation & Startup Issues](#installation--startup-issues)
- [Upload & Processing Issues](#upload--processing-issues)
- [Performance & Resource Issues](#performance--resource-issues)
- [Advanced Troubleshooting Training](#advanced-troubleshooting-training)

### **Module 4: Training Assessment & Certification**
- [Knowledge Assessment](#knowledge-assessment)
- [Practical Skills Assessment](#practical-skills-assessment)
- [Performance Metrics](#performance-metrics)
- [Continuing Education](#continuing-education)

### **Module 5: Quick Reference & Cheat Sheets**
- [Command Quick Reference](#command-quick-reference)
- [File Format Reference](#file-format-reference)
- [Error Code Reference](#error-code-reference)
- [System Requirements Quick Check](#system-requirements-quick-check)

---

## **🏁 TRAINING OVERVIEW**

### **Who Should Read This Guide**
- **New Users**: First-time NeuroInsight users learning the system
- **System Administrators**: Users responsible for local deployment and maintenance
- **Researchers**: Clinical researchers and neuroimaging specialists
- **IT Staff**: Technical support personnel managing local installations

### **Estimated Training Time**
- **Basic Usage**: 2-3 hours
- **Full Deployment**: 4-6 hours
- **Advanced Features**: 8-12 hours
- **Maintenance & Troubleshooting**: Ongoing learning

### **Prerequisites for Training**
- Basic Linux command-line knowledge
- Understanding of MRI data and neuroimaging concepts
- Familiarity with web browsers
- Access to a Linux system meeting minimum requirements

---

## **📋 MODULE 1: SYSTEM REQUIREMENTS & SETUP**

### **System Requirements Training**

#### **Minimum Hardware Requirements**
| **Component** | **Minimum** | **Recommended** | **Why Important** |
|---------------|-------------|------------------|-------------------|
| **RAM** | 8GB | 16GB+ | MRI processing requires significant memory |
| **CPU** | 4 cores | 8+ cores | Parallel processing and computation |
| **Storage** | 50GB free | 100GB+ free | Temporary files, processed data, logs |
| **Network** | 10 Mbps | 100 Mbps | File uploads and data transfer |

#### **Software Prerequisites**
- **Operating System**: Ubuntu 18.04+, CentOS 7+, or compatible Linux distribution
- **Docker**: Version 20.10+ (automatically installed by setup script)
- **Python**: Version 3.8-3.12 (automatically installed by setup script)
- **Web Browser**: Chrome, Firefox, or Edge (latest versions)

### **Pre-Installation Checklist**

**✅ Before starting installation, verify:**

1. **System Resources**
   ```bash
   # Check memory
   free -h

   # Check disk space
   df -h .

   # Check CPU cores
   nproc
   ```

2. **Network Connectivity**
   ```bash
   # Test internet connection
   ping -c 3 google.com

   # Check DNS resolution
   nslookup github.com
   ```

3. **User Permissions**
   ```bash
   # Check if you can run Docker commands
   docker --version

   # Check sudo access (may be needed for installation)
   sudo -l
   ```

### **Installation Training**

#### **Step-by-Step Installation Process**

**🎯 TRAINING OBJECTIVE**: Successfully install NeuroInsight on a Linux system

**Estimated Time**: 30-45 minutes

**Step 1: Download and Prepare**
```bash
# Clone the repository
git clone https://github.com/your-repo/neuroinsight.git
cd neuroinsight

# Make scripts executable
chmod +x *.sh
```

**Step 2: Run Installation Script**
```bash
# Execute automated installation
./install.sh

# Follow on-screen prompts
# The script will:
# - Install Docker if needed
# - Install Python dependencies
# - Configure the environment
# - Set up required services
```

**Step 3: Post-Installation Verification**
```bash
# Check installation status
./status.sh

# Verify all services are running
# Expected output: All services should show "running"
```

#### **FreeSurfer License Setup (Required)**

**🎯 TRAINING OBJECTIVE**: Configure FreeSurfer license for MRI processing

**Step 1: Obtain License**
- Visit FreeSurfer website: https://surfer.nmr.mgh.harvard.edu/
- Register and download license file
- Save as `license.txt` in the NeuroInsight directory

**Step 2: Verify License**
```bash
# Check license validity
./check_license.sh

# Expected: "FreeSurfer license is valid"
```

**Step 3: Test Processing**
- Upload a sample MRI scan
- Verify processing completes successfully

### **System Validation Training**

#### **Pre-Processing System Checks**

**🎯 TRAINING OBJECTIVE**: Ensure system is ready for MRI processing

**Memory Validation:**
```bash
# Check available memory
free -h

# Should show at least 8GB available
# Recommended: 16GB+ for optimal performance
```

**Disk Space Validation:**
```bash
# Check available space
df -h /home/ubuntu/src/desktop_alone_web_1

# Should show at least 50GB available
# Recommended: 100GB+ for multiple scans
```

**Service Validation:**
```bash
# Check all services
./status.sh

# Verify these are running:
# - Backend (FastAPI)
# - Celery Worker
# - Redis
# - PostgreSQL
# - MinIO
```

---

## Getting Started

### First Time Setup

1. **Access the Application**
   - Open your web browser
   - Navigate to `http://localhost:8000` (or auto-selected port)
   - Check `./status.sh` to see which port is being used
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

## **📋 MODULE 3: TROUBLESHOOTING & PROBLEM SOLVING TRAINING**

### **Systematic Troubleshooting Methodology**

#### **Problem-Solving Framework**
**🎯 TRAINING OBJECTIVE**: Develop systematic approach to diagnosing and resolving issues

**Step 1: Gather Information**
```bash
# Always start with system status
./status.sh

# Check recent logs
tail -50 neuroinsight.log

# Verify system resources
free -h && df -h .
```

**Step 2: Identify Problem Category**
- **Installation Issues**: Problems during setup or startup
- **Upload Problems**: File upload failures or validation errors
- **Processing Errors**: MRI analysis pipeline failures
- **Performance Issues**: Slow processing or system hangs
- **Access Problems**: Web interface or service connectivity issues

**Step 3: Apply Targeted Solutions**
- Follow specific troubleshooting procedures for each category
- Document steps taken and results
- Escalate if problem persists

### **Installation & Startup Issues**

#### **Scenario 1: Services Won't Start**
**Symptoms**: `./start.sh` fails or services don't start
**Training Exercise**: Diagnose and resolve startup failures

**Step-by-Step Resolution:**
```bash
# 1. Check system prerequisites
./status.sh

# 2. Verify Docker is running
sudo systemctl status docker

# 3. Check available resources
free -h
df -h .

# 4. Review startup logs
tail -100 neuroinsight.log

# 5. Try manual service restart
./stop.sh
sleep 5
./start.sh
```

**Common Causes & Solutions:**
- **Port conflicts**: Check `./status.sh` for port information
- **Insufficient memory**: Free up RAM or upgrade system
- **Docker issues**: `sudo systemctl restart docker`
- **Permission problems**: Ensure proper file permissions

#### **Scenario 2: License Validation Fails**
**Symptoms**: FreeSurfer processing unavailable
**Training Exercise**: Configure and validate FreeSurfer license

**Resolution Steps:**
```bash
# 1. Verify license file exists
ls -la license.txt

# 2. Check license content
head -10 license.txt

# 3. Run license validation
./check_license.sh

# 4. Restart services after license update
./restart.sh
```

### **Upload & Processing Issues**

#### **Scenario 3: File Upload Rejections**
**Symptoms**: Files rejected with validation errors
**Training Exercise**: Identify and fix file format issues

**Common Upload Problems:**

**File Format Issues:**
```
Error: "Invalid file format"
Solution: Convert to supported format
- DICOM → NIfTI: dcm2niix input.dcm output.nii.gz
- Other formats → NIfTI: Use MRIcroGL or similar tools
```

**File Size Issues:**
```
Error: "File too large"
Solution: Compress or split files
- Compress NIfTI: gzip file.nii
- Split large datasets: Use archive tools
```

**T1 Validation Issues:**
```
Error: "Filename must contain T1 indicators"
Solution: Rename file with T1 indicators
- Valid: sub01_T1w.nii.gz, mprage.nii, spgr_T1.nii
- Invalid: brain_scan.nii, mri_data.dcm
```

#### **Scenario 4: Processing Jobs Get Stuck**
**Symptoms**: Jobs remain in "processing" state indefinitely
**Training Exercise**: Diagnose and recover stuck processing jobs

**Investigation Steps:**
```bash
# 1. Check job status
./status.sh

# 2. Monitor Celery worker
ps aux | grep celery

# 3. Check worker logs
tail -50 celery_worker.log

# 4. Restart worker if needed
./stop.sh
./start.sh
```

**Recovery Procedures:**
- **Soft restart**: `./restart.sh` (preserves jobs)
- **Hard restart**: `./stop.sh && ./start.sh` (may lose current job)
- **Job cleanup**: Use `./stop.sh --clear-stuck` for stuck jobs

### **Performance & Resource Issues**

#### **Scenario 5: Slow Processing Performance**
**Symptoms**: Processing takes much longer than expected
**Training Exercise**: Optimize system performance

**Performance Diagnosis:**
```bash
# Monitor system during processing
htop  # or top

# Check memory usage
free -h

# Monitor disk I/O
iotop -o

# Check CPU utilization
mpstat 1
```

**Optimization Strategies:**
1. **Memory**: Ensure 16GB+ RAM available
2. **CPU**: Close unnecessary applications
3. **Disk**: Ensure SSD storage, defragment if needed
4. **Network**: Stable high-speed connection

#### **Scenario 6: System Resource Exhaustion**
**Symptoms**: Out of memory errors, disk full messages
**Training Exercise**: Prevent and recover from resource exhaustion

**Prevention Measures:**
```bash
# Set up monitoring alerts
# Check resources before processing large jobs
free -h && df -h .

# Clean up regularly
find data/temp -mtime +1 -delete
```

**Recovery Steps:**
```bash
# Free up memory
sudo sync && sudo sysctl -w vm.drop_caches=3

# Clean temporary files
rm -rf data/temp/*
rm -rf /tmp/neuroinsight_*

# Restart services
./restart.sh
```

### **Advanced Troubleshooting Training**

#### **Log Analysis Techniques**
**🎯 TRAINING OBJECTIVE**: Interpret system logs for problem diagnosis

**Log File Locations:**
- `neuroinsight.log`: Main application log
- `celery_worker.log`: Processing worker log
- `backend.log`: API server log
- Docker logs: `docker logs neuroinsight-backend`

**Common Log Patterns:**
```
INFO: Processing completed successfully
WARNING: Low memory detected
ERROR: FreeSurfer license invalid
CRITICAL: Database connection failed
```

#### **Network Connectivity Issues**
**Training Exercise**: Diagnose and resolve connectivity problems

**Testing Steps:**
```bash
# Test local connectivity
curl http://localhost:8000/api/health

# Check service ports
netstat -tlnp | grep :8000

# Test Docker networking
docker network ls
docker inspect bridge
```

### **Maintenance & Prevention Training**

#### **Regular System Health Checks**
**Daily Monitoring:**
```bash
#!/bin/bash
# Daily health check script
echo "=== Daily NeuroInsight Health Check ==="
./status.sh
echo "--- Resource Usage ---"
free -h
df -h /home/ubuntu/src/desktop_alone_web_1
echo "--- Recent Errors ---"
grep -i error neuroinsight.log | tail -5
```

#### **Backup and Recovery Training**
**🎯 TRAINING OBJECTIVE**: Implement reliable backup procedures

**Backup Strategy:**
```bash
# Create backup script
./backup_neuroinsight.sh

# Backup includes:
# - Database (PostgreSQL)
# - Processed results (MinIO)
# - Configuration files
# - User data
```

**Recovery Testing:**
- Test backup restoration on separate system
- Verify data integrity after restore
- Document recovery time objectives

### **Getting Help & Escalation**

#### **Support Resources**
1. **Documentation**: Check [TROUBLESHOUTING.md](TROUBLESHOUTING.md)
2. **FAQ**: Review [FAQ.md](FAQ.md) for common questions
3. **Logs**: Collect relevant log files for support
4. **System Info**: Gather system information for diagnosis

#### **Support Ticket Preparation**
**Required Information:**
- System information (`uname -a`, `lsb_release -a`)
- NeuroInsight version (`./status.sh`)
- Error messages and logs
- Steps to reproduce the issue
- System resource information

---

## **📋 MODULE 2: SAFETY & BEST PRACTICES TRAINING**

### **Data Privacy and Security Training**

#### **HIPAA Compliance Guidelines**
**🎯 TRAINING OBJECTIVE**: Understand data handling requirements for medical imaging

**Key Principles:**
1. **Patient Privacy**: Never upload scans with embedded PHI
2. **Data Minimization**: Only include necessary clinical information
3. **Access Control**: Limit system access to authorized personnel
4. **Audit Trails**: Maintain logs of all data access and processing

**Pre-Upload Checklist:**
- [ ] Remove patient names from file metadata
- [ ] Strip DICOM headers of identifying information
- [ ] Use anonymized patient IDs only
- [ ] Document data de-identification procedures

#### **Data Security Best Practices**

**File Handling:**
- Store original scans separately from processed data
- Use encrypted storage for sensitive data
- Implement regular backup procedures
- Maintain data retention policies

**System Security:**
- Keep system updated with security patches
- Use strong passwords for system access
- Limit network exposure of the application
- Regularly audit system access logs

### **Quality Assurance Training**

#### **Data Quality Standards**
**🎯 TRAINING OBJECTIVE**: Ensure reliable and reproducible results

**Scan Quality Checklist:**
- [ ] T1-weighted anatomical sequence confirmed
- [ ] Adequate signal-to-noise ratio
- [ ] No significant motion artifacts
- [ ] Complete brain coverage
- [ ] Proper orientation and positioning

**Processing Quality Metrics:**
- Monitor segmentation accuracy scores
- Review volume measurements for consistency
- Check processing completion rates
- Validate results against known standards

#### **Regular Maintenance Procedures**

**Daily Checks:**
```bash
# Verify system status
./status.sh

# Check disk usage
df -h /home/ubuntu/src/desktop_alone_web_1

# Review recent processing logs
tail -50 neuroinsight.log
```

**Weekly Maintenance:**
```bash
# Clean up old temporary files
find data/temp -type f -mtime +7 -delete

# Backup important data
./backup_neuroinsight.sh

# Update system packages
sudo apt update && sudo apt upgrade -y
```

**Monthly Reviews:**
- Audit processing logs for anomalies
- Review storage usage trends
- Update NeuroInsight if new versions available
- Test backup restoration procedures

### **Performance Optimization Training**

#### **System Resource Management**
**🎯 TRAINING OBJECTIVE**: Optimize processing performance and system stability

**Memory Management:**
- Monitor RAM usage during processing
- Close unnecessary applications
- Consider system upgrades for memory-intensive workloads
- Use system monitoring tools to track resource usage

**Storage Optimization:**
- Regularly clean temporary processing files
- Compress completed job data when possible
- Monitor disk I/O performance
- Plan for storage expansion needs

**Processing Optimization:**
- Process scans during off-peak hours
- Limit concurrent jobs based on system capacity
- Use batch processing for multiple scans
- Monitor processing times for performance trends

---

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

## Port Configuration

### Automatic Port Selection

NeuroInsight automatically handles port conflicts:

- **Default Behavior**: Tries port 8000 first
- **Auto-Selection**: If 8000 is occupied, automatically finds available port (8000-8050)
- **Smart Detection**: No manual intervention required for most users

### Manual Port Configuration

For specific port requirements:

```bash
# Force a specific port
export PORT=8080
./start.sh

# Let NeuroInsight auto-select
unset PORT  # or don't set PORT variable
./start.sh
```

### Checking Current Port

```bash
# Always check which port is being used
./status.sh
# Shows: Backend: running (PID: 12345, Port: 8001, API: responding)
```

**Note**: The automatic port selection makes NeuroInsight much easier to use in shared environments!

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

## **📋 MODULE 4: TRAINING ASSESSMENT & CERTIFICATION**

### **Knowledge Assessment**

#### **Basic User Certification Checklist**
**🎯 TRAINING OBJECTIVE**: Verify fundamental NeuroInsight knowledge

**System Requirements Knowledge:**
- [ ] Can identify minimum hardware requirements (8GB RAM, 50GB storage)
- [ ] Understands software prerequisites (Docker, Python 3.8+)
- [ ] Knows how to check system resources (`free -h`, `df -h`)

**Installation Skills:**
- [ ] Can execute `./install.sh` successfully
- [ ] Knows how to configure FreeSurfer license
- [ ] Can verify installation with `./status.sh`
- [ ] Understands post-installation validation steps

**Basic Usage Skills:**
- [ ] Can access web interface at correct port
- [ ] Knows supported file formats (NIfTI, DICOM, ZIP)
- [ ] Can upload a sample MRI scan
- [ ] Understands job status progression (PENDING → PROCESSING → COMPLETED)

#### **Advanced User Certification Checklist**
**Processing Knowledge:**
- [ ] Understands MRI processing pipeline stages
- [ ] Can monitor processing progress and identify bottlenecks
- [ ] Knows how to interpret processing results
- [ ] Can generate and download PDF reports

**Troubleshooting Skills:**
- [ ] Can diagnose common startup failures
- [ ] Knows how to resolve file upload validation errors
- [ ] Can recover from stuck processing jobs
- [ ] Understands log analysis techniques

**System Administration Skills:**
- [ ] Can perform regular maintenance tasks
- [ ] Knows backup and recovery procedures
- [ ] Can optimize system performance
- [ ] Understands security and privacy requirements

### **Practical Skills Assessment**

#### **Installation Lab Exercise**
**Scenario**: Fresh Linux system, install NeuroInsight from scratch

**Required Tasks:**
1. Verify system meets minimum requirements
2. Download and install NeuroInsight
3. Configure FreeSurfer license
4. Start all services successfully
5. Access web interface
6. Upload and process sample data

**Success Criteria:**
- All services running within 30 minutes
- Web interface accessible
- Sample processing completes successfully
- Proper error handling demonstrated

#### **Troubleshooting Lab Exercise**
**Scenario**: System experiencing various issues

**Problem Scenarios:**
1. **Port conflict**: Resolve port 8000 already in use
2. **Memory exhaustion**: Handle out-of-memory during processing
3. **License invalid**: Update and validate FreeSurfer license
4. **Stuck job**: Diagnose and recover failed processing job

**Assessment Criteria:**
- Systematic problem-solving approach
- Proper use of diagnostic tools
- Correct solution implementation
- Documentation of resolution steps

### **Performance Metrics**

#### **Training Completion Benchmarks**
- **Basic User**: Complete installation and first successful processing
- **Intermediate User**: Handle 10+ processing jobs, basic troubleshooting
- **Advanced User**: System administration, performance optimization, backup/recovery

#### **Quality Assurance Metrics**
- **Processing Success Rate**: >95% successful completions
- **Mean Time to Resolution**: <30 minutes for common issues
- **System Uptime**: >99% during normal operation
- **Data Integrity**: 100% accuracy in backup/restore testing

### **Continuing Education**

#### **Advanced Training Modules**
1. **Performance Tuning**: Optimizing processing speed and resource usage
2. **Batch Processing**: Managing large-scale analysis workflows
3. **Integration**: Connecting with external systems and databases
4. **Customization**: Modifying processing parameters and workflows

#### **Certification Maintenance**
- **Annual Recertification**: Review updated procedures and features
- **Continuing Education**: 8 hours of training per year recommended
- **Skills Assessment**: Practical testing every 2 years
- **Technology Updates**: Stay current with software updates

---

## **📋 MODULE 5: QUICK REFERENCE & CHEAT SHEETS**

### **Command Quick Reference**

#### **Daily Operations**
```bash
# Start NeuroInsight
./start.sh

# Check status
./status.sh

# Stop services
./stop.sh

# Restart services
./restart.sh
```

#### **Troubleshooting Commands**
```bash
# Check system resources
free -h && df -h .

# View logs
tail -50 neuroinsight.log

# Check Docker services
docker ps

# Restart Docker
sudo systemctl restart docker
```

#### **Maintenance Commands**
```bash
# Clean temporary files
find data/temp -mtime +7 -delete

# Backup data
./backup_neuroinsight.sh

# Check license
./check_license.sh

# Update system
sudo apt update && sudo apt upgrade -y
```

### **File Format Reference**

#### **Supported Input Formats**
| Format | Extension | Notes |
|--------|-----------|-------|
| NIfTI | `.nii`, `.nii.gz` | Preferred format, fastest processing |
| DICOM | `.dcm`, `.dicom` | Single file or directory |
| Compressed | `.zip`, `.tar.gz` | Must contain supported formats |

#### **T1 Filename Indicators**
Valid indicators: `t1`, `t1w`, `t1-weighted`, `mprage`, `spgr`, `tfl`, `tfe`, `fspgr`

### **Error Code Reference**

| Error Code | Meaning | Action Required |
|------------|---------|-----------------|
| 400 | Bad Request | Check input data format |
| 413 | File Too Large | Compress or split file |
| 500 | Server Error | Check logs, restart services |
| 503 | Service Unavailable | Wait and retry |

### **System Requirements Quick Check**

#### **Minimum Requirements**
- RAM: 8GB (16GB recommended)
- Storage: 50GB free (100GB recommended)
- CPU: 4 cores (8+ recommended)
- Network: 10 Mbps stable connection

#### **Software Versions**
- Python: 3.8 - 3.12
- Docker: 20.10+
- Linux: Ubuntu 18.04+, CentOS 7+

---

## Support and Resources

### **Documentation Library**
- **[TROUBLESHOUTING.md](TROUBLESHOUTING.md)**: Detailed technical solutions
- **[FAQ.md](FAQ.md)**: Frequently asked questions
- **[README.md](README.md)**: Project overview and installation
- **[INSTALL.md](INSTALL.md)**: Step-by-step installation guide

### **Community Support**
- **GitHub Issues**: Report bugs and request features
- **Discussion Forums**: Share experiences and solutions
- **User Community**: Connect with other NeuroInsight users

### **Professional Support**
- **Training Workshops**: Scheduled training sessions
- **Consulting Services**: Custom deployment assistance
- **Priority Support**: Enterprise support options

---

## **🎓 TRAINING COMPLETION CERTIFICATE**

**Upon completion of this training guide, users should be able to:**

✅ **Deploy NeuroInsight** on compatible Linux systems
✅ **Process MRI scans** with confidence and accuracy
✅ **Troubleshoot issues** using systematic problem-solving
✅ **Maintain system health** through regular procedures
✅ **Ensure data security** and compliance requirements
✅ **Optimize performance** for efficient processing

**Remember**: Safe and effective use of NeuroInsight requires ongoing learning and adherence to best practices. Regular system maintenance and staying current with updates are essential for optimal performance.

---

**🎉 Congratulations on completing NeuroInsight training!** Questions? Check the [FAQ](FAQ.md) or create an issue.