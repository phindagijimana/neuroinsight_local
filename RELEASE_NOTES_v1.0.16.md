# NeuroInsight v1.0.16 Release Notes

**Release Date:** February 7, 2026  
**Docker Image:** `phindagijimana321/neuroinsight:v1.0.16`  
**Critical Fix:** Dockerfile Path Correction for Docker Socket Fix

---

## Critical Fix: Docker Image Build Path

### Problem in v1.0.15

While v1.0.15 introduced the universal Docker socket permission fix in the codebase, the Docker image was built using the **wrong entrypoint.sh file**:

- **Issue:** Dockerfile copied from root `entrypoint.sh` (old version without fix)
- **Should copy:** `deploy/entrypoint.sh` (new version with fix)
- **Result:** v1.0.15 Docker image didn't include the automatic permission fix
- **Impact:** Users still experienced "No container runtimes available" error

### What's Fixed in v1.0.16

**Dockerfile Path Correction:**
```dockerfile
# Before (v1.0.15):
COPY entrypoint.sh /app/entrypoint.sh           # Wrong - copies old file
COPY supervisord.conf /etc/supervisor/conf.d/   # Wrong path
COPY healthcheck.sh /app/healthcheck.sh         # Wrong path

# After (v1.0.16):
COPY deploy/entrypoint.sh /app/entrypoint.sh           # Correct
COPY deploy/supervisord.conf /etc/supervisor/conf.d/   # Correct
COPY deploy/healthcheck.sh /app/healthcheck.sh         # Correct
```

**Now the Docker image actually contains the automatic Docker socket fix!**

---

## What This Means

### Universal Docker Socket Fix Now Active

The v1.0.16 image now **actually includes** the automatic permission fix:

```bash
# At container startup (shown in logs):
Configuring Docker socket access...
  Docker socket GID: 122
  Current docker group GID: 999
  Updating docker group GID to match socket...
  ✓ Docker group updated to GID 122
  ✓ User already in docker group
  ✓ Docker access verified - FreeSurfer spawning enabled
Docker configuration complete
```

### Key Benefits

✅ **True Universal Compatibility** - Works on Linux, WSL2, and Docker Desktop  
✅ **Automatic Configuration** - No manual setup required  
✅ **Runtime GID Detection** - Adapts to any system's Docker setup  
✅ **Verified on Startup** - Tests Docker access before processing jobs  

---

## Upgrade Instructions

### For All Users (Including v1.0.15)

**Everyone should upgrade to v1.0.16:**

```bash
cd ~/neuroinsight_local/deploy

# Pull the corrected image
docker pull phindagijimana321/neuroinsight:v1.0.16

# Or use latest tag (now points to v1.0.16)
docker pull phindagijimana321/neuroinsight:latest

# Recreate container
./neuroinsight-docker stop
./neuroinsight-docker remove
./neuroinsight-docker install
```

### Verification

Check that the fix is active:

```bash
# Should show Docker socket configuration messages
docker logs neuroinsight 2>&1 | grep -A 10 "Docker socket"

# Should list containers without errors
docker exec neuroinsight docker ps

# Should show user is in docker group with correct GID
docker exec neuroinsight id neuroinsight
```

---

## What Changed

### Files Modified

**deploy/Dockerfile:**
- Fixed COPY paths to use `deploy/` prefix for config files
- Ensures latest entrypoint.sh with Docker socket fix is included
- Also includes correct supervisord.conf and healthcheck.sh

**Added:**
- `MACOS.md` - Documentation for macOS Docker-in-Docker solutions

### Why This Matters

This is a **critical build fix** that makes the v1.0.15 code changes actually work in the Docker image. Without this fix, the Docker image was still using the old entrypoint without automatic permission handling.

---

## Comparison: v1.0.15 vs v1.0.16

| Aspect | v1.0.15 | v1.0.16 |
|--------|---------|---------|
| Code has Docker fix | ✅ Yes | ✅ Yes |
| Docker image has fix | ❌ No (wrong file) | ✅ Yes (correct file) |
| Auto-configures permissions | ❌ No | ✅ Yes |
| Works on WSL2 | ❌ Hit-or-miss | ✅ Yes |
| Startup logs show fix | ❌ No | ✅ Yes |

---

## Features (Carried Over from v1.0.15)

All features from previous releases are included:
- Universal Docker socket permission fix (NOW ACTIVE)
- Command-line job deletion utility (`./neuroinsight-docker delete <job_id>`)
- Desktop application support
- Comprehensive documentation
- Enhanced troubleshooting guides

---

## Testing Results

**Tested on:**
- ✅ Ubuntu 22.04 (native Docker, socket GID 122)
- ✅ WSL2 Ubuntu (Docker Desktop for Windows)
- ✅ Various Docker GID configurations (999, 998, 122, 133)

**All tests passed:**
- Docker access configured automatically on all systems
- FreeSurfer container spawning works universally
- No "No container runtimes available" errors

---

## Technical Details

### Startup Sequence

1. Container starts with `entrypoint.sh`
2. Detects Docker socket presence and GID
3. Updates internal docker group to match
4. Adds neuroinsight user to docker group
5. Verifies Docker access works
6. Starts all services via supervisord

### Image Information

- **Version:** v1.0.16
- **Base Image:** python:3.10-slim
- **Size:** ~1.65 GB
- **Tags:** `v1.0.16`, `latest`
- **Registry:** docker.io/phindagijimana321/neuroinsight

---

## Backwards Compatibility

✅ **100% Compatible** - No breaking changes  
✅ **Data Preserved** - Existing jobs and data remain intact  
✅ **Same Commands** - All CLI commands work identically  
✅ **Same Ports** - Default ports unchanged (8000, 9000, 9001)  

---

## Documentation

- **Docker Socket Fix:** `deploy/DOCKER_SOCKET_FIX.md`
- **User Guide:** `docs/USER_GUIDE.md`
- **Troubleshooting:** `docs/TROUBLESHOOTING.md`
- **macOS Reference:** `MACOS.md`

---

## Support

**GitHub Repository:** https://github.com/phindagijimana/neuroinsight_local  
**Desktop App:** https://github.com/phindagijimana/neuroinsight_desktop  
**Issues:** https://github.com/phindagijimana/neuroinsight_local/issues

---

**Recommendation:** All users should upgrade to v1.0.16 to ensure the Docker socket permission fix is active in their containers.
