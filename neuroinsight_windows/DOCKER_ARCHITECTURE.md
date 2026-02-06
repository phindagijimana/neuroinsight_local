# Docker Architecture on Windows

## TL;DR

**Q: Do we need a separate Docker image for Windows?**  
**A: NO! We use the same Linux image. This is standard practice.**

## How Docker Works on Different Platforms

### Linux (Native)
```
Linux Host
└─ Docker Engine (native)
   └─ Linux Container
      └─ NeuroInsight (Linux binaries)
```

### Windows (Docker Desktop + WSL2)
```
Windows 10/11
└─ Docker Desktop
   └─ WSL2 (Lightweight Linux VM)
      └─ Docker Engine (Linux)
         └─ Linux Container
            └─ NeuroInsight (same Linux binaries!)
```

### macOS (Docker Desktop + VM)
```
macOS
└─ Docker Desktop
   └─ Linux VM (Hypervisor)
      └─ Docker Engine (Linux)
         └─ Linux Container
            └─ NeuroInsight (same Linux binaries!)
```

**Key insight:** Docker Desktop on Windows and Mac both run a Linux VM behind the scenes!

## Two Types of Containers on Windows

### Option 1: Linux Containers (What We Use) ✅

**Image base:**
```dockerfile
FROM python:3.10-slim  # Linux (Debian)
```

**Who uses this:**
- 95%+ of all Docker usage on Windows
- All major cloud platforms (AWS, Azure, GCP)
- Development tools (Node.js, Python, databases)
- CI/CD systems (GitHub Actions, GitLab CI)

**Examples:**
- PostgreSQL → Linux container
- Redis → Linux container
- Node.js → Linux container
- Python apps → Linux container
- **NeuroInsight** → Linux container

**Advantages:**
- ✅ Same image runs on Linux, Windows, Mac
- ✅ Huge ecosystem (Docker Hub has millions of Linux images)
- ✅ Smaller image sizes
- ✅ Better performance
- ✅ Free (no Windows licensing)
- ✅ Industry standard

### Option 2: Windows Containers (We DON'T Use) ❌

**Image base:**
```dockerfile
FROM mcr.microsoft.com/windows/servercore:ltsc2022  # Windows
```

