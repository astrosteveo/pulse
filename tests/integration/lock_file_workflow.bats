#!/usr/bin/env bats
# Integration tests for lock file automatic generation
# Tests that lock file is created/updated during plugin operations (US3)

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

# Test: Lock file should be generated on plugin installation
@test "generates lock file on plugin installation" {
  # Verify no lock file exists initially
  [[ ! -f "$PULSE_LOCK_FILE" ]]

  # Use plugin engine to discover and register a plugin
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    export PULSE_DEBUG=1

    # Source plugin engine (which sources lock-file.zsh)
    source ${PULSE_ROOT}/lib/plugin-engine.zsh

    # Initialize engine
    _pulse_init_engine

    # Define plugins array (using local path to mock plugin)
    plugins=(
      '${MOCK_PLUGINS_DIR}/plugin-a'
    )

    # Discover plugins (this should trigger lock file creation if plugin has .git)
    _pulse_discover_plugins

    # Check if lock file was created
    [[ -f '${PULSE_LOCK_FILE}' ]] && echo 'LOCK_CREATED'
  "

  [ "$status" -eq 0 ]
  [[ "$output" =~ "LOCK_CREATED" ]]

  # Verify lock file is valid
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    pulse_validate_lock_file
  "
  
  [ "$status" -eq 0 ]
}

# Test: Lock file should be updated when plugin is reinstalled
@test "updates lock file when plugin is reinstalled" {
  # Install plugin initially
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'

    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine

    plugins=('${MOCK_PLUGINS_DIR}/plugin-a')
    _pulse_discover_plugins
  "
  [ "$status" -eq 0 ]

  # Get initial lock entry
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    pulse_read_lock_entry 'plugin-a'
  "
  [ "$status" -eq 0 ]
  local initial_entry="$output"

  # Manually modify the lock file (simulate outdated entry)
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh

    # Remove existing entry
    pulse_remove_lock_entry 'plugin-a'

    # Write an outdated entry with a fake commit
    pulse_write_lock_entry 'plugin-a' 'fake-url' '' 'outdated123' '2020-01-01T00:00:00Z' 'normal'
  "
  [ "$status" -eq 0 ]

  # Re-discover plugins (should update lock file)
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'

    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine

    plugins=('${MOCK_PLUGINS_DIR}/plugin-a')
    _pulse_discover_plugins
  "
  [ "$status" -eq 0 ]

  # Verify lock file was updated with real commit (not "outdated123")
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    pulse_read_lock_entry 'plugin-a' | awk '{print \$3}'
  "

  [ "$status" -eq 0 ]
  [[ "$output" != "outdated123" ]]
  [[ "$output" =~ ^[0-9a-f]{40}$ ]]  # Should be a valid 40-char SHA
}

# Test: Corrupted lock file should be regenerated
@test "regenerates corrupted lock file" {
  # First install a plugin to create a valid lock file
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'

    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine

    plugins=('${MOCK_PLUGINS_DIR}/plugin-a')
    _pulse_discover_plugins
  "
  [ "$status" -eq 0 ]

  # Verify valid lock file exists
  [[ -f "$PULSE_LOCK_FILE" ]]

  # Corrupt the lock file
  echo "INVALID CONTENT" > "$PULSE_LOCK_FILE"

  # Verify lock file is now invalid
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    pulse_validate_lock_file
  "
  [ "$status" -ne 0 ]

  # Re-initialize engine (should detect corruption and regenerate)
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    export PULSE_DEBUG=1

    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
  "

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Lock file invalid, regenerating" ]]

  # Verify lock file is now valid
  run zsh -c "
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    pulse_validate_lock_file
  "
  [ "$status" -eq 0 ]
}

# Test: Lock file should record exact commit SHA
@test "records exact commit SHA in lock file" {
  # Get expected commit SHA from mock plugin
  local expected_commit=$(git -C "${MOCK_PLUGINS_DIR}/plugin-a" rev-parse HEAD)

  # Use plugin engine to install plugin
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'

    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine

    plugins=('${MOCK_PLUGINS_DIR}/plugin-a')
    _pulse_discover_plugins
  "
  [ "$status" -eq 0 ]

  # Verify lock file contains exact commit SHA
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    pulse_read_lock_entry 'plugin-a' | awk '{print \$3}'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == "$expected_commit" ]]
}

# Test: Lock file should record plugin stage
@test "records plugin stage in lock file" {
  # Use plugin engine to install plugin (stage detected automatically)
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'

    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine

    plugins=('${MOCK_PLUGINS_DIR}/plugin-a')
    _pulse_discover_plugins
  "
  [ "$status" -eq 0 ]

  # Verify lock file contains a valid stage
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    pulse_read_lock_entry 'plugin-a' | awk '{print \$5}'
  "
  
  [ "$status" -eq 0 ]
  # Should be one of the valid stages
  [[ "$output" =~ ^(early|normal|late|deferred)$ ]]
}