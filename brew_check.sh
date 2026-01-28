#!/usr/bin/env zsh
#
# brew_check.sh – Compare the contents of `brew.sh` with what Homebrew actually has installed.
#
# This script intentionally **does not** run any commands that are in brew.sh
# (e.g. `brew update`, `brew install`). It only parses the array declarations
# and then queries Homebrew for what is installed on the system.
#
# Usage:
#   ./brew_check.sh
#
# ------------------------------------------------------------
set -euo pipefail

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"
BREW_SH="${SCRIPT_DIR}/brew.sh"

if [[ ! -f "$BREW_SH" ]]; then
  echo "Error: brew.sh not found at $BREW_SH"
  exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# -------------------------------------------------------------------
# 1. Extract the raw contents of each array from brew.sh without executing it.
# -------------------------------------------------------------------
extract_array() {
  local name=$1
  # Use sed to extract lines between the array declaration and the closing parenthesis
  sed -n "/^$name=(/,/^)/p" "$BREW_SH" | sed '1d;$d'
}

# -------------------------------------------------------------------
# 2. Turn the raw lines into clean package names.
# -------------------------------------------------------------------
parse_array() {
  local raw=$1
  # Remove comments, trim whitespace, and extract quoted strings
  echo "$raw" | sed 's/#.*//' | tr -d '[:space:]' | grep -oE '"[^"]+"' | tr -d '"'
}

echo -e "${BLUE}=== Analyzing Homebrew Setup (Read-Only) ===${NC}\n"

echo -e "${YELLOW}Reading desired state from: ${NC}$BREW_SH"

packages_raw=$(extract_array packages)
apps_raw=$(extract_array apps)

packages=($(parse_array "$packages_raw"))
apps=($(parse_array "$apps_raw"))
# fonts_raw=$(extract_array fonts)
# fonts=($(parse_array "$fonts_raw"))

# -------------------------------------------------------------------
# 3. Gather what is actually installed by Homebrew.
# -------------------------------------------------------------------
echo -e "${YELLOW}Querying Homebrew for installed components...${NC}"
# Use || true and suppress stderr for broken casks/formulae
installed_formula=($(brew list --formula 2>/dev/null || true | sort -u))
installed_leaves=($(brew leaves 2>/dev/null || true | sort -u))
installed_cask=($(brew list --cask 2>/dev/null || true | sort -u))

# -------------------------------------------------------------------
# 4. Helper for comparison
# -------------------------------------------------------------------
check_category() {
  local label=$1
  local count=$2
  shift 2
  
  local -a desired=("${(@)argv[1,count]}")
  shift $count
  # Arguments: desired_formula_count [desired_formula...] [installed_formula...] [optional_extras_filter...]
  # However, it's easier to just pass the extra_filter list if it exists.
  # Let's simplify: 
  # check_category "Label" desired_count [desired...] installed_count [installed...] extras_filter_count [extras_filter...]
  
  local inst_count=$1
  shift
  local -a installed=("${(@)argv[1,inst_count]}")
  shift $inst_count
  
  local filter_count=$1
  shift
  local -a extras_to_show=("${(@)argv[1,filter_count]}")

  local -a missing=()
  local -a extra=()
  local -a matched=()

  # Use associative arrays for membership checks
  typeset -A installed_set
  for i in "${installed[@]}"; do
    installed_set[$i]=1
  done

  # Find missing (in desired but not in installed)
  for d in "${desired[@]}"; do
    if [[ -v "installed_set[$d]" ]]; then
      matched+=("$d")
    else
      # Fallback for Casks: check if it exists manually in /Applications
      local is_manual=0
      if [[ "$label" == "Cask Apps" ]]; then
        # Try a few common mappings (e.g. google-chrome -> Google Chrome)
        # Replacing hyphens with spaces and capitalizing
        local app_name=$(echo "$d" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        if [[ -d "/Applications/${app_name}.app" ]] || [[ -d "${HOME}/Applications/${app_name}.app" ]]; then
          is_manual=1
        elif [[ "$d" == "google-chrome" && -d "/Applications/Google Chrome.app" ]]; then
          is_manual=1
        elif [[ "$d" == "visual-studio-code" && -d "/Applications/Visual Studio Code.app" ]]; then
          is_manual=1
        elif [[ "$d" == "sublime-text" && -d "/Applications/Sublime Text.app" ]]; then
          is_manual=1
        fi
      fi
      
      if [[ $is_manual -eq 1 ]]; then
        matched+=("$d (manual)")
      else
        missing+=("$d")
      fi
    fi
  done

  # Find extra
  typeset -A desired_set
  for d in "${desired[@]}"; do
    desired_set[$d]=1
  done

  # If an extras_to_show filter was provided, only check those for "Extra" status
  local -a base_extra_list
  if [[ ${#extras_to_show[@]} -gt 0 ]]; then
    base_extra_list=("${extras_to_show[@]}")
  else
    base_extra_list=("${installed[@]}")
  fi

  for i in "${base_extra_list[@]}"; do
    if [[ ! -v "desired_set[$i]" ]]; then
      extra+=("$i")
    fi
  done

  echo -e "\n${BLUE}--- $label ---${NC}"
  echo -e "  Desired (in brew.sh): ${YELLOW}${#desired[@]}${NC}"
  echo -e "  Installed on system:  ${YELLOW}${#installed[@]}${NC}"
  echo -e "  Match:                ${GREEN}${#matched[@]}${NC}"
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "  ${RED}Missing (to be installed):${NC} ${#missing[@]}"
    for m in "${missing[@]}"; do
      echo -e "    ${RED}✘${NC} $m"
    done
  fi

  # Filter extras for fonts specifically
  if [[ "$label" == "Fonts" ]]; then
    local -a extra_fonts=()
    for e in "${extra[@]}"; do
      if [[ "$e" == font-* ]]; then
        extra_fonts+=("$e")
      fi
    done
    extra=("${extra_fonts[@]}")
  fi

  if [[ ${#extra[@]} -gt 0 ]]; then
    if [[ "$label" == "Formula Packages" ]]; then
      echo -e "  ${YELLOW}Extra (top-level packages not in brew.sh):${NC} ${#extra[@]}"
    else
      echo -e "  ${YELLOW}Extra (not in brew.sh):${NC} ${#extra[@]}"
    fi
    for e in "${extra[@]}"; do
      echo -e "    ${YELLOW}?${NC} $e"
    done
  fi
}

# -------------------------------------------------------------------
# 5. Run comparisons
# -------------------------------------------------------------------

# Filter out fonts from the main apps comparison to avoid duplication
apps_only_installed=()
for c in "${installed_cask[@]}"; do
  if [[ "$c" != font-* ]]; then
    apps_only_installed+=("$c")
  fi
done

# We pass installed_leaves as the extras filter for Formula Packages
check_category "Formula Packages" ${#packages[@]} "${packages[@]}" ${#installed_formula[@]} "${installed_formula[@]}" ${#installed_leaves[@]} "${installed_leaves[@]}"
check_category "Cask Apps"        ${#apps[@]}     "${apps[@]}"     ${#apps_only_installed[@]}  "${apps_only_installed[@]}" 0
# installed_fonts=()
# for c in "${installed_cask[@]}"; do
#   if [[ "$c" == font-* ]]; then
#     installed_fonts+=("$c")
#   fi
# done
# check_category "Fonts"            ${#fonts[@]}    "${fonts[@]}"    ${#installed_fonts[@]}     "${installed_fonts[@]}"     0

echo -e "\n${BLUE}===========================================${NC}"
echo -e "${YELLOW}Summary complete.${NC} No changes were made to your system."

exit 0
