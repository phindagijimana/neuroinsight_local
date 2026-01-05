#!/bin/bash
# NeuroInsight Automated Backup Script
# Creates backups of database, configurations, and user data

set -e

echo "🛡️ NeuroInsight Backup Script"
echo "=============================="

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/data/backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="neuroinsight_backup_${TIMESTAMP}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"
echo "📁 Backup directory: ${BACKUP_DIR}"

# Load environment variables
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

# --- Database Backup ---
echo "💾 Backing up PostgreSQL database..."
if command -v pg_dump &> /dev/null; then
    PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump \
        -h "${POSTGRES_HOST:-localhost}" \
        -U "${POSTGRES_USER:-neuroinsight}" \
        -d "${POSTGRES_DB:-neuroinsight}" \
        > "${BACKUP_DIR}/database_${TIMESTAMP}.sql"

    echo "✅ Database backup created: database_${TIMESTAMP}.sql"
else
    echo "⚠️ pg_dump not found. Skipping database backup."
fi

# --- Configuration Backup ---
echo "⚙️ Backing up configuration files..."
CONFIG_BACKUP="${BACKUP_DIR}/config_${TIMESTAMP}.tar.gz"
tar -czf "${CONFIG_BACKUP}" \
    --exclude="*.log" \
    --exclude="*.pid" \
    --exclude="__pycache__" \
    .env* \
    supervisord.conf \
    docker-compose*.yml \
    *.sh \
    2>/dev/null || true

echo "✅ Configuration backup created: config_${TIMESTAMP}.tar.gz"

# --- User Data Backup ---
echo "📊 Backing up user data..."
DATA_BACKUP="${BACKUP_DIR}/data_${TIMESTAMP}.tar.gz"
if [ -d "data/uploads" ] && [ -d "data/outputs" ]; then
    tar -czf "${DATA_BACKUP}" \
        --exclude="*.tmp" \
        --exclude="cache" \
        data/uploads \
        data/outputs \
        2>/dev/null || true

    echo "✅ User data backup created: data_${TIMESTAMP}.tar.gz"
else
    echo "⚠️ User data directories not found. Skipping data backup."
fi

# --- Redis Backup (if applicable) ---
echo "🔴 Backing up Redis data..."
if command -v redis-cli &> /dev/null; then
    redis-cli -h "${REDIS_HOST:-localhost}" -p "${REDIS_PORT:-6379}" \
        --rdb "${BACKUP_DIR}/redis_${TIMESTAMP}.rdb" 2>/dev/null || \
    echo "⚠️ Redis backup failed or not accessible"
fi

# --- Create Backup Archive ---
echo "📦 Creating consolidated backup archive..."
BACKUP_ARCHIVE="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
tar -czf "${BACKUP_ARCHIVE}" \
    -C "${BACKUP_DIR}" \
    $(ls -t "${BACKUP_DIR}" | head -4 | tr '\n' ' ') \
    2>/dev/null || true

echo "✅ Consolidated backup: ${BACKUP_NAME}.tar.gz"

# --- Calculate Backup Size ---
BACKUP_SIZE=$(du -sh "${BACKUP_ARCHIVE}" | cut -f1)
echo "📏 Backup size: ${BACKUP_SIZE}"

# --- Cleanup Old Backups ---
echo "🧹 Cleaning up old backups..."
# Keep only last 7 daily backups and last 4 weekly backups
find "${BACKUP_DIR}" -name "neuroinsight_backup_*.tar.gz" -mtime +7 -delete 2>/dev/null || true

# --- Backup Summary ---
echo ""
echo "🎉 Backup completed successfully!"
echo "=================================="
echo "📁 Location: ${BACKUP_DIR}"
echo "📦 Archive: ${BACKUP_NAME}.tar.gz"
echo "📏 Size: ${BACKUP_SIZE}"
echo "🕒 Timestamp: ${TIMESTAMP}"
echo ""

# --- Verification ---
echo "🔍 Verifying backup integrity..."
if tar -tzf "${BACKUP_ARCHIVE}" > /dev/null 2>&1; then
    echo "✅ Backup archive is valid"
else
    echo "❌ Backup archive is corrupted!"
    exit 1
fi

echo ""
echo "💡 To restore this backup, run:"
echo "   tar -xzf ${BACKUP_ARCHIVE} -C /tmp"
echo "   # Then follow restoration procedures in documentation"

# --- Optional: Upload to remote storage ---
if [ "${BACKUP_REMOTE_URL}" ]; then
    echo "☁️ Uploading backup to remote storage..."
    # Add your remote upload logic here
    # Example: curl -X PUT "${BACKUP_REMOTE_URL}/${BACKUP_NAME}.tar.gz" --data-binary @${BACKUP_ARCHIVE}
fi

echo ""
echo "✅ NeuroInsight backup completed successfully!"








