#!/usr/bin/env bash
#
# General shared functions that are used in multiple scripts.
#
# License:         MIT License
# Author:          Victor Popkov <victor@popkov.me>
# Last modified:   07.06.2016

# Constants and globals
declare PROGRAM
declare VERSION
declare BROWSER_HEADERS
declare -a REVIEW_NAMES
declare -a REVIEW_VALUES

# Display syntax error.
#
# Globals:
#   PROGRAM
#
# Arguments:
#   $1 - Error description
#
# Returns exit status 1.
syntax_error() {
  echo "${PROGRAM}: $1" >&2
  echo "Try \`${PROGRAM} --help\` for more information." >&2
  exit 1
}

# Display error.
#
# Arguments:
#   $1 - Error description
#
# Returns exit status 1.
error() {
  echo -e "$(tput setaf 1)$1$(tput sgr0)"
  exit 1
}

# Display version.
#
# Globals:
#   VERSION
#
# Returns exit status 0.
version() {
  echo -e "${VERSION}"
  exit 0
}

# Divider to separate output in terminal.
#
# Globals:
#   COLUMNS
divide() {
  if [[ $(which hr) ]]; then hr '-'
  else printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -; fi
}

# Unquote a piped string and remove a trailing comma.
#
# Returns unquoted string.
unquote() {
  while read -r data; do
    sed -e 's/,$//' -e "s/^\([\"']\)\(.*\)\1\$/\2/g" <<< "${data}"
  done
}

# Add info to review.
#
# Globals:
#   REVIEW_NAMES
#   REVIEW_VALUES
#
# Arguments:
#   $1 - Name
#   $2 - Value
add_to_review() {
  local name value

  readonly name="$1"
  readonly value="$2"

  REVIEW_NAMES+=("${name}")
  REVIEW_VALUES+=("${value}")
}

# Show review.
#
# Globals:
#   REVIEW_NAMES
#   REVIEW_VALUES
#
# Arguments:
#   $1 - Length of the name string (optional)
#
# Returns status.
show_review() {
  local name
  local -i name_max_length

  if [[ -z "$1" ]]; then
    # get the longest length of the name string
    name_max_length=0
    for name in "${REVIEW_NAMES[@]}"; do
      [[ "${name_max_length}" -lt "${#name}" ]] && name_max_length="${#name}"
    done
  else
    name_max_length="$1"
    name_max_length=$((name_max_length-4))
  fi

  [[ "${#REVIEW_VALUES[@]}" -eq 0 ]] && return 1

  # display review
  for ((i = 0; i < ${#REVIEW_VALUES[@]}; i++)); do
    name="${REVIEW_NAMES[i]}:"
    [[ -z "${REVIEW_NAMES[i]}" ]] && name=''
    [[ "${name_max_length}" -gt 0 ]] && printf "%-$((name_max_length+3))s %s\n" "${name}" "${REVIEW_VALUES[i]}" || printf "%s\n" "${REVIEW_VALUES[i]}"
  done

  REVIEW_NAMES=()
  REVIEW_VALUES=()

  return 0
}

# Get content from URL.
#
# Globals:
#   BROWSER_HEADERS
#
# Arguments:
#   $1 - URL
#
# Returns content and status code (last line).
get_url_content() {
  curl --silent --compressed --location "$1" --header "${BROWSER_HEADERS}" --max-time 10 --write-out '\n%{http_code}' 2>/dev/null
}

# Extract version from string.
#
# Arguments:
#   $1 - Version
#
# Returns version.
extract_version() {
  sed -e 's/[^0-9.]*\([0-9A-Za-z.]*\).*/\1/' <<< "$1"
}

# Version comparison.
#
# Use 'sort -V' if available, otherwise use custom solution.
#
# Arguments:
#   $1 - First version
#   $2 - Second version
#
# Returns:
#   0 - First = second
#   1 - First > second
#   2 - First < second
compare_versions() {
  local first second

  first=$(extract_version "$1")
  second=$(extract_version "$2")

  [[ "${first}" == "${second}" ]] && return 0

  if echo | sort -Vr > /dev/null 2>&1; then
    local versions
    readonly versions=($(printf '%s\n%s\n' "${first}" "${second}" | sort -Vr))
    [[ "${first}" == "${versions[0]}" ]] && return 1
    [[ "${second}" == "${versions[0]}" ]] && return 2
  else
    # inspired by: http://stackoverflow.com/a/4025065
    local IFS='.'
    local i
    first=($(sed -e 's/[A-Za-z]/ /g' <<< "${first}" | tr -s ' ' '.'))
    second=($(sed -e 's/[A-Za-z]/ /g' <<< "${second}" | tr -s ' ' '.'))
    for ((i = ${#first[@]}; i < ${#second[@]}; i++)); do first[i]=0; done
    for ((i = 0; i < ${#first[@]}; i++)); do
      [[ -z "${second[i]}" ]] && second[i]=0
      ((10#${first[i]} > 10#${second[i]})) && return 1
      ((10#${first[i]} < 10#${second[i]})) && return 2
    done
  fi

  return 0
}
