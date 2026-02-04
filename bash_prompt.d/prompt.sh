# prompt

prompt_init() {
  PROMPT_COMMAND="__prompt_command"
  bind -x '"\C-l":__prompt_clear'
}

prompt_build() {
  local exit_code="${1:-0}" prompt_color
  if (( exit_code == 0 )); then
    prompt_color="\[$(color_print orange)\]"
  else
    prompt_color="\[$(color_print red)\]"
  fi
  PS1="\n${prompt_color}❯\[$(color_print reset)\] "
}

__prompt_command() {
  local exit_code=$?
  terminal_reserve
  status_bar_render
  prompt_build "$exit_code"
}

__prompt_clear() {
  terminal_clear
  terminal_reserve
  status_bar_render
  terminal_to_start
}
