# NeuroInsight-AutoHS

**NeuroInsight-AutoHS** is the deployable application for the **AutoHS** workflow inside the **NeuroInsight** platform — web and desktop UI, API, job queue, PDF reports, and deployment tooling.

**GitHub repository:** [`neuroinsight_local`](https://github.com/phindagijimana/neuroinsight_local) — the product and release name is **NeuroInsight-AutoHS** (the repo name is historical).

## NeuroInsight platform

**NeuroInsight** is the umbrella program for automated neuroimaging **workflows**. Each workflow is a defined scientific pipeline; each shipped tool follows the name **NeuroInsight-AutoHS** pattern (`NeuroInsight-<Workflow>`).

```text
NeuroInsight (platform — workflows and shared application patterns)
  └── AutoHS — hippocampal asymmetry / HS screening from T1w MRI
        └── NeuroInsight-AutoHS — this repository (app that runs AutoHS)
  └── (future workflows)
        └── NeuroInsight-<Workflow> — future tools
```

| Name | Repository | What it is |
|------|------------|------------|
| **NeuroInsight** | [Landing page](https://phindagijimana.github.io/neuroinsight_landing_web/) | Platform brand; workflow catalog (more workflows planned) |
| **AutoHS** | [AutoHS](https://github.com/phindagijimana/AutoHS) | **Workflow:** pipeline spec, CLI, BIDS App (incoming), method from the publication |
| **NeuroInsight-AutoHS** | This repo (`neuroinsight_local`) | **Tool:** UI, API, workers, deployment for AutoHS |

Processing logic for AutoHS is defined in **[AutoHS](https://github.com/phindagijimana/AutoHS)** (FreeSurfer → AI post-processing and reporting).

## Research Software and Licensing

NeuroInsight-AutoHS is **publicly available, source-available research software** — the application layer (dashboard, API, job management, reporting, deployment) for the hippocampal asymmetry method described in:

Ndagijimana P, Brennan D, Shinohara RT, Gugger JJ.
*MRI derived hippocampal asymmetry identifies hippocampal sclerosis in epilepsy surgical specimens.*
Brain Communications. 2026;8(4):fcag320.
https://doi.org/10.1093/braincomms/fcag320

The underlying pipeline is defined in [AutoHS](https://github.com/phindagijimana/AutoHS).

### Research and validation use

The source code is publicly available to support scientific research, reproducibility, independent validation, education, and evaluation on independent datasets, subject to the [LICENSE](LICENSE).

Independent validation by other research groups is encouraged. See [VALIDATION.md](VALIDATION.md).

### Commercial use

The current release is distributed under a non-commercial, source-available license. **Commercial use requires a separate commercial license.** Organizations interested in commercial deployment, hosting, integration, or products should see [COMMERCIAL.md](COMMERCIAL.md).

### Clinical status

This software is research software and has not been cleared or approved by the U.S. Food and Drug Administration as a medical device. Outputs should not be interpreted as a substitute for professional clinical judgment.

### Licensing history

The software associated with the original publication was released under the MIT License and described in the publication as open-source software.

Beginning with the first commit **after** git tag **`publication-v1.0`**, subsequent releases are distributed under the license in the current [LICENSE](LICENSE) file.

The licensing transition does not alter the terms under which earlier versions were validly distributed.

Each repository (**neuroinsight_local** and **AutoHS**) defines its own git tag **`publication-v1.0`**; see that repository’s README for the exact release commit and version.

| Release | License |
|---------|---------|
| Tag **`publication-v1.0`** (same commit as **`v1.1.5`**, `cf91038`) — publication-associated MIT implementation | MIT License |
| Commits after **`publication-v1.0`** on the default branch | PolyForm Noncommercial License 1.0.0 |

### Legacy naming (still in paths and filenames)

Older installs and scripts may use **`neuroinsight`** (CLI alias), data under `~/.local/share/neuroinsight/`, or PDF downloads named `neuroinsight_report_*.pdf`. Current commands and defaults use **`neuroinsight-autohs`** / **`neuroinsight-autohs-data`**; legacy paths are kept when they already contain your data (see deployment table below).

## Deployment options

Choose **one** way to run NeuroInsight-AutoHS:

| | **Native** | **Docker** | **Desktop** |
|---|------------|------------|-------------|
| **Best for** | Ubuntu / WSL2 servers | macOS, Linux, shared servers | macOS, Windows, Linux (GUI users) |
| **Requires** | Ubuntu 20.04+, systemd | Docker Desktop or Engine | Docker Desktop + installer or dev build |
| **Install** | `./neuroinsight-autohs install` | `./neuroinsight-autohs-docker setup` | Download `.dmg` / `.exe` / `.AppImage`, or `npm start` |
| **Manage** | `./neuroinsight-autohs start\|stop\|status` | `./neuroinsight-autohs-docker …` | App menu + Docker in background |
| **Data** | `~/.local/share/neuroinsight-autohs/` (legacy: `…/neuroinsight/` if it already holds your uploads) | Docker volume `neuroinsight-autohs-data` | Same Docker volume as Docker option |
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

**Download installers:** [GitHub Releases](https://github.com/phindagijimana/neuroinsight_local/releases) — assets on tags `desktop-v*` (e.g. [`desktop-v1.1.5`](https://github.com/phindagijimana/neuroinsight_local/releases/tag/desktop-v1.1.5))

| Platform | Installers |
|----------|------------|
| macOS (Apple Silicon) | `.dmg`, `.zip` |
| Linux | `.AppImage`, `.deb` |
| Windows | `.exe` (NSIS) |

**macOS first launch (Gatekeeper):** The desktop app is not notarized yet. If macOS blocks the app, use one of these workarounds:
- **Right-click** **NeuroInsight-AutoHS** → **Open**, or
- Install from the release **`.dmg`**, then approve the app in **System Settings → Privacy & Security**.

**From source (development):**

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
├── neuroinsight-autohs      # native CLI (primary)
├── neuroinsight             # deprecated alias → neuroinsight-autohs
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

Current releases are distributed under the [PolyForm Noncommercial License 1.0.0](LICENSE) unless you obtained an earlier release under MIT (see **Licensing history** above).

FreeSurfer and other third-party components remain subject to their respective licenses.

Copyright (c) 2025 University of Rochester. All rights reserved.
