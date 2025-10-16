#!/usr/bin/env bats
# Integration tests for CLI commands
# Tests pulse list, update, and doctor commands (US2)

load ../test_helper

setup() {
  # Create temporary test directory
  TEST_TMPDIR="$(mktemp -d)"
  export HOME="${TEST_TMPDIR}"
  export PULSE_DIR="${TEST_TMPDIR}/.local/share/pulse"
  export PULSE_CACHE_DIR="${TEST_TMPDIR}/.cache/pulse"
  export PULSE_LOCK_FILE="${PULSE_DIR}/plugins.lock"
  mkdir -p "${PULSE_DIR}/plugins"
  mkdir -p "${PULSE_CACHE_DIR}"

  # Use mock plugins from fixtures
  export MOCK_PLUGINS_DIR="${PULSE_ROOT}/tests/fixtures/mock-plugins"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

# Test: pulse list shows installed plugins in table format
@test "pulse list shows installed plugins in table format" {
  # Setup: Install 3 plugins and create lock file
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'

    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh

    # Initialize and install plugins
    _pulse_init_engine

    plugins=(
      '${MOCK_PLUGINS_DIR}/plugin-a'
      '${MOCK_PLUGINS_DIR}/plugin-b'
      '${MOCK_PLUGINS_DIR}/plugin-c'
    )

    _pulse_discover_plugins
  "

  [ "$status" -eq 0 ]

    # Now run pulse list command with environment variables
  run env PULSE_DIR="${PULSE_DIR}" PULSE_LOCK_FILE="${PULSE_LOCK_FILE}" ${PULSE_ROOT}/bin/pulse list

  [ "$status" -eq 0 ]
  [[ "$output" =~ "PLUGIN" ]]  # Table header
  [[ "$output" =~ "VERSION" ]] # Table header
  [[ "$output" =~ "COMMIT" ]]  # Table header
  [[ "$output" =~ "plugin-a" ]]
  [[ "$output" =~ "plugin-b" ]]
  [[ "$output" =~ "plugin-c" ]]
}

# Test: pulse list with no plugins shows helpful message
@test "pulse list with no plugins shows helpful message" {
  # Clean environment - no plugins installed
  run ${PULSE_ROOT}/bin/pulse list

  [ "$status" -eq 2 ]
  [[ "$output" =~ "No plugins installed" ]]
}
