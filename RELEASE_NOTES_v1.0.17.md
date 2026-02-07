# NeuroInsight v1.0.17 Release Notes

## UI Cleanup: Removed Debug Strings from Browser Title

This minor release removes leftover development cache-busting strings from the browser title.

## What's Fixed

**Clean Browser Tab Title:**
- Removed: `NeuroInsight-CACHE-BUST-1769124326-CACHE-BUST-1769124327 - Hippocampal Analysis Platform (v20251217170402) - CLEAN UI`
- Now shows: `NeuroInsight - Hippocampal Analysis Platform`

**Removed Debug Console Logs:**
- Cleaned up development debug messages in ViewerPage component
- Removed cache-bust test console logs

## Files Changed

- `frontend/index.html` - Updated page title
- `frontend/index.dev.html` - Updated page title
- `frontend/src/pages/ViewerPage.jsx` - Removed debug console logs

## Upgrade Instructions

### Docker Deployment

```bash
# Stop current container
./neuroinsight-docker stop

# Remove old container
./neuroinsight-docker remove

# Pull updated image
docker pull phindagijimana321/neuroinsight:latest

# Reinstall with new version
./neuroinsight-docker install
```

### Docker Compose Deployment

```bash
# Pull updated image
docker-compose pull

# Restart services
docker-compose down
docker-compose up -d
```

### Native Deployment

```bash
# Pull latest changes
git pull origin master

# Rebuild frontend
cd frontend
npm run build
cd ..

# Restart services
sudo systemctl restart neuroinsight
```

## Verification

After upgrading, verify by checking:

1. Open the application in your browser
2. Check the browser tab title - should show clean "NeuroInsight - Hippocampal Analysis Platform"
3. No more cache-bust debug strings visible

## Docker Image

- **Tag:** `phindagijimana321/neuroinsight:v1.0.17`
- **Latest:** `phindagijimana321/neuroinsight:latest`
- **Size:** ~2.5GB
- **Digest:** sha256:5d6c3344852c53049945db7ac7afd0fc8fd9e905d39bea3c3495b0646add0467

## Notes

This is a cosmetic fix with no functional changes. The application behavior remains identical to v1.0.16.
