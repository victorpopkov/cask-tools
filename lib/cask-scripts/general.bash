#!/usr/bin/env bash
#
# General shared functions that are used in multiple scripts.
#
# License:         MIT License
# Author:          Victor Popkov <victor@popkov.me>
# Last modified:   26.11.2016

# Constants and globals
declare PROGRAM
declare VERSION
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

# Display warning.
#
# Arguments:
#   $1 - Warning description
#
# Returns exit status 1.
warning() {
  echo -e "$(tput setaf 3)$1$(tput sgr0)"
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
  local -a check_array_contains_array # name should differ from external variables
  local element

  readonly check_array_contains_array=(${!1})
  readonly element="$2"
  [[ -z "${check_array_contains_array[@]}" ]] || [[ -z "${element}" ]] && return 1

  fgrep --word-regexp -q "${element}" <<< "${check_array_contains_array[@]}" && return 0
  return 1
}

# Get values from XML configurations file.
#
# Globals:
#   CONFIG_FILE_XML
#
# Arguments:
#   $1 - Path to match (required)
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

# Highlight first difference between two strings using provided color.
#
# Arguments:
#   $1 - Original string (required)
#   $2 - Modified string (required)
#   $3 - Highlight color (optional)
#   $4 - Precision (optional)
#
# Returns highlighted string.
highlight_diff() {
  local -i max_length color precision chars_shift
  local original modified

  readonly original="$1"
  readonly modified="$2"
  [[ -z "${original}" ]] || [[ -z "${modified}" ]] && return 1

  color="$3"
  [[ -z "$3" ]] && color=7
  readonly color

  precision="$4"
  [[ -z "$4" ]] && precision=20
  readonly precision

  [[ "${#original}" -gt "${#modified}" ]] && max_length="${#original}" || max_length="${#modified}"

  for ((i = 0; i < max_length; i++)); do
    char_original="${original:${i}:1}"
    char="${modified:${i}:1}"

    if [[ "${char_original}" != "${char}" ]]; then
      if [[ "${chars_shift}" -eq 0 ]]; then
        chars_shift=0
        for ((j = i; j < max_length; j++)); do
          if [[ "${chars_shift}" -eq 0 ]]; then
            for ((k = j; k < max_length; k++)); do
              if [[ -z "${original:${j}:${precision}}" ]]; then
                chars_shift="${max_length}"
                break
              elif [[ "${original:${j}:${precision}}" == "${modified:${k}:${precision}}" ]]; then
                chars_shift="${k}"
                break
              fi
            done
          fi
        done
        [[ "${chars_shift}" -ne 0 ]] && printf "$(tput setaf "${color}")"
      fi
    fi

    [[ "${chars_shift}" -ne 0 ]] && [[ "${chars_shift}" -eq "${i}" ]] && printf "$(tput sgr0)"
    printf "%s" "${char}"
  done

  [[ "${original}" != "${modified}" ]] && [[ "${chars_shift}" -eq "${i}" ]] && printf "$(tput sgr0)"

  printf "\n"
  return 0
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
