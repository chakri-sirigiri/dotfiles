#!/bin/bash

# Load the .private file containing the SMB credentials, hostname, and folders to mount
if [ -f .private ]; then
    export $(grep -v '^#' .private | xargs)
else
    echo ".... .private file not found!"
    exit 1
fi

# Create a credentials file with username and password from .private
CREDENTIALS_FILE="$HOME/.smbcredentials"

if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "username=$SMB_USER" > "$CREDENTIALS_FILE"
    echo "password=$SMB_PASS" >> "$CREDENTIALS_FILE"
    chmod 600 "$CREDENTIALS_FILE"  # Restrict file permissions
fi

# Split the FOLDERS_TO_MOUNT variable into an array
IFS=',' read -r -a FOLDERS <<< "$FOLDERS_TO_MOUNT"

# Get the UID and GID of the current user
uid=$(id -u $USER)
gid=$(id -g $USER)

# Loop through each folder and add them to /etc/fstab
for folder in "${FOLDERS[@]}"; do
    local_mount_point="/Volumes/$folder"
    remote_share="//${SMB_HOST}/$folder"

    # Check if the target mount directory exists, create it if not
    if [ ! -d "$local_mount_point" ]; then
        echo ".... Creating $local_mount_point directory..."
        sudo mkdir -p "$local_mount_point"
        # Change ownership to the current user after creation
        sudo chown "$USER":"$USER" "$local_mount_point"
        # Set directory permissions for read/write/execute by the user
        sudo chmod 755 "$local_mount_point"
        echo ".... Directory $local_mount_point ownership changed to $USER and permissions set."
    else
        echo ".... Directory $local_mount_point already exists."
    fi

    # Add entry to /etc/fstab
    echo ".... Adding $remote_share to /etc/fstab..."

    # Create the fstab entry with uid, gid, file_mode, and dir_mode options
    fstab_entry="$remote_share $local_mount_point cifs credentials=$CREDENTIALS_FILE,vers=3.0,_netdev,rw,uid=$uid,gid=$gid,file_mode=0644,dir_mode=0755 0 0"

    # Check if the entry already exists in /etc/fstab to avoid duplication
    if ! grep -q "$remote_share" /etc/fstab; then
        echo "$fstab_entry" | sudo tee -a /etc/fstab
    else
        echo ".... $remote_share already exists in /etc/fstab."
    fi
done

# Reload /etc/fstab and mount all filesystems
echo ".... Mounting all filesystems from /etc/fstab..."
sudo mount -a

if [ $? -eq 0 ]; then
    echo ".... All volumes mounted successfully from /etc/fstab!"
else
    echo ".... Failed to mount volumes. Check /etc/fstab for errors."
    exit 1
fi
