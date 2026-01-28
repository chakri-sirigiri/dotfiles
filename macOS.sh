#!/usr/bin/env zsh

xcode-select --install

echo "Complete the installation of Xcode Command Line Tools before proceeding."
echo "Press enter to continue..."
read

# Set scroll as traditional instead of natural
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
killall Finder

# Set location for screenshots
mkdir -p "${HOME}/Desktop/Screenshots"
defaults write com.apple.screencapture location "${HOME}/Desktop/Screenshots"
# Set screenshot prefix
defaults write com.apple.screencapture name "Screenshot"
# Set screenshot format to JPEG
defaults write com.apple.screencapture type -string "jpg"
killall SystemUIServer

# Add Bluetooth to Menu Bar for battery percentages
defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true
killall ControlCenter

# Get the absolute path to the image
IMAGE_PATH="${HOME}/dotfiles/settings/Desktop-ultrawide-monitor3840x1080-wallpapers.jpg"

# AppleScript command to set the desktop background
osascript <<EOF
tell application "System Events"
    set desktopCount to count of desktops
    repeat with desktopNumber from 1 to desktopCount
        tell desktop desktopNumber
            set picture to "$IMAGE_PATH"
        end tell
    end repeat
end tell
EOF

manual_installs=(
    "Bitwarden"
    "digiKam"
    "ChatGPT"
    "iMazing"
)

# Loop over the array to install each application.
for app in "${manual_installs[@]}"; do
    echo "Install $app manually"
    echo "Press enter to continue..."
    read
done
