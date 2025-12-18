#!/bin/bash

# Convert PDFs to high-resolution PNGs for tvOS
# Using sips (built into macOS)

PDF_DIR="leadsheets/Resources/pdfs"
OUTPUT_DIR="leadsheets/Resources/images"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Converting PDFs to images..."
echo "Source: $PDF_DIR"
echo "Output: $OUTPUT_DIR"
echo ""

count=0
total=$(find "$PDF_DIR" -name "*.pdf" -type f | wc -l | tr -d ' ')

for pdf in "$PDF_DIR"/*.pdf; do
    if [ -f "$pdf" ]; then
        count=$((count + 1))
        basename=$(basename "$pdf" .pdf)
        output="$OUTPUT_DIR/${basename}.png"

        echo "[$count/$total] Converting: $basename"

        # sips can't directly convert PDF to PNG, so we'll use a different approach
        # We'll create a temporary TIFF first, then convert to PNG
        temp_tiff="/tmp/${basename}.tiff"

        # Convert PDF to TIFF using sips (first page only)
        sips -s format tiff "$pdf" --out "$temp_tiff" 2>/dev/null

        # Convert TIFF to high-res PNG
        sips -s format png -Z 2048 "$temp_tiff" --out "$output" 2>/dev/null

        # Clean up temp file
        rm -f "$temp_tiff"
    fi
done

echo ""
echo "Done! Converted $count PDFs to images in $OUTPUT_DIR"
