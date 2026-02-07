# ---------------------------------------------------------------------------------------
# Status bar layout and rendering.
# Requires:
# - terminal, segments
# Public functions:
# - status_bar_init: Initialize segment layout and register segments.
# - status_bar_render: Build and draw the status bar.
# ---------------------------------------------------------------------------------------

status_bar_init() {
  local segments_ref=$1

  unset __regions_specs __regions_content
  declare -g -A __regions_specs=([left]="$2" [center]="$3" [right]="$4")
  declare -g -A __regions_content=()

  local region spec
  for region in left center right; do
    spec="${__regions_specs[$region]}"
    [[ -z "$spec" ]] && continue
    if [[ "$spec" == \|* || "$spec" == *\| || "$spec" == *'||'* ]]; then
      terminal_abort "status_bar_init: invalid region spec for '$region': $spec"
    fi
  done

  segments_init "$segments_ref"
}

__status_bar_build() {
  local region
  for region in left center right; do
    local -a names=()
    local name result
    IFS='|' read -r -a names <<< "${__regions_specs[$region]}"
    for name in "${names[@]}"; do
      result="$(segments_render "$name")" || true
      __regions_content["$region/$name"]="$result"
    done
  done
}

__status_bar_draw() {
  local center_col right_col

  #
  # Build: assemble region output strings and lengths from segment results
  #

  local -A region_out region_len
  local sep="$SEGMENTS_RENDER_SEP"

  local region name result seg_len seg_styled
  for region in left center right; do
    region_out["$region"]=""
    region_len["$region"]=0

    local -a names=()
    IFS='|' read -r -a names <<< "${__regions_specs[$region]}"
    for name in "${names[@]}"; do
      result="${__regions_content["$region/$name"]}"
      if [[ -n "$result" ]]; then
        seg_len="${result%%${sep}*}"
        seg_styled="${result#*${sep}}"
      else
        seg_len=0
        seg_styled=""
      fi

      region_out["$region"]+="${seg_styled} "
      region_len["$region"]=$((region_len["$region"] + seg_len + 1))
    done
  done

  #
  # Position: calculate regions positions based on their
  #           lengths and the terminal width and adjust for overlap
  #

  local cols=$(terminal_num_cols)

  local left_len="${region_len[left]}"
  local center_len="${region_len[center]}"
  local right_len="${region_len[right]}"

  center_col=$(( (cols - center_len) / 2 ))
  if (( center_len > 0 )) && (( center_col <= left_len )); then
    center_col=$((left_len + 1))
  fi

  right_col=$(( cols - right_len ))
  if (( right_col <= left_len + 1 )); then
    right_col=$((left_len + 1))
  fi

  #
  # Draw: render the status bar regions at their positions
  #

  local left_out="${region_out[left]}"
  local center_out="${region_out[center]}"
  local right_out="${region_out[right]}"

  terminal_top_init

  printf "%s" "$left_out"

  if (( center_len > 0 )) && (( center_col < cols )); then
    terminal_to_col "$center_col"
    printf "%s" "$center_out"
  fi

  if (( right_col < cols )); then
    terminal_to_col "$right_col"
    printf "%s" "$right_out"
  fi

  terminal_top_exit
}

status_bar_render() {
  __status_bar_build
  __status_bar_draw
}
