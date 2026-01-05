# 🧠 FreeSurfer License Setup

**CRITICAL: Required for MRI processing functionality**

## 🚨 IMPORTANT NOTICE

**NeuroInsight cannot process MRI scans without a valid FreeSurfer license.**

The application will appear to work, but MRI analysis will fail silently or show placeholder results.

## 📋 How to Get Your FreeSurfer License

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
2. Copy the **entire contents** of `license.txt`
3. Open `freesurfer_license.txt` in the NeuroInsight directory
4. **Replace all content** with your license file content
5. Save the file

## 📁 File Location

```
neuroinsight/
├── freesurfer_license.txt  ← **REPLACE THIS FILE**
├── docker-compose.production.yml
└── [other files...]
```

## ✅ Verification

After installing the license:

```bash
# Start NeuroInsight
./setup-production-environment.sh

# Upload a test MRI file (use test_data/test_brain.nii.gz)
# Check that processing completes with real results
# Verify hippocampal volume measurements appear
```

## 🔍 What the License Enables

With a valid FreeSurfer license, NeuroInsight can perform:

- ✅ **Cortical Reconstruction**: Detailed brain surface analysis
- ✅ **Subcortical Segmentation**: Identify brain structures
- ✅ **Hippocampal Analysis**: Volume and asymmetry measurements
- ✅ **Complete MRI Processing**: Full neuroimaging pipeline

## ⚠️ Without License

- ❌ MRI processing fails silently
- ❌ No brain segmentation results
- ❌ Placeholder or missing data
- ❌ Incomplete analysis reports

## 🆘 Troubleshooting

### License Not Recognized
- Ensure you copied the **entire** license file content
- Check for extra spaces or formatting issues
- Verify the file is named exactly `freesurfer_license.txt`

### Still Not Working
- Restart the FreeSurfer container: `docker-compose restart freesurfer`
- Check container logs: `docker-compose logs freesurfer`
- Verify license file permissions: `ls -la freesurfer_license.txt`

## 📞 Support

For FreeSurfer license issues:
- FreeSurfer Registration: https://surfer.nmr.mgh.harvard.edu/registration.html
- FreeSurfer Support: https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSupport

For NeuroInsight setup:
- Check logs: `docker-compose logs neuroinsight-api`
- Verify configuration: `cat freesurfer_license.txt`
