#!/usr/bin/env bash
#
# Appcast specific shared functions that are used in multiple scripts.
#
# License:         MIT License
# Author:          Victor Popkov <victor@popkov.me>
# Last modified:   20.10.2016

# Constants and globals
declare BROWSER_HEADERS
declare GITHUB_USER
declare GITHUB_TOKEN
declare GITHUB_PRERELEASE

# Create sha256 checksum from that represents appcast checkpoint from piped content string.
#
# Arguments:
#   $1 - Content
#
# Returns checkpoint and status.
generate_appcast_checkpoint() {
  local content

  readonly content="$1"
  [[ -z "${content}" ]] && return 1

  sed -e 's/<pubDate>[^<]*<\/pubDate>//g' <<< "${content}" | shasum --algorithm 256 | awk '{ print $1 }'

  return 0
}

# Guess the appcast provider from the content.
#
# Arguments:
#   $1 - Content
#
# Returns provider and status.
get_appcast_provider() {
  local content result

  readonly content="$1"
  [[ -z "${content}" ]] && return 1

  # GitHub
  [[ "${content}" =~ '<feed'.*'<id>tag:github.com' ]] && result='GitHub Atom'

  # RSS
  if [[ "${content}" =~ '<rss'.* ]]; then
    # Sparkle
    [[ "${content}" =~ '<rss'.*'xmlns:sparkle' ]] && result='Sparkle'
    [[ "${content}" =~ '<item'.*'<enclosure' ]] && result='Sparkle'
  fi
  readonly result

  if [[ ! -z "${result}" ]]; then
    echo "${result}"
    return 0
  fi

  return 1
}

# Make Sparkle namespaces more consistent.
#
# Arguments:
#   $1 - Content
#
# Returns XML with fixed namespaces and status.
fix_sparkle_xmlns() {
  local content

  readonly content="$1"
  [[ -z "${content}" ]] && return 1

  if [[ "${content}" =~ '<rss'.*'xmlns:sparkle' ]]; then
    sed -e 's/ xmlns:sparkle=".*"/ xmlns:sparkle="http:\/\/www.andymatuschak.org\/xml-namespaces\/sparkle"/g' <<< "${content}"
  else
    sed -e 's/<rss/<rss xmlns:sparkle="http:\/\/www.andymatuschak.org\/xml-namespaces\/sparkle"/g' <<< "${content}"
  fi

  return 0
}

# Format XML content using xmlstarlet and uncomment tags.
#
# Arguments:
#   $1 - Content
#
# Returns formatted XML and return status.
format_xml() {
  local content

  content="$1"
  [[ -z "${content}" ]] && return 1

  content=$(xmlstarlet fo -s 2 -D -N <<< "${content}" 2> /dev/null)
  content=$(awk '{ sub(/<!--([[:space:]]*)?</, "<"); sub(/>([[:space:]]*)?-->/, ">"); print }' <<< "${content}") # uncomment tags

  echo "${content}"
  return 0
}

# Transform Sparkle line to array of values.
#
# Arguments:
#   $1 - Line in format: "<version>";"<build>";"<url>";"<title>"
#
# Returns array of values:
#   <version>
#   <build>
#   <url>
get_sparkle_version_build_url() {
  local line version version_before build url title
  local -a vars result

  readonly line="$1"
  [[ -z "${line}" ]] && return 1
  IFS=';' read -ra vars <<< "$1"

  version="${vars[0]//[\"[:space:]]}"
  readonly version_before="${version}"
  readonly build="${vars[1]//[\"[:space:]]}"
  readonly url=$(echo "${vars[2]}" | sed -e 's/"//g' | sed -e 's/["[:space:]]/%20/g')
  readonly title="${vars[3]//[\"]}"

  [[ -z "${version}" ]] && [[ ! -z "${build}" ]] && version="${build}"
  [[ -z "${version}" ]] && [[ -z "${build}" ]] && version=$(extract_version "${title}")
  readonly version

  result=("${version}")
  [[ ! -z "${build}" ]] && [[ "${version}" != "${build}" ]] && result+=("${build}")
  [[ ! -z "${url}" ]] && result+=("${url}")

  echo "${result[@]}"
  return 0
}

