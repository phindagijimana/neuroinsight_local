# NeuroInsight v1.0.19 Release Notes

## Critical Fixes for WSL/Docker Desktop FreeSurfer Processing

Fixes two critical bugs that prevented FreeSurfer processing on WSL and Docker Desktop.

### Problems Fixed

**Issue 1: Volume Path Detection (v1.0.18)**
- FreeSurfer jobs failed with "cannot find /input/filename.nii"
- Hardcoded volume paths didn't work on WSL/Docker Desktop
- Fixed by removing hardcoded paths and enabling auto-detection

**Issue 2: Subprocess Module Variable Scope (v1.0.19)**
- Jobs crashed with "local variable 'subprocess_module' referenced before assignment"
- Redundant local imports shadowed global import when auto-detection path wasn't taken
- Fixed by removing redundant local imports

### Changes

**v1.0.19 (this release):**
- Removed redundant `import subprocess as subprocess_module` statements in mri_processor.py (lines 2647, 5120)
- Fixed variable scope issue that caused jobs to crash during FreeSurfer processing

**v1.0.18:**
- Removed hardcoded `HOST_UPLOAD_DIR` and `HOST_OUTPUT_DIR` from deployment scripts
- Enabled automatic host path detection from container mounts
- Works universally on native Linux, WSL2, and Docker Desktop

### Upgrade

**Docker (neuroinsight-docker script):**
```bash
cd ~/neuroinsight_local/deploy
git pull origin master
./neuroinsight-docker stop
./neuroinsight-docker remove
docker pull phindagijimana321/neuroinsight:latest
./neuroinsight-docker install
```

**Docker Compose:**
```bash
cd ~/neuroinsight_local/deploy
git pull origin master
docker-compose pull
docker-compose down
docker-compose up -d
```

**Native:**
```bash
cd ~/neuroinsight_local
git pull origin master
sudo systemctl restart neuroinsight
```

### Verification

After upgrading, submit a test job:
1. Upload a NIfTI file
2. Enter patient information
3. Submit for processing
4. Job should complete successfully

Check logs for auto-detection:
```bash
docker logs neuroinsight 2>&1 | grep -i "detected.*path\|using.*path"
```

### Technical Details

**Files Modified:**
- `pipeline/processors/mri_processor.py` - Removed redundant local subprocess imports
- `deploy/neuroinsight-docker` - Removed hardcoded HOST_*_DIR variables
- `deploy/docker-compose.yml` - Removed hardcoded environment variables

**Root Cause:**
When HOST_UPLOAD_DIR was removed, the conditional block containing a local `import subprocess as subprocess_module` was never executed. Python treats variables with local imports as local scope throughout the function, shadowing the global import and causing "referenced before assignment" errors when the variable is used later in the function.

### Tested Platforms

- Ubuntu 22.04 (native Docker)
- WSL2 (Ubuntu on Windows 11 with Docker Desktop)
- Docker Desktop for Windows

Note: Critical fix for all WSL/Docker Desktop users. Upgrade immediately to enable FreeSurfer processing.
