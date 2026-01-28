#!/bin/bash

############################
# This script copies my custom configs to the home directory
# And also installs Ubuntu Software
# Assumes Ubuntu 22.04, already has ssh and git installed
# And also sets up Visual Code as a server / tunnel
############################

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Function for dotted logs
log_info() {
    echo -e "\n\n.... $1"
}

# Function to check for file existence and throw error if missing
check_required_files() {
    if [ ! -f "$1" ]; then
        echo "ERROR: Required file $1 is missing."
        exit 1
    else
        log_info "Required file $1 found."
    fi
}

dotfiledir="${HOME}/dotfiles"

# Check if .private, .gitconfig, and mount_my_volumes.sh files exist
log_info "Checking for .private, .gitconfig, and mount_my_volumes.sh files..."
check_required_files "$dotfiledir/.private"
check_required_files "$dotfiledir/.gitconfig"
check_required_files "$dotfiledir/.gitignore_global"
check_required_files "$dotfiledir/mount_my_volumes.sh"

# Load values from .private file
log_info "Loading SSH port and VSCode tunnel name from .private file..."
source "$dotfiledir/.private"

# list of files/folders to copy from ${homedir}
files=(gitignore_global gitconfig private)

# change to the dotfiles directory
echo "Changing to the ${dotfiledir} directory"
cd "${dotfiledir}" || exit

# create symlinks (will overwrite old dotfiles)
for file in "${files[@]}"; do
    echo "copying $file in home directory."
    cp "${dotfiledir}/.${file}" "${HOME}/.${file}"
done

# Modify the sudoers file and enable passwordless sudo for the current user
log_info "Configuring passwordless sudo for $(whoami)..."
echo "$(whoami) ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$(whoami)

# Update and install basic packages
log_info "Updating system and installing basic packages..."
sudo apt update
sudo apt upgrade -y 
sudo apt install -y git zsh curl openssh-server nano tree cifs-utils

# Enable and start the SSH service
log_info "Enabling and starting the SSH service..."
sudo systemctl enable ssh
sudo systemctl start ssh
log_info "SSH service is enabled and started."

# Change the SSH port based on value in .private
SSH_CONFIG_FILE="/etc/ssh/sshd_config"
if grep -q "^Port $SSH_PORT" "$SSH_CONFIG_FILE"; then
    log_info "SSH is already configured to use port $SSH_PORT."
else
    log_info "Changing SSH default port to $SSH_PORT..."
    sudo sed -i "s/^#Port 22/Port $SSH_PORT/" "$SSH_CONFIG_FILE"
    sudo systemctl restart ssh
    if [ $? -eq 0 ]; then
        log_info "SSH port changed to $SSH_PORT and service restarted."
    else
        log_info "Failed to change SSH port."
    fi
fi

# Install Oh My Zsh
log_info "Installing Oh My Zsh..."
RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
chsh -s $(which zsh)
log_info "Oh My Zsh installed and Zsh set as the default shell."

# Mount network volumes
log_info "Mounting network volumes..."
bash mount_my_volumes.sh

# Download VS Code CLI
log_info "Downloading Visual Studio Code CLI..."
curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz

# Install VS Code CLI and setup tunnel Extract and move to home directory
log_info "Extracting VS Code CLI..."
tar -xf vscode_cli.tar.gz
mv ./code $HOME/

# Add the 'code' command to the PATH by modifying .zshrc
log_info "Adding VS Code CLI to PATH..."
if ! grep -q "export PATH=\$HOME/code:\$PATH" "$HOME/.zshrc"; then
    echo 'export PATH=$HOME/code:$PATH' >> "$HOME/.zshrc"
    export PATH=$HOME/code:$PATH
    log_info "VS Code CLI added to PATH."
else
    log_info "VS Code CLI already in PATH."
fi

# Start VS Code server via tunnel, using the name from .private
source "$dotfiledir/.private"
log_info "Starting VS Code server using tunnel with name $VSCODE_TUNNEL_NAME..."
nohup $HOME/code tunnel --name "$VSCODE_TUNNEL_NAME" --accept-server-license-terms > "$HOME/vscode_tunnel.log" 2>&1 &
log_info "VS Code server tunnel started. check the log file at $HOME/vscode_tunnel.log"

# # Set up auto-start for VS Code server tunnel
# log_info "Setting up auto-start for VS Code Server Tunnel..."

# sudo bash -c "cat << EOF > /etc/systemd/system/vscode-server-tunnel.service
# [Unit]
# Description=VS Code Server Tunnel
# After=network.target

# [Service]
# ExecStart=$HOME/code tunnel --name $VSCODE_TUNNEL_NAME --accept-server-license-terms
# Restart=always
# User=$(whoami)

# [Install]
# WantedBy=multi-user.target
# EOF"

# # Enable and start the systemd service
# sudo systemctl daemon-reload
# sudo systemctl enable vscode-server-tunnel.service
# sudo systemctl start vscode-server-tunnel.service

