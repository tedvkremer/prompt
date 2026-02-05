
die_init() {
  trap "exit 1" TERM
  export TOP_PID=$$
}

die() {
  echo "Error: $1" >&2
  kill -s TERM $TOP_PID
}
