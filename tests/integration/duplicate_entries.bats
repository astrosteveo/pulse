#!/usr/bin/env bats
# Integration test for preventing duplicate lock file entries
# Tests that plugins are not duplicated when framework is sourced multiple times

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

# Test: Lock file should not create duplicate entries when framework is sourced multiple times
@test "no duplicate entries after multiple shell sessions" {
  # First session: Install plugins
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    _pulse_init_engine
    
    plugins=(
      '${MOCK_PLUGINS_DIR}/plugin-a'
      '${MOCK_PLUGINS_DIR}/plugin-b'
    )
    
    _pulse_discover_plugins
  "
  [ "$status" -eq 0 ]

  # Count entries for plugin-a after first session
  local count_first=$(grep -c '^\[plugin-a\]$' "${PULSE_LOCK_FILE}" || echo 0)
  [ "$count_first" -eq 1 ]

  # Second session: Source framework again with same plugins
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    _pulse_init_engine
    
    plugins=(
      '${MOCK_PLUGINS_DIR}/plugin-a'
      '${MOCK_PLUGINS_DIR}/plugin-b'
    )
    
    _pulse_discover_plugins
  "
  [ "$status" -eq 0 ]

  # Count entries for plugin-a after second session - should still be 1
  local count_second=$(grep -c '^\[plugin-a\]$' "${PULSE_LOCK_FILE}" || echo 0)
  [ "$count_second" -eq 1 ]

  # Third session: Source framework again
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    _pulse_init_engine
    
    plugins=(
      '${MOCK_PLUGINS_DIR}/plugin-a'
      '${MOCK_PLUGINS_DIR}/plugin-b'
    )
    
    _pulse_discover_plugins
  "
  [ "$status" -eq 0 ]

  # Count entries for plugin-a after third session - should still be 1
  local count_third=$(grep -c '^\[plugin-a\]$' "${PULSE_LOCK_FILE}" || echo 0)
  [ "$count_third" -eq 1 ]

  # Count entries for plugin-b after third session - should be 1
  local count_b=$(grep -c '^\[plugin-b\]$' "${PULSE_LOCK_FILE}" || echo 0)
  [ "$count_b" -eq 1 ]
}

# Test: pulse list should show each plugin only once after multiple sessions
@test "pulse list shows each plugin once after multiple sessions" {
  # Create lock file with plugins (simulate first session)
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    _pulse_init_engine
    
    plugins=(
      '${MOCK_PLUGINS_DIR}/plugin-a'
    )
    
    _pulse_discover_plugins
  "
  [ "$status" -eq 0 ]

  # Simulate second session
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    _pulse_init_engine
    
    plugins=(
      '${MOCK_PLUGINS_DIR}/plugin-a'
    )
    
    _pulse_discover_plugins
  "
  [ "$status" -eq 0 ]

  # Simulate third session
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    _pulse_init_engine
    
    plugins=(
      '${MOCK_PLUGINS_DIR}/plugin-a'
    )
    
    _pulse_discover_plugins
  "
  [ "$status" -eq 0 ]

  # Run pulse list and count how many times plugin-a appears
  run env PULSE_DIR="${PULSE_DIR}" PULSE_LOCK_FILE="${PULSE_LOCK_FILE}" ${PULSE_ROOT}/bin/pulse list
  
  [ "$status" -eq 0 ]
  
  # Count how many times plugin-a appears in output (should be 1, plus maybe in header)
  local plugin_count=$(echo "$output" | grep -c 'plugin-a' || echo 0)
  
  # Should appear exactly once (not 3 times for 3 sessions)
  [ "$plugin_count" -eq 1 ]
}

# Test: pulse_write_lock_entry should replace existing entry, not append
@test "pulse_write_lock_entry replaces existing entry" {
  # Create initial lock file
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    
    # Write first entry
    pulse_write_lock_entry 'test-plugin' 'https://example.com/test.git' 'main' 'abc123' '2024-01-01T00:00:00Z' 'normal'
  "
  [ "$status" -eq 0 ]

  # Verify one entry exists
  local count_first=$(grep -c '^\[test-plugin\]$' "${PULSE_LOCK_FILE}" || echo 0)
  [ "$count_first" -eq 1 ]

  # Write same plugin again with different commit
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    
    # Write entry with updated commit
    pulse_write_lock_entry 'test-plugin' 'https://example.com/test.git' 'main' 'def456' '2024-01-02T00:00:00Z' 'normal'
  "
  [ "$status" -eq 0 ]

  # Verify still only one entry exists
  local count_second=$(grep -c '^\[test-plugin\]$' "${PULSE_LOCK_FILE}" || echo 0)
  [ "$count_second" -eq 1 ]

  # Verify the commit was updated to the new value
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    
    pulse_read_lock_entry 'test-plugin'
  "
  [ "$status" -eq 0 ]
  [[ "$output" =~ "def456" ]]
  [[ ! "$output" =~ "abc123" ]]
}
