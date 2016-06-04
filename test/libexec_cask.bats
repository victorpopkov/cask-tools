#!/usr/bin/env bats
load test_helper
load ../libexec/cask-scripts/general
load ../libexec/cask-scripts/appcast
load ../libexec/cask-scripts/cask

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
  echo "${output}"
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

# get_cask_version_appcast_checkpoint_url()
@test "get_cask_version_appcast_checkpoint_url() when no arguments passed" {
  run get_cask_version_appcast_checkpoint_url
  [ "${status}" -eq 1 ]
}

@test "get_cask_version_appcast_checkpoint_url() when single version, appcast and download url (acorn.rb)" {
  run get_cask_version_appcast_checkpoint_url 'acorn'
  [ "${status}" -eq 0 ]
  [ "${output}" == '"5.4" "http://www.flyingmeat.com/download/acorn5update.xml" "95ffe5b581434db6284ed8dfe0cddead69a5d3f7269ca488baba3bd1218e43f7" "https://secure.flyingmeat.com/download/Acorn.zip"' ]
}

@test "get_cask_version_appcast_checkpoint_url() when single version and appcast, but multiple download urls (praat.rb)" {
  run get_cask_version_appcast_checkpoint_url 'praat'
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == '"6.0.16" "https://github.com/praat/praat/releases.atom" "a260a0ac0d3fdc0cab09f8d9788c9022fc6c12c0cbe801e98b5cdadeb8300f0d" "http://www.fon.hum.uva.nl/praat/praat#{version.no_dots}_mac64.dmg"' ]
}

@test "get_cask_version_appcast_checkpoint_url() when equal number of separate versions, appcasts and download urls (cocktail.rb)" {
  run get_cask_version_appcast_checkpoint_url 'cocktail'
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == '"5.1" "http://www.maintain.se/downloads/sparkle/snowleopard/snowleopard.xml" "3fb0fdcd252f0d0898076a66c3ad3ef045590a82abc9c9789bc1d7fdd0dc21f0" "http://www.maintain.se/downloads/sparkle/snowleopard/Cocktail_#{version}.zip"' ]
  [ "${lines[1]}" == '"5.6" "http://www.maintain.se/downloads/sparkle/lion/lion.xml" "81397ad4229e65572fb5386f445e7ecfdfc2161c51ce85747d2b4768b419984e" "http://www.maintain.se/downloads/sparkle/lion/Cocktail_#{version}.zip"' ]
  [ "${lines[2]}" == '"6.9" "http://www.maintain.se/downloads/sparkle/mountainlion/mountainlion.xml" "916ed186f168a0ce5072beccb6e17f6f1771417ef3769aabff46d348f79b4c66" "http://www.maintain.se/downloads/sparkle/mountainlion/Cocktail_#{version}.zip"' ]
  [ "${lines[3]}" == '"7.9.1" "http://www.maintain.se/downloads/sparkle/mavericks/mavericks.xml" "9a81f957ef6be7894a7ee7bd68ce37c4b5c6062560c9ef6c708c1cb3270793cc" "http://www.maintain.se/downloads/sparkle/mavericks/Cocktail_#{version}.zip"' ]
  [ "${lines[4]}" == '"8.8.1" "http://www.maintain.se/downloads/sparkle/yosemite/yosemite.xml" "3618d6152a3a32bc2793e876f1b89a485b2160cc43ba44e17141497fe7e04301" "http://www.maintain.se/downloads/sparkle/yosemite/Cocktail_#{version}.zip"' ]
  [ "${lines[5]}" == '"9.2.4" "http://www.maintain.se/downloads/sparkle/elcapitan/elcapitan.xml" "421755f2e5436e77b334fc1a9871a384d467dc2bbb00bbe847ff13c3753998a3" "http://www.maintain.se/downloads/sparkle/elcapitan/Cocktail_#{version}.zip"' ]
}

@test "get_cask_version_appcast_checkpoint_url() when multiple versions point to the same download url and appcast (amethyst.rb)" {
  run get_cask_version_appcast_checkpoint_url 'amethyst'
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == '"0.9.10" "" "" "https://ianyh.com/amethyst/versions/Amethyst-#{version}.zip"' ]
  [ "${lines[1]}" == '"0.10.1" "https://ianyh.com/amethyst/appcast.xml" "d49ecc458c9c5528022f51c661da5d1fbad9699c30365552bde6e96340a74db6" "https://ianyh.com/amethyst/versions/Amethyst-#{version}.zip"' ]
}

@test "get_cask_version_appcast_checkpoint_url() when multiple versions point to the same download urls, but not all have appcast (clamxav.rb)" {
  run get_cask_version_appcast_checkpoint_url 'clamxav'
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == '"2.2.1" "" "" "https://www.clamxav.com/downloads/ClamXav_#{version}.dmg"' ]
  [ "${lines[1]}" == '"2.5.1" "" "" "https://www.clamxav.com/downloads/ClamXav_#{version}.dmg"' ]
  [ "${lines[2]}" == '"2.8.9.3" "https://www.clamxav.com/sparkle/appcast.xml" "3174407536e67a24c265ba98e7c1e6fe78558ef28ce2e3defde2c30bac1f6270" "https://www.clamxav.com/downloads/ClamXav_#{version}.dmg"' ]
}

@test "get_cask_version_appcast_checkpoint_url() when multiple versions have own separate download urls, but not all have appcast (bettertouchtool.rb)" {
  run get_cask_version_appcast_checkpoint_url 'bettertouchtool'
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == '"0.939" "" "" "https://bettertouchtool.net/btt#{version}.zip"' ]
  [ "${lines[1]}" == '"1.69" "http://appcast.boastr.net" "c0db13ea9aec2e83f4a69ce215d652b457898a2fb3f9d71d1fb9f0085a86cf08" "https://boastr.net/releases/btt#{version}.zip"' ]
}
