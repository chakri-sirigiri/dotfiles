# =====================================================
#  ~/.zshrc – executed for every interactive zsh session
# =====================================================
autoload -Uz colors && colors
setopt PROMPT_SUBST
setopt no_nomatch
# --------------------------------------------------
#  History settings (per‑session)
# --------------------------------------------------
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt SHARE_HISTORY APPEND_HISTORY HIST_REDUCE_BLANKS HIST_IGNORE_SPACE HIST_EXPIRE_DUPS_FIRST
# --------------------------------------------------
#  Oh‑My‑Zsh
# --------------------------------------------------
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source $ZSH/oh-my-zsh.sh
else
    echo "Warning: Oh My Zsh not found at $ZSH"
fi

# --------------------------------------------------
#  Theme & plugins
# --------------------------------------------------
ZSH_THEME="robbyrussell"
# Check which plugins actually exist before enabling them
available_plugins=()
for p in git docker docker-compose zsh-autosuggestions zsh-completions zsh-syntax-highlighting; do
    if [ -d "$ZSH/plugins/$p" ] || [ -d "$ZSH_CUSTOM/plugins/$p" ]; then
        available_plugins+=("$p")
    fi
done
plugins=($available_plugins)


# Kubectl completion (if installed)
if command -v kubectl &>/dev/null; then
    source <(kubectl completion zsh)
fi
# --------------------------------------------------
#  Load custom dotfiles
# --------------------------------------------------
for file in ~/.{aliases,private}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file
# --------------------------------------------------
#  GitHub Copilot CLI shell integration
# --------------------------------------------------
if command -v gh &>/dev/null; then
    # Check if copilot extension is installed
    if gh extension list | grep -q 'gh-copilot'; then
        eval "$(gh copilot alias -- zsh)"
    fi
fi
# --------------------------------------------------
#  History search key bindings
# --------------------------------------------------
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search