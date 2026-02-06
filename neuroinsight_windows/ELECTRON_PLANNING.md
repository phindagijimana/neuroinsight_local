# Electron Desktop App - Cross-Platform Strategy

## Question: Will Electron app work on Windows + Linux?

**YES! Electron is inherently cross-platform.** But there are different approaches for how to handle FreeSurfer processing.

## Electron Basics

### What is Electron?
- Framework for building desktop apps using web technologies
- **Single codebase** → Build for Windows, macOS, and Linux
- Examples: VS Code, Slack, Discord, GitHub Desktop

### Build Process
```javascript
// Write once:
src/
├── main.js          // Node.js backend
├── renderer.js      // Web frontend
└── package.json

// Build for all platforms:
npm run build

// Results in:
dist/
├── NeuroInsight-Windows.exe
├── NeuroInsight-Linux.AppImage
└── NeuroInsight-Mac.dmg
```

**One codebase → Three platforms!**

## Approaches for NeuroInsight Electron App

### Approach 1: Embedded Docker (Recommended) ✅

**Architecture:**
```
Electron App
├─ Frontend (React)
├─ Backend (Node.js)
└─ Spawns Docker Containers
   └─ FreeSurfer Processing
```

**How it works:**
```javascript
// Electron app detects Docker and spawns containers
const { exec } = require('child_process');

// Check if Docker is available
exec('docker --version', (error) => {
  if (error) {
    // Fallback: Offer to install Docker Desktop
    // Or: Use bundled Apptainer (Linux only)
  } else {
    // Use Docker to spawn FreeSurfer containers
    exec('docker run freesurfer/freesurfer:7.4.1 ...');
  }
});
```

**Cross-platform behavior:**

| Platform | Method |
|----------|--------|
| **Windows** | Docker Desktop (includes WSL2) |
| **Linux** | Docker Engine (native) |
| **macOS** | Docker Desktop (includes Linux VM) |

**Advantages:**
- ✅ Same FreeSurfer container everywhere
- ✅ Consistent behavior across platforms
- ✅ Easy updates (just update Docker image)
- ✅ Leverages existing Docker infrastructure
- ✅ Can reuse `processing_docker.py` logic

**Disadvantages:**
- ❌ Requires Docker Desktop on Windows/Mac
- ❌ ~500MB Docker Desktop download
- ❌ Extra step for users (install Docker)

**User experience:**
```
User installs: NeuroInsight.exe (200MB)
               +
               Docker Desktop (500MB, if not present)
               ↓
Total: ~700MB + first-time FreeSurfer image (~7GB)
```

### Approach 2: Bundled FreeSurfer (Complex) ⚠️

**Architecture:**
```
Electron App (includes FreeSurfer binaries)
├─ Frontend (React)
├─ Backend (Node.js)
└─ Bundled FreeSurfer
   ├─ Windows: Not possible (FreeSurfer = Linux only)
   ├─ Linux: Bundle FreeSurfer binaries
   └─ macOS: Bundle FreeSurfer binaries
```

**Problems:**
- ❌ **Windows:** FreeSurfer has NO Windows version
  - Would still need WSL2 or Docker
  - Can't bundle Linux binaries in Windows .exe
- ❌ **Massive size:** FreeSurfer ~15GB installed
- ❌ **Updates:** Need to rebuild entire app for FreeSurfer updates
- ❌ **Complexity:** Different builds for each platform

**Verdict:** Not feasible due to FreeSurfer being Linux-only

### Approach 3: Hybrid (Best of Both Worlds) ✅

**Architecture:**
```
Electron App
├─ Frontend (React)
├─ Backend (Node.js)
└─ Platform-specific processing:
   ├─ Windows: Docker Desktop (auto-install WSL2)
   ├─ Linux: Native Docker or Apptainer/Singularity
   └─ macOS: Docker Desktop
```

**Implementation:**
```javascript
const os = require('os');
const platform = os.platform();

if (platform === 'win32') {
  // Windows: Use Docker Desktop
  // Check if installed, offer to install if not
  useDockerDesktop();
  
} else if (platform === 'linux') {
  // Linux: Try Docker, fallback to Apptainer
  if (hasDocker()) {
    useDocker();
  } else if (hasApptainer()) {
    useApptainer();
  } else {
    promptInstallDocker();
  }
  
} else if (platform === 'darwin') {
  // macOS: Use Docker Desktop
  useDockerDesktop();
}
```

**Advantages:**
- ✅ Cross-platform single codebase
- ✅ Optimized for each platform
- ✅ Fallback options (Apptainer on Linux)
- ✅ Can reuse existing processing code

