#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export TERM="${TERM:-xterm-256color}"

pass() { printf "PASS: %s\n" "$1"; }
fail() { printf "FAIL: %s\n" "$1" >&2; }

shopt -s nullglob
test_files=("$ROOT_DIR"/tests/unit-test-*)
shopt -u nullglob

if (( ${#test_files[@]} == 0 )); then
  fail "no unit-test files found under tests/unit-test-*"
  exit 1
fi

# 1) Syntax checks
bash -n "$ROOT_DIR/bash_prompt" "$ROOT_DIR"/bash_prompt.d/*.sh "${test_files[@]}"
pass "syntax"

# 2) Runtime smoke checks for each unit-test config
run_smoke() {
  local mode="$1"
  local workdir="$2"
  local test_file="$3"
  local test_name
  local err_file

  test_name="$(basename -- "$test_file")"
  err_file="$(mktemp)"

  if ROOT_DIR="$ROOT_DIR" WORKDIR="$workdir" TEST_FILE="$test_file" bash -lc '
    set -euo pipefail
    export TERM="${TERM:-xterm-256color}"
    cd "$WORKDIR"

    source "$TEST_FILE"

    [[ ${left+x} ]] || { echo "missing left in test file" >&2; exit 1; }
    [[ ${center+x} ]] || { echo "missing center in test file" >&2; exit 1; }
    [[ ${right+x} ]] || { echo "missing right in test file" >&2; exit 1; }
    [[ ${prompt_color+x} ]] || { echo "missing prompt_color in test file" >&2; exit 1; }
    declare -p segments >/dev/null 2>&1
    [[ "${#segments[@]}" -gt 0 ]]

    for f in "$ROOT_DIR/bash_prompt.d"/*.sh; do
      [ -r "$f" ] && source "$f"
    done

    color_init
    terminal_init

    status_bar_init segments "$left" "$center" "$right"
    __status_bar_build
    __status_bar_draw >/dev/null
  ' 2>"$err_file"; then
    pass "${test_name}:${mode}"
  else
    fail "${test_name}:${mode}"
    sed -n '1,8p' "$err_file" >&2
    rm -f "$err_file"
    return 1
  fi

  rm -f "$err_file"
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

for test_file in "${test_files[@]}"; do
  run_smoke "non-git" "$tmp_dir" "$test_file"
  run_smoke "git" "$ROOT_DIR" "$test_file"
done

pass "validate"
