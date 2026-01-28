#!/usr/bin/env zsh
############################
# This script creates symlinks from the home directory to any desired dotfiles in $HOME/dotfiles
# And also installs MacOS Software
# And also installs Homebrew Packages and Casks (Apps)
# And also sets up VS Code
# And also sets up Sublime Text
############################

# dotfiles directory
dotfiledir="${HOME}/dotfiles"

# list of files/folders to symlink in ${homedir}
files=(zshrc zprofile zprompt bashrc bash_profile bash_prompt aliases private)

# Reminder to ensure .private is ready
echo "--------------------------------------------------"
echo "REMINDER: Ensure you have your .private file ready if needed."
echo "If this is a new machine, you should copy your .private file to this directory now."
echo "--------------------------------------------------"
read -p "Press Enter to acknowledge and continue with installation..."

# change to the dotfiles directory
echo "Changing to the ${dotfiledir} directory"
cd "${dotfiledir}" || exit

# create symlinks (will backup old dotfiles with timestamp)
timestamp=$(date +%Y%m%d_%H%M%S)
for file in "${files[@]}"; do
    target_file="${HOME}/.${file}"
    if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        echo "Backing up existing .${file} to .${file}_${timestamp}.bak"
        mv "$target_file" "${target_file}_${timestamp}.bak"
    fi
    echo "Creating symlink to $file in home directory."
    ln -sf "${dotfiledir}/.${file}" "$target_file"
done

# Create symlinks for configs (will overwrite old configs)
mkdir -p "${HOME}/.config/ruff"
ln -sf "${dotfiledir}/settings/ruff.toml" "${HOME}/.config/ruff/ruff.toml"

# Update VS Code Python interpreter path based on hostname
HOSTNAME_SHORT=$(hostname -s | tr '[:upper:]' '[:lower:]')
VSCODE_SETTINGS="${dotfiledir}/settings/VSCode-Settings.json"
if [ -f "$VSCODE_SETTINGS" ]; then
    echo "Updating VS Code Python interpreter path for hostname: $HOSTNAME_SHORT"
    # Use sed to replace the placeholder or previous venv name with the current hostname-based one
    sed -i '' "s/\.venv_[^/]*\//.venv_${HOSTNAME_SHORT}\//g" "$VSCODE_SETTINGS"
fi

# Install Oh My Zsh if not already installed
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Oh My Zsh plugins if they don't exist
ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"
# Autosuggestions
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
    echo "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi
# Syntax Highlighting
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
    echo "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.0.8.0.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
fi
# Completions
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-completions" ]; then
    echo "Installing zsh-completions..."
    git clone https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM}/plugins/zsh-completions"
fi

# Set up Screenshot Renamer LaunchAgent
echo "Setting up Screenshot Renamer LaunchAgent..."
LAUNCH_AGENTS_DIR="${HOME}/Library/LaunchAgents"
PLIST_NAME="com.user.screenshot-renamer.plist"
mkdir -p "$LAUNCH_AGENTS_DIR"

# Template the plist with the current HOME path (LaunchAgents require absolute paths)
sed "s|{{HOME}}|${HOME}|g" "${dotfiledir}/settings/${PLIST_NAME}" > "$LAUNCH_AGENTS_DIR/${PLIST_NAME}"

# Unload if already loaded to pick up changes
launchctl unload "$LAUNCH_AGENTS_DIR/${PLIST_NAME}" 2>/dev/null
launchctl load "$LAUNCH_AGENTS_DIR/${PLIST_NAME}"

# Make scripts in utils executable
chmod +x "${dotfiledir}/utils/"*.sh 2>/dev/null
chmod +x "${dotfiledir}/utils/"*.py 2>/dev/null

# Run the MacOS Script
./macOS.sh

# Run the Homebrew Script
./brew.sh

# Run VS Code Script
./vscode.sh

# Run the Sublime Script
./sublime.sh

echo "Installation Complete!"
