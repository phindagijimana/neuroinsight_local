# NeuroInsight v1.0.27 Release Notes

## Multiple Fixes and Improvements

This release includes bug fixes for PDF reports, Python 3.13 compatibility, and native installation improvements.

### PDF Report Fix

**Fixed: Removed unnecessary 180° rotation in PDF reports**

- PDF coronal images were being rotated 180° after visualization.py already corrected orientation
- This caused images to appear in wrong orientation (back to upside-down)
- Now PDF reports show images in correct anatomical orientation
- Matches web viewer display (after viewer's vertical flip)

**Changed:**
- `backend/api/reports.py` - Removed `.rotate(180)` calls on anatomical and overlay images
- Updated report text to remove misleading "rotated 180 degrees for optimal viewing" statement

### Python 3.13 Compatibility

**Added: Full Python 3.13 support**

Updated scientific computing packages to support Python 3.9-3.13:
- `numpy: 1.26.4 → 2.2.3` (Python 3.13 support with pre-built wheels)
- `pandas: 2.1.4 → 2.2.3` (fixes C API compatibility errors)
- `scipy: 1.11.4 → 1.15.2` (Python 3.13 compatible)
- `nibabel: 5.1.0 → 5.3.2` (updated for compatibility)

**Why this matters:**
- pandas 2.1.4 failed to build on Python 3.13 with error:
  ```
  error: too few arguments to function '_PyLong_AsByteArray'
  ```
- New versions are tested and compatible with Python 3.13's new C API

**Added to install.sh:**
- Python 3.13 detection and warning
- Recommends Python 3.10-3.12 if issues occur
- Tested compatibility range: Python 3.9-3.13

### Native Installation Improvements

**Fixed: HOST_*_DIR environment variables in native mode**

Native installations no longer set `HOST_UPLOAD_DIR` or `HOST_OUTPUT_DIR` in `.env`:
- These variables are only for Docker-in-Docker deployments
- Native mode uses auto-detection from `~/.local/share/neuroinsight/`
- Fixes exit code 125 errors: `create $(pwd)/data/outputs/...`

**Added: Auto-detection of broken .env files**

The `install.sh` script now:
1. Detects broken `.env` files with literal `$(pwd)`, `$HOME`, or `${HOME}`
2. Backs up old `.env` to `.env.backup`
3. Creates fresh `.env` with correct configuration
4. Shows clear message about what was fixed

**For existing users:**
```bash
git pull origin master
./neuroinsight install  # Auto-detects and fixes broken .env
./neuroinsight restart
```

**Added: UPDATING.md documentation**

Comprehensive update guide for existing users:
- Quick update commands
- Python 3.13 migration steps
- Troubleshooting for common issues
- Version checking commands

## Docker Deployment

**No changes required** - Docker deployments:
- Already use auto-detection (not affected by `.env` issues)
- Now include PDF rotation fix
- Now include Python 3.13 compatible dependencies

## Files Changed

- `backend/api/reports.py` - Removed 180° rotation
- `requirements.txt` - Updated for Python 3.13
- `scripts/install.sh` - Auto-detect broken .env, Python 3.13 warning
- `UPDATING.md` - New: comprehensive update guide

## Version

v1.0.27
