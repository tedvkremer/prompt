# ---------------------------------------------------------------------------------------
# Segment renderers for the status bar.
#
# Public functions:
# - render_time: Print the current timestamp.
# - render_user: Print the current user name.
# - render_host: Print the short host name.
# - render_path: Print the current working directory, truncated if needed.
# - render_git: Print git branch and dirty state when inside a repo.
# ---------------------------------------------------------------------------------------

render_time() { printf "%s" "$(date +'%a %b%e %I:%M%P')"; }
render_user() { printf "%s" "${USER:-$(id -un 2>/dev/null)}"; }
render_host() { printf "%s" "${HOSTNAME%%.*}"; }

render_time_complex() {
  # "date @ time"
  printf "%s|@|%s" "$(date +'%a %b%e') " "$(date +'%I:%M%P')"
}

render_path() {
  local max_len=${PROMPT_PWD_MAXLEN:-50}
  local pwd="${PWD/#$HOME/\~}"
  if (( ${#pwd} > max_len )); then
    pwd=$(printf "...%s" "${pwd: -$max_len}")
  fi

  # @ [~/Projects/Code/prompt]
  printf "@|[|%s|]" "$pwd"
}

render_git() {
  # Validation
  command -v git >/dev/null 2>&1 || return
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

  # Branch
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || \
           git describe --tags --exact-match 2>/dev/null || \
           git rev-parse --short HEAD 2>/dev/null)
  [[ -z "$branch" ]] && return

  # Status (good or dirty) (0|1 for green?red)
  local mark="✓"
  local state_idx=0
  if [[ -n $(git status --porcelain --ignore-submodules 2>/dev/null | head -n 1) ]]; then
    mark="✗"
    state_idx=1
  fi

  # "@ main [x]"
  printf "@|%s|[|%s|]" "$branch " "$mark,$state_idx"
}
