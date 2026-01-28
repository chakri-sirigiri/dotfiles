#!/bin/bash

# --- Video Compression Script using libx264 + CRF ---

# Ask for input file if not provided
if [ -z "$1" ]; then
  read -rp "Enter path to the .mov file: " input_file
else
  input_file="$1"
fi

# Check if file exists
if [ ! -f "$input_file" ]; then
  echo "❌ File not found: $input_file"
  exit 1
fi

# Get absolute path, filename, and directory
input_file=$(realpath "$input_file")
input_dir=$(dirname "$input_file")
input_base=$(basename "$input_file")
input_name="${input_base%.*}"
output_file="$input_dir/${input_name}_compressed.mp4"

# Start timing
start_time=$(date +%s)

# Run ffmpeg with CRF-based compression
echo "🔄 Compressing: $input_file"
ffmpeg -i "$input_file" -c:v libx264 -crf 20 -preset veryslow -c:a aac -b:a 192k "$output_file"

# End timing
end_time=$(date +%s)
elapsed=$((end_time - start_time))

# Display result
echo "✅ Done. Compressed file saved to:"
echo "$output_file"
echo "🕒 Time taken: ${elapsed} seconds"

