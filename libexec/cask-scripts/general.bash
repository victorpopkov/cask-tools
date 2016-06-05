#!/usr/bin/env bash
#
# General shared functions that are used in multiple scripts.
#
# License:         MIT License
# Author:          Victor Popkov <victor@popkov.me>
# Last modified:   04.06.2016

# Constants and globals
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
# Returns status.
show_review() {
  local name
  local -i name_max_length

  # get the longest length of the name string
  name_max_length=0
  for name in "${REVIEW_NAMES[@]}"; do
    [[ "${name_max_length}" -lt "${#name}" ]] && name_max_length="${#name}"
  done

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

# Interpolate version into string.
#
# Arguments:
#   $1 - String
#   $2 - Version
#
# Returns string with version.
interpolate_version() {
  local IFS version_original version_only major minor patch string string_part version_part replace
  local -a string_parts version_parts

  string="$1"
  readonly version_original="$2"
  readonly version_only=$(sed -e 's/[^0-9.]*\([0-9.]*\).*/\1/' <<< "${version_original}")
  readonly string_parts=($(grep -o "#{version[^}]*}" <<< "${string}" | xargs))

  for string_part in "${string_parts[@]}"; do
    if [[ "${string_part}" == '#{version}' ]]; then
      string="${string//${string_part}/${version_original}}"
      continue
    fi

    IFS='.' read -ra version_parts <<< "$(sed -e 's/^#{version//' -e 's/}$//' -e 's/^\.//' <<< "${string_part}")"

    for version_part in "${version_parts[@]}"; do
      replace=''
      major=$(cut -d '.' -f 1 <<< "${version_only}")
      minor=$(cut -d '.' -f 2 <<< "${version_only}")
      patch=$(cut -d '.' -f 3 <<< "${version_only}")

      case "${version_part}" in
        'major')             replace+="${major}" ;;
        'minor')             replace+="${minor}" ;;
        'patch')             replace+="${patch}" ;;
        'major_minor')       replace+="${major}.${minor}" ;;
        'major_minor_patch') replace+="${major}.${minor}.${patch}" ;;
        'before_comma')      replace+="$(cut -d ',' -f 1 <<< "${version_original}")" ;;
        'after_comma')       replace+="$(cut -d ',' -f 2 <<< "${version_original}")" ;;
        'before_colon')      replace+="$(cut -d ':' -f 1 <<< "${version_original}")" ;;
        'after_colon')       replace+="$(cut -d ':' -f 2 <<< "${version_original}")" ;;
      esac
    done

    string="${string//${string_part}/${replace}}"
  done

  echo "${string}"
}