**Disadvantages:**
- ⚠️ More complex installation flow
- ⚠️ Need to handle Docker installation prompts

## Recommended Architecture

### For NeuroInsight Electron App

```
┌─────────────────────────────────────────┐
│     Electron Shell (Cross-platform)     │
│  ┌───────────────────────────────────┐  │
│  │   Frontend (React)                │  │
│  │   - Same UI as web version        │  │
│  │   - Packaged as Electron renderer │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │   Backend (Node.js/Python)        │  │
│  │   - FastAPI or Express            │  │
│  │   - Job management                │  │
│  │   - Database (SQLite/PostgreSQL)  │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │   FreeSurfer Processing Layer     │  │
│  │   - Detect platform               │  │
│  │   - Spawn containers              │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
              ↓
    ┌─────────────────┐
    │  Docker Engine  │
    │  (via Desktop   │
    │   or native)    │
    └─────────────────┘
              ↓
    ┌─────────────────┐
    │   FreeSurfer    │
    │   Container     │
    └─────────────────┘
```

## Implementation Plan

### Phase 1: Core Electron App
```javascript
// package.json
{
  "name": "neuroinsight-desktop",
  "version": "1.0.0",
  "main": "main.js",
  "build": {
    "appId": "com.neuroinsight.desktop",
    "productName": "NeuroInsight",
    "win": {
      "target": ["nsis", "portable"]
    },
    "linux": {
      "target": ["AppImage", "deb"]
    },
    "mac": {
      "target": ["dmg", "zip"]
    }
  }
}
```

### Phase 2: Docker Integration
```javascript
// main.js
const { app, BrowserWindow } = require('electron');
const { checkDocker, installDocker } = require('./docker-manager');

app.whenReady().then(async () => {
  // Check Docker availability
  const hasDocker = await checkDocker();
  
  if (!hasDocker) {
    // Prompt user to install Docker Desktop
    const result = await dialog.showMessageBox({
      type: 'info',
      title: 'Docker Required',
      message: 'NeuroInsight requires Docker Desktop for FreeSurfer processing.',
      buttons: ['Download Docker', 'Quit']
    });
    
    if (result.response === 0) {
      // Open Docker Desktop download page
      shell.openExternal('https://www.docker.com/products/docker-desktop/');
    }
  }
  
  createWindow();
});
```

### Phase 3: FreeSurfer Processing
```javascript
// freesurfer-processor.js
const { exec } = require('child_process');
const os = require('os');

class FreeSurferProcessor {
  async process(inputPath, subjectId) {
    const platform = os.platform();
    
    if (platform === 'win32') {
      return this.processWithDocker(inputPath, subjectId);
    } else if (platform === 'linux') {
      // Try Docker first, fallback to Apptainer
      if (await this.hasDocker()) {
        return this.processWithDocker(inputPath, subjectId);
      } else if (await this.hasApptainer()) {
        return this.processWithApptainer(inputPath, subjectId);
      }
    } else if (platform === 'darwin') {
      return this.processWithDocker(inputPath, subjectId);
    }
  }
  
  async processWithDocker(inputPath, subjectId) {
    // Same Docker spawning as current implementation
    const cmd = `docker run --rm \
      -v ${inputPath}:/input \
      -v ${outputPath}:/output \
      freesurfer/freesurfer:7.4.1 \
      recon-all -s ${subjectId} -i /input/scan.nii.gz -all`;
    
    return new Promise((resolve, reject) => {
      exec(cmd, (error, stdout, stderr) => {
        if (error) reject(error);
        else resolve(stdout);
      });
    });
  }
}
```

## Cross-Platform Features

### Windows-Specific
```javascript
// Handle WSL2/Docker Desktop automatically
if (process.platform === 'win32') {
  // Check if Docker Desktop is installed
  const dockerPath = 'C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe';
  
  if (!fs.existsSync(dockerPath)) {
    // Offer to download and install
    showDockerInstallPrompt();
  } else {
    // Check if Docker Desktop is running
    exec('docker ps', (error) => {
      if (error) {
        // Docker Desktop not running, start it
        exec(`"${dockerPath}"`);
      }
    });
  }
}
```

### Linux-Specific
```javascript
// Multiple backend options
if (process.platform === 'linux') {
  const backends = await detectBackends();
  // backends = ['docker', 'apptainer', 'singularity', 'none']
  
  if (backends.length === 0) {
    // Offer installation options
    showBackendInstallDialog([
      'Docker Engine (recommended)',
      'Apptainer (no root required)'
    ]);
  }
}
```

### macOS-Specific
```javascript
// Similar to Windows (Docker Desktop)
if (process.platform === 'darwin') {
  // Check Docker Desktop for Mac
  const dockerPath = '/Applications/Docker.app';
  
  if (!fs.existsSync(dockerPath)) {
    showDockerInstallPrompt();
  }
}
```

