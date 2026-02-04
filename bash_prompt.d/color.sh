# color

color_print() {
  case "$1" in
    ""|none) printf "%s" "" ;;
    reset) printf "%s" '\033[0m' ;;
    bold) printf "%s" '\033[1m' ;;
    orange) printf "%s" '\033[38;5;208m' ;;
    blue) printf "%s" '\033[38;5;39m' ;;
    yellow) printf "%s" '\033[38;5;226m' ;;
    green) printf "%s" '\033[38;5;82m' ;;
    bright_green) printf "%s" '\033[38;5;46m' ;;
    red) printf "%s" '\033[38;5;196m' ;;
    gray) printf "%s" '\033[38;5;245m' ;;
    purple) printf "%s" '\033[38;5;141m' ;;
    cyan) printf "%s" '\033[38;5;51m' ;;
    magenta) printf "%s" '\033[38;5;201m' ;;
    pink) printf "%s" '\033[38;5;213m' ;;
    teal) printf "%s" '\033[38;5;38m' ;;
    lime) printf "%s" '\033[38;5;154m' ;;
    brown) printf "%s" '\033[38;5;130m' ;;
    maroon) printf "%s" '\033[38;5;88m' ;;
    navy) printf "%s" '\033[38;5;18m' ;;
    olive) printf "%s" '\033[38;5;100m' ;;
    indigo) printf "%s" '\033[38;5;54m' ;;
    coral) printf "%s" '\033[38;5;209m' ;;
    turquoise) printf "%s" '\033[38;5;45m' ;;
    *) printf "%s" '\033[0m' ;;
  esac
}
