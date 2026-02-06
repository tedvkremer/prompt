#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PROMPT="$HOME/.bash_prompt"
TARGET_DIR="$HOME/.bash_prompt.d"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

backup_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    mv "$path" "${path}.bak.${TIMESTAMP}"
  fi
}

if [[ ! -f "$SRC_DIR/bash_prompt" ]]; then
  printf "Error: missing %s\n" "$SRC_DIR/bash_prompt" >&2
  exit 1
fi
if [[ ! -d "$SRC_DIR/bash_prompt.d" ]]; then
  printf "Error: missing %s\n" "$SRC_DIR/bash_prompt.d" >&2
  exit 1
fi

backup_if_exists "$TARGET_PROMPT"
backup_if_exists "$TARGET_DIR"

cp -f "$SRC_DIR/bash_prompt" "$TARGET_PROMPT"
cp -a "$SRC_DIR/bash_prompt.d" "$TARGET_DIR"

sed -i 's|^PROMPT_DIR=.*|PROMPT_DIR="$HOME/.bash_prompt.d"|' "$TARGET_PROMPT"

SOURCE_LINE='[ -r "$HOME/.bash_prompt" ] && source "$HOME/.bash_prompt"'

printf "Installed prompt to %s and %s\n" "$TARGET_PROMPT" "$TARGET_DIR"
printf "Backups (if any) saved with .bak.%s\n" "$TIMESTAMP"
printf "Add this to your shell config if desired:\n  %s\n" "$SOURCE_LINE"
