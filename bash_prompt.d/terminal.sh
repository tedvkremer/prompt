# terminal

terminal_init() { trap 'terminal_reserve' SIGWINCH; }
terminal_clear() { tput clear; }
terminal_num_cols() { tput cols; }
terminal_to_col() { tput cup 0 $1; }
terminal_to_start() { tput cup 1 0; }
terminal_top_init() { tput sc; tput cup 0 0; tput el; }
terminal_top_exit() { tput rc; }

terminal_reserve() {
  local lines
  lines=$(tput lines)

  if (( lines < 2 )); then
    return
  fi

  tput sc
  tput csr 1 $((lines - 1))
  tput rc
}
