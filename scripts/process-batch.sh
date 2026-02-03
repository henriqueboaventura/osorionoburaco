#!/bin/bash

# Batch process multiple images for Osório no Buraco
# Usage: ./scripts/process-batch.sh <input_folder> [reporter_name]
#
# Example:
#   ./scripts/process-batch.sh ~/Downloads/novos-buracos
#   ./scripts/process-batch.sh ~/Downloads/novos-buracos "João Silva"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="${1:-.}"
REPORTER="${2:-Anônimo}"

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Directory '$INPUT_DIR' not found"
    exit 1
fi

# Find all image files
shopt -s nullglob nocaseglob
IMAGE_FILES=("$INPUT_DIR"/*.{jpg,jpeg,png,heic,webp})
shopt -u nullglob nocaseglob

if [ ${#IMAGE_FILES[@]} -eq 0 ]; then
    echo "No image files found in '$INPUT_DIR'"
    exit 1
fi

echo "Found ${#IMAGE_FILES[@]} image(s) to process"
echo "Reporter: $REPORTER"
echo "----------------------------------------"

PROCESSED=0
for img in "${IMAGE_FILES[@]}"; do
    echo "Processing: $(basename "$img")"
    "$SCRIPT_DIR/process-image.sh" "$img" "$REPORTER"
    echo "----------------------------------------"

    # Add delay between requests to respect Nominatim rate limit (1 req/sec)
    sleep 1.5

    ((PROCESSED++))
done

echo ""
echo "Done! Processed $PROCESSED image(s)"
