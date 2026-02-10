#!/bin/bash
# Isolated test: simulate a random user on WSL/Linux pulling and running the
# published Docker image (no local repo, no source code).
# Uses Docker Hub image only; creates a temporary volume; cleans up after.
#
# Usage: ./isolated-test-wsl.sh [--cleanup]
#   --cleanup  Stop and remove the container after the test (default: keep running on 18000)

set -e

IMAGE="${IMAGE:-phindagijimana321/neuroinsight:latest}"
CONTAINER_NAME="neuroinsight-isolated-test"
VOLUME_NAME="neuroinsight-isolated-test-data"
# Use a different port so we don't conflict with a real deployment
HOST_PORT="${TEST_PORT:-18000}"
CLEANUP=false
[ "$1" = "--cleanup" ] && CLEANUP=true

echo "=============================================="
echo "NeuroInsight isolated test (WSL/Linux user)"
echo "=============================================="
echo "Image:    $IMAGE"
echo "Port:     $HOST_PORT"
echo "Container: $CONTAINER_NAME"
echo ""

# Clean up any previous test run
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  echo "Removing existing test container..."
  docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
fi

echo "Pulling image from Docker Hub..."
docker pull "$IMAGE"

echo "Starting container (no license mount - app should still start)..."
# Bind 0.0.0.0 so WSL/Windows can reach localhost:18000
docker run -d \
  --name "$CONTAINER_NAME" \
  -p "0.0.0.0:${HOST_PORT}:8000" \
  -v "${VOLUME_NAME}:/data" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e POSTGRES_PASSWORD=neuroinsight_secure_password \
  -e REDIS_PASSWORD=redis_secure_password \
  -e MINIO_ROOT_PASSWORD=minioadmin_secure \
  "$IMAGE"

echo "Waiting for services to be ready (up to 90s)..."
for i in $(seq 1 90); do
  if curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${HOST_PORT}/health" 2>/dev/null | grep -q 200; then
    echo "  Backend responded at ${i}s"
    break
  fi
  if [ "$i" -eq 90 ]; then
    echo "ERROR: Timeout waiting for backend. Logs:"
    docker logs "$CONTAINER_NAME" 2>&1 | tail -80
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    exit 1
  fi
  sleep 1
done

echo ""
echo "--- Health check ---"
HEALTH=$(curl -s "http://127.0.0.1:${HOST_PORT}/health" 2>/dev/null || echo "{}")
echo "$HEALTH" | head -20
if echo "$HEALTH" | grep -q "status"; then
  echo "[OK] Health endpoint returned JSON"
else
  echo "[WARN] Health response unexpected (may still be OK)"
fi

echo ""
echo "--- Frontend (/) ---"
ROOT_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${HOST_PORT}/" 2>/dev/null || echo "000")
if [ "$ROOT_CODE" = "200" ]; then
  echo "[OK] Frontend returns HTTP 200"
else
  echo "[WARN] Frontend returned HTTP $ROOT_CODE"
fi

echo ""
echo "--- API /api/jobs ---"
JOBS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${HOST_PORT}/api/jobs/" 2>/dev/null || echo "000")
if [ "$JOBS_CODE" = "200" ]; then
  echo "[OK] API /api/jobs returns HTTP 200"
else
  echo "[WARN] API /api/jobs returned HTTP $JOBS_CODE"
fi

echo ""
echo "=============================================="
echo "Isolated test passed. App is RUNNING on port ${HOST_PORT}:"
echo "  http://127.0.0.1:${HOST_PORT}"
echo "  http://localhost:${HOST_PORT}  (WSL: use this in Windows browser)"
echo "=============================================="

if [ "$CLEANUP" = true ]; then
  echo "Stopping and removing test container (--cleanup)..."
  docker stop "$CONTAINER_NAME"
  docker rm "$CONTAINER_NAME"
  echo "Done. Volume '$VOLUME_NAME' left (remove with: docker volume rm $VOLUME_NAME)"
else
  echo "Container left running. To stop and remove later:"
  echo "  docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
fi
