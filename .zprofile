# =====================================================
#  ~/.zprofile – executed once per login session
# =====================================================
# --------------------------------------------------
#  Oh‑My‑Zsh path (must be set before any .zshrc logic)
# --------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
# --------------------------------------------------
#  PATH configuration (executed at login)
# --------------------------------------------------
# LM Studio
export OLLAMA_BIND_ADDRESS=0.0.0.0
export PATH="$HOME/.cache/lm-studio/bin:$PATH"

# Function to export a variable only if directory exists
_export_if_dir() {
    local var_name=$1
    local dir_path=$2
    if [[ -d "$dir_path" ]]; then
        export $var_name="$dir_path"
    fi
}

# Helper to prepend a directory to PATH if it exists
_add_to_path_if_dir() {
    local dir=$1
    if [[ -d "$dir" ]]; then
        export PATH="$dir:$PATH"
    fi
}

# _export_if_dir "JENKINS_HOME" "$HOME/Documents/mywork/sag/jenkins_wm105/jenkins_home"
# _export_if_dir "GITLAB_HOME" "$HOME/Documents/mywork/docker/gitlab_rltd.gitlab_volume"
# _export_if_dir "IS_HOME" "/Applications/SoftwareAG/sag_10_15_sd_wjdk/wMServiceDesigner/IntegrationServer"

# Adds to PATH
_add_to_path_if_dir "$HOME/dotfiles/utils"
_add_to_path_if_dir "/Applications/LibreOffice.app/Contents/MacOS"

# Jenv (conditional)
if [ -d "$HOME/.jenv/bin" ]; then
    _add_to_path_if_dir "$HOME/.jenv/bin"
    eval "$(jenv init -)"
fi

# Homebrew environment (conditional)
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# MariaDB connector (conditional)
_add_to_path_if_dir "/opt/homebrew/opt/mariadb-connector-c/bin"

# UV completions (conditional)
if command -v uv &>/dev/null; then
    eval "$(uv generate-shell-completion zsh)"
    eval "$(uvx --generate-shell-completion zsh)"
fi

# Codeium / Antigravity / Opencode (conditional)
_add_to_path_if_dir "$HOME/.codeium/windsurf/bin"
_add_to_path_if_dir "$HOME/.antigravity/antigravity/bin"
_add_to_path_if_dir "$HOME/.opencode/bin"

# Docker Desktop completions (conditional)
if [ -d "$HOME/.docker/completions" ]; then
    fpath=($HOME/.docker/completions $fpath)
fi
autoload -Uz compinit
compinit
# --------------------------------------------------
#  End of PATH configuration
# --------------------------------------------------