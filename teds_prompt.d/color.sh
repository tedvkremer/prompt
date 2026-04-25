# ---------------------------------------------------------------------------------------
# Color palette and formatting helpers.
#
# Public functions:
# - color_init: Initialize the color map.
# - color_print: Return the ANSI escape sequence for a named color or reset if unknown.
#                For high-performance cases, use __color_map data-structure
# ---------------------------------------------------------------------------------------

color_init() {
  unset __color_map
  typeset -gA __color_map

  __color_map[none]=''
  __color_map[reset]=$'\e[0m'
  __color_map[bold]=$'\e[1m'
  __color_map[orange]=$'\e[38;5;208m'
  __color_map[blue]=$'\e[38;5;39m'
  __color_map[yellow]=$'\e[38;5;226m'
  __color_map[green]=$'\e[38;5;82m'
  __color_map[bright_green]=$'\e[38;5;46m'
  __color_map[red]=$'\e[38;5;196m'
  __color_map[gray]=$'\e[38;5;245m'
  __color_map[white]=$'\e[38;5;255m'
  __color_map[purple]=$'\e[38;5;141m'
  __color_map[cyan]=$'\e[38;5;51m'
  __color_map[magenta]=$'\e[38;5;201m'
  __color_map[pink]=$'\e[38;5;213m'
  __color_map[teal]=$'\e[38;5;38m'
  __color_map[lime]=$'\e[38;5;154m'
  __color_map[brown]=$'\e[38;5;130m'
  __color_map[maroon]=$'\e[38;5;88m'
  __color_map[navy]=$'\e[38;5;18m'
  __color_map[olive]=$'\e[38;5;100m'
  __color_map[indigo]=$'\e[38;5;54m'
  __color_map[coral]=$'\e[38;5;209m'
  __color_map[turquoise]=$'\e[38;5;45m'
}

color_print() {
  printf "%s" "${__color_map[$1]:-${__color_map[reset]}}"
}
