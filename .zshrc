# =====================================================
#  ~/.zshrc — clean, fast, and safe configuration
# =====================================================

# --------------------------------------------------
#  1. Basics
# --------------------------------------------------
autoload -Uz colors && colors
setopt PROMPT_SUBST
setopt NO_NOMATCH

# --------------------------------------------------
#  2. History
# --------------------------------------------------
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

setopt SHARE_HISTORY \
       APPEND_HISTORY \
       HIST_REDUCE_BLANKS \
       HIST_IGNORE_SPACE \
       HIST_EXPIRE_DUPS_FIRST

# --------------------------------------------------
#  3. Oh My Zsh (plugins BEFORE sourcing)
# --------------------------------------------------
ZSH_THEME="robbyrussell"

available_plugins=()
for p in git docker docker-compose zsh-autosuggestions zsh-completions zsh-syntax-highlighting; do
  if [[ -d "$ZSH/plugins/$p" || -d "$ZSH_CUSTOM/plugins/$p" ]]; then
    available_plugins+=("$p")
  fi
done
plugins=($available_plugins)

if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  echo "Warning: Oh My Zsh not found at $ZSH"
fi

# --------------------------------------------------
#  4. Completions
# --------------------------------------------------
if [[ -d "$HOME/.docker/completions" ]]; then
  fpath=("$HOME/.docker/completions" $fpath)
fi
# OMZ handles compinit

# --------------------------------------------------
#  5. Tool integrations
# --------------------------------------------------

# kubectl
if command -v kubectl &>/dev/null; then
  source <(kubectl completion zsh)
fi

# uv / uvx
if command -v uv &>/dev/null; then
  eval "$(uv generate-shell-completion zsh)"
  eval "$(uvx --generate-shell-completion zsh)"
fi

# GitHub Copilot CLI
if command -v gh &>/dev/null; then
  if gh extension list 2>/dev/null | grep -q '^gh-copilot'; then
    eval "$(gh copilot alias -- zsh)"
  fi
fi

# --------------------------------------------------
#  6. Custom files
# --------------------------------------------------
for file in "$HOME"/.{aliases,private}; do
  [[ -r "$file" && -f "$file" ]] && source "$file"
done
unset file

# --------------------------------------------------
#  7. Key bindings
# --------------------------------------------------
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# =====================================================
#  8. Cleanup utilities
# =====================================================

ds_clean() {
  local dry_run=false
  [[ "$1" == "--dry" ]] && dry_run=true && shift

  local target="${1:-.}"
  if [[ ! -d "$target" ]]; then
    echo "Usage: ds_clean [--dry] [directory]"
    return 1
  fi

  echo "Cleaning .DS_Store files in: $target"

  if $dry_run; then
    find "$target" -type f -name ".DS_Store" -print
  else
    find "$target" -type f -name ".DS_Store" -print -delete
  fi
}

empty_dirs_clean() {
  local dry_run=false
  [[ "$1" == "--dry" ]] && dry_run=true && shift

  local target="${1:-.}"
  if [[ ! -d "$target" ]]; then
    echo "Usage: empty_dirs_clean [--dry] [directory]"
    return 1
  fi

  echo "Cleaning empty directories in: $target"

  if $dry_run; then
    find "$target" -type d -empty -print
  else
    find "$target" -type d -empty -print -delete
  fi
}

full_clean() {
  local dry_run=false
  [[ "$1" == "--dry" ]] && dry_run=true && shift

  local target="${1:-.}"
  if [[ ! -d "$target" ]]; then
    echo "Usage: full_clean [--dry] [directory]"
    return 1
  fi

  echo "Step 1: Removing .DS_Store files"
  if $dry_run; then
    find "$target" -type f -name ".DS_Store" -print
  else
    find "$target" -type f -name ".DS_Store" -print -delete
  fi

  echo "Step 2: Removing empty directories"
  if $dry_run; then
    find "$target" -type d -empty -print
  else
    while find "$target" -type d -empty -print -quit | grep -q .; do
      find "$target" -type d -empty -print -delete
    done
  fi

  echo "Cleanup complete"
}

cleanup_py() {
  if [[ -z "$1" ]]; then
    echo "Usage: cleanup_py <directory>"
    echo "Example: cleanup_py /path/to/project"
    return 1
  fi

  local target="$1"
  if [[ ! -d "$target" ]]; then
    echo "Error: '$target' is not a directory"
    return 1
  fi

  find "$target" -type d -name ".venv" -prune -exec rm -rf {} +
  find "$target" -type d -name "__pycache__" -prune -exec rm -rf {} +
  say "Python cleanup of $(basename "$target") folder is complete"
}