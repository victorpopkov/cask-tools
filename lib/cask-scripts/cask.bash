#!/usr/bin/env bash
#
# Cask specific shared functions that are used in multiple scripts.
#
# Requires functions from general.bash and appcast.bash to be loaded.
#
# License:         MIT License
# Author:          Victor Popkov <victor@popkov.me>
# Last modified:   26.11.2016

# Get value(s) of a cask stanza.
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

  grep -E "\s{2,}${stanza} " <<< "${content}" | sed -e "s/${stanza} //g" -e 's/ //g' | awk '{ print $1 }' | unquote
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
  local -a versions urls appcasts checkpoints line temp
  local -i counter

  readonly caskname="$1"
  [[ -z "${caskname}" ]] && return 1

  readonly cask="${caskname}.rb"
  readonly versions=($(get_cask_stanza_value "${caskname}" 'version'))
  readonly urls=($(get_cask_stanza_value "${caskname}" 'url'))
  readonly appcasts=($(get_cask_stanza_value "${caskname}" 'appcast'))
  readonly checkpoints=($(get_cask_stanza_value "${caskname}" 'checkpoint'))

  counter="${#versions[@]}"
  [[ "${#urls[@]}" -gt "${counter}" ]] && counter="${#urls[@]}"

  for ((i = 0; i < counter; i++)); do
    line=()

    [[ "$((i+1))" -lt "${#versions[@]}" ]] && next="/version '${versions[$i+1]}'/" || next='0'
    content=$(awk "/version '${versions[i]}'/,${next}" < "${cask}")

    temp=($(get_cask_stanza_value "${caskname}" 'appcast' "${content}"))
    appcast="${temp[0]}"
    temp=($(get_cask_stanza_value "${caskname}" 'checkpoint:' "${content}"))
    checkpoint="${temp[0]}"

    if [[ "${#urls[@]}" -gt "${#versions[@]}" ]]; then
      version="${versions[${#versions[@]}-1]}"
      url="${urls[i]}"
    elif [[ "${#urls[@]}" -lt "${#versions[@]}" ]]; then
      version="${versions[i]}"
      url="${urls[${#urls[@]}-1]}"
    else
      version="${versions[i]}"
      url="${urls[i]}"
    fi

    line+=("\"${version}\"")
    line+=("\"${appcast}\"")
    line+=("\"${checkpoint}\"")
    line+=("\"${url}\"")

    echo "${line[@]}"
  done

  return 0
}