## Packaging & Distribution

### Build Process
```bash
# Install dependencies
npm install electron electron-builder

# Build for all platforms (on CI/CD)
npm run build:win
npm run build:linux
npm run build:mac

# Or build current platform only
npm run build
```

### Output Files
```
dist/
├── NeuroInsight-Setup-1.0.0.exe        # Windows installer (200MB)
├── NeuroInsight-1.0.0.AppImage         # Linux AppImage (250MB)
├── neuroinsight_1.0.0_amd64.deb        # Debian package (250MB)
└── NeuroInsight-1.0.0.dmg              # macOS disk image (220MB)
```

### What Gets Bundled
- ✅ Electron framework (~100MB)
- ✅ Node.js runtime (~50MB)
- ✅ Frontend code (React app) (~10MB)
- ✅ Backend code (Python/Node) (~20MB)
- ✅ SQLite database (~1MB)
- ❌ FreeSurfer (downloaded separately as Docker image)
- ❌ Docker (user installs separately)

## User Experience Comparison

### Docker Deployment (Current)
```
User downloads: neuroinsight_windows.zip (10KB scripts)
User installs: Docker Desktop (500MB)
User runs: .\neuroinsight-docker.ps1 install
Downloads: NeuroInsight image (1.65GB)
          + FreeSurfer image (7GB, on first job)
Total: ~9GB
```

### Electron App (Future)
```
User downloads: NeuroInsight-Setup.exe (200MB)
User installs: NeuroInsight (auto-detects Docker)
If no Docker: Prompts to install Docker Desktop (500MB)
On first run: Downloads FreeSurfer image (7GB)
Total: ~7.7GB

Advantage: Single .exe installer, more polished UX
```

## Feature Parity

| Feature | Docker Deployment | Electron App |
|---------|-------------------|--------------|
| **Cross-platform** | ✅ Win/Linux/Mac | ✅ Win/Linux/Mac |
| **Single codebase** | ✅ | ✅ |
| **Docker required** | ✅ | ✅ (same) |
| **Auto-updates** | Manual pull | ✅ Built-in |
| **Native feel** | ❌ Web only | ✅ Desktop app |
| **Offline UI** | ❌ | ✅ |
| **Tray icon** | ❌ | ✅ |
| **Installer** | ❌ Scripts | ✅ .exe/.dmg |
| **File associations** | ❌ | ✅ .nii/.dcm |
| **Distribution** | GitHub/Zip | ✅ App stores |

## Comparison with Native Deployment

### Native (Current)
```python
# processing_desktop.py
# Uses threading + local FreeSurfer (Apptainer/Singularity)
# Platform-specific: Linux mainly, WSL2 on Windows
```

### Electron (Future)
```javascript
// Cross-platform Electron shell
// Uses Docker containers for FreeSurfer
// Works on Windows/Linux/Mac with same codebase
```

## Recommendation

**YES, build an Electron app with Docker backend!**

### Why This Approach
1. ✅ **True cross-platform:** One codebase → Win/Linux/Mac
2. ✅ **Leverage existing Docker work:** Reuse container logic
3. ✅ **Professional UX:** Native installer, auto-updates, tray icon
4. ✅ **Easier distribution:** App stores, direct downloads
5. ✅ **Same FreeSurfer:** Uses tested Docker containers

### Development Path
1. **Start:** Electron shell + React frontend
2. **Backend:** Node.js or Python (FastAPI via subprocess)
3. **Processing:** Spawn Docker containers (reuse existing code)
4. **Build:** `electron-builder` for all platforms
5. **Test:** Windows 10/11, Ubuntu 22.04, macOS 12+

### Timeline Estimate
- **Phase 1:** Electron shell + UI (2 weeks)
- **Phase 2:** Docker integration (1 week)
- **Phase 3:** Cross-platform testing (1 week)
- **Phase 4:** Installers + distribution (1 week)
- **Total:** ~5 weeks for MVP

## Next Steps

1. Create `neuroinsight_electron/` folder
2. Set up Electron + React boilerplate
3. Port web UI to Electron renderer
4. Implement Docker detection/spawning
5. Build platform-specific installers
6. Test on all platforms
7. Publish to GitHub Releases or app stores

## Code Reuse

From existing deployments:
- ✅ Frontend: Reuse React app 100%
- ✅ Backend: Port FastAPI → Express or keep FastAPI
- ✅ Processing: Reuse Docker spawning logic 90%
- ✅ Database: Switch PostgreSQL → SQLite for portability

**Estimated code reuse: 70-80%**