# Get latest version values from content of Sparkle appcast.
#
# Arguments:
#   $1 - Content
#   $2 - Match tag
#
# Returns status and array of values of latest version:
#   <version>
#   <build>
#   <url>
get_sparkle_latest() {
  local IFS content transform match
  local -a lines first last values result

  content=$(fix_sparkle_xmlns "$1")
  content=$(format_xml "${content}")
  readonly content
  readonly match="$2"

  transform=$(xmlstarlet sel -t -m '//channel/item' \
-o '"' -i 'sparkle:shortVersionString' -v 'sparkle:shortVersionString[1]' --else -v 'enclosure[1]/@sparkle:shortVersionString' -b -o '";' \
-o '"' -i 'sparkle:version' -v 'sparkle:version[1]' --else -v 'enclosure[1]/@sparkle:version' -b -o '";' \
-o '"' -i 'link' -v 'link[1]' --else -v 'enclosure[1]/@url' -b -o '";' \
-o '"' -v 'title' -o '"' -n <<< "${content}" 2> /dev/null)
  [[ ! -z "${match}" ]] && transform=$(grep "${match}" <<< "${transform}")
  readonly transform

  IFS=$'\n' read -rd '' -a lines <<< "${transform}"
  [[ "${#lines[@]}" -eq 0 ]] && return 1

  readonly first=($(get_sparkle_version_build_url "${lines[0]}"))

  if [[ "${#lines[@]}" -gt 1 ]]; then
    readonly last=($(get_sparkle_version_build_url "${lines[${#lines[@]}-1]}"))

    compare_versions "${first[0]}" "${last[0]}"
    case $? in
      0) values=("${first[@]}") ;; # =
      1) values=("${first[@]}") ;; # >
      2) values=("${last[@]}") ;;  # <
    esac
  else
    values=("${first[@]}")
  fi
  readonly values

  echo "${values[@]}"
  return 0
}

# Get latest version values from GitHub Atom URL.
#
# Globals:
#   GITHUB_USER
#   GITHUB_TOKEN
#   BROWSER_HEADERS
#   GITHUB_PRERELEASE
#
# Arguments:
#   $1 - GitHub Atom URL
#   $2 - Match tag
#
# Returns status and array of values:
#   <prerelease>      (true|false)
#   <version>
#   <download_urls>   (array)
#
#   Statuses:
#     0 - Success
#     1 - No releases found
#     2 - API forbidden
get_github_atom_latest() {
  local user repo match url out code content latest_tag prerelease_tag version prerelease download_urls
  local -a result

  IFS='/' read -ra parts <<< "$1"
  readonly parts
  readonly user="${parts[3]}"
  readonly repo="${parts[4]}"
  readonly match="$2"

  readonly url="https://api.github.com/repos/${user}/${repo}/releases"
  if [[ ! -z "${GITHUB_USER}" ]] && [[ ! -z "${GITHUB_TOKEN}" ]]; then
    out=$(curl --silent --compressed --location "${url}" --user "${GITHUB_USER}:${GITHUB_TOKEN}" --header "${BROWSER_HEADERS}" --max-time 10 --write-out '\n%{http_code}')
  else
    out=$(curl --silent --compressed --location "${url}" --header "${BROWSER_HEADERS}" --max-time 10 --write-out '\n%{http_code}')
  fi
  readonly out
  readonly code=$(echo "${out}" | tail -n1)
  readonly content=$(echo "${out}" | sed \$d)

  [[ "${code}" -eq 403 ]] && return 2

  if [[ ! -z "${match}" ]]; then
    latest_tag=$(echo "${content}" | jq ".|=sort_by(.created_at) | reverse | .[] | select(.prerelease == false) | .tag_name" 2> /dev/null | grep -i "${match}" | head -1 | xargs)
    prerelease_tag=$(echo "${content}" | jq ".|=sort_by(.created_at) | reverse | .[] | select(.prerelease == true) | .tag_name" 2> /dev/null | grep -i "${match}" | head -1 | xargs)
  fi

  if [[ -z "${latest_tag}" ]] && [[ -z "${prerelease_tag}" ]]; then
    latest_tag=$(echo "${content}" | jq ".|=sort_by(.created_at) | reverse | .[] | select(.prerelease == false) | .tag_name" 2> /dev/null | head -1 | xargs)
    prerelease_tag=$(echo "${content}" | jq ".|=sort_by(.created_at) | reverse | .[] | select(.prerelease == true) | .tag_name" 2> /dev/null | head -1 | xargs)
  fi

  readonly latest_tag prerelease_tag

  version="${latest_tag}"
  compare_versions "${latest_tag}" "${prerelease_tag}"
  [[ "$?" -eq 2 ]] && [[ "${GITHUB_PRERELEASE}" == 'true' ]] && version="${prerelease_tag}" # if latest_tag < prerelease_tag

  [[ -z "${version}" ]] && return 1

  prerelease='false'
  [[ "${version}" == "${prerelease_tag}" ]] && prerelease='true'

  readonly download_urls=($(echo "${content}" | jq ".[] | select(.tag_name == \"${latest_tag}\") | .assets" | jq '.[] | .browser_download_url' 2> /dev/null | xargs))
  version=$(grep -q 'v[0-9]' <<< "${version}" && echo "${version/v}" || echo "${version}") # v3.0 => 3.0
  result+=("${prerelease}")
  result+=("${version}")
  result+=("${download_urls[@]}")

  echo "${result[@]}"
  return 0
}
