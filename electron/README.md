# NeuroInsight-AutoHS Desktop (Electron)

Desktop app for the Docker all-in-one deployment. The app:

1. Runs setup checks (Docker, license, ports)
2. Pulls `phindagijimana321/neuroinsight:latest` + FreeSurfer image
3. Creates/starts the `neuroinsight-autohs` container
4. Opens the web UI served from the container

**Prerequisite:** Docker Desktop must be installed and running.

## Development

```bash
cd electron
npm install
npm start
```

Place `license.txt` in the repo root (`../license.txt`) or use **Choose license.txt** in the setup screen.

## Build installers

Build on each target OS (or use CI):

```bash
cd electron
npm install

# All platforms (from macOS with wine for win — or run per OS)
npm run dist

# Per platform
npm run dist:mac     # .dmg + .zip
npm run dist:linux   # .AppImage + .deb
npm run dist:win     # NSIS .exe installer
```

Outputs go to `electron/dist/`.

### Icons (optional but recommended for release)

Add icons before building:

- `build/icon.icns` — macOS
- `build/icon.ico` — Windows
- `build/icons/` — Linux (png sizes)

Without icons, electron-builder uses the default Electron icon.

Generate from the project favicon:

```bash
# macOS with brew install png2icons imagemagick
convert ../static/favicon.svg -resize 512x512 build/icon.png
# then convert to .icns / .ico with your preferred tool
```

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

- **Docker not running** — start Docker Desktop, then click **Run checks**
- **macOS socket errors** — bundled `entrypoint.sh` is mounted automatically
- **Apple Silicon** — uses `--platform linux/amd64` automatically
- See `../deploy/DOCKER_SOCKET_FIX.md`

## Related

- CLI equivalent: `../deploy/neuroinsight-autohs-docker`
- Hub image: `phindagijimana321/neuroinsight:latest`
