#!/usr/bin/env bats
load test_helper
load ../lib/cask-scripts/general
load ../lib/cask-scripts/appcast
load ../lib/cask-scripts/cask

interpolate_cask_version_to_stanza() {
  local cask stanza version url
  local -a values

  readonly cask="$1"
  readonly stanza="$2"

  run get_cask_version_appcast_checkpoint_url "${cask}"
  readonly values=(${output})

  for ((i = 0; i < ${#values[@]}; i++)); do
    version=$(echo "${values[i]}" | awk '{ print $1 }' | unquote)
    url=$(echo "${values[i]}" | awk '{ print $4 }' | unquote)
    interpolate_version "${url}" "${version}"
  done
}

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
  [ "${lines[0]}" == '"6.0.16" "https://github.com/praat/praat/releases.atom" "a260a0ac0d3fdc0cab09f8d9788c9022fc6c12c0cbe801e98b5cdadeb8300f0d" "http://www.fon.hum.uva.nl/praat/praat#{version.no_dots}_mac32.dmg"' ]
  [ "${lines[1]}" == '"6.0.16" "https://github.com/praat/praat/releases.atom" "a260a0ac0d3fdc0cab09f8d9788c9022fc6c12c0cbe801e98b5cdadeb8300f0d" "http://www.fon.hum.uva.nl/praat/praat#{version.no_dots}_mac64.dmg"' ]
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

@test "get_cask_version_appcast_checkpoint_url() when the stanza name can be found in comments (world-of-tanks.rb)" {
  run get_cask_version_appcast_checkpoint_url 'world-of-tanks'
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == '"1.0.30" "https://wot.gcdn.co/us/files/osx/WoT_OSX_update_na.xml" "84e19ba0bf8fa534ad34ce6b844bc5682f809a935cd4f08bae376997d81f2a1f" "http://redirect.wargaming.net/WoT/latest_mac_install_na"' ]
}

# interpolate_version()
@test "interpolate_version() when #{version}: 1.2.3,1000 => 1.2.3,1000" {
  run interpolate_version '#{version}' '1.2.3,1000'
  [ "${output}" == '1.2.3,1000' ]
}

@test "interpolate_version() when #{version.major}: 1.2.3,1000 => 1" {
  run interpolate_version '#{version.major}' '1.2.3,1000'
  [ "${output}" == '1' ]
}

@test "interpolate_version() when #{version.minor}: 1.2.3,1000 => 2" {
  run interpolate_version '#{version.minor}' '1.2.3,1000'
  [ "${output}" == '2' ]
}

@test "interpolate_version() when #{version.patch}: 1.2.3,1000 => 3" {
  run interpolate_version '#{version.patch}' '1.2.3,1000'
  [ "${output}" == '3' ]
}

@test "interpolate_version() when #{version.major_minor}: 1.2.3,1000 => 1.2" {
  run interpolate_version '#{version.major_minor}' '1.2.3,1000'
  [ "${output}" == '1.2' ]
}

@test "interpolate_version() when #{version.major_minor_patch}: 1.2.3,1000 => 1.2.3" {
  run interpolate_version '#{version.major_minor_patch}' '1.2.3,1000'
  [ "${output}" == '1.2.3' ]
}

@test "interpolate_version() when #{version.before_comma}: 1.2.3,1000 => 1.2.3" {
  run interpolate_version '#{version.before_comma}' '1.2.3,1000'
  [ "${output}" == '1.2.3' ]
}

@test "interpolate_version() when #{version.after_comma}: 1.2.3,1000 => 1000" {
  run interpolate_version '#{version.after_comma}' '1.2.3,1000'
  [ "${output}" == '1000' ]
}

@test "interpolate_version() when #{version.before_colon: 1.2.3:1000 => 1.2.3" {
  run interpolate_version '#{version.before_colon}' '1.2.3:1000'
  [ "${output}" == '1.2.3' ]
}

@test "interpolate_version() when #{version.after_colon}: 1.2.3:1000 => 1000" {
  run interpolate_version '#{version.after_colon}' '1.2.3:1000'
  [ "${output}" == '1000' ]
}

@test "interpolate_version() when #{version.no_dots}: 1.2.3:1000 => 123:1000" {
  run interpolate_version '#{version.no_dots}' '1.2.3:1000'
  [ "${output}" == '123:1000' ]
}

@test "interpolate_version() when #{version.dots_to_underscores}: 1.2.3:1000 => 1_2_3:1000" {
  run interpolate_version '#{version.dots_to_underscores}' '1.2.3:1000'
  [ "${output}" == '1_2_3:1000' ]
}

@test "interpolate_version() when Ruby #{version.sub(%r{.*-}, '')}: 1.2.3-1000 => 1000" {
  run interpolate_version "#{version.sub(%r{.*-}, '')}" '1.2.3-1000'
  [ "${output}" == '1000' ]
}

@test "interpolate_version() when Ruby #{version.gsub(':', '_')}: 1.2.3:1000 => 1.2.3_1000" {
  run interpolate_version "#{version.gsub(':', '_')}" '1.2.3:1000'
  [ "${output}" == '1.2.3_1000' ]
}

@test "interpolate_version() when Ruby #{version.delete('.')}: 1.2.3:1000 => 123:1000" {
  run interpolate_version "#{version.delete('.')}" '1.2.3:1000'
  [ "${output}" == '123:1000' ]
}

@test "interpolate_version() when Ruby #{version.to_i}: 1.2.3:1000 => 1" {
  run interpolate_version "#{version.to_i}" '1.2.3:1000'
  [ "${output}" == '1' ]
}

@test "interpolate_version() when Ruby #{version.to_f}: 1.2.3:1000 => 1.2" {
  run interpolate_version "#{version.to_f}" '1.2.3:1000'
  [ "${output}" == '1.2' ]
}

@test "interpolate_version() when multiple versions in string: #{version.gsub(',', '_')} #{version.minor} #{version.patch} (1.2.3,1000:200) => 1.2.3_1000:200 2 3" {
  run interpolate_version "#{version.gsub(',', '_')} #{version.minor} #{version.patch}" '1.2.3,1000:200'
  [ "${output}" == '1.2.3_1000:200 2 3' ]
}

@test "interpolate_version() when chained: #{version.before_colon.before_comma.gsub('.', '_')} (1.2.3,1000:200) => 1_2_3" {
  run interpolate_version "#{version.before_colon.before_comma.gsub('.', '_')}" '1.2.3,1000:200'
  [ "${output}" == '1_2_3' ]
}

@test "interpolate_version() when chained and another name is used: #{build.before_comma.gsub('.', '_')} (1.2.3,1000:200) => 1_2_3" {
  run interpolate_version "#{build.before_comma.gsub('.', '_')}" '1.2.3,1000:200' 'build'
  [ "${output}" == '1_2_3' ]
}

@test "interpolate_version() when chained and another name is used but not passed as argument: #{build.before_comma.gsub('.', '_')} (1.2.3,1000:200) => #{build.before_comma.gsub('.', '_')}" {
  run interpolate_version "#{build.before_comma.gsub('.', '_')}" '1.2.3,1000:200'
  echo "${output}"
  [ "${output}" == "#{build.before_comma.gsub('.', '_')}" ]
}

@test "interpolate_version() in url stanza(s) for cask (acorn.rb)" {
  local -a urls

  readonly urls=(
    https://secure.flyingmeat.com/download/Acorn.zip
  )

  run interpolate_cask_version_to_stanza 'acorn' 'url'
  for ((i = 0; i < ${#urls[@]}; i++)); do
    [ "${lines[i]}" == "${urls[i]}" ]
  done
}

@test "interpolate_version() in url stanza(s) for cask (adobe-bloodhound.rb)" {
  local -a urls

  readonly urls=(
    https://github.com/Adobe-Marketing-Cloud/mobile-services/releases/download/Bloodhound-v3.1.1-OSX/Bloodhound-3.1.1-OSX.dmg
  )

  run interpolate_cask_version_to_stanza 'adobe-bloodhound' 'url'
  for ((i = 0; i < ${#urls[@]}; i++)); do
    echo -e "${lines[i]}\n${urls[i]}\n"
    [ "${lines[i]}" == "${urls[i]}" ]
  done
}

@test "interpolate_version() in url stanza(s) for cask (amethyst.rb)" {
  local -a urls

  readonly urls=(
    https://ianyh.com/amethyst/versions/Amethyst-0.9.10.zip
    https://ianyh.com/amethyst/versions/Amethyst-0.10.1.zip
  )

  run interpolate_cask_version_to_stanza 'amethyst' 'url'
  for ((i = 0; i < ${#urls[@]}; i++)); do
    [ "${lines[i]}" == "${urls[i]}" ]
  done
}

@test "interpolate_version() in url stanza(s) for cask (bettertouchtool.rb)" {
  local -a urls

  readonly urls=(
    https://bettertouchtool.net/btt0.939.zip
    https://boastr.net/releases/btt1.69.zip
  )

  run interpolate_cask_version_to_stanza 'bettertouchtool' 'url'
  for ((i = 0; i < ${#urls[@]}; i++)); do
    [ "${lines[i]}" == "${urls[i]}" ]
  done
}

@test "interpolate_version() in url stanza(s) for cask (clamxav.rb)" {
  local -a urls

  readonly urls=(
    https://www.clamxav.com/downloads/ClamXav_2.2.1.dmg
    https://www.clamxav.com/downloads/ClamXav_2.5.1.dmg
    https://www.clamxav.com/downloads/ClamXav_2.8.9.3.dmg
  )

  run interpolate_cask_version_to_stanza 'clamxav' 'url'
  for ((i = 0; i < ${#urls[@]}; i++)); do
    [ "${lines[i]}" == "${urls[i]}" ]
  done
}

@test "interpolate_version() in url stanza(s) for cask (cocktail.rb)" {
  local -a urls

  readonly urls=(
    http://www.maintain.se/downloads/sparkle/snowleopard/Cocktail_5.1.zip
    http://www.maintain.se/downloads/sparkle/lion/Cocktail_5.6.zip
    http://www.maintain.se/downloads/sparkle/mountainlion/Cocktail_6.9.zip
    http://www.maintain.se/downloads/sparkle/mavericks/Cocktail_7.9.1.zip
    http://www.maintain.se/downloads/sparkle/yosemite/Cocktail_8.8.1.zip
    http://www.maintain.se/downloads/sparkle/elcapitan/Cocktail_9.2.4.zip
  )

  run interpolate_cask_version_to_stanza 'cocktail' 'url'
  for ((i = 0; i < ${#urls[@]}; i++)); do
    [ "${lines[i]}" == "${urls[i]}" ]
  done
}

@test "interpolate_version() in url stanza(s) for cask (codekit.rb)" {
  local -a urls

  readonly urls=(
    https://incident57.com/codekit/files/codekit-19127.zip
  )

  run interpolate_cask_version_to_stanza 'codekit' 'url'
  for ((i = 0; i < ${#urls[@]}; i++)); do
    [ "${lines[i]}" == "${urls[i]}" ]
  done
}

@test "interpolate_version() in url stanza(s) for cask (daemon-tools-lite.rb)" {
  local -a urls

  readonly urls=(
    http://web-search-home.com/download/dtLiteMac
  )

  run interpolate_cask_version_to_stanza 'daemon-tools-lite' 'url'
  for ((i = 0; i < ${#urls[@]}; i++)); do
    [ "${lines[i]}" == "${urls[i]}" ]
  done
}

@test "interpolate_version() in url stanza(s) for cask (evernote.rb)" {
  local -a urls

  readonly urls=(
    https://cdn1.evernote.com/mac/release/Evernote_402634.dmg
    https://cdn1.evernote.com/mac-smd/public/Evernote_RELEASE_6.6.1_453372.dmg
  )

  run interpolate_cask_version_to_stanza 'evernote' 'url'
  for ((i = 0; i < ${#urls[@]}; i++)); do
    [ "${lines[i]}" == "${urls[i]}" ]
  done
}

@test "interpolate_version() in url stanza(s) for cask (framer.rb)" {
  local -a urls

  readonly urls=(
    https://dl.devmate.com/com.motif.framer/FramerStudio.zip
  )

  run interpolate_cask_version_to_stanza 'framer' 'url'
  for ((i = 0; i < ${#urls[@]}; i++)); do
    [ "${lines[i]}" == "${urls[i]}" ]
  done
}

@test "interpolate_version() in url stanza(s) for cask (praat.rb)" {
  local -a urls

  readonly urls=(
    http://www.fon.hum.uva.nl/praat/praat6016_mac32.dmg
    http://www.fon.hum.uva.nl/praat/praat6016_mac64.dmg
  )

  run interpolate_cask_version_to_stanza 'praat' 'url'
  for ((i = 0; i < ${#urls[@]}; i++)); do
    [ "${lines[i]}" == "${urls[i]}" ]
  done
}

@test "interpolate_version() in url stanza(s) for cask (world-of-tanks.rb)" {
  local -a urls

  readonly urls=(
    http://redirect.wargaming.net/WoT/latest_mac_install_na
  )

  run interpolate_cask_version_to_stanza 'world-of-tanks' 'url'
  for ((i = 0; i < ${#urls[@]}; i++)); do
    [ "${lines[i]}" == "${urls[i]}" ]
  done
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

@test "get_xml_config_custom_rule() with interpolated version (1.2.3-release) and build (1000): v#{version.gsub(/-release$/, '')}-#{build} => v1.2.3-1000" {
  readonly CONFIG_FILE_XML="${BATS_TEST_DIRNAME}/config/cask-check-updates.xml"
  run get_xml_config_custom_rule 'example'
  [ "${status}" -eq 0 ]
  [ "${output}" == "v#{version.gsub(/-release$/, '')}-#{build}" ]
  run interpolate_version "${output}" '1.2.3-release'
  run interpolate_version "${output}" '1000' 'build'
  echo "${output}"
  [ "${output}" == 'v1.2.3-1000' ]
}
