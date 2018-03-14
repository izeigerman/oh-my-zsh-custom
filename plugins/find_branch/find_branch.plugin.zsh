
find_branch() {
  original_dir="$(pwd)"

  pattern=".*"
  if [[ $# -gt 0 ]]; then
    pattern="$1"
  fi

  find_dir="."
  if [[ $# -gt 1 ]]; then
    find_dir="$2"
  fi

  cd $find_dir
  for d in $(ls "."); do
    repo_dir="./${d}"
    if [[ -d "$repo_dir" ]]; then
      cd $repo_dir
      test "$(git status 2> /dev/null | grep $pattern)" && print -P "%F{white}${d%/}%f: %F{green}$(git status | grep --color=never  On | awk -F ' ' '{ print $3 }')%f"
      cd $find_dir
    fi
  done

  cd $original_dir
}
