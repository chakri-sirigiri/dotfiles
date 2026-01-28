# Development Environment Setup

This repository contains scripts and configuration files to set up a development environment for macOS. It's tailored for software development, focusing on a clean, minimal, and efficient setup.

## Overview

The setup includes automated scripts for installing essential software, configuring Bash and Zsh shells, and setting up Sublime Text and Visual Studio Code editors. This guide will help you replicate this development environment on your machine.

## Important Note Before Installation

**WARNING:** The configurations and scripts in this repository will **MODIFY** your current system, potentially making some changes that are **IRREVERSIBLE** without a fresh installation of your operating system.

While the scripts strive to backup files wherever possible, we cannot guarantee that all files are backed up. The backup mechanism is designed to backup files **ONCE**. If the script is run more than once, the initial backups will be **OVERWRITTEN**, potentially resulting in loss of data.

If you would like to use this development environment, it's highly encouraged to fork this repository and make your own personalized changes to these scripts instead of running them exactly as written.

If you choose to run these scripts, please do so with **EXTREME CAUTION**. It's recommended to review the scripts and understand the changes they will make to your system before proceeding.

By using these scripts, you acknowledge and accept the risk of potential data loss or system alteration. Proceed at your own risk.

## Getting Started

### Prerequisites

- macOS (The scripts are tailored for macOS)

### Installation

1. Clone the repository to your local machine:
   ```sh
   git clone https://github.com/chakri-sirigiri/dotfiles.git ~/dotfiles
   ```
2. Navigate to the `dotfiles` directory:
   ```sh
   cd ~/dotfiles
   ```
3. Run the installation script:
   ```sh
   ./install.sh
   ```

### Safe Verification (Read-Only)

If you want to see what changes `install.sh` would make to your Homebrew setup *before* running it, you can run the read-only check script:

```sh
./brew_check.sh
```

This will compare your current system against `brew.sh` and list missing/extra packages without modifying anything.

This script will:

- Create symlinks for dotfiles (`.bashrc`, `.zshrc`, etc.)
- Run macOS-specific configurations
- Install Homebrew packages and casks
- Configure Sublime Text and Visual Studio Code

## Configuration Files

- `.bashrc` & `.zshrc`: Shell configuration files for Bash and Zsh.
- `.shared_prompt`: Custom prompt setup used by both `.bash_prompt` & `.zprompt`
- `.bash_prompt` & `.zprompt`: Custom prompt setup for Bash and Zsh.
- `.bash_profile`: Setting system-wide environment variables
- `.aliases`: Aliases for common commands, including:
  - `dedup`: Backup deduplication script with safety confirmations
  - `rmds`: Recursively find and delete .DS_Store files with path logging
- `.private`: This is a file you'll create locally to hold private information and shouldn't be uploaded to version control
- `utils/`: Directory containing utility scripts:
  - `dedup_backup.sh`: Safe backup deduplication with user confirmations
- `settings/`: Directory containing editor settings and themes for Sublime Text and Visual Studio Code.

### Customizing Your Setup

You're encouraged to modify the scripts and configuration files to suit your preferences. Here are some tips for customization:

- **Dotfiles**: Edit `.shared_prompt`, `.zprompt`, `.bash_prompt` to add or modify shell configurations.
- **Sublime Text and VS Code**: Adjust settings in the `settings/` directory to change editor preferences and themes.

## Contributing

Feel free to fork this repository and customize it for your setup. Pull requests for improvements and bug fixes are welcome.

## License

This project is licensed under the MIT License - see the [LICENSE-MIT.txt](LICENSE-MIT.txt) file for details.

## Acknowledgments

- Originally forked from [Corey Schafer's dotfiles](https://github.com/CoreyMSchafer/dotfiles), which was in turn forked from [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles)
- Thanks to all the open-source projects used in this setup.