# Interpolate version into string.
#
# Arguments:
#   $1 - String  (required)
#   $2 - Version (required)
#   $3 - Name    (optional)
#
# Returns string with version.
interpolate_version() {
  local -a string_parts methods version_parts
  local string name version_original version_only major minor patch string_part version_part replace

  string="$1"
  readonly version_original="$2"

  name="$3"
  [[ -z "${name}" ]] && name='version'
  readonly name

  readonly version_only=$(sed -e 's/[^0-9.]*\([0-9.]*\).*/\1/' <<< "${version_original}")
  readonly string_parts=($(grep -Eo "#{${name}}|(#{${name}\.[^}]*.[^{]*})" <<< "${string}" | sed -e "s/['\"]/QUOTE/g" -e 's/ /SPACE/g' | cut -d ' ' -f 1))

  for string_part in "${string_parts[@]}"; do
    if [[ "${string_part}" == "#{${name}}" ]]; then
      string="${string//${string_part}/${version_original}}"
      continue
    fi

    methods=(
      'sub' 'gsub' 'delete' 'to_i' 'to_f'
      'major' 'minor' 'patch' 'major_minor' 'major_minor_patch'
      'before_comma' 'after_comma' 'before_colon' 'after_colon'
      'no_dots' 'dots_to_underscores'
    )
    for method in "${methods[@]}"; do
      if [[ "${string_part}" =~ \."${method}" ]]; then
        string_part=$(sed -e "s/\.${method}/!${method}/g" -e "s/['\"]/QUOTE/g" <<< "${string_part}")
      fi
    done

    IFS='!' read -ra version_parts <<< "$(sed -e "s/^#{${name}//" -e 's/}$//' <<< "${string_part}" | xargs)"
    string_part=$(sed -e 's/!/\./g' -e "s/QUOTE/'/g" -e "s/SPACE/ /g" <<< "${string_part}")

    replace="${version_original}"
    for version_part in "${version_parts[@]}"; do
      major=$(cut -d '.' -f 1 <<< "${version_only}")
      minor=$(cut -d '.' -f 2 <<< "${version_only}")
      patch=$(cut -d '.' -f 3 <<< "${version_only}")

      version_part=$(sed -e "s/QUOTE/'/g" -e "s/SPACE/ /g" <<< "${version_part}")

      if [[ ! -z "${version_part}" ]]; then
        case "${version_part}" in
          'major')               replace="${major}" ;;
          'minor')               replace="${minor}" ;;
          'patch')               replace="${patch}" ;;
          'major_minor')         replace="${major}.${minor}" ;;
          'major_minor_patch')   replace="${major}.${minor}.${patch}" ;;
          'before_comma')        replace="$(cut -d ',' -f 1 <<< "${version_original}")" ;;
          'after_comma')         replace="$(cut -d ',' -f 2 <<< "${version_original}")" ;;
          'before_colon')        replace="$(cut -d ':' -f 1 <<< "${version_original}")" ;;
          'after_colon')         replace="$(cut -d ':' -f 2 <<< "${version_original}")" ;;
          'no_dots')             replace="${version_original//\.}" ;;
          'dots_to_underscores') replace="${version_original//\./_}" ;;
          *)                     replace=$(ruby -e "version='${replace}'; puts version.${version_part}" 2> /dev/null) ;;
        esac
      fi
    done

    string_part=$(printf "%q" "${string_part}")

    [[ ! -z "${replace}" ]] && string="${string//${string_part}/${replace}}"
  done

  echo "${string}"
}

# Get custom rule for specific cask from XML configurations file.
#
# Globals:
#   CONFIG_FILE_XML
#
# Arguments:
#   $1 - Cask name
#
# Returns rule and status.
get_xml_config_custom_rule() {
  local cask

  readonly cask="$1"
  [[ -z "${cask}" ]] && return 1
  [[ ! -f "${CONFIG_FILE_XML}" ]] && return 1

  xmlstarlet sel -t -m "//custom/cask[@name='${cask}']" -m '*' -i "name()='text'" -v '.' --else -o '#{' -v 'name()' \
  -i '@pattern' -o ".gsub(" -v '@pattern' -o ", '" -v '@replacement' -o "')" \
  -b -o '}' "${CONFIG_FILE_XML}"
}

# Modify cask stanza.
#
# Stolen from https://github.com/vitorgalvao/tiny-scripts/blob/master/cask-repair.
#
# Arguments:
#   $1 - Cask name
#   $2 - Stanza name
#   $3 - New stanza value
#
# Returns rule and status.
modify_stanza() {
  local cask stanza value

  readonly cask="${1/.rb}"
  readonly stanza="$2"
  readonly value="$3"

  perl -0777 -i -e'
    $stanza_to_modify = shift(@ARGV);
    $new_stanza_value = shift(@ARGV);
    print <> =~ s|\A.*^\s*\Q$stanza_to_modify\E\s\K[^\n]*|$new_stanza_value|smr;
  ' "${stanza}" "${value}" "${cask}.rb"
}

# Edit a cask.
#
# Globals:
#   EDITOR
#   GIT_EDITOR
#
# Arguments:
#   $1 - Cask name
#
# Returns rule and status.
edit_cask() {
  local cask

  readonly cask="${1/.rb}"
  [[ -z "$*" ]] && return 1

  if [[ -n "${EDITOR}" ]]; then
    eval "${EDITOR}" "${cask}.rb"
  else
    [[ -n "${GIT_EDITOR}" ]] && eval "${GIT_EDITOR}" "${cask}" || open -W "${cask}.rb"
  fi
}
