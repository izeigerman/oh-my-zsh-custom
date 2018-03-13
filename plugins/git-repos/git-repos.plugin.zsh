
autoload -Uz vcs_info

# Set vcs_info parameters
#
zstyle ':vcs_info:*' enable hg bzr git
zstyle ':vcs_info:*:*' unstagedstr '!'
zstyle ':vcs_info:*:*' stagedstr '+'
zstyle ':vcs_info:*' check-for-changes true


# List of vcs_info format strings:
#
# %b => current branch
# %a => current action (rebase/merge)
# %s => current version control system
# %r => name of the root directory of the repository
# %S => current path relative to the repository root directory
# %m => in case of Git, show information about stashes
# %u => show unstaged changes in the repository
# %c => show staged changes in the repository

zstyle ':vcs_info:*:*' formats "%b"
zstyle ':vcs_info:*:*' actionformats "%b"
zstyle ':vcs_info:*:*' nvcsformats ""

# Fastest possible way to check if repo is dirty
#
function _is_repo_dirty() {
    # Check if we're in a git repo
    command git rev-parse --is-inside-work-tree &>/dev/null || return
    # Check if it's dirty
    command git diff --quiet --ignore-submodules HEAD &>/dev/null; [ $? -eq 1 ] && echo "true" && return
    # We're in a git repo but we're clean
    echo "false"
}

function _pluralize() {
  if [[ "$1" == "1" ]]; then
    echo "$2"
  else
    echo "$2s"
  fi
}

function _fetch_repo_info() {
    GST=""
    if [[ "$1" == "verbose" ]]; then
      local git_is_dirty=$(_is_repo_dirty)

      if [[ "$git_is_dirty" != "" ]]; then
         INDEX=$(command git status --porcelain -b 2> /dev/null)

         local untracked="$(command echo "$INDEX" | grep -E '^\?\? ' | wc -l | sed 's/^ *//' 2> /dev/null)"
         if [[ "$untracked" != "0" ]]; then
           GST="%{$FG[249]%}, $untracked $(_pluralize $untracked 'file') untracked$GST"
         fi

         if [[ "$git_is_dirty" == "false" ]]; then
            GST="%{$FG[040]%}✔$GST"
         elif [[ "$git_is_dirty" == "true" ]]; then

            local changed="$(command git diff --shortstat 2> /dev/null)"

            if [[ "$changed" != "" ]]; then
              GST="%{$FG[249]%},$changed$GST"
            fi

            local added="$(command echo "$INDEX" | grep '^A  ' | wc -l | sed 's/^ *//' 2> /dev/null)"
            if [[ "$added" != "0" ]]; then
               GST="%{$FG[249]%}, $added $(_pluralize $added 'file') added$GST"
            fi

            GST="%{%F{red}%}✘%{$FG[249]%}$GST"
         fi

         if [[ "$GST" != '' ]]; then
           GST=" %{$FG[249]%}$GST%f"
         fi
      fi
    fi

    if [[ "$vcs_info_msg_0_" != '' ]]; then
      echo "%F{green}${vcs_info_msg_0_%%/.}%f$GST"
    fi
}

function git-repos-status() {
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
      test "$(git status 2> /dev/null | grep $pattern)" && vcs_info && print -P "%F{white}${d%/}%f: $(_fetch_repo_info verbose)%f"
      cd $original_dir
    fi
  done

  cd $original_dir
}

alias grs='git-repos-status'
