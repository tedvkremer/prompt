#!/usr/bin/env bash
# Enhanced Installer by Gemini CLI

set -euo pipefail

# --- UI / Styling ---
R=$'\e[0m'
B=$'\e[1m'
C_CYAN=$'\e[36m'
C_GREEN=$'\e[32m'
C_BLUE=$'\e[34m'
C_RED=$'\e[31m'
C_GRAY=$'\e[90m'
C_ORANGE=$'\e[38;5;208m'
C_PURPLE=$'\e[38;5;141m'

# Box Drawing Characters (Round Corners)
TL="╭"
TR="╮"
BL="╰"
BR="╯"
H="─"
V="│"

WIDTH=64

draw_header() {
  local title="$1"
  local color="$2"
  local title_len=${#title}
  local padding=$(( WIDTH - title_len - 4 ))
  local side_len=$(( padding / 2 ))
  local extra=$(( padding % 2 ))

  local line_l=""
  local line_r=""
  for ((i=0; i<side_len; i++)); do line_l="${line_l}${H}"; done
  for ((i=0; i<side_len+extra; i++)); do line_r="${line_r}${H}"; done

  echo ""
  echo "${color}${TL}${line_l} ${B}${title}${R}${color} ${line_r}${TR}${R}"
}

draw_footer() {
  local color="$1"
  local line=""
  for ((i=0; i<WIDTH-2; i++)); do line="${line}${H}"; done
  echo "${color}${BL}${line}${BR}${R}"
  echo ""
}

log_row() {
  local key="$1"
  local val="$2"
  local max_len=$(( WIDTH - 20 ))

  if (( ${#val} > max_len )); then
    val="${val:0:$((max_len-3))}..."
  fi

  local pad_len=$(( WIDTH - 19 - ${#val} - 1 ))
  local pad=""
  for ((i=0; i<pad_len; i++)); do pad="${pad} "; done

  printf "${C_ORANGE}${V}${R}  ${B}%-15s${R} %s%s${C_ORANGE}${V}${R}\n" "$key" "$val" "$pad"
}

log_step() {
  local msg="$1"
  printf "${C_ORANGE}${V}${R}  ${C_BLUE}•${R} %-40s" "$msg..."
}

log_result() {
  local status="$1"
  local status_text
  local status_len

  if (( status == 0 )); then
    status_text="${C_GREEN}✔ Done${R}"
    status_len=6
  else
    status_text="${C_RED}✘ Failed${R}"
    status_len=8
  fi

  local used=45
  local available=$(( WIDTH - 1 - used ))
  local pad_len=$(( available - status_len ))

  local pad=""
  for ((i=0; i<pad_len; i++)); do pad="${pad} "; done

  printf "%s%s${C_ORANGE}${V}${R}\n" "$status_text" "$pad"
}

log_msg() {
  local msg="$1"
  local max_len=$(( WIDTH - 8 ))
  if (( ${#msg} > max_len )); then
    msg="${msg:0:$((max_len-3))}..."
  fi

  local pad_len=$(( WIDTH - 7 - ${#msg} - 1 ))
  local pad=""
  for ((i=0; i<pad_len; i++)); do pad="${pad} "; done

  printf "${C_ORANGE}${V}${R}      ${C_CYAN}%s${R}%s${C_ORANGE}${V}${R}\n" "$msg" "$pad"
}

# --- Logic ---

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PROMPT="$HOME/.bash_prompt"
TARGET_DIR="$HOME/.bash_prompt.d"

rotate_backups() {
  local path="$1"
  # Shift .2 -> .3, .1 -> .2
  rm -rf "${path}.bak.3"
  [[ -e "${path}.bak.2" ]] && mv "${path}.bak.2" "${path}.bak.3"
  [[ -e "${path}.bak.1" ]] && mv "${path}.bak.1" "${path}.bak.2"
}

safe_install() {
  local src="$1"
  local dest="$2"
  local type="$3" # "file" or "dir"

  # 1. Stage new version to .tmp
  rm -rf "${dest}.tmp"
  if [[ "$type" == "dir" ]]; then
    mkdir -p "${dest}.tmp"
    cp -a "$src/"* "${dest}.tmp/"
  else
    cp -f "$src" "${dest}.tmp"
  fi

  # 2. Move existing to .bak.0 (Hold)
  rm -rf "${dest}.bak.0"
  local has_existing=0
  if [[ -e "$dest" ]]; then
    mv "$dest" "${dest}.bak.0"
    has_existing=1
  fi

  # 3. Swap in new version
  if mv "${dest}.tmp" "$dest"; then
    # Success: Commit backup
    if (( has_existing )); then
      rotate_backups "$dest"
      mv "${dest}.bak.0" "${dest}.bak.1"
      return 1 # Code 1 indicates "Installed + Backup created" for logging
    fi
    return 0 # Code 0 indicates "Installed (fresh)"
  else
    # Failure: Rollback
    rm -rf "$dest" # Clean up partial mess if any
    if (( has_existing )); then
      mv "${dest}.bak.0" "$dest"
    fi
    return 2 # Code 2 indicates failure
  fi
}

# --- Execution ---

clear
draw_header "\"TED'S PROMPT\" INSTALLER" "$C_ORANGE"

log_row "Source" "$SRC_DIR"
log_row "Target" "$HOME"
printf "${C_ORANGE}${V}%*s${V}${R}\n" $((WIDTH-2)) ""

# 1. Validation
log_step "Checking prerequisites"
if [[ ! -f "$SRC_DIR/bash_prompt" ]] || [[ ! -d "$SRC_DIR/bash_prompt.d" ]]; then
  log_result 1
  log_msg "Missing source files in: $SRC_DIR"
  draw_footer "$C_ORANGE"
  exit 1
fi
log_result 0

# 2. Install Main Script
log_step "Installing main script"
set +e
safe_install "$SRC_DIR/bash_prompt" "$TARGET_PROMPT" "file"
RET=$?
set -e
if (( RET == 2 )); then
  log_result 1
  log_msg "Failed to install bash_prompt"
  draw_footer "$C_ORANGE"
  exit 1
fi
log_result 0
if (( RET == 1 )); then
  log_msg "Existing file saved to .bak.1"
fi

# 3. Install Directory
log_step "Installing library files"
set +e
safe_install "$SRC_DIR/bash_prompt.d" "$TARGET_DIR" "dir"
RET=$?
set -e
if (( RET == 2 )); then
  log_result 1
  log_msg "Failed to install bash_prompt.d"
  draw_footer "$C_ORANGE"
  exit 1
fi
log_result 0
if (( RET == 1 )); then
  log_msg "Existing directory saved to .bak.1"
fi

# 4. Config
log_step "Configuring paths"
sed -i 's|^PROMPT_DIR=.*|PROMPT_DIR="$HOME/.bash_prompt.d"|' "$TARGET_PROMPT"
log_result 0

draw_footer "$C_ORANGE"

# Summary
SOURCE_LINE='[ -r "$HOME/.bash_prompt" ] && source "$HOME/.bash_prompt"'

echo "  ${C_GREEN}${B}Success!${R} The prompt has been installed."
echo ""
echo "  To activate, add the following to your shell config:"
echo "  (e.g., ${C_CYAN}~/.bashrc${R} or ${C_CYAN}~/.bash_profile${R})"
echo ""
echo "  ${C_PURPLE}${SOURCE_LINE}${R}"
echo ""
