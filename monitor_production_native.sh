#!/bin/bash
# NeuroInsight Production Native Monitoring Script
# Monitors all native services health and performance

set -e

echo "📊 Monitoring NeuroInsight Production Native Deployment"
echo "====================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/data"
LOGS_DIR="${DATA_DIR}/logs"
PIDS_DIR="${SCRIPT_DIR}"

# Configuration
API_PORT="8000"
PG_PORT="5432"
REDIS_PORT="6379"
MINIO_PORT="9000"

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

    if [ -f "${pid_file}" ]; then
        local pid=$(cat "${pid_file}")
        if kill -0 "${pid}" 2>/dev/null; then
            echo "   ✅ ${service_name}: RUNNING (PID: ${pid})"
            return 0
        else
            echo "   ❌ ${service_name}: PROCESS DEAD"
            return 1
        fi
    else
        echo "   ❌ ${service_name}: PID FILE MISSING"
        return 1
    fi
}

# Check PostgreSQL
check_service "PostgreSQL" "pg_isready -p ${PG_PORT}" "accepting connections"

# Check Redis
check_service "Redis" "redis-cli -p ${REDIS_PORT} ping" "PONG"

# Check MinIO
check_service "MinIO" "curl -f http://localhost:${MINIO_PORT}/minio/health/live" ""

# Check FastAPI Backend
check_process "${PIDS_DIR}/backend.pid" "FastAPI Backend"
if kill -0 $(cat "${PIDS_DIR}/backend.pid" 2>/dev/null) 2>/dev/null; then
    # Additional health check for API
    if curl -f http://localhost:${API_PORT}/health >/dev/null 2>&1; then
        echo "   ✅ API Health Check: PASS"
    else
        echo "   ❌ API Health Check: FAIL"
    fi
fi

# Check Celery Worker
check_process "${PIDS_DIR}/celery.pid" "Celery Worker"

echo ""
echo "📈 Performance Metrics"
echo "======================"

# PostgreSQL connections
echo "🐘 PostgreSQL Connections:"
psql -p ${PG_PORT} -U neuroinsight -d neuroinsight -c "SELECT count(*) as active_connections FROM pg_stat_activity;" 2>/dev/null || echo "   Unable to query PostgreSQL"

# Redis memory usage
echo "🔴 Redis Memory Usage:"
redis-cli -p ${REDIS_PORT} info memory | grep -E "used_memory_human|used_memory_peak_human" 2>/dev/null || echo "   Unable to query Redis"

# Disk usage
echo "💾 Disk Usage:"
echo "   Data directory: $(du -sh ${DATA_DIR} 2>/dev/null | cut -f1 || echo 'N/A')"
echo "   PostgreSQL: $(du -sh ${DATA_DIR}/postgresql 2>/dev/null | cut -f1 || echo 'N/A')"
echo "   Redis: $(du -sh ${DATA_DIR}/redis 2>/dev/null | cut -f1 || echo 'N/A')"
echo "   MinIO: $(du -sh ${DATA_DIR}/minio 2>/dev/null | cut -f1 || echo 'N/A')"

echo ""
echo "📋 Recent Job Status"
echo "===================="

# Check for recent jobs via API
if curl -f http://localhost:${API_PORT}/health >/dev/null 2>&1; then
    echo "Recent jobs:"
    curl -s http://localhost:${API_PORT}/api/jobs | jq '.[:3][] | "\(.id): \(.status) - \(.filename)"' 2>/dev/null || echo "   Unable to query jobs API"
else
    echo "API not accessible for job status check"
fi

echo ""
echo "📝 Log File Status"
echo "=================="

# Check log files
logs=(
    "${LOGS_DIR}/backend.log:FastAPI Backend"
    "${LOGS_DIR}/celery.log:Celery Worker"
    "${LOGS_DIR}/postgresql.log:PostgreSQL"
    "${LOGS_DIR}/redis.log:Redis"
    "${LOGS_DIR}/minio.log:MinIO"
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
echo "🎯 Recommendations"
echo "=================="

# Check for issues and provide recommendations
issues_found=0

# Check disk space
disk_usage=$(df "${DATA_DIR}" | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "${disk_usage}" -gt 90 ]; then
    echo "⚠️ WARNING: High disk usage (${disk_usage}%)"
    echo "   Consider cleaning up old data or expanding storage"
    issues_found=$((issues_found + 1))
fi

# Check for stuck jobs
stuck_jobs=$(curl -s http://localhost:${API_PORT}/api/jobs 2>/dev/null | jq '[.[] | select(.status == "processing" and (.updated_at | fromdateiso8601 < (now - 3600)))] | length' 2>/dev/null || echo "0")
if [ "${stuck_jobs}" -gt 0 ]; then
    echo "⚠️ WARNING: ${stuck_jobs} job(s) appear stuck (processing >1h)"
    echo "   Consider restarting Celery worker or checking logs"
    issues_found=$((issues_found + 1))
fi

# Check memory usage (rough estimate)
mem_usage=$(ps aux --no-headers -o pmem -C python | awk '{sum+=$1} END {print sum}' 2>/dev/null || echo "0")
if (( $(echo "${mem_usage} > 80" | bc -l 2>/dev/null || echo "0") )); then
    echo "⚠️ WARNING: High Python process memory usage (~${mem_usage}%)"
    echo "   Consider restarting services or checking for memory leaks"
    issues_found=$((issues_found + 1))
fi

if [ ${issues_found} -eq 0 ]; then
    echo "✅ All systems operating normally"
fi

echo ""
echo "✅ Monitoring complete"
echo "======================"
echo "Next check: Run this script again or set up automated monitoring"








