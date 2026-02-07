# NeuroInsight v1.0.18 Release Notes

## Critical Fix: WSL/Docker Desktop FreeSurfer Path Issue

Fixes FreeSurfer processing failures on WSL and Docker Desktop where volume paths were incorrectly hardcoded.

### Problem

FreeSurfer jobs failed with "cannot find /input/filename.nii" error on WSL/Docker Desktop because:
- Container was created with hardcoded `HOST_UPLOAD_DIR=/var/lib/docker/volumes/...` 
- This path doesn't exist on WSL/Docker Desktop (volumes are in Docker VM)
- FreeSurfer container couldn't access input files

### What's Fixed

**Removed hardcoded volume paths:**
- deploy/neuroinsight-docker: Removed `HOST_UPLOAD_DIR` and `HOST_OUTPUT_DIR` environment variables
- deploy/docker-compose.yml: Removed hardcoded volume paths
- Now uses automatic path detection by inspecting container mounts at runtime

**How it works:**
- Container startup detects actual host paths from volume mount information
- Works universally on native Linux, WSL2, and Docker Desktop
- No manual configuration needed

### Upgrade

**Docker (neuroinsight-docker script):**
```bash
cd ~/neuroinsight_local/deploy
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
2. Submit for processing
3. Job should complete successfully (no "cannot find /input" error)

Check logs to confirm auto-detection:
```bash
docker logs neuroinsight 2>&1 | grep -i "using_host.*path\|detected.*path"
```

### Technical Details

**Files Modified:**
- `deploy/neuroinsight-docker` - Removed hardcoded HOST_*_DIR variables
- `deploy/docker-compose.yml` - Removed hardcoded environment variables

**Auto-detection logic** (already in code, now active):
- Inspects container's own mount points via `docker inspect`
- Extracts host paths from volume mount sources
- Falls back to container paths if detection fails

### Tested Platforms

- Ubuntu 22.04 (native Docker)
- WSL2 (Ubuntu on Windows 11 with Docker Desktop)
- Docker Desktop for Windows

Note: Critical fix for WSL/Docker Desktop users. All users on these platforms should upgrade immediately.
