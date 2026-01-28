#!/bin/bash

# Exit on any error
set -e

# The name of your VM (you'll need to replace this with your actual VM name)
VM_NAME="HomeAssistant"

# Path to VBoxManage
VBOXMANAGE="/usr/local/bin/VBoxManage"

# Check if VM exists
if ! $VBOXMANAGE list vms | grep -q "\"$VM_NAME\""; then
    echo "Error: VM '$VM_NAME' not found"
    exit 1
fi

# Check if VM is already running
if ! $VBOXMANAGE list runningvms | grep -q "\"$VM_NAME\""; then
    echo "Starting VM '$VM_NAME'..."
    $VBOXMANAGE startvm "$VM_NAME" --type headless
else
    echo "VM '$VM_NAME' is already running"
fi
