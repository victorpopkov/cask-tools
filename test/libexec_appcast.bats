#!/usr/bin/env bats
load test_helper
load ../libexec/cask-scripts/general
load ../libexec/cask-scripts/appcast
load ../libexec/cask-scripts/cask

# generate_appcast_checkpoint()
@test "generate_appcast_checkpoint() when no arguments passed" {
  run generate_appcast_checkpoint
  [ "${status}" -eq 1 ]
}

@test "generate_appcast_checkpoint(): github_default.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'github_default.xml')"
  [ "${output}" == '1e92c6187485bdafa39716f824ddf8c1233e776fd23f9a0d42032bedc92edfb8' ]
}

@test "generate_appcast_checkpoint(): sparkle_default.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_default.xml')"
  [ "${output}" == '583743f5e8662cb223baa5e718224fa11317b0983dbf8b3c9c8d412600b6936c' ]
}

@test "generate_appcast_checkpoint(): sparkle_default_asc.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_default_asc.xml')"
  [ "${output}" == '8ad0cd8d67f12ed75fdfbf74e904ef8b82084875c959bec00abd5a166c512b5d' ]
}

@test "generate_appcast_checkpoint(): sparkle_attributes_as_elements.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_attributes_as_elements.xml')"
  [ "${output}" == '06a16fc0d5c7f8e18ca04dbc52138159b5438cdb929e033dae6ddebca7e710fc' ]
}

@test "generate_appcast_checkpoint(): sparkle_multiple_enclosure.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_multiple_enclosure.xml')"
  [ "${output}" == '6ba0ab0e37d4280803ff2f197aaf362a3553849fb296a64bc946eda1bdb759c7' ]
}

@test "generate_appcast_checkpoint(): sparkle_incorrect_namespace.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_incorrect_namespace.xml')"
  [ "${output}" == 'f7ced8023765dc7f37c3597da7a1f8d33b3c22cc764e329babd3df16effdd245' ]
}

@test "generate_appcast_checkpoint(): sparkle_without_namespaces.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_without_namespaces.xml')"
  [ "${output}" == 'd4cdd55c6dbf944d03c5267f3f7be4a9f7c2f1b94929359ce7e21aeef3b0747b' ]
}

@test "generate_appcast_checkpoint(): sparkle_no_releases.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_no_releases.xml')"
  [ "${output}" == '65911706576dab873c2b30b2d6505581d17f8e2c763da7320cfb06bbc2d4eaca' ]
}

@test "generate_appcast_checkpoint(): unknown.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'unknown.xml')"
  [ "${output}" == 'cfed64a67417a29011b607e6194a2e06e447ceee681d2b5c0daee77a8bdac673' ]
}

# get_appcast_provider()
@test "get_appcast_provider() when no arguments passed" {
  run get_appcast_provider
  [ "${status}" -eq 1 ]
}

@test "get_appcast_provider() when using the most common layout (github_default.xml) => GitHub Atom" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_appcast_provider "$(cat 'github_default.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'GitHub Atom' ]
}

@test "get_appcast_provider() when using the most common layout (sparkle_default.xml) => Sparkle" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_appcast_provider "$(cat 'sparkle_default.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'Sparkle' ]
}

@test "get_appcast_provider() when version releases are sorted by ascending (sparkle_default_asc.xml) => Sparkle" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_appcast_provider "$(cat 'sparkle_default_asc.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'Sparkle' ]
}

@test "get_appcast_provider() when versions are specified in tags instead of attributes (sparkle_attributes_as_elements.xml) => Sparkle" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_appcast_provider "$(cat 'sparkle_attributes_as_elements.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'Sparkle' ]
}

@test "get_appcast_provider() when multiple enclosure tags (sparkle_multiple_enclosure.xml) => Sparkle" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_appcast_provider "$(cat 'sparkle_multiple_enclosure.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'Sparkle' ]
}

@test "get_appcast_provider() when Sparkle namespace is incorrect (sparkle_incorrect_namespace.xml) => Sparkle" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_appcast_provider "$(cat 'sparkle_incorrect_namespace.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'Sparkle' ]
}

@test "get_appcast_provider() when Sparkle namespaces are not specified (sparkle_without_namespaces.xml) => Sparkle" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_appcast_provider "$(cat 'sparkle_without_namespaces.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'Sparkle' ]
}

@test "get_appcast_provider() when no releases (sparkle_no_releases.xml) => Sparkle" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_appcast_provider "$(cat 'sparkle_no_releases.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == 'Sparkle' ]
}

@test "get_appcast_provider() when unknown provider (unknown.xml) => unknown" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_appcast_provider "$(cat 'unknown.xml')"
  [ "${status}" -eq 1 ]
  [ "${output}" == '' ]
}

# fix_sparkle_xmlns()
@test "fix_sparkle_xmlns() when no arguments passed" {
  run fix_sparkle_xmlns
  [ "${status}" -eq 1 ]
}

@test "fix_sparkle_xmlns() when Sparkle namespace is incorrect (sparkle_incorrect_namespace.xml)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run cat 'sparkle_incorrect_namespace.xml'
  [ "${lines[1]}" == '<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sparkle="https://example.com/xml-namespaces/sparkle" version="2.0">' ]
  run fix_sparkle_xmlns "$(cat 'sparkle_incorrect_namespace.xml')"
  [ "${status}" -eq 0 ]
  [ "${lines[1]}" == '<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">' ]
}

