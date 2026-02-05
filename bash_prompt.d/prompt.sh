
prompt_init() {
  local segments=$1 left=$2 center=$3 right=$4 prompt_color=$5

  unset __prompt_color
  declare -g __prompt_color="$prompt_color"

  die_init
  terminal_init
  status_bar_init $segments "${left}" "${center}" "${right}"

  PROMPT_COMMAND="__prompt_command"
  bind -x '"\C-l":__prompt_clear'
}

__prompt_build() {
  local exit_code="${1:-0}" prompt_color

  local color_good="$(color_print "$__prompt_color")"
  local color_bad="$(color_print red)"

  if (( exit_code == 0 )); then
    prompt_color="\[${color_good}\]"
  else
    prompt_color="\[${color_bad}\]"
  fi

  PS1="\n${prompt_color}❯\[$(color_print reset)\] "
}

__prompt_command() {
  local exit_code=$?
  terminal_reserve
  status_bar_render
  __prompt_build "$exit_code"
}

__prompt_clear() {
  terminal_clear
  terminal_reserve
  status_bar_render
  terminal_to_start
}
