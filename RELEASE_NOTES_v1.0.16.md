# NeuroInsight v1.0.16 Release Notes

## Critical Fix: Dockerfile Path Correction

Corrects Dockerfile build paths to ensure v1.0.15 Docker socket permission fix is actually included in the image.

### Problem in v1.0.15

While v1.0.15 introduced the universal Docker socket fix in the codebase, the Docker image used incorrect file paths:
- Dockerfile copied from root `entrypoint.sh` (old version) instead of `deploy/entrypoint.sh` (new version with fix)
- Result: v1.0.15 Docker image did not include the automatic permission fix
- Impact: Users still experienced "No container runtimes available" error

### What's Fixed

**Dockerfile Path Correction:**
```dockerfile
# Before (v1.0.15):
COPY entrypoint.sh /app/entrypoint.sh

# After (v1.0.16):
COPY deploy/entrypoint.sh /app/entrypoint.sh
```

Docker image now actually contains the automatic Docker socket fix.

### Upgrade

**All users, including those on v1.0.15, should upgrade:**

```bash
docker pull phindagijimana321/neuroinsight:v1.0.16
./neuroinsight-docker stop
./neuroinsight-docker remove
./neuroinsight-docker install
```

### Verification

```bash
# Should show Docker socket configuration messages
docker logs neuroinsight 2>&1 | grep -A 5 "Docker socket"

# Should list containers without errors
docker exec neuroinsight docker ps
```

### Comparison: v1.0.15 vs v1.0.16

| Aspect | v1.0.15 | v1.0.16 |
|--------|---------|---------|
| Code has Docker fix | Yes | Yes |
| Docker image has fix | No | Yes |
| Auto-configures permissions | No | Yes |
| Startup logs show fix | No | Yes |

### Files Modified

- `deploy/Dockerfile` - Fixed COPY paths to use `deploy/` prefix
- `MACOS.md` - Added macOS Docker-in-Docker documentation

### Tested Platforms

- Ubuntu 22.04 (native Docker)
- WSL2 Ubuntu (Docker Desktop for Windows)
- Various Docker GID configurations

Note: Critical build fix. All users should upgrade to ensure Docker socket permissions work correctly.
