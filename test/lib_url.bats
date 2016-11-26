#!/usr/bin/env bats
load ../lib/cask-scripts/general
load ../lib/cask-scripts/url

# get_url_content()
@test "get_url_content() from example.com (skipped if no connection)" {
  if ping -q -c 1 example.com; then
    local -i response_code response_status
    local content
    run get_url_content 'example.com'
    [ "${status}" -eq 0 ]
    content=$(echo "${output}" | sed -e :a -e '$d;N;2,2ba' -e 'P;D') # delete last 2 lines
    readonly response_code=$(echo "${output}" | tail -n 2 | head -n 1)
    readonly response_status=$(echo "${output}" | tail -n 1)
    [ "${response_code}" -eq 200 ]
    [ "${response_status}" -eq 0 ]
    [ "$(echo "${content}" | sed -n 2p)" == '<html>' ]
    [ "$(echo "${content}" | sed -n 3p)" == '<head>' ]
  else
    skip
  fi
}

# get_url_status()
@test "get_url_status() when no arguments" {
  run get_url_status
  [ "${status}" -eq 1 ]
}

@test "get_url_status() when example URL (skipped if no connection)" {
  if ping -q -c 1 example.com; then
    run get_url_status 'http://example.com/'
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" -eq 200 ]
    [ "${lines[1]}" -eq 0 ]
  else
    skip
  fi
}

# get_url_host()
@test "get_url_host() when no arguments" {
  run get_url_host
  [ "${status}" -eq 1 ]
}

@test "get_url_host() when full URL without www: http://example.com/index.html => example.com" {
  run get_url_host 'http://example.com/index.html'
  [ "${status}" -eq 0 ]
  [ "${output}" == 'example.com' ]
}

@test "get_url_host() when full URL with www: http://www.example.com/index.html => example.com" {
  run get_url_host 'http://www.example.com/index.html'
  [ "${status}" -eq 0 ]
  [ "${output}" == 'example.com' ]
}

@test "get_url_host() when full URL with subdomain and without www: http://subdomain.example.com/index.html => subdomain.example.com" {
  run get_url_host 'http://subdomain.example.com/index.html'
  [ "${status}" -eq 0 ]
  [ "${output}" == 'subdomain.example.com' ]
}

@test "get_url_host() when full URL with subdomain and with www: http://www.subdomain.example.com/index.html => subdomain.example.com" {
  run get_url_host 'http://www.subdomain.example.com/index.html'
  [ "${status}" -eq 0 ]
  [ "${output}" == 'subdomain.example.com' ]
}

# get_url_path()
@test "get_url_path() when no arguments" {
  run get_url_path
  [ "${status}" -eq 1 ]
}

@test "get_url_path() when URL without path and trailing slash: http://example.com/ => /" {
  run get_url_path 'http://example.com/'
  [ "${status}" -eq 0 ]
  [ "${output}" == '/' ]
}

@test "get_url_path() when URL without path: http://example.com => /" {
  run get_url_path 'http://example.com'
  [ "${status}" -eq 0 ]
  [ "${output}" == '/' ]
}

@test "get_url_path() when URL with path: http://example.com/index.html => /index.html" {
  run get_url_path 'http://example.com/index.html'
  [ "${status}" -eq 0 ]
  [ "${output}" == '/index.html' ]
}

# get_url_redirect()
@test "get_url_redirect() when no arguments" {
  run get_url_redirect
  [ "${status}" -eq 1 ]
}

# check_url_https_availability()
@test "check_url_https_availability() when no arguments" {
  run check_url_https_availability
  [ "${status}" -eq 1 ]
}

@test "check_url_https_availability() when URL has HTTPS (skipped if no connection)" {
  if ping -q -c 1 example.com; then
    run check_url_https_availability 'http://www.example.com/'
    [ "${status}" -eq 0 ]
  else
    skip
  fi
}

