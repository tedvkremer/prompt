# ---------------------------------------------------------------------------------------
# Bash shell provider for prompt.sh.
#
# Implements the provider API:
# - __prompt_register_hooks: wire PROMPT_COMMAND, key binding, and signal traps.
# - __prompt_before_command: called by DEBUG trap before each user command.
# - __prompt_format_ps1 <color>: set PS1 with bash non-printing escape sequences.
# ---------------------------------------------------------------------------------------

__prompt_register_hooks() {
  PROMPT_COMMAND="__prompt_command"
  bind -x '"\C-l":__prompt_clear'
  trap '__prompt_before_command' DEBUG
  trap '__prompt_render' SIGWINCH
}

__prompt_before_command() {
  [[ "${BASH_COMMAND:-}" == __prompt_* ]] && return
  terminal_unreserve
}

__prompt_format_ps1() {
  local color=$1
  PS1="\n\W\[${__color_map[$color]}\]❯\[${__color_map[reset]}\] "
}
