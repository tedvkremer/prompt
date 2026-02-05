
segments_init() {
  local -n segment_array="$1"

  # Reset Global Registry
  unset __segments __segment_names
  declare -g -A __segments
  declare -g -a __segment_names

  local line name icon_spec renderer metadata glyph width
  for line in "${segment_array[@]}"; do
    [[ -z "$line" ]] && continue

    # Parse the 4-column spec
    IFS='|' read -r name icon_spec renderer metadata <<< "$line"
    if [[ -z "$name" || -z "$icon_spec" || -z "$renderer" || -z "$metadata" ]]; then
      die "segments_init: invalid segment spec (expected 4 fields): $line"
    fi

    # Process Icon Spec (glyph:width)
    glyph="${icon_spec%%:*}"
    width="${icon_spec#*:}"
    [[ "$icon_spec" != *:* ]] && width=1
    [[ -z "$width" ]] && width=1
    if [[ -z "$glyph" ]]; then
      die "segments_init: invalid icon spec (empty glyph) for segment '$name': $icon_spec"
    fi
    if ! [[ "$width" =~ ^[0-9]+$ ]] || (( width < 1 )); then
      die "segments_init: invalid icon width for segment '$name': $width"
    fi

    # Populate Virtual Namespace
    __segment_names+=("$name")
    __segments["$name/icon/glyph"]="$glyph"
    __segments["$name/icon/width"]="$width"
    __segments["$name/renderer"]="$renderer"
    __segments["$name/metadata"]="$metadata"
  done

}

segments_render() { __segments_render "$1" "color"; }
segments_plain()  { __segments_render "$1" "plain"; }

segments_print_icon_aligned() {
  local s="$1" name glyph width tmp count extra
  extra=0

  # Iterate through the registered names
  for name in "${__segment_names[@]}"; do
    glyph="${__segments["$name/icon/glyph"]}"
    width="${__segments["$name/icon/width"]}"

    tmp="$s"
    count=0
    # Count occurrences of this icon in the plain-text string
    while [[ "$tmp" == *"$glyph"* ]]; do
      tmp="${tmp#*"$glyph"}"
      count=$((count + 1))
    done
    extra=$((extra + (width - 1) * count))
  done
  printf "%s" "$extra"
}

# Private helper for the A-Priori Zip-Merge
# $1: segment_name, $2: output_mode (color|plain)
__segments_render() {
  local name="$1" mode="$2"
  local renderer="${__segments["$name/renderer"]}"
  local metadata="${__segments["$name/metadata"]}"
  local glyph="${__segments["$name/icon/glyph"]}"
  local width="${__segments["$name/icon/width"]}"

  local padding=$(printf "%${width}s")
  local padded_glyph="${glyph}${padding}"

  local raw_output
  raw_output=$($renderer) || return
  [[ -z "$raw_output" ]] && return

  # FAST PATH: 90% Simple Scalar
  if [[ "$metadata" != *":"* ]]; then
    local val="${padded_glyph}${raw_output}"
    if [[ "$mode" == "color" ]]; then
      local c_esc=""
      IFS='+' read -ra mods <<< "$metadata"
      for mod in "${mods[@]}"; do c_esc+="${__colors[$mod]}"; done
      printf "%s" "${c_esc}${val}${__colors[reset]}"
    else
      printf "%s" "$val"
    fi
    return
  fi

  # SLOW PATH: 10% Complex Vector (Git)
  IFS=':' read -ra schema_parts <<< "$metadata"
  IFS='|' read -r -a data_parts <<< "$raw_output"

  local i attr val output=""
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

    if [[ "$mode" == "color" ]]; then
      local c_esc=""
      IFS='+' read -ra mods <<< "$attr"
      for mod in "${mods[@]}"; do c_esc+="${__colors[$mod]}"; done
      output+="${c_esc}${val}${__colors[reset]}"
    else
      output+="$val"
    fi
  done
  printf "%s" "$output"
}
