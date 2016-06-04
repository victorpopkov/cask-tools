#!/usr/bin/env bats
load test_helper

@test "cask-check-updates -v prints version" {
  run cask-check-updates -v
  [ "${status}" -eq 0 ]
  [[ "${lines[0]}" =~ ^[0-9]*\.[0-9]*\.[0-9]*$ ]]
}
