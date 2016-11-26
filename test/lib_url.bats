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
