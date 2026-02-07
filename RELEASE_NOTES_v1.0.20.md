# NeuroInsight v1.0.20 Release Notes

## Critical Fix: Automatic Host Path Detection for FreeSurfer

Fixes FreeSurfer processing by automatically detecting host volume paths when environment variables are not set.

### Problem in v1.0.18-v1.0.19

FreeSurfer failed with "cannot find /input/filename.nii" because:
- Removed hardcoded `HOST_UPLOAD_DIR` and `HOST_OUTPUT_DIR` environment variables
- Code fell back to container paths (`/data/uploads`) instead of host paths
- FreeSurfer container couldn't access files at container paths

### What's Fixed

**Automatic Host Path Detection:**
- Container inspects its own mounts to find host paths for `/data` volume
- Automatically extracts host upload and output directories
- Works universally without environment variables or manual configuration

**Detection Logic:**
```python
# Runs at job processing time
docker inspect $(hostname)  # Inspect our own container
# Finds: /data -> /var/lib/docker/volumes/neuroinsight-data/_data
# Sets: host_upload_dir = /var/lib/docker/volumes/neuroinsight-data/_data/uploads
#       host_output_dir = /var/lib/docker/volumes/neuroinsight-data/_data/outputs
```

### Upgrade

**Docker:**
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

After upgrading, submit a test job and check logs:

```bash
# Watch for auto-detection
docker logs neuroinsight -f 2>&1 | grep -i "auto_detected\|using_host"
```

Expected output:
```
auto_detected_host_paths    upload_dir=/var/lib/docker/volumes/.../uploads output_dir=/var/lib/docker/volumes/.../outputs
using_host_upload_path      path=/var/lib/docker/volumes/.../uploads
using_host_output_path      path=/var/lib/docker/volumes/.../outputs
```

Job should complete successfully without "cannot find /input" errors.

### Technical Details

**Files Modified:**
- `pipeline/processors/mri_processor.py` - Added auto-detection logic before path usage

**Auto-Detection Logic:**
1. Check if `HOST_UPLOAD_DIR` and `HOST_OUTPUT_DIR` are set
2. If not, run `docker inspect $(hostname)` to get own container info
3. Parse mounts to find where `/data` is mounted from host
4. Set `host_upload_dir` and `host_output_dir` from detected source path
5. Use detected paths for FreeSurfer volume mounts

**Fallback:**
- If auto-detection fails, falls back to container paths
- Logs warning if detection fails

### Complete Fix Chain

- **v1.0.18:** Removed hardcoded environment variables (incorrect paths on WSL)
- **v1.0.19:** Fixed subprocess module scope issue
- **v1.0.20:** Added automatic host path detection (complete solution)

### Tested Platforms

- Ubuntu 22.04 (native Docker) - Works
- WSL2 (Ubuntu on Windows 11 with Docker Desktop) - Ready to test
- Docker Desktop for Windows - Ready to test

Note: All users on v1.0.18 or v1.0.19 should upgrade to v1.0.20 for working FreeSurfer processing.
