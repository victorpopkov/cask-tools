#!/usr/bin/env bash
#
# Cask specific shared functions that are used in multiple scripts.
#
# Requires functions from general.bash and appcast.bash to be loaded.
#
# License:         MIT License
# Author:          Victor Popkov <victor@popkov.me>
# Last modified:   28.11.2016

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

# Modify cask stanza by it's value.
#
# Arguments:
#   $1 - Cask name
#   $2 - Stanza name
#   $3 - Old stanza value
#   $4 - New stanza value
modify_stanza_by_value() {
  local cask stanza old_value new_value

  readonly cask="${1/.rb}"
  readonly stanza="$2"
  readonly old_value="$3"
  readonly new_value="$4"

  perl -0777 -i -e'
    $stanza_to_modify = shift(@ARGV);
    $old_stanza_value = shift(@ARGV);
    $new_stanza_value = shift(@ARGV);
    print <> =~ s|\A.*^\s*\Q$stanza_to_modify\E\s\K[^\n]$old_stanza_value|$new_stanza_value|smr;
  ' "${stanza}" "${old_value}" "${new_value}" "${cask}.rb"
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
