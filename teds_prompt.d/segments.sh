# ---------------------------------------------------------------------------------------
# Segment registry and rendering utilities.
#
# Requires:
# - renderers, terminal, color
#
# Public functions:
# - segments_init: Parse segment specs and register renderers and metadata.
# - segments_render: Render a segment using the spec/renderer contract:
#   * simple metadata (no colons) expects a single renderer value.
#   * complex metadata (with colons) expects a '|' delimited renderer vector
#     aligned to the metadata schema, including '@' for icon placement.
#   * returns "length<record-sep>styled"
# ---------------------------------------------------------------------------------------

SEGMENTS_RENDER_SEP=$'\x1F'

segments_init() {
  local segments_ref="$1"

  # Portable way to copy array elements to positional parameters
  eval "set -- \"\${$segments_ref[@]}\""

  unset __segments
  typeset -gA __segments

  local line name icon_spec renderer metadata glyph width
  for line in "$@"; do
    [[ -z "$line" ]] && continue

    # Validate 4-column DSL
    IFS='|' read -r name icon_spec renderer metadata <<< "$line"
    if [[ -z "$name" || -z "$icon_spec" || -z "$renderer" || -z "$metadata" ]]; then
      terminal_abort "segments_init: invalid segment spec (expected 4 fields): $line"
    fi

    # Validate icon (glyph:width)
    glyph="${icon_spec%%:*}"
    width="${icon_spec#*:}"
    [[ "$icon_spec" != *:* ]] && width=1
    [[ -z "$width" ]] && width=1
    if [[ -z "$glyph" ]]; then
      terminal_abort "segments_init: invalid icon spec (empty glyph) for segment '$name': $icon_spec"
    fi
    if ! [[ "$width" =~ ^[0-9]+$ ]] || (( width < 1 )); then
      terminal_abort "segments_init: invalid icon width for segment '$name': $width"
    fi

    # Populate segments registry
    __segments["$name/icon/glyph"]="$glyph"
    __segments["$name/icon/width"]="$width"
    __segments["$name/renderer"]="$renderer"
    __segments["$name/metadata"]="$metadata"
  done
}

segments_render() {
  local name="$1"
  local renderer="${__segments["$name/renderer"]}"
  local metadata="${__segments["$name/metadata"]}"
  local glyph="${__segments["$name/icon/glyph"]}"
  local width="${__segments["$name/icon/width"]}"

  local padding=$(printf "%${width}s")
  local padded_glyph="${glyph}${padding}"

  local raw_output
  raw_output=$($renderer) || return
  [[ -z "$raw_output" ]] && return

  # Simple atomic value
  if [[ "$metadata" != *":"* ]]; then
    local val="${padded_glyph}${raw_output}"
    local length=${#val}
    local c_esc=""
    local mods_str="$metadata"
    while [[ -n "$mods_str" ]]; do
      local mod="${mods_str%%+*}"
      c_esc+="${__color_map[$mod]}"
      [[ "$mods_str" == *+* ]] && mods_str="${mods_str#*+}" || mods_str=""
    done
    printf "%s%s%s" "$length" "$SEGMENTS_RENDER_SEP" "${c_esc}${val}${__color_map[reset]}"
    return
  fi

  # Complex vector of values (Shell-agnostic parsing via string manipulation)
  local stripped="${metadata//:}"
  local schema_count=$(( ${#metadata} - ${#stripped} + 1 ))
  stripped="${raw_output//|}"
  local data_count=$(( ${#raw_output} - ${#stripped} + 1 ))
  if (( schema_count != data_count )); then
    local err_msg="segments_render: schema/data length mismatch for segment '$name'"
    err_msg+=" (schema_count=${schema_count},"
    err_msg+=" data_count=${data_count},"
    err_msg+=" metadata='${metadata//$'\n'/ }',"
    err_msg+=" raw_output='${raw_output//$'\n'/ }')"
    terminal_abort "$err_msg"
  fi

  local schema_str="$metadata"
  local data_str="$raw_output"
  local output=""
  local total_length=0

  while [[ -n "$schema_str" ]]; do
    local attr="${schema_str%%:*}"
    local val="${data_str%%|*}"

    # Advance strings
    [[ "$schema_str" == *:* ]] && schema_str="${schema_str#*:}" || schema_str=""
    [[ "$data_str" == *\|* ]] && data_str="${data_str#*|}" || data_str=""

    # Handle Magic (conditional coloring and icon placement)
    if [[ "$val" == *","* ]]; then
      local data_val="${val%,*}"
      local data_idx="${val#*,}"
      if [[ "$attr" == *"?"* ]]; then
        local choices="$attr"
        local i=0
        while (( i < data_idx )); do
          choices="${choices#*[?]}"
          ((i++))
        done
        attr="${choices%%[?]*}"
      fi
      val="$data_val"
    elif [[ "$val" == "@" ]]; then
      val="${padded_glyph}"
    fi

    total_length=$((total_length + ${#val}))

    # Apply colors
    local c_esc=""
    local mods_str="$attr"
    while [[ -n "$mods_str" ]]; do
      local mod="${mods_str%%+*}"
      c_esc+="${__color_map[$mod]}"
      [[ "$mods_str" == *+* ]] && mods_str="${mods_str#*+}" || mods_str=""
    done
    output+="${c_esc}${val}${__color_map[reset]}"
  done

  printf "%s%s%s" "$total_length" "$SEGMENTS_RENDER_SEP" "$output"
}
