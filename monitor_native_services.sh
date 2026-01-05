#!/bin/bash
# NeuroInsight Native Services Monitoring Script
# Monitors PostgreSQL, Redis, and MinIO health and performance

set -e

echo "📊 Monitoring NeuroInsight Native Services"
echo "=========================================="

# Load environment
if [ -f ".env.native" ]; then
    set -a
    source .env.native
    set +a
else
    echo "⚠️ .env.native not found, using default values"
fi

# Default values
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
REDIS_PORT="${REDIS_PORT:-6379}"
MINIO_PORT="${MINIO_PORT:-9000}"
LOG_DIR="${LOG_DIR:-./data/logs}"

# Function to check service health
check_service() {
    local service_name="$1"
    local check_command="$2"
    local expected_output="$3"

    echo "🔍 Checking ${service_name}..."
    if eval "${check_command}" 2>/dev/null | grep -q "${expected_output}"; then
        echo "   ✅ ${service_name}: HEALTHY"
        return 0
    else
        echo "   ❌ ${service_name}: UNHEALTHY"
        return 1
    fi
}

# Function to check process
check_process() {
    local pid_file="$1"
    local service_name="$2"

    if [ -f "${pid_file}" ] && kill -0 "$(cat "${pid_file}")" 2>/dev/null; then
        echo "   ✅ ${service_name}: RUNNING (PID: $(cat "${pid_file}"))"
        return 0
    else
        echo "   ❌ ${service_name}: PROCESS DEAD OR PID FILE MISSING"
        return 1
    fi
}

# Check PostgreSQL
check_service "PostgreSQL" "pg_isready -p ${POSTGRES_PORT}" "accepting connections"

# Check Redis
check_service "Redis" "redis-cli -p ${REDIS_PORT} ping" "PONG"

# Check MinIO
check_service "MinIO" "curl -f http://localhost:${MINIO_PORT}/minio/health/live" ""

echo ""
echo "📈 Performance Metrics"
echo "======================"

# PostgreSQL metrics
echo "🐘 PostgreSQL Status:"
if pg_isready -p "${POSTGRES_PORT}" >/dev/null 2>&1; then
    echo "   Active Connections:"
    psql -h localhost -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
         -c "SELECT count(*) as active_connections FROM pg_stat_activity WHERE state = 'active';" 2>/dev/null || \
         echo "   Unable to query (check credentials)"

    echo "   Database Size:"
    psql -h localhost -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
         -c "SELECT pg_size_pretty(pg_database_size('${POSTGRES_DB}')) as db_size;" 2>/dev/null || \
         echo "   Unable to query database size"
else
    echo "   PostgreSQL not accessible"
fi

