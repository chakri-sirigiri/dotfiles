# If not running interactively, exit script
[[ $- != *i* ]] && return

# Load dotfiles:
# I DO NOT WANT TO USE BASH_PROMPT
# for file in ~/.{bash_prompt,aliases,private}; do
for file in ~/.{aliases,private}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

# GitHub Copilot CLI shell integration
eval "$(gh copilot alias -- bash)"
