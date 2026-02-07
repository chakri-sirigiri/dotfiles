#!/bin/bash

# This script compresses a video file using Apple Silicon GPU acceleration.
# Use the --split flag to also split the video into fragments based on silence detection.

DO_SPLIT=false
if [[ "$1" == "--split" ]]; then
    DO_SPLIT=true
elif [[ "$1" == "--compress" ]]; then
    DO_SPLIT=false
elif [[ $# -eq 0 ]]; then
    echo "Available Modes:"
    echo "  1) Compression Only (Standard GPU compression)"
    echo "  2) Split and Compress (Silence detection + fragmenting)"
    read -p "Select Mode [1/2, default 1]: " mode_choice
    if [[ "$mode_choice" == "2" ]]; then
        DO_SPLIT=true
    else
        DO_SPLIT=false
    fi
fi

echo "----------------------------------------------------------------------------"
echo "SELECTED MODE: $([ "$DO_SPLIT" = true ] && echo "Split and Compress" || echo "Compression Only")"
echo "----------------------------------------------------------------------------"

# Configuration for Silence Detection (Adjust if splitting is not accurate)
# NOISE: -20dB is quite lenient (good for ambient noise), -30dB is stricter.
# DURATION: Minimum seconds of silence required to trigger a split.
noise_val=-25
SILENCE_DURATION=${SILENCE_DURATION:-"2.5"}
MIN_CHUNK_DURATION=${MIN_CHUNK_DURATION:-"3.0"}

WORKING_DIR="$HOME/Desktop/input"
mkdir -p "$WORKING_DIR"
cd "$WORKING_DIR" || exit 1

# Cleanup previous logs if they exist
rm -f silence_log.txt split_points.txt

echo "Move exactly ONE video file to $WORKING_DIR and confirm"
read -p "Press Enter when ready..."
read -r -p "Enter the file name (e.g., video.mov, video.mp4, video.m4v): " file_name

# Strip leading/trailing quotes if the user pasted them
file_name="${file_name%\"}"
file_name="${file_name#\"}"
file_name="${file_name%\'}"
file_name="${file_name#\'}"

# Verify the file exists
if [[ ! -f "$file_name" ]]; then
    echo "Error: File $file_name not found in $WORKING_DIR"
    exit 1
fi

if [ "$DO_SPLIT" = true ]; then
    # --- SPLIT AND COMPRESS MODE ---
    # --- INTERACTIVE TUNING ---
    while true; do
        SILENCE_NOISE="${noise_val}dB"
        echo "Tuning with Noise < $SILENCE_NOISE, Duration > $SILENCE_DURATION s"
        echo "Scanning for first 2 silence points..."
        
        # Detect first 2 silence points
        splits=$(ffmpeg -hide_banner -v info -stats -i "$file_name" \
            -af "silencedetect=noise=$SILENCE_NOISE:d=$SILENCE_DURATION" \
            -f null - 2>&1 | grep -m 2 "silence_start" | awk '{print $NF}')
        
        if [[ -z "$splits" ]]; then
            echo "No silence found with current settings."
        else
            echo "Preview (first 2 splits):"
            echo "$splits" | nl
        fi
        
        echo "Options:"
        echo "  y: Accept and proceed"
        echo "  +: Increase threshold (to $(((noise_val + 5)))dB) -> MORE splits (less strict)"
        echo "  -: Decrease threshold (to $(((noise_val - 5)))dB) -> FEWER splits (more strict)"
        echo "  q: Quit"
        read -p "Choice [y/+/ - /q]: " choice
        
        case "$choice" in
            y) break ;;
            +) noise_val=$((noise_val + 5)) ;;
            -) noise_val=$((noise_val - 5)) ;;
            q) exit 0 ;;
            *) echo "Invalid choice." ;;
        esac
        echo "-----------------------------------"
    done

    # 1. Detect silence in the file (Full scan)
    echo "Scanning for silence..."
    # We use -v info because silencedetect lines are logged at INFO level
    ffmpeg -hide_banner -v info -stats -fflags +genpts -i "$file_name" \
        -af "silencedetect=noise=$SILENCE_NOISE:d=$SILENCE_DURATION" \
        -f null - 2>&1 | grep -E "silence_start|frame=" | tee silence_log.txt

    # 2. Extract split points from the silence log
    echo "Calculating split points... Minimum gap: ${MIN_CHUNK_DURATION}s"
    awk -v min="$MIN_CHUNK_DURATION" '
    /silence_start/ { 
        # ffmpeg output format example: [silencedetect @ 0x...] silence_start: 123.456
        for(i=1;i<=NF;i++) if($i ~ /silence_start:/) print $(i+1)
    }
    ' silence_log.txt > split_points.txt

    # Check if we found any split points
    if [[ ! -s split_points.txt ]]; then
        echo "No silence (>= ${MIN_DURATION}s) found. Falling back to single-file compression."
        DO_SPLIT=false
    else
        # 3. Split the video into chunks and compress them
        echo "Splitting and compressing into chunks (GPU Accelerated)..."
        ffmpeg -stats -i "$file_name" \
            -map 0 \
            -f segment \
            -segment_times $(paste -sd, split_points.txt) \
            -reset_timestamps 1 \
            -c:v h264_videotoolbox -q:v 75 \
            -c:a copy \
            chunk_%03d.mp4
    fi
fi

if [ "$DO_SPLIT" = false ]; then
    # --- COMPRESS ONLY MODE (DEFAULT) ---
    base_filename=$(basename "$file_name")
    output_name="compressed_${base_filename%.*}.mp4"
    
    echo "Compressing $file_name -> $output_name (GPU Accelerated)..."
    ffmpeg -stats -fflags +genpts -i "$file_name" \
        -c:v h264_videotoolbox -q:v 75 \
        -c:a copy \
        "$output_name"
fi

echo "Finished! Files are located in $WORKING_DIR"
