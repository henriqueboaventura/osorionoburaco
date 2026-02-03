#!/bin/bash

# Process and optimize images for Osório no Buraco
# Extracts GPS coordinates and adds entry to data.json
#
# Usage: ./scripts/process-image.sh <input_image> [reporter_name] [address]
#
# Example:
#   ./scripts/process-image.sh ~/Downloads/foto.jpg
#   ./scripts/process-image.sh ~/Downloads/foto.jpg "João Silva"
#   ./scripts/process-image.sh ~/Downloads/foto.jpg "João Silva" "Rua das Flores, 123"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
MAX_WIDTH=800
MAX_HEIGHT=600
QUALITY=85
OUTPUT_DIR="$PROJECT_DIR/photos"
DATA_FILE="$PROJECT_DIR/data.json"

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input_image> [reporter_name] [address]"
    echo ""
    echo "Examples:"
    echo "  $0 ~/Downloads/pothole.jpg"
    echo "  $0 ~/Downloads/pothole.jpg \"João Silva\""
    echo "  $0 ~/Downloads/pothole.jpg \"João Silva\" \"Rua das Flores, 123\""
    exit 1
fi

INPUT_FILE="$1"
REPORTER="${2:-Anônimo}"
ADDRESS="${3:-}"

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

# Extract GPS coordinates from EXIF data
extract_gps() {
    local file="$1"
    local lat=""
    local lng=""

    # Try exiftool first (most reliable)
    if command -v exiftool &> /dev/null; then
        lat=$(exiftool -n -GPSLatitude "$file" 2>/dev/null | awk -F': ' '{print $2}')
        lng=$(exiftool -n -GPSLongitude "$file" 2>/dev/null | awk -F': ' '{print $2}')

        # Check for GPS longitude ref (West is negative)
        local lng_ref=$(exiftool -GPSLongitudeRef "$file" 2>/dev/null | awk -F': ' '{print $2}')
        if [[ "$lng_ref" == "West" && "$lng" != -* ]]; then
            lng="-$lng"
        fi

        # Check for GPS latitude ref (South is negative)
        local lat_ref=$(exiftool -GPSLatitudeRef "$file" 2>/dev/null | awk -F': ' '{print $2}')
        if [[ "$lat_ref" == "South" && "$lat" != -* ]]; then
            lat="-$lat"
        fi
    # Fallback to mdls on macOS
    elif command -v mdls &> /dev/null; then
        lat=$(mdls -name kMDItemLatitude "$file" 2>/dev/null | awk -F' = ' '{print $2}' | grep -v null)
        lng=$(mdls -name kMDItemLongitude "$file" 2>/dev/null | awk -F' = ' '{print $2}' | grep -v null)
    fi

    echo "$lat $lng"
}

# Extract date from EXIF or use current date
extract_date() {
    local file="$1"
    local photo_date=""

    if command -v exiftool &> /dev/null; then
        photo_date=$(exiftool -DateTimeOriginal -d "%Y-%m-%d" "$file" 2>/dev/null | awk -F': ' '{print $2}')
    fi

    if [ -z "$photo_date" ]; then
        photo_date=$(date +%Y-%m-%d)
    fi

    echo "$photo_date"
}

# Get next ID from data.json
get_next_id() {
    if [ -f "$DATA_FILE" ]; then
        local max_id=$(cat "$DATA_FILE" | grep '"id"' | sed 's/[^0-9]//g' | sort -n | tail -1)
        echo $((max_id + 1))
    else
        echo 1
    fi
}

# Add entry to data.json
add_to_json() {
    local id="$1"
    local lat="$2"
    local lng="$3"
    local photo="$4"
    local reporter="$5"
    local date="$6"
    local address="$7"

    if [ -z "$address" ]; then
        address="Endereço a confirmar"
    fi

    local new_entry=$(cat <<EOF
    {
        "id": $id,
        "lat": $lat,
        "lng": $lng,
        "address": "$address",
        "photo": "$photo",
        "reporter": "$reporter",
        "reportedDate": "$date",
        "fixed": false,
        "fixedDate": null
    }
EOF
)

    if [ -f "$DATA_FILE" ] && [ -s "$DATA_FILE" ]; then
        # File exists and has content - append to array
        # Remove the last ] and add comma + new entry + ]
        sed -i '' '$ d' "$DATA_FILE"
        echo "," >> "$DATA_FILE"
        echo "$new_entry" >> "$DATA_FILE"
        echo "]" >> "$DATA_FILE"
    else
        # Create new file with array
        echo "[" > "$DATA_FILE"
        echo "$new_entry" >> "$DATA_FILE"
        echo "]" >> "$DATA_FILE"
    fi
}

echo "Processing image..."

# Extract GPS before resizing (EXIF may be lost)
GPS_DATA=$(extract_gps "$INPUT_FILE")
LAT=$(echo "$GPS_DATA" | awk '{print $1}')
LNG=$(echo "$GPS_DATA" | awk '{print $2}')
PHOTO_DATE=$(extract_date "$INPUT_FILE")

# Process image
if command -v sips &> /dev/null; then
    cp "$INPUT_FILE" "$OUTPUT_FILE"
    sips --resampleHeightWidthMax $MAX_HEIGHT "$OUTPUT_FILE" --out "$OUTPUT_FILE" > /dev/null 2>&1
    sips --setProperty format jpeg --setProperty formatOptions $QUALITY "$OUTPUT_FILE" --out "$OUTPUT_FILE" > /dev/null 2>&1
elif command -v convert &> /dev/null; then
    convert "$INPUT_FILE" \
        -resize "${MAX_WIDTH}x${MAX_HEIGHT}>" \
        -quality $QUALITY \
        -strip \
        "$OUTPUT_FILE"
else
    echo "Error: Neither sips (macOS) nor ImageMagick (convert) found"
    exit 1
fi

FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')

echo ""
echo "Image processed successfully!"
echo "Output: $OUTPUT_FILE"
echo "Size: $FILE_SIZE"
echo ""

# Check if GPS data was found
if [ -n "$LAT" ] && [ -n "$LNG" ]; then
    NEXT_ID=$(get_next_id)

    echo "GPS coordinates found!"
    echo "Latitude: $LAT"
    echo "Longitude: $LNG"
    echo "Date: $PHOTO_DATE"
    echo ""

    # Add to data.json
    add_to_json "$NEXT_ID" "$LAT" "$LNG" "photos/$UNIQUE_NAME" "$REPORTER" "$PHOTO_DATE" "$ADDRESS"

    echo "Added to data.json with ID: $NEXT_ID"
    echo ""
    echo "View at: https://henriqueboaventura.github.io/osorionoburaco/#buraco-$NEXT_ID"
else
    echo "No GPS coordinates found in image."
    echo ""
    echo "Add manually to data.json:"
    echo "\"photo\": \"photos/$UNIQUE_NAME\""
fi
