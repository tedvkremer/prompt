
status_bar_init() {
  local segments_ref=$1

  declare -g __bar_left_names="$2"
  declare -g __bar_center_names="$3"
  declare -g __bar_right_names="$4"

  segments_init "$segments_ref"
}

__status_bar_build() {
  __status_left="";   __status_left_plain=""
  __status_center=""; __status_center_plain=""
  __status_right="";  __status_right_plain=""

  local name

  for name in $__bar_left_names; do
    __status_left+="$(segments_render "$name") "
    __status_left_plain+="$(segments_plain "$name") "
  done

  for name in $__bar_center_names; do
    __status_center+="$(segments_render "$name") "
    __status_center_plain+="$(segments_plain "$name") "
  done

  for name in $__bar_right_names; do
    __status_right+="$(segments_render "$name") "
    __status_right_plain+="$(segments_plain "$name") "
  done
}

__status_bar_draw() {
  local cols left_len center_len right_len center_col right_col extra
  cols=$(terminal_num_cols)

  terminal_top_init

  # 1. Draw Left
  printf " %s" "$__status_left"

  # 2. Calculate Lengths
  extra="$(segments_print_icon_aligned "$__status_left_plain")"
  left_len=$(( ${#__status_left_plain} + extra ))
  extra="$(segments_print_icon_aligned "$__status_center_plain")"
  center_len=$(( ${#__status_center_plain} + extra ))
  extra="$(segments_print_icon_aligned "$__status_right_plain")"
  right_len=$(( ${#__status_right_plain} + extra ))

  # 3. Calculate Columns
  center_col=$(( (cols - center_len) / 2 ))
  right_col=$(( cols - right_len ))

  # 4. Collision Handling
  if (( center_len > 0 )) && (( center_col <= left_len )); then
    center_col=$((left_len + 1))
  fi
  if (( right_col <= left_len + 1 )); then
    right_col=$((left_len + 1))
  fi

  # 5. Draw Center
  if (( center_len > 0 )) && (( center_col < cols )); then
    terminal_to_col "$center_col"
    printf "%s" "$__status_center"
  fi

  # 6. Draw Right
  if (( right_col < cols )); then
    terminal_to_col "$right_col"
    printf "%s " "$__status_right"
  fi

  terminal_top_exit
}

status_bar_render() {
  __status_bar_build
  __status_bar_draw
}
