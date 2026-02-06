# NeuroInsight v1.0.15 Release Notes

**Release Date:** February 6, 2026  
**Docker Image:** `phindagijimana321/neuroinsight:v1.0.15`  
**Critical Fix:** Universal Docker-in-Docker Permission Issue

---

## Critical Fix: Universal Docker Socket Permissions

### Problem Solved

This release permanently fixes the "No container runtimes available" error that prevented FreeSurfer container spawning on WSL2 and some Linux systems.

**Before v1.0.15:**
- Users experienced: "FreeSurfer processing failed: No container runtimes available"
- Required manual troubleshooting and permission fixes
- Different solutions needed for Linux vs WSL2 vs Docker Desktop
- Jobs would fail during FreeSurfer processing

**After v1.0.15:**
- Automatic Docker socket permission detection and configuration
- Works universally on Linux, WSL2, and Docker Desktop
- Zero user configuration required
- FreeSurfer spawning works out of the box

---

## What's New

### Automatic Docker Permission Configuration

The container now **automatically detects and configures** Docker socket permissions at startup:

1. **Runtime Detection:** Detects the Docker socket's actual GID at container startup
2. **Auto-Configuration:** Updates the internal docker group to match the host
3. **Verification:** Tests Docker access before starting services
4. **Universal Compatibility:** Works on any system without manual intervention

### Technical Implementation

**entrypoint.sh Enhancement:**
```bash
# At container startup:
- Detect Docker socket GID: stat -c '%g' /var/run/docker.sock
- Update docker group to match
- Add neuroinsight user to docker group
- Verify Docker access works
- Report status in logs
```

**Dockerfile Update:**
- Removed hardcoded Docker group GID (was 122, caused issues)
- Now uses placeholder GID, updated at runtime by entrypoint
- Universal compatibility across all platforms

---

## Benefits

### For Users
✅ **No troubleshooting needed** - Just works on any system  
✅ **No manual fixes** - No scripts to run, no permissions to check  
✅ **Universal solution** - Same behavior on Linux, WSL2, Docker Desktop  
✅ **Eliminates #1 support issue** - "No container runtimes available" is gone  

### For Developers
✅ **Fewer support requests** - Automatic fix eliminates common error  
✅ **Better testing** - Same image works everywhere  
✅ **Professional quality** - Industry best practice implementation  
✅ **Easier deployment** - No platform-specific instructions needed  

---

## Upgrade Instructions

### For Existing Users

**Option 1: Pull and Restart (Recommended)**
```bash
cd ~/neuroinsight_local/deploy

# Pull the new image
docker pull phindagijimana321/neuroinsight:v1.0.15

# Recreate container
./neuroinsight-docker stop
./neuroinsight-docker remove
./neuroinsight-docker install

# Permissions are now auto-configured!
```

**Option 2: Using docker-compose**
```bash
cd ~/neuroinsight_local/deploy

docker-compose pull
docker-compose down
docker-compose up -d
```

### For New Users

No special steps - just install normally:
```bash
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local/deploy
./neuroinsight-docker install

# Docker permissions work automatically!
```

---

## Verification

After upgrading, verify the fix:

### Check Container Logs
```bash
docker logs neuroinsight 2>&1 | grep -A 10 "Docker socket"
```

**Expected output:**
```
Configuring Docker socket access...
  Docker socket GID: 999
  Updating docker group GID to match socket...
  ✓ Docker group updated to GID 999
  ✓ User added to docker group
  ✓ Docker access verified - FreeSurfer spawning enabled
Docker configuration complete
```

### Test Docker Access
```bash
docker exec neuroinsight docker ps
```

Should show running containers without errors.

### Submit Test Job
1. Navigate to http://localhost:8000
2. Upload a T1-weighted NIfTI file
3. Submit for processing
4. Job should process successfully (no "No container runtimes" error)

---

## What's Fixed

### Issues Resolved
- ❌ **FIXED:** "No container runtimes available" error
- ❌ **FIXED:** FreeSurfer container spawn failures on WSL2
- ❌ **FIXED:** Docker permission denied errors
- ❌ **FIXED:** Jobs failing during FreeSurfer processing
- ❌ **FIXED:** Platform-specific Docker group ID issues

### Tested Platforms
✅ Ubuntu 20.04, 22.04, 24.04 (native)  
✅ Debian 11, 12  
✅ WSL2 (Ubuntu on Windows 10/11)  
✅ Docker Desktop for Windows  
✅ Docker Desktop for Mac (via Lima VM)  

---

## Technical Details

### Files Modified
- `deploy/entrypoint.sh` - Added automatic Docker permission detection/config
- `deploy/Dockerfile` - Changed hardcoded GID to placeholder
- `deploy/docker-compose.yml` - Removed manual group_add (now automatic)
- `deploy/neuroinsight-docker` - Simplified script (no manual GID detection)
- `docs/TROUBLESHOOTING.md` - Updated with new automatic fix info

### Image Details
- **Size:** 1.65 GB
- **Base:** Python 3.10-slim
- **Digest:** sha256:be8a9e67cd69149b42f435e42f8547d0229fecf5ba4ce601f23ee975ed28fd09
- **Tags:** `v1.0.15`, `latest`

---

## Backwards Compatibility

✅ **Fully backwards compatible** - No breaking changes  
✅ **Existing data preserved** - Upgrade in place with no data loss  
✅ **Same API** - All endpoints remain unchanged  
✅ **Same CLI** - All management commands work as before  

---

## Previous Versions

### Upgrading from v1.0.14 and earlier
- **Major improvement:** Automatic Docker socket permissions
- **No configuration changes needed:** Just pull and restart
- **All previous features retained:** This is purely additive

---

## Support

### Documentation
- **Technical Details:** `deploy/DOCKER_SOCKET_FIX.md`
- **User Guide:** `docs/USER_GUIDE.md`
- **Troubleshooting:** `docs/TROUBLESHOOTING.md`

### Getting Help
- **GitHub Issues:** https://github.com/phindagijimana/neuroinsight_local/issues
- **Desktop App Issues:** https://github.com/phindagijimana/neuroinsight_desktop/issues

### Reporting Bugs
If you still encounter Docker-related issues after upgrading:
1. Check container logs: `docker logs neuroinsight`
2. Test Docker access: `docker exec neuroinsight docker ps`
3. Report with full logs if issue persists

---

## Credits

This fix implements industry best practices for Docker-in-Docker permission handling, ensuring universal compatibility across all Docker environments.

---

**Note:** This is a critical bug fix release. All users experiencing FreeSurfer spawning issues should upgrade immediately.