# check_url_www()
@test "check_url_www() when no arguments" {
  run check_url_www
  [ "${status}" -eq 1 ]
}

@test "check_url_www() when URL has www" {
  run check_url_www 'http://www.example.com/'
  [ "${status}" -eq 0 ]
}

@test "check_url_www() when URL doesn't have www" {
  run check_url_www 'http://example.com/'
  [ "${status}" -eq 1 ]
}

# check_url_https()
@test "check_url_https() when no arguments" {
  run check_url_https
  [ "${status}" -eq 1 ]
}

@test "check_url_https() when URL has HTTPS" {
  run check_url_https 'https://example.com/'
  [ "${status}" -eq 0 ]
}

@test "check_url_www() when URL doesn't have HTTPS" {
  run check_url_https 'http://example.com/'
  [ "${status}" -eq 1 ]
}

# url_fix_http()
@test "url_fix_http() when no arguments" {
  run url_fix_http
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_http() when URL and redirect have different hosts" {
  local url redirect
  readonly url='https://example.com/index.html'
  readonly redirect='http://test.example.com/'
  run url_fix_http "${url}" "${redirect}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_http() when URL with HTTPS but with redirect to plain HTTP" {
  local url redirect
  readonly url='https://example.com/index.html'
  readonly redirect='http://example.com/'
  run url_fix_http "${url}" "${redirect}"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'http://example.com/index.html' ]
}

