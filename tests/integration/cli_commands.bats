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

# ============================================================================
# pulse update command tests (T019)
# ============================================================================

# Test: pulse update updates all outdated plugins
@test "pulse update updates all outdated plugins" {
  skip "T019 - RED phase: pulse update not yet implemented"
  
  # Setup: 2 plugins installed, 1 outdated
  # Create mock git repos with different commits
  local plugin_a_dir="${PULSE_DIR}/plugins/plugin-a"
  local plugin_b_dir="${PULSE_DIR}/plugins/plugin-b"
  
  # Install plugins via plugin engine
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    plugins=('${MOCK_PLUGINS_DIR}/plugin-a' '${MOCK_PLUGINS_DIR}/plugin-b')
    _pulse_discover_plugins
  "
  
  # Simulate outdated plugin by changing lock file commit
  # (plugin-a will be "outdated")
  
  # Run update
  run ${PULSE_ROOT}/bin/pulse update
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "plugin-a" ]]     # Updated plugin mentioned
  [[ "$output" =~ "updated" ]]       # Success message
  [[ ! "$output" =~ "plugin-b" ]]    # Up-to-date plugin not mentioned
}

# Test: pulse update <plugin> updates only specified plugin
@test "pulse update <plugin> updates only specified plugin" {
  skip "T019 - RED phase: pulse update with plugin arg not yet implemented"
  
  # Setup: 2 plugins installed, both outdated
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    plugins=('${MOCK_PLUGINS_DIR}/plugin-a' '${MOCK_PLUGINS_DIR}/plugin-b')
    _pulse_discover_plugins
  "
  
  # Simulate both plugins being outdated
  
  # Update only plugin-a
  run ${PULSE_ROOT}/bin/pulse update plugin-a
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "plugin-a" ]]
  [[ "$output" =~ "updated" ]]
  [[ ! "$output" =~ "plugin-b" ]]
}

# Test: pulse update skips plugin with local changes
@test "pulse update skips plugin with local changes" {
  skip "T019 - RED phase: pulse update local changes detection not yet implemented"
  
  # Setup: Plugin with uncommitted changes
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    plugins=('${MOCK_PLUGINS_DIR}/plugin-a')
    _pulse_discover_plugins
  "
  
  # Create uncommitted change in plugin-a
  echo "# modified" >> "${PULSE_DIR}/plugins/plugin-a/README.md"
  
  # Run update
  run ${PULSE_ROOT}/bin/pulse update
  
  [ "$status" -eq 0 ]  # Success even though skipped
  [[ "$output" =~ "plugin-a" ]]
  [[ "$output" =~ "skipped" ]] || [[ "$output" =~ "local changes" ]]
}

# Test: pulse update --force updates plugin with local changes
@test "pulse update --force updates plugin with local changes" {
  skip "T019 - RED phase: pulse update --force not yet implemented"
  
  # Setup: Plugin with uncommitted changes
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    plugins=('${MOCK_PLUGINS_DIR}/plugin-a')
    _pulse_discover_plugins
  "
  
  # Create uncommitted change
  echo "# modified" >> "${PULSE_DIR}/plugins/plugin-a/README.md"
  
  # Run update with --force
  run ${PULSE_ROOT}/bin/pulse update --force
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "plugin-a" ]]
  [[ "$output" =~ "updated" ]] || [[ "$output" =~ "forced" ]]
}

