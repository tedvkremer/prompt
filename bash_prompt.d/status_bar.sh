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
  #
  # Build: assemble region output strings and lengths from segment results
  #

  local -A region_out region_len
  local sep="$SEGMENTS_RENDER_SEP"

  local region name result segment_length segment_styled
  for region in left center right; do
    region_out["$region"]=""
    region_len["$region"]=0

    local -a names=()
    IFS='|' read -r -a names <<< "${__regions_specs[$region]}"

    local segments_tot=0
    for name in "${names[@]}"; do
      result="${__regions_content["$region/$name"]}"

      if [[ -n "$result" ]]; then
        segment_length="${result%%${sep}*}"
        segment_styled="${result#*${sep}}"
      else
        segment_length=0
        segment_styled=""
      fi

      (( segment_length == 0 )) && continue

      if (( segments_tot > 0 )); then
        region_out["$region"]+=" "
        region_len["$region"]=$(( region_len["$region"] + 1 ))
      fi

      region_out["$region"]+="${segment_styled}"
      region_len["$region"]=$(( region_len["$region"] + segment_length ))

      segments_tot=$(( segments_tot + 1 ))
    done
  done

  local region_left="${region_out[left]}"
  local region_center="${region_out[center]}"
  local region_right="${region_out[right]}"

  #
  # Position: calculate regions positions based on their
  #           lengths and the terminal width and adjust for overlap
  #

  local total_cols=$(terminal_num_cols)

  local length_left="${region_len[left]}"
  local length_center="${region_len[center]}"
  local length_right="${region_len[right]}"

  local pos_center=$(( (total_cols - length_center) / 2 ))
  if (( length_center > 0 )) && (( pos_center <= length_left )); then
    pos_center=$(( length_left + 1 ))
  fi

  local pos_right=$(( total_cols - length_right ))
  if (( pos_right <= length_left + 1 )); then
    pos_right=$(( length_left + 1 ))
  fi

  #
  # Draw: render the status bar regions at their positions
  #

  terminal_top_init

  printf "%s" "$region_left"

  if (( length_center > 0 )) && (( pos_center + length_center < pos_right )); then
    terminal_to_col "$pos_center"
    printf "%s" "$region_center"
  fi

  if (( length_right > 0 )) && (( pos_right + length_right <= total_cols )); then
    terminal_to_col "$pos_right"
    printf "%s" "$region_right"
  fi

  terminal_top_exit
}

status_bar_render() {
  __status_bar_build
  __status_bar_draw
}
