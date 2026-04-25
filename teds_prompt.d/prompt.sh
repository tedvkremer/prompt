# ---------------------------------------------------------------------------------------
# Prompt setup and render loop.
#
# Requires:
# - terminal, color, status_bar
# - a shell provider implementing:
#     __prompt_register_hooks: wire up shell-specific prompt hooks
#     __prompt_format_ps1 <color>: set PS1 with correct escape syntax
#     __prompt_before_command: called before each user command
#
# Public functions:
# - prompt_init: Initialize prompt state, status bar, and key bindings.
# ---------------------------------------------------------------------------------------

prompt_init() {
  local segments_ref=$1 left=$2 center=$3 right=$4 prompt_color=$5

  unset __prompt_color
  typeset -g __prompt_color="$prompt_color"

  terminal_init
  terminal_clear
  color_init
  status_bar_init $segments_ref "${left}" "${center}" "${right}"
  echo

  __prompt_register_hooks
}

__prompt_build() {
  local exit_code="${1:-0}"

  # TODO:
  # Use a segment definition and renderer to render PS1
  #
  # prompt="prompt|❯|render_prompt_a|orange?red"
  # ❯ _
  #
  # prompt="prompt|❯|render_prompt_b|orange?red:gray:none:gray"
  # [path]❯ _

  local color=$__prompt_color
  (( exit_code != 0 )) && color=red
  __prompt_format_ps1 "$color"
}

__prompt_command() {
  local exit_code=$?
  terminal_reserve
  status_bar_render
  __prompt_build "$exit_code"
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
  echo
}
