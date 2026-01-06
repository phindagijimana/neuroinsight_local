# FreeSurfer License Setup for NeuroInsight

## Overview
NeuroInsight uses FreeSurfer for MRI brain segmentation and analysis. A valid FreeSurfer license is **required** to process MRI scans.

## Quick Setup (3 Steps)

### 1. Get Your Free License
```
Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
- Register with your academic/research email
- License is FREE for research use
- Receive license via email (usually within minutes)
```

### 2. Set Up License File
```bash
# Copy the example file
# Place your license.txt file directly in the NeuroInsight directory

# Edit the file with your license content
nano license.txt
# OR
vim license.txt

# The file should contain your license exactly as received via email
```

### 3. Verify License
```bash
# Check if license is properly configured
./check_license.sh
```

## Expected License Format

Your `license.txt` file should look like this:
```
your.email@university.edu
12345
*A1B2C3D4E5F6G7H8
```

**Important:** 
- File must be named exactly `license.txt`
- Must be in the same folder as NeuroInsight
- Do NOT include the example comments - just the license content

## License Validation

### Automatic Check on Startup
NeuroInsight automatically checks for a valid license when starting:
```bash
./start_neuroinsight.sh
# Will show: FreeSurfer license found
```

### Manual Verification
```bash
# Quick license check
./check_license.sh

# API validation (when NeuroInsight is running)
curl http://localhost:8000/api/setup/license/validate
```

## Troubleshooting

### Error: "license.txt not found"
**Solution:**
```bash
# Copy the example file
# Place your license.txt file directly in the NeuroInsight directory

# Edit with your license
nano license.txt
```

### Error: "contains example content"
**Solution:**
- Open `license.txt`
- Replace the example content with your actual license
- Remove all comment lines starting with #

### Error: "License file format incorrect"
**Solution:**
- Ensure the file has at least 3 lines
- Check that the license content matches exactly what you received via email
- No extra spaces or characters

### Error: "Failed to validate license"
**Solution:**
- Check file permissions: `ls -la license.txt`
- Ensure file is readable: `chmod 644 license.txt`

## For Production Deployment

### Directory Structure
```
neuroinsight/
├── license.txt    ← Your license goes here
├── start_neuroinsight.sh     ← Startup script (validates license)
├── check_license.sh          ← License verification
├── backend/
├── frontend/
└── ...
```

### License Security
- Keep `license.txt` in the NeuroInsight directory
- Do NOT commit real licenses to version control
- The `license.txt.example` file is safe to commit

### Batch Processing
For processing multiple scans, the same license works for all jobs.

## Support

If you encounter issues:
1. Run `./check_license.sh` for detailed diagnostics
2. Check the NeuroInsight logs: `tail -f neuroinsight.log`
3. Verify license format matches the example above

**Get your free license:** https://surfer.nmr.mgh.harvard.edu/registration.html
