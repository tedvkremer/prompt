# color

declare -g -A __colors=(
  [none]=''
  [reset]=$'\e[0m'
  [bold]=$'\e[1m'
  [orange]=$'\e[38;5;208m'
  [blue]=$'\e[38;5;39m'
  [yellow]=$'\e[38;5;226m'
  [green]=$'\e[38;5;82m'
  [bright_green]=$'\e[38;5;46m'
  [red]=$'\e[38;5;196m'
  [gray]=$'\e[38;5;245m'
  [purple]=$'\e[38;5;141m'
  [cyan]=$'\e[38;5;51m'
  [magenta]=$'\e[38;5;201m'
  [pink]=$'\e[38;5;213m'
  [teal]=$'\e[38;5;38m'
  [lime]=$'\e[38;5;154m'
  [brown]=$'\e[38;5;130m'
  [maroon]=$'\e[38;5;88m'
  [navy]=$'\e[38;5;18m'
  [olive]=$'\e[38;5;100m'
  [indigo]=$'\e[38;5;54m'
  [coral]=$'\e[38;5;209m'
  [turquoise]=$'\e[38;5;45m'
)

color_print() {
  # Default to reset if color is unknown
  printf "%s" "${__colors[$1]:-${__colors[reset]}}"
}
