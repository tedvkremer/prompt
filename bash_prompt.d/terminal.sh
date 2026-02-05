# ---------------------------------------------------------------------------------------
# Terminal utilities for positioning.
#
# Public functions:
# - terminal_init: Install a SIGWINCH handler to re-reserve the status-bar line on resize.
# - terminal_clear: Clear the terminal screen.
# - terminal_num_cols: Return the current terminal width in columns.
# - terminal_to_col: Move the cursor to column N on the top row.
# - terminal_to_start: Move the cursor to the start of the main prompt area (row 1, col 0).
# - terminal_top_init: Save cursor position, move to top-left, and clear the top line.
# - terminal_top_exit: Restore the saved cursor position after drawing the top line.
# - terminal_reserve: Reserve the top line for the status bar via the scrolling region.
# ---------------------------------------------------------------------------------------

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
