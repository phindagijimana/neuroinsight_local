# NeuroInsight v1.0.15 Release Notes

## Critical Fix: Universal Docker Socket Permissions

Fixes "No container runtimes available" error that prevented FreeSurfer container spawning on WSL2 and Linux systems.

### Changes

- Automatic Docker socket permission detection and configuration at container startup
- Runtime GID detection adapts to any system's Docker setup
- Universal compatibility across Linux, WSL2, and Docker Desktop
- No manual configuration required

### Technical Implementation

Container now automatically:
1. Detects Docker socket GID at startup
2. Updates internal docker group to match host
3. Adds neuroinsight user to docker group
4. Verifies Docker access before starting services

### Upgrade

**Docker:**
```bash
docker pull phindagijimana321/neuroinsight:v1.0.15
./neuroinsight-docker stop
./neuroinsight-docker remove
./neuroinsight-docker install
```

**Docker Compose:**
```bash
docker-compose pull
docker-compose down
docker-compose up -d
```

### Verification

Check container logs for automatic configuration:
```bash
docker logs neuroinsight 2>&1 | grep -A 5 "Docker socket"
```

Test Docker access:
```bash
docker exec neuroinsight docker ps
```

### Files Modified

- `deploy/entrypoint.sh` - Added automatic Docker permission detection
- `deploy/Dockerfile` - Changed hardcoded GID to runtime placeholder
- `deploy/docker-compose.yml` - Removed manual group_add
- `deploy/neuroinsight-docker` - Simplified script

### Tested Platforms

- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12
- WSL2 (Ubuntu on Windows 10/11)
- Docker Desktop for Windows/Mac

Note: Critical bug fix release. All users experiencing FreeSurfer spawning issues should upgrade immediately.
