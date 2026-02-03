#!/bin/bash

# Process and optimize images for Osório no Buraco
# Usage: ./scripts/process-image.sh <input_image> [output_folder]
#
# Example:
#   ./scripts/process-image.sh ~/Downloads/foto.jpg
#   ./scripts/process-image.sh ~/Downloads/foto.jpg photos/

set -e

# Configuration
MAX_WIDTH=800
MAX_HEIGHT=600
QUALITY=85
OUTPUT_DIR="${2:-photos}"

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input_image> [output_folder]"
    echo "Example: $0 ~/Downloads/pothole.jpg"
    exit 1
fi

INPUT_FILE="$1"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Generate unique filename using timestamp and random string
TIMESTAMP=$(date +%Y%m%d%H%M%S)
RANDOM_STR=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 6)
UNIQUE_NAME="buraco-${TIMESTAMP}-${RANDOM_STR}.jpg"
OUTPUT_FILE="${OUTPUT_DIR}/${UNIQUE_NAME}"

# Check if sips is available (macOS)
if command -v sips &> /dev/null; then
    # Use sips (macOS built-in)
    # First, copy the file
    cp "$INPUT_FILE" "$OUTPUT_FILE"

    # Resize to fit within max dimensions while maintaining aspect ratio
    sips --resampleHeightWidthMax $MAX_HEIGHT "$OUTPUT_FILE" --out "$OUTPUT_FILE" > /dev/null 2>&1

    # Convert to JPEG if not already
    sips --setProperty format jpeg --setProperty formatOptions $QUALITY "$OUTPUT_FILE" --out "$OUTPUT_FILE" > /dev/null 2>&1

elif command -v convert &> /dev/null; then
    # Use ImageMagick
    convert "$INPUT_FILE" \
        -resize "${MAX_WIDTH}x${MAX_HEIGHT}>" \
        -quality $QUALITY \
        -strip \
        "$OUTPUT_FILE"
else
    echo "Error: Neither sips (macOS) nor ImageMagick (convert) found"
    echo "Please install ImageMagick: brew install imagemagick"
    exit 1
fi

# Get file size
FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')

echo "Image processed successfully!"
echo "Output: $OUTPUT_FILE"
echo "Size: $FILE_SIZE"
echo ""
echo "Add this to your data.json:"
echo "\"photo\": \"${OUTPUT_DIR}/${UNIQUE_NAME}\""
