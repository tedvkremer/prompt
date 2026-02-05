
render_time() { printf "%s" "$(date +'%Y-%m-%d %H:%M:%S')"; }
render_user() { printf "%s" "${USER:-$(id -un 2>/dev/null)}"; }
render_host() { printf "%s" "${HOSTNAME%%.*}"; }

render_path() {
  local max_len=${PROMPT_PWD_MAXLEN:-50}
  local pwd="${PWD/#$HOME/\~}"

  if (( ${#pwd} > max_len )); then
    printf "...%s" "${pwd: -$max_len}"
    return
  fi

  printf "%s" "$pwd"
}

render_git() {
  # 1. Verification
  command -v git >/dev/null 2>&1 || return
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

  # 2. Logic: Get Branch
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || \
           git describe --tags --exact-match 2>/dev/null || \
           git rev-parse --short HEAD 2>/dev/null)
  [[ -z "$branch" ]] && return

  # 3. Logic: Get State (index for red?green)
  local state_idx=0
  if [[ -n $(git status --porcelain --ignore-submodules 2>/dev/null | head -n 1) ]]; then
    state_idx=1
  fi

  # 4. Logic: Get Mark
  local mark=" ✓"
  [[ "$state_idx" -eq 1 ]] && mark=" ✗"

  # 5. Output Vector mapping:
  # (      : @         : branch : mark,index : )
  # gray   : blue+bold : purple : red?green  : gray
  printf "%s|%s|%s|%s|%s" "(" "@" "$branch" "$mark,$state_idx" ")"
}