**Who uses this:**
- Legacy .NET Framework apps (can't run on .NET Core/Linux)
- Windows-specific services (IIS, MSMQ, etc.)
- Corporate environments locked into Windows Server

**Examples:**
- Old ASP.NET apps (pre-.NET Core)
- Windows Services
- COM+ applications

**Disadvantages for our use case:**
- ❌ FreeSurfer is Linux-only (no Windows version)
- ❌ Huge images (10-20GB base vs 100MB for Linux)
- ❌ Can't run on Linux or Mac
- ❌ Requires Windows Server license
- ❌ Less tooling/support
- ❌ Performance overhead

## Why Our Approach is Standard

### 1. FreeSurfer is Linux-Only

FreeSurfer has NO Windows version:
```bash
# FreeSurfer officially supports:
- Linux (CentOS, Ubuntu, Debian)
- macOS (via Linux compatibility layer)

# FreeSurfer does NOT support:
- Windows (no native build exists)
```

**Our only option:** Run Linux container with FreeSurfer Linux binaries

### 2. Docker Hub Statistics

Docker Hub image types:
- **Linux containers:** ~99% of all images
- **Windows containers:** ~1% of all images

Top 10 most-pulled images (all Linux):
1. nginx
2. redis
3. postgres
4. mysql
5. node
6. python
7. ubuntu
8. httpd
9. mongo
10. alpine

### 3. Cloud Platform Default

All major cloud platforms default to Linux containers:

**AWS ECS/Fargate:**
- Default: Linux containers
- Windows: Available but requires specific instance types

**Azure Container Instances:**
- Default: Linux containers
- Windows: Available but costs 2-3x more

**Google Cloud Run:**
- Only supports: Linux containers
- No Windows container support at all

### 4. Development Tools

Docker Desktop for Windows **defaults to Linux containers**:

```powershell
# After installing Docker Desktop on Windows:
docker --version
# Docker version 24.0.x, build xxx

docker system info | findstr "OSType"
# OSType: linux  ← Default!
```

To use Windows containers, you must explicitly switch:
```powershell
# Not the default! Requires manual switch:
& 'C:\Program Files\Docker\Docker\DockerCli.exe' -SwitchDaemon
```

## Technical Details: How It Works

### Docker Desktop Architecture on Windows

```
┌─────────────────────────────────────────┐
│         Windows 10/11 Host              │
├─────────────────────────────────────────┤
│  Docker Desktop                         │
│  ├─ Docker CLI (Windows .exe)           │
│  ├─ Docker API Proxy                    │
│  └─ WSL2 Integration                    │
│     ↓                                   │
│  ┌──────────────────────────────────┐  │
│  │  WSL2 (Windows Subsystem Linux)   │  │
│  │  ├─ Lightweight Linux Kernel       │  │
│  │  ├─ Docker Engine (Linux)          │  │
│  │  └─ Linux Containers               │  │
│  │     └─ NeuroInsight Container     │  │
│  │        ├─ Python 3.10 (Linux)      │  │
│  │        ├─ FreeSurfer (Linux)       │  │
│  │        └─ All services             │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Port Mapping

Windows apps can access container ports transparently:

```
User's Browser (Windows)
        ↓
http://localhost:8000  ← Windows network
        ↓
Docker Desktop (port forwarding)
        ↓
WSL2 Linux VM:8000  ← Linux network
        ↓
Container:8000  ← Container network
        ↓
NeuroInsight Backend
```

### Volume Mapping

Windows paths are automatically translated:

```powershell
# User sees Windows path:
C:\Users\John\AppData\Local\Docker\volumes\neuroinsight-data

# Docker Desktop translates to WSL2:
/mnt/c/Users/John/AppData/Local/Docker/volumes/neuroinsight-data

# Container sees Linux path:
/data
```

## Comparison with Competitors

### Similar Medical Imaging Software

**FreeSurfer:**
- Platform: Linux (native) + Mac (via Linux)
- Windows: Not supported
- Recommendation: Use WSL2 or VM

**FSL (FMRIB):**
- Platform: Linux (native) + Mac
- Windows: Via WSL2 or VM only

**AFNI:**
- Platform: Linux (native) + Mac
- Windows: Via WSL2 recommended

**3D Slicer:**
- Platform: Native builds for Windows, Linux, Mac
- But uses Linux containers for some processing pipelines

### Industry Pattern

**Medical imaging software overwhelmingly uses Linux** because:
- Academic origins (most HPC clusters run Linux)
- Better performance for compute-intensive tasks
- Easier to deploy on research clusters
- Standard in neuroimaging community

## Our Decision: Why Linux Containers

### Requirements Analysis

```
✓ Must run FreeSurfer          → Requires Linux
✓ Must work on Windows         → Docker Desktop + WSL2 = solved
✓ Must work on Linux           → Native Linux
✓ Must work on macOS           → Docker Desktop + VM = solved
✓ Single deployment model      → Same Linux image everywhere
✓ Easy updates                 → One image to maintain
✓ Minimize image size          → Linux base = 100MB, Windows = 10GB
✓ No licensing costs           → Linux = free
```

**Verdict:** Linux containers are the ONLY viable option.

## Common Questions

### Q: Does this make Windows a "second-class citizen"?

**A: No!** Linux containers on Windows via Docker Desktop is the industry standard:
- Microsoft actively develops and supports WSL2
- Docker Desktop for Windows is officially supported
- Most Windows developers use Linux containers daily
- Major companies (Microsoft, Amazon, Google) all do this

### Q: Is there a performance penalty?

**A: Minimal.** WSL2 uses hardware virtualization:
- Near-native Linux performance
- Direct CPU/memory access
- Negligible overhead (<5%)
- Much faster than old Docker Toolbox (VirtualBox)

### Q: What about "pure Windows" solutions?

**A: Not possible for FreeSurfer.** FreeSurfer has no Windows build:
- 20+ years of Linux development
- Deep Linux kernel dependencies
- No Windows port planned
- Community expects Linux deployment

### Q: Do users need to know about Linux?

**A: No!** Docker abstracts this away:
- Users just run: `install.bat`
- Docker Desktop handles Linux VM
- Works transparently
- Users interact with Windows CLI

## Alternatives Considered

### Alternative 1: Native Windows Build ❌

**Idea:** Compile FreeSurfer for Windows natively

**Why rejected:**
- FreeSurfer source is complex (~500k lines)
- Heavy POSIX/Linux dependencies
- Would require months of porting effort
- Would need ongoing maintenance
- No official support from FreeSurfer team

### Alternative 2: Windows Containers ❌

**Idea:** Use Windows Server Core containers

**Why rejected:**
- FreeSurfer doesn't run on Windows
- Would still need to port FreeSurfer
- Same problems as Alternative 1
- Plus: larger images, licensing costs

### Alternative 3: Cygwin/MinGW ❌

**Idea:** Use Linux compatibility layer on Windows

**Why rejected:**
- Complex setup for users
- Incomplete POSIX support
- Performance issues
- Maintenance nightmare
- Breaks frequently with Windows updates

### Alternative 4: Virtual Machine ❌

**Idea:** Ship a pre-configured VirtualBox/VMware VM

**Why rejected:**
- Large downloads (10-20GB)
- Requires VM software installation
- More resource intensive than Docker
- Harder to update
- More complex networking

### Alternative 5: Linux Containers via Docker Desktop ✅

**Our choice!**

**Why selected:**
- FreeSurfer runs natively (Linux environment)
- Works on Windows, Mac, Linux
- Single Docker image to maintain
- Standard industry practice
- Docker handles all complexity
- Easy updates (just pull new image)
- Minimal overhead

## Conclusion

**We are using the STANDARD and RECOMMENDED approach:**

1. ✅ Linux containers on Docker Desktop
2. ✅ WSL2 provides Linux environment on Windows
3. ✅ Same image for all platforms
4. ✅ This is what 95%+ of Docker on Windows uses
5. ✅ Best practice for cross-platform deployment

**We do NOT need a separate Windows Docker image.**

**This is not a workaround - this is the proper way to do it!**

## References

- [Docker Desktop for Windows Documentation](https://docs.docker.com/desktop/windows/)
- [WSL2 Backend](https://docs.docker.com/desktop/windows/wsl/)
- [FreeSurfer System Requirements](https://surfer.nmr.mgh.harvard.edu/fswiki/SystemRequirements)
- [Windows Container vs Linux Container](https://docs.microsoft.com/en-us/virtualization/windowscontainers/about/)
