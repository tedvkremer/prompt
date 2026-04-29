#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export TERM="${TERM:-xterm-256color}"

pass() { printf "PASS: %s\n" "$1"; }
fail() { printf "FAIL: %s\n" "$1" >&2; }
skip() { printf "SKIP: %s\n" "$1"; }

shopt -s nullglob
test_files=("$ROOT_DIR"/tests/unit-test-*)
shopt -u nullglob

if (( ${#test_files[@]} == 0 )); then
  fail "no unit-test files found under tests/unit-test-*"
  exit 1
fi

# 1) Syntax checks
bash -n "$ROOT_DIR/teds_prompt" "$ROOT_DIR"/teds_prompt.d/*.sh "${test_files[@]}"
pass "syntax:bash"

if command -v zsh >/dev/null 2>&1; then
  zsh -n "$ROOT_DIR/teds_prompt" "$ROOT_DIR"/teds_prompt.d/*.sh "${test_files[@]}"
  pass "syntax:zsh"
fi

# 2) Runtime smoke checks
#
# The inline script is valid in both bash (4.3+) and zsh (5.1+).
# $1 = shell binary  $2 = mode  $3 = workdir  $4 = test_file
run_smoke() {
  local shell_bin="$1" mode="$2" workdir="$3" test_file="$4"
  local shell_name test_name err_file

  shell_name="$(basename -- "$shell_bin")"
  test_name="$(basename -- "$test_file")"
  err_file="$(mktemp)"

  # bash: -lc for a login shell so PATH is fully populated
  # zsh:  --no-rcs -c to avoid sourcing the user's .zshrc (which may
  #       already source teds_prompt and interfere with the test)
  local -a shell_opts
  case "$shell_name" in
    zsh) shell_opts=(--no-rcs -c) ;;
    *)   shell_opts=(-lc) ;;
  esac

  if ROOT_DIR="$ROOT_DIR" WORKDIR="$workdir" TEST_FILE="$test_file" \
     "$shell_bin" "${shell_opts[@]}" '
    set -euo pipefail
    export TERM="${TERM:-xterm-256color}"
    cd "$WORKDIR"

    source "$TEST_FILE"

    [[ ${left+x} ]]         || { echo "missing left in test file" >&2; exit 1; }
    [[ ${center+x} ]]       || { echo "missing center in test file" >&2; exit 1; }
    [[ ${right+x} ]]        || { echo "missing right in test file" >&2; exit 1; }
    [[ ${prompt_color+x} ]] || { echo "missing prompt_color in test file" >&2; exit 1; }
    [[ "${#segments[@]}" -gt 0 ]] || { echo "segments array empty" >&2; exit 1; }

    for f in "$ROOT_DIR/teds_prompt.d"/*.sh; do
      [ -r "$f" ] && source "$f"
    done

    color_init
    terminal_init

    status_bar_init segments "$left" "$center" "$right"
    __status_bar_build
    __status_bar_draw >/dev/null
  ' 2>"$err_file"; then
    pass "${test_name}:${shell_name}:${mode}"
  else
    fail "${test_name}:${shell_name}:${mode}"
    sed -n '1,8p' "$err_file" >&2
    rm -f "$err_file"
    return 1
  fi

  rm -f "$err_file"
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# Detect which shells are usable
bash_bin=""
if bash -c '(( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 3) ))' 2>/dev/null; then
  bash_bin="$(command -v bash)"
fi

zsh_bin=""
if command -v zsh >/dev/null 2>&1; then
  zsh_bin="$(command -v zsh)"
fi

if [[ -z "$bash_bin" && -z "$zsh_bin" ]]; then
  fail "neither bash >= 4.3 nor zsh is available — cannot run smoke tests"
  exit 1
fi

[[ -z "$bash_bin" ]] && skip "bash smoke tests (bash >= 4.3 not found, have: $BASH_VERSION)"
[[ -z "$zsh_bin"  ]] && skip "zsh smoke tests (zsh not found)"

for test_file in "${test_files[@]}"; do
  [[ -n "$bash_bin" ]] && run_smoke "$bash_bin" "non-git" "$tmp_dir"    "$test_file"
  [[ -n "$bash_bin" ]] && run_smoke "$bash_bin" "git"     "$ROOT_DIR"   "$test_file"
  [[ -n "$zsh_bin"  ]] && run_smoke "$zsh_bin"  "non-git" "$tmp_dir"    "$test_file"
  [[ -n "$zsh_bin"  ]] && run_smoke "$zsh_bin"  "git"     "$ROOT_DIR"   "$test_file"
done

pass "validate"
