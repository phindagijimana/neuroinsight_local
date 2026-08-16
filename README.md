# NeuroInsight-AutoHS

**NeuroInsight-AutoHS** is the web application ([neuroinsight_local](https://github.com/phindagijimana/neuroinsight_local)) for automated hippocampal segmentation and analysis from T1-weighted MRI — dashboard, job queue, PDF reports, and deployment tooling.

It uses the **[AutoHS pipeline](https://github.com/phindagijimana/AutoHS)** for processing: a two-step workflow (FreeSurfer → AI post-processing and reporting) defined in the separate [AutoHS repository](https://github.com/phindagijimana/AutoHS).

| Name | Repository | What it is |
|------|------------|------------|
| **NeuroInsight-AutoHS** | This repo (`neuroinsight_local`) | Web UI, API, Celery workers, deployment |
| **AutoHS** | [AutoHS](https://github.com/phindagijimana/AutoHS) | Pipeline specification, CLI, and BIDS App |

## Deployment options

Choose **one** way to run NeuroInsight-AutoHS:

| | **Native** | **Docker** | **Desktop** |
|---|------------|------------|-------------|
| **Best for** | Ubuntu / WSL2 servers | macOS, Linux, shared servers | macOS, Windows, Linux (GUI users) |
| **Requires** | Ubuntu 20.04+, systemd | Docker Desktop or Engine | Docker Desktop + installer or dev build |
| **Install** | `./neuroinsight-autohs install` | `./neuroinsight-autohs-docker setup` | Download `.dmg` / `.exe` / `.AppImage`, or `npm start` |
| **Manage** | `./neuroinsight-autohs start\|stop\|status` | `./neuroinsight-autohs-docker …` | App menu + Docker in background |
| **Data** | `~/.local/share/neuroinsight-autohs/` | Docker volume `neuroinsight-autohs-data` | Same Docker volume as Docker option |
| **Docs** | [Commands](#commands-native-linux) below | [`deploy/README_DOCKER.md`](deploy/README_DOCKER.md) | [`electron/README.md`](electron/README.md) |

All three options need a **FreeSurfer license** (`license.txt`) for real MRI processing. See [FreeSurfer setup](#freesurfer-setup).

---

### Option 1 — Native (Linux / WSL2)

Direct installation with systemd services on Ubuntu 20.04+ (or WSL2).

```bash
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local

./neuroinsight-autohs check-wsl    # optional, WSL only
./neuroinsight-autohs install      # one-time setup
./neuroinsight-autohs license      # place or verify license.txt
./neuroinsight-autohs start

# Open http://localhost:8000
```

---

### Option 2 — Docker (Linux & macOS)

Single all-in-one container. Image: `phindagijimana321/neuroinsight-autohs:latest`.

```bash
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local/deploy

# license.txt — one of:
#   ../license.txt
#   ~/Documents/license.txt
#   ~/license.txt

./neuroinsight-autohs-docker check     # verify license, Docker, ports
./neuroinsight-autohs-docker setup     # pull image, start container
./neuroinsight-autohs-docker status    # URL and health
```

`setup` automatically pulls the image and FreeSurfer, picks free ports, mounts the Docker socket for FreeSurfer jobs, and uses `--platform linux/amd64` on Apple Silicon.

More detail: [`deploy/README_DOCKER.md`](deploy/README_DOCKER.md) · [`deploy/DEPLOYMENT_GUIDE.md`](deploy/DEPLOYMENT_GUIDE.md)

---

### Option 3 — Desktop app (Electron)

GUI launcher that runs the same Docker all-in-one container. Shows a splash only when something needs your attention (Docker stopped, license missing, etc.).

**Prerequisites:** Docker Desktop installed and running.

**Download installers:** [GitHub Releases](https://github.com/phindagijimana/neuroinsight_local/releases) — assets on tags `desktop-v*` (e.g. [`desktop-v1.1.2`](https://github.com/phindagijimana/neuroinsight_local/releases/tag/desktop-v1.1.2))

| Platform | Installers |
|----------|------------|
| macOS (Apple Silicon) | `.dmg`, `.zip` |
| Linux | `.AppImage`, `.deb` |
| Windows | `.exe` (NSIS) |

**From source (development):****

```bash
cd electron
npm install
npm start
```

**Build installers:**

```bash
cd electron
npm install
npm run dist:mac      # macOS .dmg + .zip
npm run dist:linux    # AppImage + .deb
npm run dist:win      # Windows NSIS installer
```

Outputs: `electron/dist/` (e.g. `NeuroInsight-AutoHS.app`, `.dmg`).

Place `license.txt` in the repo root (`../license.txt`) or choose it in the setup screen. Full details: [`electron/README.md`](electron/README.md).

---

## Requirements

- **Native:** Ubuntu 20.04+ (or WSL2), Redis, 16 GB+ RAM (32 GB recommended), 4+ CPU cores, 50 GB storage
- **Docker / Desktop:** Docker Desktop or Engine, same RAM/storage guidance
- **All:** FreeSurfer license (free for research)

## FreeSurfer setup

1. Register at https://surfer.nmr.mgh.harvard.edu/registration.html
2. Save the file as `license.txt`

**Native:** project root `neuroinsight_local/license.txt`  
**Docker / Desktop:** `../license.txt`, `~/Documents/license.txt`, or `~/license.txt`

Example layout:

```
neuroinsight_local/
├── neuroinsight-autohs      # native CLI
├── license.txt
├── deploy/
│   └── neuroinsight-autohs-docker
├── electron/                # desktop app
└── data/
```

## File requirements

T1-weighted MRI only. Filenames must contain: `t1`, `t1w`, `t1-weighted`, `mprage`, `spgr`, `tfl`, `tfe`, or `fspgr`.

Supported formats: NIfTI (`.nii`, `.nii.gz`).

## Commands (native Linux)

| Command | `./neuroinsight-autohs` |
|---------|-------------------------|
| Install | `install` |
| Start / stop | `start` · `stop` |
| Status / health | `status` · `monitor` |
| Logs | `logs` |
| Clean jobs | `clean` |
| Recover job | `bring <job_id>` |
| License | `license` |
| Sleep prevention | `nosleep` |

```bash
./neuroinsight-autohs install
./neuroinsight-autohs start
./neuroinsight-autohs status
./neuroinsight-autohs logs
./neuroinsight-autohs clean
./neuroinsight-autohs bring <job_id>
```

## Hippocampal asymmetry & HS classification

Same thresholds as the AutoHS pipeline:

**Volume laterality** (±0.05): Left > Right if AI > 0.05; Right > Left if AI < −0.05; symmetric between.

**HS classification:** Right HS if AI > 0.046915816971433; Left HS if AI < −0.070839747728063; otherwise Balanced (No HS).

See [AutoHS](https://github.com/phindagijimana/AutoHS) for the full pipeline spec.

## Further documentation

- [User Guide](docs/USER_GUIDE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Docker deployment](deploy/README_DOCKER.md)
- [Desktop app](electron/README.md)
- [AutoHS pipeline](https://github.com/phindagijimana/AutoHS)

## License

MIT License. FreeSurfer requires a separate license for research use.

© 2025 University of Rochester. All rights reserved.
