#!/usr/bin/env bash
#
# General shared functions that are used in multiple scripts.
#
# License:         MIT License
# Author:          Victor Popkov <victor@popkov.me>
# Last modified:   22.11.2016

# Constants and globals
declare PROGRAM
declare VERSION
declare BROWSER_HEADERS
declare CONFIG_FILE_XML
declare -a REVIEW_NAMES
declare -a REVIEW_VALUES
declare -a REVIEW_WARNINGS

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

# Check if value exists in array.
#
# Arguments:
#   $1 - Array
#   $2 - Element
#
# Returns:
#   0 – Contains
#   1 – Doesn't contain
check_array_contains() {
  [[ -z "$1" ]] && return 1
  echo "${!1}" | fgrep --word-regexp -q "$2" && return 0 || return 1
}

# Get values from XML configurations file.
#
# Globals:
#   CONFIG_FILE_XML
#
# Arguments:
#   $1 - Path to match  (required)
#   $2 - Path for value (required)
#   $2 - Path for attribute (required)
#
# Returns values and status.
get_xml_config_values() {
  local path_match path_value path_attribute

  readonly path_match="$1"
  readonly path_value="$2"
  readonly path_attribute="$3"
  [[ -z "${path_match}" ]] || [[ -z "${path_value}" ]] && return 1
  [[ ! -f "${CONFIG_FILE_XML}" ]] && return 1

  if [[ -z "${path_attribute}" ]]; then
    xmlstarlet sel -t -m "${path_match}" -v "${path_value}" "${CONFIG_FILE_XML}"
  else
    xmlstarlet sel -t -m "${path_match}" -v "${path_value}" -n -v "${path_attribute}" -n "${CONFIG_FILE_XML}"
  fi
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

# Add warning to the review.
#
# Globals:
#   REVIEW_WARNINGS
#
# Arguments:
#   $1 - Value
add_warning_to_review() {
  REVIEW_WARNINGS+=("$1")
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
#   REVIEW_WARNINGS
#
# Arguments:
#   $1 - Length of the name string (optional)
#
# Returns status.
show_review() {
  local -i name_max_length i
  local name

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

  # desplay warnings if available
  if [[ "${#REVIEW_WARNINGS[@]}" -gt 0 ]]; then
    printf "\n"
    for ((i = 0; i < ${#REVIEW_WARNINGS[@]}; i++)); do
      name=''
      # [[ "${i}" -eq 0 ]] && name='Warnings'
      [[ "${name_max_length}" -gt 0 ]] && printf "%-$((name_max_length+3))s %s\n" "${name}" "$((i+1)). ${REVIEW_WARNINGS[i]}" || printf "%s\n" "$((i+1)). ${REVIEW_WARNINGS[i]}"
    done
  fi

  REVIEW_NAMES=()
  REVIEW_VALUES=()
  REVIEW_WARNINGS=()

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
# Returns content, response code and execution status code.
get_url_content() {
  curl --silent --compressed --location --header "${BROWSER_HEADERS}" --max-time 10 --write-out '\n%{http_code}' "$1" 2>/dev/null
  printf "\n%i" "$?"
}

# Get response code from URL.
#
# Globals:
#   BROWSER_HEADERS
#
# Arguments:
#   $1 - URL
#
# Returns response code and execution status code.
get_url_status() {
  [[ -z "$*" ]] && return 1
  curl --silent --compressed --head --header "${BROWSER_HEADERS}" --max-time 10 --output /dev/null --write-out '%{http_code}' "$1" 2>/dev/null
  printf "\n%i" "$?"
}

# Get host from URL.
#
# Arguments:
#   $1 - URL
#
# Returns host.
get_url_host() {
  [[ -z "$*" ]] && return 1
  ruby -ruri -e "
  host = URI.parse('$1').host.downcase
  p host.start_with?('www.') ? host[4..-1] : host" | unquote
}

# Get path from URL.
#
# Arguments:
#   $1 - URL
#
# Returns path.
get_url_path() {
  local path

  [[ -z "$*" ]] && return 1
  readonly path=$(ruby -ruri -e "
  path = URI.parse('$1').path.downcase
  p path" | unquote)

  [[ -z "${path}" ]] && echo '/' || echo "${path}"
}

# Get redirect URL from original one.
#
# Globals:
#   BROWSER_HEADERS
#
# Arguments:
#   $1 - URL
#
# Returns redirect URL.
get_url_redirect() {
  [[ -z "$*" ]] && return 1
  curl --silent --location --head --header "${BROWSER_HEADERS}" --max-time 10 --output /dev/null --write-out "%{url_effective}" "$1" 2>/dev/null
}

# Check if HTTPS is available for URL.
#
# Arguments:
#   $1 - URL
#
# Returns:
#   0 - Available
#   1 - Not available
check_url_https_availability() {
  local -i code status
  local out url

  readonly url="$1"
  readonly out=$(get_url_status "${url/http:/https:}")
  readonly code=$(echo "${out}" | head -n 1)
  readonly status=$(echo "${out}" | tail -n 1)

  if [[ "${status}" -eq 0 ]] && [[ "${code}" -eq 200 ]]; then
    return 0
  fi

  return 1
}

# Check if URL has www.
#
# Arguments:
#   $1 - URL
#
# Returns:
#   0 - Has www
#   1 - Doens't have www
check_url_www() {
  [[ "$1" =~ http[s]?\:\/\/www ]] && return 0 || return 1
}

# Check if URL has HTTPS.
#
# Arguments:
#   $1 - URL
#
# Returns:
#   0 - Has HTTPS
#   1 - Doens't have HTTPS
check_url_https() {
  [[ "$1" =~ ^https\: ]] && return 0 || return 1
}

# Generate random string with given length.
#
# Arguments:
#   $1 - Length
#
# Returns reandom string.
random() {
  [[ -z "$*" ]] && return 1
  date +%s | shasum -a 256 | base64 | head -c "$1" ; echo
}

# Implode an array using specified separator.
#
# Arguments:
#   $1 - Separator
#   $2 - Array
#
# Returns joined string.
join_by() {
  local IFS

  IFS="$1"
  [[ -z "$*" ]] && return 1
  shift

  sed "s/${IFS/ }/${IFS}/g" <<< "$*"
  return 0
}

# Highlight a specific part of the string using provided color.
#
# Arguments:
#   $1 - String
#   $2 - Part to highlight
#   $3 - Replace with
#   $4 - Highlight color
#
# Returns highlighted string.
highlight() {
  local -i color
  local string part replace

  readonly string="$1"
  readonly part="$2"
  readonly replace="$3"
  readonly color="$4"
  [[ -z "${string}" ]] || [[ -z "${part}" ]] || [[ -z "${replace}" ]] || [[ -z "${color}" ]] && return 1

  sed -e "s/${part}/$(tput setaf "${color}")${replace}$(tput sgr0)/" <<< "${string}"
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