@test "fix_sparkle_xmlns() when Sparkle namespaces are not specified (sparkle_without_namespaces.xml)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run cat 'sparkle_without_namespaces.xml'
  [ "${lines[1]}" == '<rss version="2.0">' ]
  run fix_sparkle_xmlns "$(cat 'sparkle_without_namespaces.xml')"
  [ "${status}" -eq 0 ]
  [ "${lines[1]}" == '<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">' ]
}

# format_xml()
@test "format_xml() when no arguments passed" {
  run format_xml
  [ "${status}" -eq 1 ]
}

@test "format_xml() should uncomment tags (sparkle_default.xml)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run cat 'sparkle_default.xml'
  [ "${lines[12]}" == '      <!--<enclosure sparkle:version="200" sparkle:shortVersionString="2.0.0" url="https://example.com/app_2.0.0.dmg" length="100000" type="application/octet-stream"/>-->' ]
  [ "${lines[19]}" == '      <!-- <enclosure sparkle:version="110" sparkle:shortVersionString="1.1.0" url="https://example.com/app_1.1.0.dmg" length="100000" type="application/octet-stream"/> -->' ]
  run format_xml "$(cat 'sparkle_default.xml')"
  echo "${output}"
  [ "${lines[12]}" == '      <enclosure sparkle:version="200" sparkle:shortVersionString="2.0.0" url="https://example.com/app_2.0.0.dmg" length="100000" type="application/octet-stream"/>' ]
  [ "${lines[19]}" == '      <enclosure sparkle:version="110" sparkle:shortVersionString="1.1.0" url="https://example.com/app_1.1.0.dmg" length="100000" type="application/octet-stream"/>' ]
}

# get_sparkle_version_build_url()
@test "get_sparkle_version_build_url() when no arguments passed" {
  run get_sparkle_version_build_url
  [ "${status}" -eq 1 ]
}

@test "get_sparkle_version_build_url() when version, build, download URL and title" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_sparkle_version_build_url '"2.0.0";"200";"https://example.com/app_2.0.0.dmg";"Release 2.0.0"'
  [ "${status}" -eq 0 ]
  [ "${output}" == '2.0.0 200 https://example.com/app_2.0.0.dmg' ]
}

@test "get_sparkle_version_build_url() when version, build, download URL, title (version and build are the same values)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_sparkle_version_build_url '"2.0.0";"2.0.0";"https://example.com/app_2.0.0.dmg";"Release 2.0.0"'
  [ "${status}" -eq 0 ]
  [ "${output}" == '2.0.0 https://example.com/app_2.0.0.dmg' ]
}

@test "get_sparkle_version_build_url() when only build, download URL and title" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_sparkle_version_build_url '"";"200";"https://example.com/app_2.0.0.dmg";"Release 2.0.0"'
  [ "${status}" -eq 0 ]
  [ "${output}" == '200 https://example.com/app_2.0.0.dmg' ]
}

@test "get_sparkle_version_build_url() when only download URL and title (version is extracted from title)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_sparkle_version_build_url '"";"";"https://example.com/app_2.0.0.dmg";"Release 2.0.0"'
  [ "${status}" -eq 0 ]
  [ "${output}" == '2.0.0 https://example.com/app_2.0.0.dmg' ]
}

@test "get_sparkle_version_build_url() when only version and build" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_sparkle_version_build_url '"2.0.0";"200";"";""'
  [ "${status}" -eq 0 ]
  [ "${output}" == '2.0.0 200' ]
}

# get_sparkle_latest()
@test "get_sparkle_latest() when no arguments passed" {
  run get_sparkle_latest
  [ "${status}" -eq 1 ]
}

@test "get_sparkle_latest() when using the most common layout (sparkle_default.xml)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_sparkle_latest "$(cat 'sparkle_default.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == '2.0.0 200 https://example.com/app_2.0.0.dmg' ]
}

@test "get_sparkle_latest() when version releases are sorted by ascending (sparkle_default_asc.xml)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_sparkle_latest "$(cat 'sparkle_default_asc.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == '2.0.0 200 https://example.com/app_2.0.0.dmg' ]
}

@test "get_sparkle_latest() when versions are specified in tags instead of attributes (sparkle_attributes_as_elements.xml)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_sparkle_latest "$(cat 'sparkle_attributes_as_elements.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == '2.0.0 200 https://example.com/app_2.0.0.dmg' ]
}

@test "get_sparkle_latest() when multiple enclosure tags (sparkle_multiple_enclosure.xml)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_sparkle_latest "$(cat 'sparkle_multiple_enclosure.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == '2.0.0 200 https://example.com/app_2.0.0.tar.gz' ]
}

@test "get_sparkle_latest() when Sparkle namespace is incorrect (sparkle_incorrect_namespace.xml)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_sparkle_latest "$(cat 'sparkle_incorrect_namespace.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == '2.0.0 200 https://example.com/app_2.0.0.dmg' ]
}

@test "get_sparkle_latest() when Sparkle namespaces are not specified (sparkle_without_namespaces.xml)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_sparkle_latest "$(cat 'sparkle_without_namespaces.xml')"
  [ "${status}" -eq 0 ]
  [ "${output}" == '2.0.0 200 https://example.com/app_2.0.0.dmg' ]
}

@test "get_sparkle_latest() when no releases (sparkle_no_releases.xml)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run get_sparkle_latest "$(cat 'sparkle_no_releases.xml')"
  [ "${status}" -eq 1 ]
  [ "${output}" == '' ]
}
