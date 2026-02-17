# ---------------------------------------------------------------------------------------
# Prompt setup and render loop.
# Requires:
# - terminal, color, status_bar
# Public functions:
# - prompt_init: Initialize prompt state, status bar, and key bindings.
# ---------------------------------------------------------------------------------------

prompt_init() {
  local segments_ref=$1 left=$2 center=$3 right=$4 prompt_color=$5

  unset __prompt_color
  declare -g __prompt_color="$prompt_color"

  terminal_init
  terminal_clear
  color_init
  status_bar_init $segments_ref "${left}" "${center}" "${right}"

  PROMPT_COMMAND="__prompt_command"
  bind -x '"\C-l":__prompt_clear'
  trap '__prompt_before_command' DEBUG
  trap '__prompt_render' SIGWINCH
}

__prompt_build() {
  local exit_code="${1:-0}"
  local color=$__prompt_color
  (( exit_code != 0 )) && color=red;
  PS1="\n\[${__color_map[$color]}\]❯\[${__color_map[reset]}\] "
}

__prompt_command() {
  local exit_code=$?
  terminal_reserve
  status_bar_render
  __prompt_build "$exit_code"
}

__prompt_before_command() {
  [[ "${BASH_COMMAND:-}" == __prompt_* ]] && return
  terminal_unreserve
}

__prompt_render() {
  terminal_reserve
  status_bar_render
}

__prompt_clear() {
  terminal_clear
  terminal_reserve
  status_bar_render
  terminal_to_start
}
