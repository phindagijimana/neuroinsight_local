# NeuroInsight v1.0.17 Release Notes

## Changes

Removed leftover development debug strings from browser title and console logs.

- Browser title changed from `NeuroInsight-CACHE-BUST-1769124326-CACHE-BUST-1769124327 - Hippocampal Analysis Platform (v20251217170402) - CLEAN UI` to `NeuroInsight - Hippocampal Analysis Platform`
- Removed debug console logs from ViewerPage component

## Upgrade

**Docker:**
```bash
./neuroinsight-docker stop
./neuroinsight-docker remove
docker pull phindagijimana321/neuroinsight:latest
./neuroinsight-docker install
```

**Docker Compose:**
```bash
docker-compose pull
docker-compose down
docker-compose up -d
```

**Native:**
```bash
git pull origin master
cd frontend && npm run build && cd ..
sudo systemctl restart neuroinsight
```

## Docker Image

- Tag: `phindagijimana321/neuroinsight:v1.0.17`
- Digest: `sha256:5d6c3344852c53049945db7ac7afd0fc8fd9e905d39bea3c3495b0646add0467`

Note: Cosmetic changes only. No functional differences from v1.0.16.
