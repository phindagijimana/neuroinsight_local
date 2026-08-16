# NeuroInsight-AutoHS Desktop (Electron)

Desktop app for the Docker all-in-one deployment. On launch it connects to an existing container or runs setup in the background, then opens the web UI. A splash screen appears only when user action is needed (Docker not running, license missing, etc.).

1. Connects immediately if NeuroInsight-AutoHS is already running
2. Otherwise pulls `phindagijimana321/neuroinsight-autohs:latest` + FreeSurfer and starts the container quietly
3. Opens the web UI automatically when ready

**Prerequisite:** Docker Desktop must be installed and running.

### macOS first launch (Gatekeeper)

The desktop app is not notarized yet. If macOS blocks the app on first open:
- **Right-click** **NeuroInsight-AutoHS** → **Open**, or
- Install from the release **`.dmg`**, then approve the app in **System Settings → Privacy & Security**.

## Development

```bash
cd electron
npm install
npm start
```

Place `license.txt` in the repo root (`../license.txt`) or use **Choose license.txt** in the setup screen.

## Build installers

Build on each target OS (or use [GitHub Actions](https://github.com/phindagijimana/neuroinsight_local/actions/workflows/electron-build.yml) — see below):

```bash
cd electron
npm install

# Per platform
npm run dist:mac     # .dmg + .zip
npm run dist:linux   # .AppImage + .deb
npm run dist:win     # NSIS .exe installer
```

Outputs go to `electron/dist/`.

## Publish to GitHub Releases

CI builds all three platforms and attaches installers to a GitHub Release when you push a tag:

```bash
# 1. Set version in electron/package.json (e.g. 1.1.0)
# 2. Commit, then tag and push:
git tag desktop-v1.1.0
git push origin desktop-v1.1.0
```

The workflow [`.github/workflows/electron-build.yml`](../.github/workflows/electron-build.yml) runs on `desktop-v*` tags. Download from [Releases](https://github.com/phindagijimana/neuroinsight_local/releases).

`workflow_dispatch` on that workflow builds artifacts for testing without creating a release.

### Icons

Brand icons (dark navy **NI-AutoHS**, `#003d7a`) are in `electron/build/`:

| File | Platform |
|------|----------|
| `icon.icns` | macOS |
| `icon.ico` | Windows |
| `icons/` | Linux (256×256, 512×512 PNG) |
| `icon.svg` | Source artwork |

After editing `icon.svg`, regenerate raster assets and run `npm run dist:*` so installers pick up the new icon.

## License locations (checked in order)

1. App user data: `license.txt` (saved via file picker)
2. Repo root `../license.txt` (dev mode only)
3. `~/Documents/license.txt`
4. `~/license.txt`

## Architecture

```
electron/
  src/
    main.js              # Window + IPC
    preload.js           # electronAPI bridge
    orchestrator/        # Docker lifecycle (mirrors neuroinsight-autohs-docker)
  renderer/
    setup.html           # First-run / checks UI
  dist/                  # Built installers (gitignored)
```

The container serves the NeuroInsight-AutoHS frontend. The app injects `window.BACKEND_URL` for API calls.

## Troubleshooting

- **macOS Gatekeeper** — if the app won't open, **right-click → Open**, or install from the release `.dmg` and approve in **System Settings → Privacy & Security**
- **Docker not running** — start Docker Desktop, then click **Run checks**
- **macOS socket errors** — bundled `entrypoint.sh` is mounted automatically
- **Apple Silicon** — uses `--platform linux/amd64` automatically
- See `../deploy/DOCKER_SOCKET_FIX.md`

## Related

- CLI equivalent: `../deploy/neuroinsight-autohs-docker`
- Hub image: `phindagijimana321/neuroinsight-autohs:latest`