# Redis metrics
echo "🔴 Redis Status:"
redis_info=$(redis-cli -p "${REDIS_PORT}" info 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "   Memory Used: $(echo "$redis_info" | grep "used_memory_human" | cut -d: -f2)"
    echo "   Connected Clients: $(echo "$redis_info" | grep "connected_clients" | cut -d: -f2)"
    echo "   Total Commands: $(echo "$redis_info" | grep "total_commands_processed" | cut -d: -f2)"
else
    echo "   Redis not accessible"
fi

# MinIO metrics
echo "📦 MinIO Status:"
if curl -f "http://localhost:${MINIO_PORT}/minio/health/live" >/dev/null 2>&1; then
    echo "   Service: Online"
    # Try to get bucket info (requires credentials)
    echo "   Buckets: $(curl -s "http://localhost:${MINIO_PORT}/minio/admin/info" 2>/dev/null | grep -o '"buckets":[0-9]*' | cut -d: -f2 || echo "Unknown")"
else
    echo "   MinIO not accessible"
fi

echo ""
echo "💾 Storage Usage"
echo "================"

# Check data directory sizes
echo "Data Directories:"
echo "   PostgreSQL: $(du -sh "${POSTGRES_DATA_DIR:-./data/postgresql}" 2>/dev/null | cut -f1 || echo 'N/A')"
echo "   Redis: $(du -sh "${REDIS_DATA_DIR:-./data/redis}" 2>/dev/null | cut -f1 || echo 'N/A')"
echo "   MinIO: $(du -sh "${MINIO_DATA_DIR:-./data/minio}" 2>/dev/null | cut -f1 || echo 'N/A')"
echo "   Total Data: $(du -sh ./data 2>/dev/null | cut -f1 || echo 'N/A')"

echo ""
echo "📝 Log Files Status"
echo "==================="

# Check log files
logs=(
    "${LOG_DIR}/postgresql.log:PostgreSQL"
    "${LOG_DIR}/redis.log:Redis"
    "${LOG_DIR}/minio.log:MinIO"
)

for log_entry in "${logs[@]}"; do
    IFS=':' read -r log_file service_name <<< "${log_entry}"
    if [ -f "${log_file}" ]; then
        size=$(stat -c%s "${log_file}" 2>/dev/null || echo "unknown")
        modified=$(stat -c%Y "${log_file}" 2>/dev/null || echo "unknown")
        age=$(( $(date +%s) - modified ))
        echo "   ✅ ${service_name}: ${size} bytes, $((${age}/3600))h ago"
    else
        echo "   ⚠️ ${service_name}: Log file missing"
    fi
done

echo ""
echo "🔍 Service-Specific Checks"
echo "=========================="

# PostgreSQL specific checks
if pg_isready -p "${POSTGRES_PORT}" >/dev/null 2>&1; then
    echo "🐘 PostgreSQL Details:"
    echo "   Version: $(psql -h localhost -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT version();" 2>/dev/null | head -3 | tail -1 | cut -d' ' -f2 || echo 'Unknown')"
    echo "   Uptime: $(psql -h localhost -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT now() - pg_postmaster_start_time();" 2>/dev/null | head -3 | tail -1 | sed 's/^[ \t]*//' || echo 'Unknown')"
fi

# Redis specific checks
if redis-cli -p "${REDIS_PORT}" ping >/dev/null 2>&1; then
    echo "🔴 Redis Details:"
    echo "   Version: $(redis-cli -p "${REDIS_PORT}" info server | grep "redis_version" | cut -d: -f2)"
    echo "   Uptime: $(redis-cli -p "${REDIS_PORT}" info server | grep "uptime_in_seconds" | cut -d: -f2 | awk '{print int($1/3600)"h "int(($1%3600)/60)"m"}')"
fi

# MinIO specific checks
if curl -f "http://localhost:${MINIO_PORT}/minio/health/live" >/dev/null 2>&1; then
    echo "📦 MinIO Details:"
    echo "   Status: Online"
    echo "   API Port: ${MINIO_PORT}"
    echo "   Console: http://localhost:9001"
fi

echo ""
echo "🎯 Health Summary"
echo "================="

# Overall health assessment
issues_found=0

# Check disk space
data_dir="./data"
if [ -d "$data_dir" ]; then
    disk_usage=$(df "$data_dir" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "${disk_usage}" -gt 90 ]; then
        echo "⚠️ WARNING: High disk usage (${disk_usage}%) in data directory"
        echo "   Consider cleaning up old data or expanding storage"
        issues_found=$((issues_found + 1))
    fi
fi

# Check for database connections
if pg_isready -p "${POSTGRES_PORT}" >/dev/null 2>&1; then
    conn_count=$(psql -h localhost -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | head -3 | tail -1 | tr -d ' ')
    if [ "${conn_count}" -gt 50 ] 2>/dev/null; then
        echo "⚠️ WARNING: High PostgreSQL connection count (${conn_count})"
        issues_found=$((issues_found + 1))
    fi
fi

# Check Redis memory
if redis-cli -p "${REDIS_PORT}" ping >/dev/null 2>&1; then
    redis_mem=$(redis-cli -p "${REDIS_PORT}" info memory | grep "used_memory" | head -1 | cut -d: -f2)
    redis_mem_mb=$((redis_mem / 1024 / 1024))
    if [ "${redis_mem_mb}" -gt 500 ]; then
        echo "⚠️ WARNING: High Redis memory usage (${redis_mem_mb}MB)"
        issues_found=$((issues_found + 1))
    fi
fi

if [ ${issues_found} -eq 0 ]; then
    echo "✅ All systems operating normally"
else
    echo "⚠️ ${issues_found} issue(s) detected - review warnings above"
fi

echo ""
echo "✅ Monitoring complete"
echo "======================"
echo "Next check: Run this script again or set up automated monitoring"








