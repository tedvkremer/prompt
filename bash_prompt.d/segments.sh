# ---------------------------------------------------------------------------------------
# Segment registry and rendering utilities.
#
# Public functions:
# - segments_init: Parse segment specs and register renderers and metadata.
# - segments_render: Render a segment using the spec/renderer contract:
#   * simple metadata (no colons) expects a single renderer value.
#   * complex metadata (with colons) expects a '|' delimited renderer vector
#     aligned to the metadata schema, including '@' for icon placement.
#   * returns "length<sep>styled" where sep is SEGMENTS_RENDER_SEP.
# ---------------------------------------------------------------------------------------

SEGMENTS_RENDER_SEP=$'\x1F'

segments_init() {
  local -n segment_array="$1"

  unset __segments
  declare -g -A __segments

  local line name icon_spec renderer metadata glyph width
  for line in "${segment_array[@]}"; do
    [[ -z "$line" ]] && continue

    # Validate 4-column DSL
    IFS='|' read -r name icon_spec renderer metadata <<< "$line"
    if [[ -z "$name" || -z "$icon_spec" || -z "$renderer" || -z "$metadata" ]]; then
      terminal_die "segments_init: invalid segment spec (expected 4 fields): $line"
    fi

    # Validate icon (glyph:width)
    glyph="${icon_spec%%:*}"
    width="${icon_spec#*:}"
    [[ "$icon_spec" != *:* ]] && width=1
    [[ -z "$width" ]] && width=1
    if [[ -z "$glyph" ]]; then
      terminal_die "segments_init: invalid icon spec (empty glyph) for segment '$name': $icon_spec"
    fi
    if ! [[ "$width" =~ ^[0-9]+$ ]] || (( width < 1 )); then
      terminal_die "segments_init: invalid icon width for segment '$name': $width"
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
    IFS='+' read -ra mods <<< "$metadata"
    for mod in "${mods[@]}"; do c_esc+="${__color_map[$mod]}"; done
    printf "%s%s%s" "$length" "$SEGMENTS_RENDER_SEP" "${c_esc}${val}${__color_map[reset]}"
    return
  fi

  # Complex vector of values
  IFS=':' read -ra schema_parts <<< "$metadata"
  IFS='|' read -ra data_parts <<< "$raw_output"
  if [[ ${#schema_parts[@]} -ne ${#data_parts[@]} ]]; then
    local err_msg="segments_render: schema/data length mismatch for segment '$name'"
    err_msg+=" (schema_count=${#schema_parts[@]}, "
    err_msg+="data_count=${#data_parts[@]}, "
    err_msg+="metadata='${metadata//$'\n'/ }', "
    err_msg+="raw_output='${raw_output//$'\n'/ }')"
    terminal_die "$err_msg"
  fi

  local i attr val output="" length=0
  for i in "${!schema_parts[@]}"; do
    attr="${schema_parts[i]}"
    val="${data_parts[i]}"

    if [[ "$val" == *","* ]]; then
      local data_idx="${val#*,}"
      val="${val%,*}"
      if [[ "$attr" == *"?"* ]]; then
        IFS='?' read -ra choices <<< "$attr"
        attr="${choices[$data_idx]:-${choices[0]}}"
      fi
    elif [[ "$val" == "@" ]]; then
      # THE FIX: Use the dynamic padded glyph here
      val="${padded_glyph}"
    fi

    length=$((length + ${#val}))
    local c_esc=""
    IFS='+' read -ra mods <<< "$attr"
    for mod in "${mods[@]}"; do c_esc+="${__color_map[$mod]}"; done
    output+="${c_esc}${val}${__color_map[reset]}"
  done

  printf "%s%s%s" "$length" "$SEGMENTS_RENDER_SEP" "$output"
}
