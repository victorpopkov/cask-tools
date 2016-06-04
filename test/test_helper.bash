#!/usr/bin/env bash
export TEST_HBC_PATH="${BATS_TMPDIR}/homebrew-cask"
export TEST_HBC_CASKS="${TEST_HBC_PATH}/Casks"
readonly INITIAL_PATH="${PATH}"

setup() {
  setup_test_hbc
  export PATH="${BATS_TEST_DIRNAME}/../bin:${INITIAL_PATH}"
  cd "${TEST_HBC_CASKS}" || exit
}

teardown() {
  delete_test_hbc
  export PATH="${INITIAL_PATH}"
  export HOME="${INITIAL_HOME}"
}

delete_test_hbc() {
  if [[ -d "${TEST_HBC_PATH}" ]]; then rm -rf "${TEST_HBC_PATH}"
  else true; fi
}

setup_test_hbc() {
  delete_test_hbc
  mkdir -p "${TEST_HBC_PATH}"
  cp -rf "${BATS_TEST_DIRNAME}/casks" "${TEST_HBC_CASKS}"
}
