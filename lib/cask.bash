#!/usr/bin/env bash
#
# Cask specific shared functions that are used in multiple scripts.
#
# License:         MIT License
# Author:          Victor Popkov <victor@popkov.me>
# Last modified:   04.06.2016

# Get value/values of a cask stanza.
#
# Arguments:
#   $1 - Cask name   (required)
#   $2 - Stanza name (required)
#   $3 - Content     (optional)
#
# Returns the stanza value and status.
get_cask_stanza_value() {
  local cask stanza content

  readonly cask="$1"
  stanza="$2"
  [[ -z "${cask}" ]] || [[ -z "${stanza}" ]] && return 1

  [[ "${stanza}" == 'checkpoint' ]] && stanza+=':'
  readonly stanza

  content="$3"
  [[ -z "$3" ]] && content=$(cat "${cask}.rb")
  readonly content

  grep "${stanza} " <<< "${content}" | sed -e "s/${stanza} //g" -e 's/ //g' | awk '{ print $1 }' | unquote
  return 0
}

# Get appcast, checkpoint and url for each version of the cask.
#
# Arguments:
#   $1 - Cask name
#
# Returns status and values of each version line by line format:
#   "<version>" "<appcast>" "<checkpoint>" "<url>"
get_cask_version_appcast_checkpoint_url() {
  local caskname cask next content appcast checkpoint
  local -a versions urls appcasts checkpoints line

  readonly caskname="$1"
  [[ -z "${caskname}" ]] && return 1

  readonly cask="${caskname}.rb"
  readonly versions=($(grep "^\s*.version " < "${cask}" | awk '{ print $2 }' | unquote))
  readonly appcasts=($(grep "^\s*.appcast " < "${cask}" | awk '{ print $2 }' | unquote))
  readonly checkpoints=($(grep "^\s*.checkpoint: " < "${cask}" | awk '{ print $2 }' | unquote))
  readonly urls=($(grep "^\s*.url " < "${cask}" | awk '{ print $2 }' | unquote))

  for ((i = 0; i < ${#versions[@]}; i++)); do
    line=()

    [[ "$((i+1))" -lt "${#versions[@]}" ]] && next="/version '${versions[$i+1]}'/" || next='0'
    content=$(awk "/version '${versions[i]}'/,${next}" < "${cask}")

    appcast=$(get_cask_stanza_value "${caskname}" 'appcast' "${content}")
    checkpoint=$(get_cask_stanza_value "${caskname}" 'checkpoint:' "${content}")
    if [[ "${#versions[@]}" -gt "${#urls[@]}" ]] || [[ "${#versions[@]}" -eq "${#urls[@]}" ]]; then
      [[ "${#urls[@]}" -gt 1 ]] && url=$(get_cask_stanza_value "${caskname}" 'url' "${content}") || url="${urls[0]}"
    else
      url="${urls[${#urls[@]}-1]}"
    fi

    line+=("\"${versions[i]}\"")
    line+=("\"${appcast}\"")
    line+=("\"${checkpoint}\"")
    line+=("\"${url}\"")

    echo "${line[@]}"
  done

  return 0
}
