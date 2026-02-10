#!/bin/bash
# Delete all Docker Hub tags for this repository except 'latest'.
# Requires: DOCKERHUB_USERNAME and DOCKERHUB_TOKEN (create at https://hub.docker.com/settings/security)
#
# Usage: ./delete-dockerhub-tags.sh [--dry-run]

set -e

NAMESPACE="${DOCKERHUB_NAMESPACE:-phindagijimana321}"
REPO="${DOCKERHUB_REPO:-neuroinsight}"
KEEP_TAG="latest"
DRY_RUN=false

[ "$1" = "--dry-run" ] && DRY_RUN=true

if [ -z "$DOCKERHUB_USERNAME" ] || [ -z "$DOCKERHUB_TOKEN" ]; then
  echo "Error: Set DOCKERHUB_USERNAME and DOCKERHUB_TOKEN."
  echo "Create a token at: https://hub.docker.com/settings/security"
  exit 1
fi

echo "Logging in to Docker Hub..."
TOKEN=$(curl -s -X POST "https://hub.docker.com/v2/users/login/" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$DOCKERHUB_USERNAME\",\"password\":\"$DOCKERHUB_TOKEN\"}" \
  | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "Error: Failed to get token. Check DOCKERHUB_USERNAME and DOCKERHUB_TOKEN."
  exit 1
fi

echo "Listing tags for $NAMESPACE/$REPO (keeping '$KEEP_TAG')..."
NEXT="https://hub.docker.com/v2/namespaces/$NAMESPACE/repositories/$REPO/tags?page_size=100"
DELETED=0

while [ -n "$NEXT" ]; do
  RESP=$(curl -s -H "Authorization: Bearer $TOKEN" "$NEXT")
  # Parse "name" from results array (one per line for simplicity)
  TAG_NAMES=$(echo "$RESP" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:"\([^"]*\)".*/\1/')
  for tag in $TAG_NAMES; do
    [ -z "$tag" ] && continue
    if [ "$tag" = "$KEEP_TAG" ]; then
      echo "  Keep: $tag"
      continue
    fi
    if [ "$DRY_RUN" = true ]; then
      echo "  [dry-run] Would delete: $tag"
      DELETED=$((DELETED+1))
    else
      echo "  Deleting: $tag"
      HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
        -H "Authorization: Bearer $TOKEN" \
        "https://hub.docker.com/v2/namespaces/$NAMESPACE/repositories/$REPO/tags/$tag")
      if [ "$HTTP" = "204" ] || [ "$HTTP" = "200" ]; then
        DELETED=$((DELETED+1))
      else
        echo "    (HTTP $HTTP)"
      fi
    fi
  done
  NEXT=$(echo "$RESP" | grep -o '"next"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:"\([^"]*\)".*/\1/')
  [ "$NEXT" = "" ] && break
  [ "$NEXT" = "$RESP" ] && break
done

echo "Done. Kept '$KEEP_TAG'. Deleted: $DELETED tag(s)."
