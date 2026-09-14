#!/bin/bash
# Deprecated alias — use install-neuroinsight-autohs.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/install-neuroinsight-autohs.sh" "$@"
