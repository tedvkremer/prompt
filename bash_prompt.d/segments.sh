# Segments DSL: name|glyph|width|color|style|value_fn
#
# - glyph: icon glyph
# - width: column width of glyph
# - color: color name resolved by color_print
# - style: "bold" or "git" (special renderer)
# - value_fn: stdout-returning value provider

declare -A seg_glyph seg_width seg_color seg_style seg_value
icon_glyphs=()
icon_widths=()

segments_init() {
  local segment_defs="$1"

  local line name glyph width color style value_fn
  while IFS='|' read -r name glyph width color style value_fn; do
    [[ -z $name ]] && continue
    seg_glyph["$name"]="$glyph"
    seg_width["$name"]="$width"
    seg_color["$name"]="$color"
    seg_style["$name"]="$style"
    seg_value["$name"]="$value_fn"
    icon_glyphs+=("$glyph")
    icon_widths+=("$width")
  done <<<"$segment_defs"
}

print_short_path() {
  local max_len=${PROMPT_PWD_MAXLEN:-50}
  local pwd="${PWD/#$HOME/\~}"

  if (( ${#pwd} > max_len )); then
    printf "...%s" "${pwd: -$max_len}"
  else
    printf "%s" "$pwd"
  fi
}

print_icon_aligned() {
  local s="$1" glyph width tmp count extra i
  extra=0
  for i in "${!icon_glyphs[@]}"; do
    glyph="${icon_glyphs[i]}"
    width="${icon_widths[i]}"
    tmp="$s"
    count=0
    while [[ "$tmp" == *"$glyph"* ]]; do
      tmp="${tmp#*"$glyph"}"
      count=$((count + 1))
    done
    extra=$((extra + (width - 1) * count))
  done
  printf "%s" "$extra"
}

print_time() { date +'%Y-%m-%d %H:%M:%S'; }
print_user() { printf "%s" "${USER:-$(id -un 2>/dev/null)}"; }
print_host() { printf " %s" "${HOSTNAME%%.*}"; }

print_git_branch() {
  command -v git >/dev/null 2>&1 || return
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -z $branch ]]; then
    branch=$(git describe --tags --exact-match 2>/dev/null)
  fi
  if [[ -z $branch ]]; then
    branch=$(git rev-parse --short HEAD 2>/dev/null)
  fi
  [[ -n $branch ]] || return

  printf "%s" "$branch"
}

print_git_mark() {
  local untracked
  if ! git diff --quiet --ignore-submodules 2>/dev/null ||
     ! git diff --cached --quiet --ignore-submodules 2>/dev/null; then
    printf "✗"
    return
  fi
  untracked=$(git ls-files --others --exclude-standard 2>/dev/null | head -n 1)
  if [[ -n $untracked ]]; then
    printf "✗"
  else
    printf "✓"
  fi
}

segment_plain() {
  local name="$1" glyph value_fn value
  glyph="${seg_glyph[$name]}"
  value_fn="${seg_value[$name]}"
  if [[ ${seg_style[$name]} == git ]]; then
    local branch mark
    branch="$(print_git_branch)"
    [[ -z $branch ]] && return
    mark="$(print_git_mark)"
    printf "(%s  %s %s)" "$glyph" "$branch" "$mark"
    return
  fi
  value="$($value_fn)"
  [[ -z $value ]] && return
  printf "%s %s" "$glyph" "$value"
}

segment_render() {
  local name="$1" glyph width color style value_fn value
  glyph="${seg_glyph[$name]}"
  width="${seg_width[$name]}"
  color="${seg_color[$name]}"
  style="${seg_style[$name]}"
  value_fn="${seg_value[$name]}"

  if [[ $style == git ]]; then
    local branch mark mark_color
    branch="$(print_git_branch)"
    [[ -z $branch ]] && return

    mark="$(print_git_mark)"
    if [[ $mark == "✓" ]]; then
      mark_color="$(color_print bright_green)"
    else
      mark_color="$(color_print red)"
    fi
    printf "%b(%b%b%s%b  %b%s %b%s%b)%b" \
      "$(color_print gray)" \
      "$(color_print bold)" "$(color_print blue)" "$glyph" "$(color_print gray)" \
      "$(color_print "$color")" "$branch" "$mark_color" "$mark" \
      "$(color_print gray)" "$(color_print reset)"
  else
    value="$($value_fn)"
    [[ -z $value ]] && return

    if [[ $style == bold ]]; then
      printf "%b%b%s %s%b" "$(color_print bold)" "$(color_print "$color")" "$glyph" "$value" "$(color_print reset)"
    else
      printf "%b%s %s%b" "$(color_print "$color")" "$glyph" "$value" "$(color_print reset)"
    fi
  fi
}
