# Updating NeuroInsight

This guide helps existing users update to the latest version.

## Quick Update (Recommended)

For most users, simply run:

```bash
cd neuroinsight_local
git pull origin master
./neuroinsight install  # Auto-detects and fixes broken configs
./neuroinsight restart
```

The `install` command now automatically detects and fixes broken configurations without losing your data.

---

## Update from v1.0.26 or Earlier (Native Mode)

If you're running **native mode** (not Docker) and encounter this error:
```
FreeSurfer Docker failed (exit code: 125)
docker: Error response from daemon: create $(pwd)/data/outputs/...
```

Your `.env` file has broken path configuration. The install script will auto-fix this:

```bash
cd neuroinsight_local
./neuroinsight stop
git pull origin master
./neuroinsight install  # Detects broken .env and recreates it
./neuroinsight start
```

**What happens:**
- Install detects `HOST_UPLOAD_DIR=$(pwd)` or `HOST_UPLOAD_DIR=$HOME` in `.env`
- Backs up old `.env` to `.env.backup`
- Creates new `.env` without broken HOST_*_DIR variables
- Native mode auto-detects paths from `~/.local/share/neuroinsight/`

**Your data is safe:** Uploads, processing results, and database are preserved.

---

## Manual Update (If Auto-Fix Fails)

If the automatic fix doesn't work:

```bash
cd neuroinsight_local
./neuroinsight stop

# Remove broken .env
rm .env

# Update code
git pull origin master

# Reinstall (creates fresh .env)
./neuroinsight install

# Start services
./neuroinsight start
```

---

## Update from Python 3.9-3.12 to Python 3.13

If you upgraded Python to 3.13, update dependencies:

```bash
cd neuroinsight_local
./neuroinsight stop
git pull origin master

# Remove old venv with incompatible packages
rm -rf venv/

# Reinstall with Python 3.13 compatible packages
./neuroinsight install

./neuroinsight start
```

**New in latest version:**
- pandas: 2.1.4 → 2.2.3 (Python 3.13 compatible)
- numpy: 1.26.4 → 2.2.3 (Python 3.13 support)
- scipy: 1.11.4 → 1.15.2 (Python 3.13 compatible)

---

## Docker Deployment Updates

Docker deployments are **not affected** by the `.env` path issue. Simply:

```bash
cd neuroinsight_local/deploy
./neuroinsight-docker stop
git pull origin master
docker pull phindagijimana321/neuroinsight:latest
./neuroinsight-docker start
```

---

## Checking Your Version

```bash
cd neuroinsight_local
git log --oneline -1
```

Latest version should show one of:
- `7e3224e` - Fix: Remove HOST_*_DIR from native installation .env
- `a088279` - Add Python 3.13 compatibility
- `f139c1d` - Remove unnecessary 180° rotation in PDF reports

---

## Need Help?

If you encounter issues:

1. **Check logs:**
   ```bash
   ./neuroinsight logs
   ```

2. **Check status:**
   ```bash
   ./neuroinsight status
   ```

3. **Fresh install (preserves data):**
   ```bash
   ./neuroinsight stop
   rm .env venv/ -rf
   git pull origin master
   ./neuroinsight install
   ```

Your uploads and processing results in `~/.local/share/neuroinsight/` are always preserved.
