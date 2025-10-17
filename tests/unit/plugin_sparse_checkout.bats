#!/usr/bin/env bats
# Tests for sparse checkout behavior of framework plugins

load ../test_helper

@test "omz plugin sparse checkout installs dependencies" {
  export PULSE_OMZ_REPO="${PULSE_ROOT}/tests/fixtures/mock-plugins/ohmyzsh"
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  plugins=("omz:plugins/git")
  _pulse_init_engine
  _pulse_discover_plugins

  assert_directory_exists "${PULSE_DIR}/plugins/ohmyzsh/plugins/git"
  [ ! -d "${PULSE_DIR}/plugins/ohmyzsh/plugins/extra" ]
  assert_file_exists "${PULSE_DIR}/plugins/ohmyzsh/lib/git.zsh"
  [ ! -f "${PULSE_DIR}/plugins/ohmyzsh/lib/unused.zsh" ]

  run git -C "${PULSE_DIR}/plugins/ohmyzsh" sparse-checkout list
  assert_success
  [[ "$output" == *"plugins/git"* ]]
  [[ "$output" == *"lib/git.zsh"* ]]

  _pulse_discover_plugins
  run git -C "${PULSE_DIR}/plugins/ohmyzsh" sparse-checkout list
  assert_success
  [[ "$output" == *"plugins/git"* ]]
  [[ "$output" == *"lib/git.zsh"* ]]
}

@test "prezto module sparse checkout installs dependencies" {
  export PULSE_PREZTO_REPO="${PULSE_ROOT}/tests/fixtures/mock-plugins/prezto"
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  plugins=("prezto:modules/git")
  _pulse_init_engine
  _pulse_discover_plugins

  assert_directory_exists "${PULSE_DIR}/plugins/prezto/modules/git"
  [ ! -d "${PULSE_DIR}/plugins/prezto/modules/prompt" ]
  assert_file_exists "${PULSE_DIR}/plugins/prezto/modules/environment/init.zsh"
  [ ! -f "${PULSE_DIR}/plugins/prezto/modules/environment/unused.zsh" ]

  run git -C "${PULSE_DIR}/plugins/prezto" sparse-checkout list
  assert_success
  [[ "$output" == *"modules/git"* ]]
  [[ "$output" == *"modules/environment/init.zsh"* ]]

  _pulse_discover_plugins
  run git -C "${PULSE_DIR}/plugins/prezto" sparse-checkout list
  assert_success
  [[ "$output" == *"modules/git"* ]]
  [[ "$output" == *"modules/environment/init.zsh"* ]]
}
