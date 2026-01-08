#  FreeSurfer License Setup

**CRITICAL: Required for MRI processing functionality**

##  IMPORTANT NOTICE

**NeuroInsight cannot process MRI scans without a valid FreeSurfer license.**

The application will appear to work, but MRI analysis will fail silently or show placeholder results.

##  How to Get Your FreeSurfer License

### Step 1: Register for FreeSurfer
1. Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
2. Fill out the registration form
3. Submit and wait for approval (usually immediate)

### Step 2: Download License File
1. After registration, you'll receive an email with download instructions
2. Download the `license.txt` file
3. **Do NOT rename the file** - keep it as `license.txt`

### Step 3: Install License in NeuroInsight
1. Locate the downloaded `license.txt` file on your computer
2. **Copy or move** the entire `license.txt` file to the NeuroInsight project directory
3. Place it in the same folder as the other NeuroInsight files

##  File Location

```
neuroinsight_local/
├── license.txt              ← **PLACE YOUR LICENSE FILE HERE**
├── README.md
├── start.sh
├── stop.sh
└── [other NeuroInsight files...]
```

##  Verification

After installing the license:

```bash
# Verify license is properly configured
./check_license.sh

# Start NeuroInsight
./start.sh

# Upload a test MRI file
# Check that processing completes with real results
# Verify hippocampal volume measurements appear
```

##  What the License Enables

With a valid FreeSurfer license, NeuroInsight can perform:

-  **Cortical Reconstruction**: Detailed brain surface analysis
-  **Subcortical Segmentation**: Identify brain structures
-  **Hippocampal Analysis**: Volume and asymmetry measurements
-  **Complete MRI Processing**: Full neuroimaging pipeline

##  Without License

-  MRI processing fails silently
-  No brain segmentation results
-  Placeholder or missing data
-  Incomplete analysis reports

##  Troubleshooting

### License Not Recognized
- Ensure you copied the **entire** license file (not just contents)
- Check for extra spaces or formatting issues
- Verify the file is named exactly `license.txt`
- Verify the file is in the NeuroInsight project root directory

### Error: "license.txt not found"
```bash
# Copy your license file to the NeuroInsight directory
cp ~/Downloads/license.txt ./license.txt

# Edit with your license content
nano license.txt
```

### Error: "contains example content"
- Open `license.txt`
- Replace the example content with your actual license
- Remove all comment lines starting with #

### Error: "License file format incorrect"
- Ensure the file has at least 3 lines
- Check that the license content matches exactly what you received via email
- No extra spaces or characters

### Error: "Failed to validate license"
- Check file permissions: `ls -la license.txt`
- Ensure file is readable: `chmod 644 license.txt`

### Still Not Working
- Restart the FreeSurfer container: `docker-compose restart freesurfer`
- Check container logs: `docker-compose logs freesurfer`
- Verify license file permissions: `ls -la license.txt`

##  Support

For FreeSurfer license issues:
- FreeSurfer Registration: https://surfer.nmr.mgh.harvard.edu/registration.html
- FreeSurfer Support: https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSupport

For NeuroInsight setup:
- Check license: `./check_license.sh`
- Verify license file: `cat license.txt`
- Check application logs: `cat neuroinsight.log`
