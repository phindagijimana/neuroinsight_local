#!/bin/bash
# FreeSurfer Apptainer/Singularity Container Download Script
# Downloads FreeSurfer Docker image and converts to Apptainer .sif format

set -e

# Configuration
FREESURFER_IMAGE="docker.io/bids/freesurfer:latest"
OUTPUT_FILE="freesurfer-7.4.1.sif"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧠 FreeSurfer Apptainer Download Script"
echo "======================================"
echo "Image: $FREESURFER_IMAGE"
echo "Output: $OUTPUT_FILE"
echo "Location: $SCRIPT_DIR"
echo ""

# Check if output already exists
if [ -f "$SCRIPT_DIR/$OUTPUT_FILE" ]; then
    echo "✅ FreeSurfer container already exists: $OUTPUT_FILE"
    echo "   Size: $(du -h "$SCRIPT_DIR/$OUTPUT_FILE" | cut -f1)"
    exit 0
fi

# Check available container runtimes
echo "🔍 Checking for container runtimes..."

# Check for Apptainer first (preferred)
if command -v apptainer >/dev/null 2>&1; then
    CONTAINER_CMD="apptainer"
    echo "✅ Found Apptainer: $(apptainer --version)"
elif command -v singularity >/dev/null 2>&1; then
    CONTAINER_CMD="singularity"
    echo "✅ Found Singularity: $(singularity --version)"
else
    echo "❌ ERROR: Neither Apptainer nor Singularity found in PATH"
    echo "   Please install Apptainer or Singularity first"
    echo "   Ubuntu/Debian: sudo apt install apptainer"
    echo "   Or download from: https://apptainer.org/"
    exit 1
fi

echo ""
echo "📦 Starting download process..."
echo "   This may take 10-15 minutes depending on your internet connection"
echo "   Image size: ~4GB"
echo ""

# Create a temporary directory for download
TEMP_DIR=$(mktemp -d)
echo "📁 Using temporary directory: $TEMP_DIR"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🧹 Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

cd "$TEMP_DIR"

# Download the container
echo "⬇️  Pulling FreeSurfer Docker image..."
echo "   Command: $CONTAINER_CMD pull $OUTPUT_FILE docker://$FREESURFER_IMAGE"

if ! $CONTAINER_CMD pull "$OUTPUT_FILE" "docker://$FREESURFER_IMAGE"; then
    echo "❌ ERROR: Failed to download FreeSurfer container"
    echo "   This could be due to:"
    echo "   • Network connectivity issues"
    echo "   • Docker Hub rate limiting"
    echo "   • Insufficient disk space"
    echo "   • Permissions issues"
    echo ""
    echo "   Please check your internet connection and try again"
    exit 1
fi

# Move to final location
echo "📂 Moving container to final location..."
mv "$OUTPUT_FILE" "$SCRIPT_DIR/"

echo ""
echo "✅ SUCCESS: FreeSurfer container downloaded!"
echo "   Location: $SCRIPT_DIR/$OUTPUT_FILE"
echo "   Size: $(du -h "$SCRIPT_DIR/$OUTPUT_FILE" | cut -f1)"
echo ""
echo "🎉 You can now use FreeSurfer with Singularity/Apptainer!"
echo "   The container will be automatically detected by NeuroInsight."

exit 0
