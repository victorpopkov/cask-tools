#!/usr/bin/env bats
load test_helper
load ../lib/cask-scripts/general
load ../lib/cask-scripts/cask

# get_cask_stanza_value()
@test "get_cask_stanza_value() when required arguments not passed" {
  run get_cask_stanza_value
  [ "${status}" -eq 1 ]
}

@test "get_cask_stanza_value() when retrieving typical stanzas (version, sha256, appcast, name, homepage, license) from cask (acorn.rb)" {
  run get_cask_stanza_value 'acorn' 'version'
  [ "${status}" -eq 0 ]
  [ "${output}" == '5.4' ]
  run get_cask_stanza_value 'acorn' 'sha256'
  [ "${status}" -eq 0 ]
  [ "${output}" == '9065ae8493fa73bfdf5d29ffcd0012cd343475cf3d550ae526407b9910eb35b7' ]
  run get_cask_stanza_value 'acorn' 'url'
  [ "${status}" -eq 0 ]
  [ "${output}" == 'https://secure.flyingmeat.com/download/Acorn.zip' ]
  run get_cask_stanza_value 'acorn' 'appcast'
  [ "${status}" -eq 0 ]
  [ "${output}" == 'http://www.flyingmeat.com/download/acorn5update.xml' ]
  run get_cask_stanza_value 'acorn' 'homepage'
  [ "${status}" -eq 0 ]
  [ "${output}" == 'http://flyingmeat.com/acorn/' ]
  run get_cask_stanza_value 'acorn' 'license'
  [ "${status}" -eq 0 ]
  [ "${output}" == ':commercial' ]
}

@test "get_cask_stanza_value() when retrieving appcast checkpoint (with semicolon: 'checkpoint:') from cask (acorn.rb)" {
  run get_cask_stanza_value 'acorn' 'checkpoint:'
  [ "${status}" -eq 0 ]
  [ "${output}" == '95ffe5b581434db6284ed8dfe0cddead69a5d3f7269ca488baba3bd1218e43f7' ]
}

@test "get_cask_stanza_value() when retrieving appcast checkpoint (without semicolon: 'checkpoint') from cask (acorn.rb)" {
  run get_cask_stanza_value 'acorn' 'checkpoint'
  [ "${status}" -eq 0 ]
  [ "${output}" == '95ffe5b581434db6284ed8dfe0cddead69a5d3f7269ca488baba3bd1218e43f7' ]
}

@test "get_cask_stanza_value() when retrieving version and its name can be found in comments (world-of-tanks.rb)" {
  run get_cask_stanza_value 'world-of-tanks' 'version'
  [ "${status}" -eq 0 ]
  [ "${output}" == '1.0.30' ]
}

# get_xml_config_custom_rule()
@test "get_xml_config_custom_rule() when no argument" {
  run get_xml_config_custom_rule
  [ "${status}" -eq 1 ]
}

@test "get_xml_config_custom_rule() when argument passed but config path not set" {
  run get_xml_config_custom_rule 'example'
  [ "${status}" -eq 1 ]
}

@test "get_xml_config_custom_rule() when argument passed but config path is invalid" {
  readonly CONFIG_FILE_XML='invalid/path.xml'
  run get_xml_config_custom_rule 'example'
  [ "${status}" -eq 1 ]
}

@test "get_xml_config_custom_rule() when non-existing cask name in custom rules" {
  readonly CONFIG_FILE_XML="${BATS_TEST_DIRNAME}/config/cask-check-updates.xml"
  run get_xml_config_custom_rule 'invalid'
  [ "${status}" -eq 1 ]
}

@test "get_xml_config_custom_rule() example found in custom rules: => v#{version.gsub('-release$', '')}-#{build}" {
  readonly CONFIG_FILE_XML="${BATS_TEST_DIRNAME}/config/cask-check-updates.xml"
  run get_xml_config_custom_rule 'example'
  [ "${status}" -eq 0 ]
  [ "${output}" == "v#{version.gsub(/-release$/, '')}-#{build}" ]
}
