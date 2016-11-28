#!/usr/bin/env bash
#
# Git specific shared functions that are used in multiple scripts.
#
# Requires functions from general.bash to be loaded.
#
# License:         MIT License
# Author:          Victor Popkov <victor@popkov.me>
# Last modified:   26.11.2016

# Constants and globals
declare -a CASKS
declare REMOTE_PULL
declare REMOTE_PUSH
declare BRANCH_NAME

# Checks if remote is set.
#
# Arguments:
#   $1 - Remote
#
# Returns status.
git_has_remote() {
  local -a remotes
  local remote

  readonly remotes=($(git remote))
  readonly remote="$1"
  [[ -z "$*" ]] && return 1

  fgrep --word-regexp --extended-regexp -q "${remote}" <<< "${remotes[@]}"
}

# Lists remote branches that start with program name.
#
# Globals:
#   REMOTE_PUSH
#   PROGRAM
#
# Returns branches.
git_list_remote_program_branches() {
  git ls-remote --heads "${REMOTE_PUSH}" | grep --extended-regexp "${PROGRAM}_.*$" --only-matching | xargs
}

# Get last upstream/master commit.
#
# Globals:
#   REMOTE_PULL
#
# Returns commit hash.
git_get_last_upstream_commit() {
  git rev-parse --short "${REMOTE_PULL}/master"
}

# Get commit hash of the branch point that was diverged from upstream/master.
#
# Globals:
#   REMOTE_PULL
#
# Arguments:
#   $1 - Branch name
#
# Returns commit hash.
git_get_branch_diverge_point() {
  local branch

  readonly branch="$1"
  [[ -z "$*" ]] && return 1

  diff -u <(git rev-list --first-parent ${branch}) <(git rev-list --first-parent "${REMOTE_PULL}/master") | sed -ne 's/^ //p' | head -1
}

# Delete creaeted branches that start with program name.
#
# Globals:
#   PROGRAM
#   REMOTE_PUSH
#
# Arguments:
#   $1 - Status: 'abort' or 'success'
#   $2 - Message
git_delete_program_branches() {
  local local_branches remote_branches

  # delete local branches
  local_branches=$(git branch --all | grep --extended-regexp "^ *${PROGRAM}_.*$" | perl -pe 's|^ *||;s|\n| |')
  [[ -n "${local_branches}" ]] && git branch -D ${local_branches}

  # delete remote branches
  git fetch --prune "${REMOTE_PUSH}"
  remote_branches=$(git branch --all | grep --extended-regexp "remotes/${REMOTE_PUSH}/${PROGRAM}_.*$" | perl -pe 's|.*/||;s|\n| |')
  [[ -n "${remote_branches}" ]] && git push "${REMOTE_PUSH}" --delete ${remote_branches}
}

# Make git push.
#
# Globals:
#   BRANCH_NAME
#   REMOTE_PUSH
git_push() {
  git push --force "${REMOTE_PUSH}" "${BRANCH_NAME}" --quiet
}

# Ask for which remote branch pull and switch to.
# Don't ask if only one is available.
#
# Globals:
#   REMOTE_PUSH
#   BRANCH_NAME
ask_remote_branch_to_switch() {
  local -a branches

  readonly branches=($(git_list_remote_program_branches))

  if [[ "${#branches[@]}" -gt 1 ]]; then
    printf 'Choose a branch to edit:\n\n'
    select opt in "${branches[@]}"; do
      printf "\033c"
      BRANCH_NAME="${opt}"
      break
    done
  else
    BRANCH_NAME="${branches[0]}"
  fi

  printf "Switched to branch '%s'...\n" "${BRANCH_NAME}"

  git pull "${REMOTE_PUSH}" "${BRANCH_NAME}" --quiet
  git checkout "${BRANCH_NAME}" --quiet
}

# Ask for which casks to edit since the branch diverge point that were modified.
#
# Globals:
#   CASKS
ask_casks_to_edit() {
  local -a casks
  local last_upstream_commit

  readonly last_upstream_commit=$(git_get_last_upstream_commit)
  readonly casks=($(git diff-tree --no-commit-id --name-only -r HEAD "${last_upstream_commit}" | xargs -L1 basename | sed -e 's/\.rb$//g'))

  printf 'List of modified casks:\n\n'

  for cask in "${!casks[@]}"; do
    echo "$((cask+1)). ${casks[cask]}"
  done

  printf '\n'
  while true; do
    read -p 'Please choose casks you would like to edit (numbers separated by spaces): ' -a numbers
    if [[ ! -z "${numbers}" ]]; then
      for number in "${numbers[@]}"; do
        CASKS+=("${casks[number-1]}")
      done
      break
    fi
  done
}
