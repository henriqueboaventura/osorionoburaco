#!/bin/bash

# Batch process multiple images for Osório no Buraco
# Usage: ./scripts/process-batch.sh <input_folder> [output_folder]
#
# Example:
#   ./scripts/process-batch.sh ~/Downloads/novos-buracos
#   ./scripts/process-batch.sh ~/Downloads/novos-buracos photos/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="${1:-.}"
OUTPUT_DIR="${2:-photos}"

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
echo "----------------------------------------"

PROCESSED=0
for img in "${IMAGE_FILES[@]}"; do
    echo "Processing: $(basename "$img")"
    "$SCRIPT_DIR/process-image.sh" "$img" "$OUTPUT_DIR"
    echo "----------------------------------------"
    ((PROCESSED++))
done

echo ""
echo "Done! Processed $PROCESSED image(s)"
