# NeuroInsight v1.0.26 Release Notes

## Critical Fix: $HOME Variable Expansion in Native Mode

Fixes issue where $HOME variable was not expanded in .env file during native installation, causing FreeSurfer Docker containers to fail with exit code 125.

### Problem

When running native installation (./neuroinsight install), the .env file contained:
```bash
HOST_UPLOAD_DIR=$HOME/.local/share/neuroinsight/uploads
HOST_OUTPUT_DIR=$HOME/.local/share/neuroinsight/outputs
```

The literal string `$HOME` was written to the file instead of the expanded path.

When FreeSurfer tried to mount volumes, Docker saw:
```
docker: Error response from daemon: create $HOME/.local/share/neuroinsight/outputs/...
```

This caused immediate failure with exit code 125 (invalid volume path).

### Root Cause

In v1.0.23, we changed from `$(pwd)/data/uploads` to `$HOME/.local/share/neuroinsight/uploads` for XDG compliance.

However, the heredoc in install.sh used a quoted delimiter:
```bash
cat > .env <<'EOF'  # <- Quotes prevent ALL variable expansion
HOST_UPLOAD_DIR=$HOME/.local/share/neuroinsight/uploads
EOF
```

The quoted `'EOF'` delimiter prevented shell variable expansion - both `$HOME` and `${HOME}` were written literally to the .env file instead of being expanded to the actual path (e.g., `/home/ubuntu`).

When Docker tried to mount volumes with literal `$HOME` in the path, it rejected it as invalid.

### What's Fixed

**Reverted to working path style in install.sh** (line 798-799):

Before (v1.0.23-v1.0.25):
```bash
cat > .env <<'EOF'  # Quoted delimiter prevents expansion
HOST_UPLOAD_DIR=$HOME/.local/share/neuroinsight/uploads
HOST_OUTPUT_DIR=$HOME/.local/share/neuroinsight/outputs
EOF
```

After (v1.0.26):
```bash
cat > .env <<'EOF'  # Keep quoted delimiter for safety
HOST_UPLOAD_DIR=$(pwd)/data/uploads
HOST_OUTPUT_DIR=$(pwd)/data/outputs  
EOF
```

**Why this works:**
- Uses `$(pwd)` style (proven working from backup version)
- Written as literal string `$(pwd)/data/uploads` to .env
- Python code's auto-detection in mri_processor.py resolves actual paths at runtime
- Compatible with quoted heredoc delimiter
- No variable expansion issues

### Impact

**Before v1.0.26:**
- Native installation appeared to succeed
- All FreeSurfer jobs failed immediately
- Error: "FreeSurfer Docker failed (exit code: 125)"
- Docker logs showed: "create $HOME/.local/share/neuroinsight/..."

**After v1.0.26:**
- Paths properly expanded during installation
- FreeSurfer containers mount volumes correctly
- Jobs process normally

### Changes

**File Modified:**
- `scripts/install.sh` - Lines 798-799: Changed `$HOME` to `${HOME}` for proper expansion

### Verification

After upgrading to v1.0.26, verify the fix:

1. **Check .env file:**
   ```bash
   cat ~/.local/share/neuroinsight/.env | grep HOST_
   # Should show: HOST_UPLOAD_DIR=/home/username/.local/share/...
   # NOT: HOST_UPLOAD_DIR=$HOME/.local/share/...
   ```

2. **Upload and process a test job:**
   - Should complete without exit code 125
   - FreeSurfer container should mount volumes successfully

### Upgrade Instructions

**For existing installations:**
```bash
cd /path/to/neuroinsight_local
git pull origin master

# Re-run installation to regenerate .env with correct paths
./neuroinsight stop
rm -f .env  # Remove old .env with literal $HOME
./neuroinsight install
```

**For new installations:**
```bash
git clone https://github.com/phindagijimana/neuroinsight_local.git
cd neuroinsight_local
./neuroinsight install
```

### Technical Details

**Why v1.0.23 worked in some cases:**
- If .env was manually edited to expand `$HOME`
- If installation was run with specific shell configurations
- If backup .env file from older version was used (with `$(pwd)` style paths)

**Why the backup worked:**
- Used older path style: `$(pwd)/data/uploads`
- While not ideal for XDG compliance, it did expand properly
- v1.0.26 maintains XDG compliance while ensuring expansion

### Related Issues

- Fixes regression introduced in v1.0.23
- Complements v1.0.22 (race condition fix)
- Complements v1.0.24 (job monitor fix)
- Complements v1.0.25 (orphan cleanup fix)

All four fixes (v1.0.22-v1.0.26) are required for fully functional native deployment.

## Files Changed

- `scripts/install.sh`

## Version

v1.0.26