@test "url_fix_http() when URL and redirect both have the same schema" {
  local url redirect
  url='http://example.com/index.html'
  redirect='http://example.com/'
  run url_fix_http "${url}" "${redirect}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]

  url='https://example.com/index.html'
  redirect='https://example.com/'
  run url_fix_http "${url}" "${redirect}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

# url_fix_https()
@test "url_fix_https() when no arguments" {
  run url_fix_https
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_https() when URL and redirect have different hosts" {
  local url redirect
  readonly url='http://example.com/index.html'
  readonly redirect='https://test.example.com/'
  run url_fix_https "${url}" "${redirect}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_https() when URL with HTTP but with redirect to HTTPS" {
  local url redirect
  readonly url='http://example.com/index.html'
  readonly redirect='https://example.com/'
  run url_fix_https "${url}" "${redirect}"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'https://example.com/index.html' ]
}

# url_fix_www()
@test "url_fix_www() when no arguments" {
  run url_fix_www
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_www() when URL and redirect have different hosts" {
  local url redirect
  readonly url='http://example.com/index.html'
  readonly redirect='http://www.test.example.com/'
  run url_fix_www "${url}" "${redirect}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_www() when URL without WWW but redirect has" {
  local url redirect
  readonly url='http://example.com/index.html'
  readonly redirect='http://www.example.com/'
  run url_fix_www "${url}" "${redirect}"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'http://www.example.com/index.html' ]
}

@test "url_fix_www() when URL and redirect both have WWW" {
  local url redirect
  readonly url='http://www.example.com/index.html'
  readonly redirect='http://www.example.com/'
  run url_fix_www "${url}" "${redirect}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

# url_fix_no_www()
@test "url_fix_no_www() when no arguments" {
  run url_fix_no_www
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_no_www() when URL and redirect have different hosts" {
  local url redirect
  readonly url='http://www.example.com/index.html'
  readonly redirect='http://test.example.com/'
  run url_fix_no_www "${url}" "${redirect}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_no_www() when URL without WWW but redirect has" {
  local url redirect
  readonly url='http://www.example.com/index.html'
  readonly redirect='http://example.com/'
  run url_fix_no_www "${url}" "${redirect}"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'http://example.com/index.html' ]
}

@test "url_fix_no_www() when URL and redirect both don't have WWW" {
  local url redirect
  readonly url='http://example.com/index.html'
  readonly redirect='http://example.com/'
  run url_fix_no_www "${url}" "${redirect}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

# url_fix_slash()
@test "url_fix_slash() when no arguments" {
  run url_fix_slash
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_slash() when server forces to add a trailing slash" {
  local url redirect
  readonly url='http://example.com/example'
  readonly redirect='http://example.com/example/'
  run url_fix_slash "${url}" "${redirect}"
  [ "${status}" -eq 0 ]
  [ "${output}" == "${redirect}" ]
}

@test "url_fix_slash() when no action required since already have a trailing slash" {
  local url redirect
  readonly url='http://example.com/example/'
  readonly redirect='http://example.com/example/'
  run url_fix_slash "${url}" "${redirect}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_slash() when we are dealing with a bare domain trailing slash (should be ignored)" {
  local url redirect
  readonly url='http://example.com'
  readonly redirect='http://example.com/'
  run url_fix_slash "${url}" "${redirect}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

# url_fix_no_slash()
@test "url_fix_no_slash() when no arguments" {
  run url_fix_no_slash
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_no_slash() when server forces to remove a trailing slash" {
  local url redirect
  readonly url='http://example.com/example/'
  readonly redirect='http://example.com/example'
  run url_fix_no_slash "${url}" "${redirect}"
  [ "${status}" -eq 0 ]
  [ "${output}" == "${redirect}" ]
}

@test "url_fix_no_slash() when no action required since already doesn't have a trailing slash" {
  local url redirect
  readonly url='http://example.com/example'
  readonly redirect='http://example.com/example'
  run url_fix_no_slash "${url}" "${redirect}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_no_slash() when we are dealing with a bare domain trailing slash (should be ignored)" {
  local url redirect
  readonly url='http://example.com/'
  readonly redirect='http://example.com'
  run url_fix_no_slash "${url}" "${redirect}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

# url_fix_bare_slash()
@test "url_fix_bare_slash() when no arguments" {
  run url_fix_bare_slash
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_bare_slash() when URL should have a bare trailing slash" {
  local url
  readonly url='http://example.com'
  run url_fix_bare_slash "${url}"
  [ "${status}" -eq 0 ]
  [ "${output}" == "${url}/" ]
}

@test "url_fix_bare_slash() when URL shouldn't have a bare trailing slash" {
  run url_fix_bare_slash 'http://example.com/example'
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]

  run url_fix_bare_slash 'http://example.com/index.html?example'
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

# url_fix_path()
@test "url_fix_path() when no arguments" {
  run url_fix_path
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_path() when hosts are the same and different path in redirect" {
  local url redirect
  readonly url='http://example.com/'
  readonly redirect='http://example.com/index.html'
  run url_fix_path "${url}" "${redirect}"
  [ "${status}" -eq 0 ]
  [ "${output}" == "${redirect}" ]
}

@test "url_fix_path() when schemas are different, hosts are the same and different path in redirect" {
  local url redirect
  url='https://example.com/'
  redirect='http://example.com/index.html'
  run url_fix_path "${url}" "${redirect}"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'https://example.com/index.html' ]

  url='http://example.com/'
  redirect='https://example.com/index.html'
  run url_fix_path "${url}" "${redirect}"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'http://example.com/index.html' ]
}

# url_fix_host()
@test "url_fix_host() when no arguments" {
  run url_fix_host
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_host() when hosts are the same but paths are different" {
  local url redirect
  readonly url='http://example.com/'
  readonly redirect='http://example.com/index.html'
  run url_fix_host "${url}" "${redirect}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "url_fix_host() when hosts are different but paths are the same" {
  local url redirect
  url='http://example.com/'
  redirect='http://other.com/'
  run url_fix_host "${url}" "${redirect}"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'http://other.com/' ]
}

@test "url_fix_host() when hosts and paths are different (redirect path should be ignored)" {
  local url redirect
  url='http://example.com/'
  redirect='http://other.com/index.html'
  run url_fix_host "${url}" "${redirect}"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'http://other.com/' ]
}
