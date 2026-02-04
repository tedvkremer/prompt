# status_bar

__status_left=""
__status_center=""
__status_right=""
__status_left_plain=""
__status_center_plain=""
__status_right_plain=""

status_bar_build() {
  local path git user host time

  path="$(segment_render path)"
  git="$(segment_render git)"
  user="$(segment_render user)"
  host="$(segment_render host)"
  time="$(segment_render time)"

  __status_left_plain="$(segment_plain path)"
  __status_center_plain=""
  __status_right_plain="$(segment_plain user) $(segment_plain host) $(segment_plain time)"

  __status_left=" ${path}"
  if [[ -n $git ]]; then
    __status_left_plain+=" $(segment_plain git)"
    __status_left+=" ${git}"
  fi

  __status_center=""
  __status_right="${user} ${host} ${time}"
}

status_bar_draw() {
  local cols left_len center_len right_len center_col right_col extra
  cols=$(terminal_num_cols)

  terminal_top_init

  printf "%b" "$__status_left"

  extra="$(print_icon_aligned "$__status_left_plain")"
  left_len=$(( ${#__status_left_plain} + extra ))

  extra="$(print_icon_aligned "$__status_center_plain")"
  center_len=$(( ${#__status_center_plain} + extra ))

  extra="$(print_icon_aligned "$__status_right_plain")"
  right_len=$(( ${#__status_right_plain} + extra ))

  center_col=$(( (cols - center_len) / 2 ))
  right_col=$(( cols - right_len ))

  if (( center_len > 0 )) && (( center_col <= left_len )); then
    center_col=$((left_len + 1))
  fi
  if (( right_col <= left_len + 1 )); then
    right_col=$((left_len + 1))
  fi

  if (( center_len > 0 )) && (( center_col < cols )); then
    terminal_to_col "$center_col"
    printf "%b" "$__status_center"
  fi

  if (( right_col < cols )); then
    terminal_to_col "$right_col"
    printf "%b" "$__status_right"
  fi

  terminal_top_exit
}

status_bar_render() {
  status_bar_build
  status_bar_draw
}
