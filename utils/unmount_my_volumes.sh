#!/bin/bash

# Load the .private file containing the folders to unmount
if [ -f .private ]; then
    export $(grep -v '^#' .private | xargs)
else
    echo ".... .private file not found!"
    exit 1
fi

# Check if FOLDERS_TO_MOUNT variable is set
if [ -z "$FOLDERS_TO_MOUNT" ]; then
    echo ".... No folders specified in FOLDERS_TO_MOUNT"
    exit 1
fi

# Split the FOLDERS_TO_MOUNT variable into an array (comma-separated list)
IFS=',' read -r -a FOLDERS <<< "$FOLDERS_TO_MOUNT"

# Loop through each folder and attempt to unmount it
for folder in "${FOLDERS[@]}"; do
    local_mount_point="/Volumes/$folder"

    # Check if the folder is mounted, and unmount it if so
    if mountpoint -q "$local_mount_point"; then
        echo ".... Unmounting $local_mount_point ..."
        if sudo umount "$local_mount_point"; then
            echo ".... Successfully unmounted $local_mount_point"
        else
            echo ".... Failed to unmount $local_mount_point"
        fi
    else
        echo ".... $local_mount_point is not mounted or does not exist"
    fi
done

echo ".... Unmounting complete!"