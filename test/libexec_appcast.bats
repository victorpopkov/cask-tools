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
  [ "${output}" == 'e5e904ede055143aed47a9c416234f5deaba2a34eb818e596bf9103ec778f9fa' ]
}

@test "generate_appcast_checkpoint(): sparkle_default.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_default.xml')"
  [ "${output}" == '1a591f1ac72a35c7975e6ab2655c6d1133d37d6e391d71186cbdb3f0dd8eb5bc' ]
}

@test "generate_appcast_checkpoint(): sparkle_default_asc.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_default_asc.xml')"
  [ "${output}" == '23fa71264825eab29a9b90a5ca97ef4c0af7e8d84c5c7838526e6d7fe1ddf954' ]
}

@test "generate_appcast_checkpoint(): sparkle_attributes_as_elements.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_attributes_as_elements.xml')"
  [ "${output}" == '7c88c7f11aba3c14edf352546193823c27b27b7d415f7b75a11ef3d014333177' ]
}

@test "generate_appcast_checkpoint(): sparkle_multiple_enclosure.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_multiple_enclosure.xml')"
  [ "${output}" == 'f38a42eecf0efec53f30f628700218b0d3478c88c268a4606ada91c61fc0317a' ]
}

@test "generate_appcast_checkpoint(): sparkle_incorrect_namespace.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_incorrect_namespace.xml')"
  [ "${output}" == '13b5a5220765dcf37052c4aacf837e5e4525cfbb0870b798e8aa2ce06e179057' ]
}

@test "generate_appcast_checkpoint(): sparkle_without_namespaces.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_without_namespaces.xml')"
  [ "${output}" == 'bf5229e9d0f3b476438705d370689fc3c7ce609ea814f3361f5a0e539b644bf3' ]
}

@test "generate_appcast_checkpoint(): sparkle_no_releases.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'sparkle_no_releases.xml')"
  [ "${output}" == '4fcd8a16f930604696785a189ae4028670a29f000564493c69b49e10fbee222b' ]
}

@test "generate_appcast_checkpoint(): unknown.xml" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run generate_appcast_checkpoint "$(cat 'unknown.xml')"
  [ "${output}" == 'd1ec5c6b7701e7aa859eb0e6b154f12ad0beed6755bdcea2f2f6afd711e35b62' ]
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
  [ "${lines[0]}" == '<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sparkle="https://example.com/xml-namespaces/sparkle" version="2.0">' ]
  run fix_sparkle_xmlns "$(cat 'sparkle_incorrect_namespace.xml')"
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == '<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">' ]
}

@test "fix_sparkle_xmlns() when Sparkle namespaces are not specified (sparkle_without_namespaces.xml)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run cat 'sparkle_without_namespaces.xml'
  [ "${lines[0]}" == '<rss version="2.0">' ]
  run fix_sparkle_xmlns "$(cat 'sparkle_without_namespaces.xml')"
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == '<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">' ]
}

# format_xml()
@test "format_xml() when no arguments passed" {
  run format_xml
  [ "${status}" -eq 1 ]
}

@test "format_xml() should uncomment tags (sparkle_default.xml)" {
  cd "${BATS_TEST_DIRNAME}/appcasts"
  run cat 'sparkle_default.xml'
  [ "${lines[11]}" == '            <!--<enclosure sparkle:version="200" sparkle:shortVersionString="2.0.0" url="https://example.com/app_2.0.0.dmg" length="100000" type="application/octet-stream"/>-->' ]
  [ "${lines[18]}" == '            <!-- <enclosure sparkle:version="110" sparkle:shortVersionString="1.1.0" url="https://example.com/app_1.1.0.dmg" length="100000" type="application/octet-stream"/> -->' ]
  run format_xml "$(cat 'sparkle_default.xml')"
  [ "${lines[11]}" == '            <enclosure sparkle:version="200" sparkle:shortVersionString="2.0.0" url="https://example.com/app_2.0.0.dmg" length="100000" type="application/octet-stream"/>' ]
  [ "${lines[18]}" == '            <enclosure sparkle:version="110" sparkle:shortVersionString="1.1.0" url="https://example.com/app_1.1.0.dmg" length="100000" type="application/octet-stream"/>' ]
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
