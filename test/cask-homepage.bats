#!/usr/bin/env bats
load test_helper

@test "cask-homepage -v prints version" {
  run cask-homepage -v
  [ "${status}" -eq 0 ]
  [[ "${lines[0]}" =~ ^[0-9]*\.[0-9]*\.[0-9]*$ ]]
}
