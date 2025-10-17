#!/usr/bin/env bats
# Unit tests for Oh-My-Zsh and Prezto environment variable setup

load ../test_helper

setup() {
  # Create temporary test directory
  TEST_TMPDIR="$(mktemp -d)"
  export PULSE_DIR="${TEST_TMPDIR}/.local/share/pulse"
  export PULSE_CACHE_DIR="${TEST_TMPDIR}/.cache/pulse"
  mkdir -p "${PULSE_DIR}/plugins"
  mkdir -p "${PULSE_CACHE_DIR}"
  
  # Clear any existing environment variables
  unset ZSH
  unset ZSH_CACHE_DIR
  unset ZPREZTODIR
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

@test "sets ZSH environment variable on init" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  _pulse_init_engine
  
  [[ -n "$ZSH" ]]
  [[ "$ZSH" == "${PULSE_DIR}/plugins/ohmyzsh" ]]
}

@test "sets ZSH_CACHE_DIR environment variable on init" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  _pulse_init_engine
  
  [[ -n "$ZSH_CACHE_DIR" ]]
  [[ "$ZSH_CACHE_DIR" == "${PULSE_CACHE_DIR}/ohmyzsh" ]]
}

@test "sets ZPREZTODIR environment variable on init" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  _pulse_init_engine
  
  [[ -n "$ZPREZTODIR" ]]
  [[ "$ZPREZTODIR" == "${PULSE_DIR}/plugins/prezto" ]]
}

@test "creates ZSH_CACHE_DIR/completions directory on init" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  _pulse_init_engine
  
  [[ -d "$ZSH_CACHE_DIR/completions" ]]
}

@test "respects existing ZSH variable if set" {
  export ZSH="/custom/path/to/ohmyzsh"
  
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  _pulse_init_engine
  
  [[ "$ZSH" == "/custom/path/to/ohmyzsh" ]]
}

@test "respects existing ZSH_CACHE_DIR variable if set" {
  export ZSH_CACHE_DIR="${TEST_TMPDIR}/custom/cache/dir"
  
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  _pulse_init_engine
  
  [[ "$ZSH_CACHE_DIR" == "${TEST_TMPDIR}/custom/cache/dir" ]]
}

@test "respects existing ZPREZTODIR variable if set" {
  export ZPREZTODIR="${TEST_TMPDIR}/custom/path/to/prezto"
  
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  _pulse_init_engine
  
  [[ "$ZPREZTODIR" == "${TEST_TMPDIR}/custom/path/to/prezto" ]]
}

@test "creates cache directory structure even with custom ZSH_CACHE_DIR" {
  export ZSH_CACHE_DIR="${TEST_TMPDIR}/custom/cache/dir"
  
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  _pulse_init_engine
  
  # Should still create the completions directory in the custom location
  [[ -d "${TEST_TMPDIR}/custom/cache/dir/completions" ]]
}
