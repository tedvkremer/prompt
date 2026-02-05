# ---------------------------------------------------------------------------------------
# Fast-fail helpers for preconditions
#
# Public functions:
# - die_init: Install a TERM trap and record TOP_PID for coordinated shutdown.
# - die: Print an error message and terminate the top-level shell via TERM.
# ---------------------------------------------------------------------------------------

die_init() {
  trap "exit 1" TERM
  export TOP_PID=$$
}

die() {
  echo "Error: $1" >&2
  kill -s TERM $TOP_PID
}
