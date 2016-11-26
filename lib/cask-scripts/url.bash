#!/usr/bin/env bash
#
# URL specific shared functions that are used in multiple scripts.
#
# Requires functions from general.bash to be loaded.
#
# License:         MIT License
# Author:          Victor Popkov <victor@popkov.me>
# Last modified:   26.11.2016

# Constants and globals
declare BROWSER_HEADERS

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
