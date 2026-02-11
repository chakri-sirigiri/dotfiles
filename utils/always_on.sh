#!/bin/bash

# always_on.sh - Toggle macOS power management and screensaver settings.
# Toggles between a "DEFAULT" mode (energy saving) and an "ALWAYS-ON" mode (preventing sleep).

MODE_FILE="$HOME/.always_on_mode"

show_help() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Toggles macOS power management and screensaver settings."
    echo ""
    echo "Options:"
    echo "  -s, --status   Check the current mode without changing it."
    echo "  -h, --help     Show this help message."
    echo ""
}

get_status() {
    if [ -f "$MODE_FILE" ]; then
        echo "Current Mode: ALWAYS-ON"
    else
        echo "Current Mode: DEFAULT"
    fi
    echo ""
    echo "Current Power Settings (pmset):"
    pmset -g | grep -E "sleep|displaysleep|disksleep"
}

set_default_mode() {
    echo "Switching to DEFAULT mode..."
    
    # Check for sudo permissions first
    if ! sudo -n pmset -a displaysleep 10 sleep 30 disksleep 10 >/dev/null 2>&1; then
        echo "Error: This script requires sudo privileges to change power settings."
        echo "Prompting for password..."
        sudo pmset -a displaysleep 10 sleep 30 disksleep 10 || return 1
    fi

    defaults -currentHost write com.apple.screensaver idleTime 600
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0

    rm -f "$MODE_FILE"
    echo "Successfully switched to DEFAULT mode."
}

set_always_on_mode() {
    echo "Switching to ALWAYS-ON mode..."
    
    # Check for sudo permissions first
    if ! sudo -n pmset -a displaysleep 0 sleep 0 disksleep 0 >/dev/null 2>&1; then
        echo "Error: This script requires sudo privileges to change power settings."
        echo "Prompting for password..."
        sudo pmset -a displaysleep 0 sleep 0 disksleep 0 || return 1
    fi

    defaults -currentHost write com.apple.screensaver idleTime 0
    defaults write com.apple.screensaver askForPassword -int 0

    touch "$MODE_FILE"
    echo "Successfully switched to ALWAYS-ON mode."
}

# Parse command line arguments
case "$1" in
    -s|--status)
        get_status
        exit 0
        ;;
    -h|--help)
        show_help
        exit 0
        ;;
    "")
        # No arguments, proceed with toggle
        ;;
    *)
        echo "Error: Unknown option '$1'"
        show_help
        exit 1
        ;;
esac

# Toggle mode
if [ -f "$MODE_FILE" ]; then
    set_default_mode
else
    set_always_on_mode
fi

echo ""
get_status
