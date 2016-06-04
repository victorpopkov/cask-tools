#!/usr/bin/env bats
load test_helper

@test "cask-appcast with no arguments prints help" {
  run cask-appcast
  [ "${status}" -eq 1 ]
  [ "${lines[0]}" == 'usage: cask-appcast [options] [<appcast_urls>...]' ]
}

@test "cask-appcast -h prints help" {
  run cask-appcast -h
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == 'usage: cask-appcast [options] [<appcast_urls>...]' ]
}

@test "cask-appcast -v prints version" {
  run cask-appcast -v
  [ "${status}" -eq 0 ]
  [[ "${lines[0]}" =~ ^[0-9]*\.[0-9]*\.[0-9]*$ ]]
}
