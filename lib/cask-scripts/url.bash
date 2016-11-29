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
    host = URI.parse('$1').host
    p host.start_with?('www.') ? host[4..-1] : host
  " | unquote
}

# Get path from URL without query and fragment parts.
#
# Arguments:
#   $1 - URL
#
# Return path.
get_url_path() {
  local path

  [[ -z "$*" ]] && return 1
  readonly path=$(ruby -ruri -e "
    path = URI.parse('$1').path
    p path
  " | unquote)

  [[ "${path}" == 'nil' ]] || [[ -z "${path}" ]] && echo '/' || echo "${path}"
  return 0
}

# Get request URI with fragment from URL (full path).
#
# Arguments:
#   $1 - URL
#
# Returns full path.
get_url_full_path() {
  local path

  [[ -z "$*" ]] && return 1
  readonly path=$(ruby -ruri -e "
    request_uri = URI.parse('$1').request_uri
    fragment = URI.parse('$1').fragment
    fragment = (fragment) ? \"##{fragment}\" : ''
    p request_uri + fragment
  " | unquote)

  [[ "${path}" == 'nil' ]] && echo '/' || echo "${path}"
  return 0
}

# Get fragment part from URL.
#
# Arguments:
#   $1 - URL
#
# Return fragment.
get_url_fragment() {
  local fragment

  [[ -z "$*" ]] && return 1
  readonly fragment=$(ruby -ruri -e "
    fragment = URI.parse('$1').fragment
    p fragment
  " | unquote)

  [[ "${fragment}" == 'nil' ]] && return 1

  echo "${fragment}"
  return 0
}

# Get redirect URL from original one.
# Return only an effective URL (fragment part is ignored).
#
# Globals:
#   BROWSER_HEADERS
#
# Arguments:
#   $1 - URL
#
# Returns redirect URL.
get_url_redirect() {
  local url redirect fragment_url fragment_redirect

  readonly url="$1"
  [[ -z "$*" ]] && return 1

  readonly fragment_url=$(get_url_fragment "${url}")
  readonly redirect=$(curl --silent --location --head --header "${BROWSER_HEADERS}" --max-time 10 --output /dev/null --write-out "%{url_effective}" "${url}" 2>/dev/null)
  readonly fragment_redirect=$(get_url_fragment "${redirect}")

  [[ ! -z "${fragment_url}" ]] && [[ -z "${fragment_redirect}" ]] && echo "${redirect}#${fragment_url}" || echo "${redirect}"
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

  [[ "${status}" -eq 0 ]] && [[ "${code}" -eq 200 ]] && return 0

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

# Fix URL based on redirect if forced to use plain HTTP.
#
# Arguments:
#   $1 - URL
#   $2 - Redirect URL
#
# Returns fixed URL if successfull.
url_fix_http() {
  local url redirect

  readonly url="$1"
  readonly redirect="$2"
  [[ -z "${url}" ]] || [[ -z "${redirect}" ]] && return 1
  [[ "$(get_url_host "${url}")" != "$(get_url_host "${redirect}")" ]] && return 1

  if check_url_https "${url}" && ! check_url_https "${redirect}"; then
    echo "${url/https:/http:}"
    return 0
  fi

  return 1
}

# Fix URL based on redirect if forced to use HTTPS.
#
# Arguments:
#   $1 - URL
#   $2 - Redirect URL
#
# Returns fixed URL if successfull.
url_fix_https() {
  local url redirect

  readonly url="$1"
  readonly redirect="$2"
  [[ -z "${url}" ]] && return 1
  [[ "$(get_url_host "${url}")" != "$(get_url_host "${redirect}")" ]] && return 1

  if [[ ! -z "${redirect}" ]]; then
    # when we have a redirect
    if ! check_url_https "${url}" && check_url_https "${redirect}"; then
      echo "${url/http:/https:}"
      return 0
    fi
  fi

  # check manually if HTTPS is available
  check_url_https_availability "${url}"
  if [[ "$?" -eq 0 ]]; then
    echo "${url/http:/https:}"
    return 0
  fi

  return 1
}

# Fix URL based on redirect if forced to add WWW in host.
#
# Arguments:
#   $1 - URL
#   $2 - Redirect URL
#
# Returns fixed URL if successfull.
url_fix_www() {
  local url redirect host

  readonly url="$1"
  readonly redirect="$2"
  [[ -z "${url}" ]] || [[ -z "${redirect}" ]] && return 1
  readonly host=$(get_url_host "${url}")
  [[ "${host}" != "$(get_url_host "${redirect}")" ]] && return 1

  if ! check_url_www "${url}" && check_url_www "${redirect}"; then
    echo "${url/${host}/www.${host}}"
    return 0
  fi

  return 1
}

# Fix URL based on redirect if forced to remove WWW in host.
#
# Arguments:
#   $1 - URL
#   $2 - Redirect URL
#
# Returns fixed URL if successfull.
url_fix_no_www() {
  local url redirect host

  readonly url="$1"
  readonly redirect="$2"
  [[ -z "${url}" ]] || [[ -z "${redirect}" ]] && return 1
  readonly host=$(get_url_host "${url}")
  [[ "${host}" != "$(get_url_host "${redirect}")" ]] && return 1

  if check_url_www "${url}" && ! check_url_www "${redirect}"; then
    echo "${url/www.${host}/${host}}"
    return 0
  fi

  return 1
}

# Fix URL based on redirect if forced to add a trailing slash.
#
# Arguments:
#   $1 - URL
#   $2 - Redirect URL
#
# Returns fixed URL if successfull.
url_fix_slash() {
  local url redirect host url_path redirect_path

  readonly url="$1"
  readonly redirect="$2"
  [[ -z "${url}" ]] || [[ -z "${redirect}" ]] && return 1
  readonly host=$(get_url_host "${url}")
  [[ "${host}" != "$(get_url_host "${redirect}")" ]] && return 1

  readonly url_path=$(get_url_full_path "${url}")
  readonly redirect_path=$(get_url_full_path "${redirect}")

  if [[ ! "${url}" =~ ${host}$ ]] && [[ "${url_path%/}" == "${redirect_path%/}" ]] && [[ ! "${url}" =~ \/$ ]] && [[ "${redirect}" =~ \/$ ]]; then
    echo "${url}/"
    return 0
  fi

  return 1
}

# Fix URL based on redirect if forced to remove a trailing slash.
#
# Arguments:
#   $1 - URL
#   $2 - Redirect URL
#
# Returns fixed URL if successfull.
url_fix_no_slash() {
  local url redirect host url_path redirect_path

  readonly url="$1"
  readonly redirect="$2"
  [[ -z "${url}" ]] || [[ -z "${redirect}" ]] && return 1
  readonly host=$(get_url_host "${url}")
  [[ "${host}" != "$(get_url_host "${redirect}")" ]] && return 1

  readonly url_path=$(get_url_full_path "${url}")
  readonly redirect_path=$(get_url_full_path "${redirect}")

  if [[ ! "${url}" =~ ${host}\/$ ]] && [[ "${url_path%/}" == "${redirect_path%/}" ]] && [[ "${url}" =~ \/$ ]] && [[ ! "${redirect}" =~ \/$ ]]; then
    echo "${url%/}"
    return 0
  fi

  return 1
}

# Fix URL by adding a bare trailing slash.
#
# Arguments:
#   $1 - URL
#
# Returns fixed URL if successfull.
url_fix_bare_slash() {
  local url host

  readonly url="$1"
  [[ -z "${url}" ]] && return 1

  readonly host=$(get_url_host "${url}")

  if [[ "${url}" =~ ${host}$ ]]; then
    echo "${url%/}/"
    return 0
  fi

  return 1
}

# Fix URL based on redirect if path changed.
#
# Arguments:
#   $1 - URL
#   $2 - Redirect URL
#
# Returns fixed URL if successfull.
url_fix_path() {
  local url redirect host url_path redirect_path

  readonly url="$1"
  readonly redirect="$2"
  [[ -z "${url}" ]] || [[ -z "${redirect}" ]] && return 1
  readonly host=$(get_url_host "${url}")
  [[ "${host}" != "$(get_url_host "${redirect}")" ]] && return 1

  readonly url_path=$(get_url_full_path "${url}")
  readonly redirect_path=$(get_url_full_path "${redirect}")

  if [[ "${url_path}" != "${redirect_path}" ]]; then
    echo "${url/${host}${url_path}/${host}${redirect_path}}"
    return 0
  fi

  return 1
}

# Fix URL based on redirect if host has changed.
#
# Arguments:
#   $1 - URL
#   $2 - Redirect URL
#
# Returns fixed URL if successfull.
url_fix_host() {
  local url redirect host redirect_host url_path redirect_path

  readonly url="$1"
  readonly redirect="$2"
  [[ -z "${url}" ]] || [[ -z "${redirect}" ]] && return 1
  readonly host=$(get_url_host "${url}")
  readonly redirect_host=$(get_url_host "${redirect}")
  [[ "${host}" == "${redirect_host}" ]] && return 1

  readonly url_path=$(get_url_full_path "${url}")
  readonly redirect_path=$(get_url_full_path "${redirect}")

  if [[ "${host}" != "${redirect_host}" ]]; then
    echo "${url/${host}/${redirect_host}}"
    return 0
  fi

  return 1
}
