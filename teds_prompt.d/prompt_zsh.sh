# ---------------------------------------------------------------------------------------
# Zsh shell provider for prompt.sh.
#
# Implements the provider API:
# - __prompt_register_hooks: wire precmd, preexec, ZLE widgets, and traps.
# - __prompt_before_command: called by preexec before each user command.
# - __prompt_format_ps1 <color>: set PS1 with zsh non-printing escape sequences.
# ---------------------------------------------------------------------------------------

__prompt_register_hooks() {
  # Zsh-specific hook registration
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd __prompt_command
  add-zsh-hook preexec __prompt_before_command

  # Key binding for Ctrl-L (Clear Screen) via ZLE
  __prompt_clear_widget() {
    __prompt_clear
    zle reset-prompt
  }
  zle -N __prompt_clear_widget
  bindkey '^L' __prompt_clear_widget
}

TRAPWINCH() {
  # Redraw status bar on terminal resize
  __prompt_render
  # Request a prompt redraw if ZLE is active
  [[ -o zle ]] && zle reset-prompt
}

__prompt_before_command() {
  # Ensure the status bar region is released before command output
  terminal_unreserve
}

__prompt_format_ps1() {
  local color=$1
  local c_esc="${__color_map[$color]}"
  local c_reset="${__color_map[reset]}"

  # %1~ is roughly equivalent to Bash \W (basename of PWD with ~)
  # %{...%} wraps non-printing escape sequences
  PS1=$'\n%1~%{'${c_esc}'%}❯%{'${c_reset}'%} '
}
