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
  skip "Integration not yet wired up (T015)"
  
  # Verify no lock file exists initially
  [[ ! -f "$PULSE_LOCK_FILE" ]]

  # Install a plugin with version tag
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export MOCK_PLUGINS_DIR='${MOCK_PLUGINS_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    
    # Source lock file library
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    # Install plugin with version
    plugins=(
      \${MOCK_PLUGINS_DIR}/plugin-a@v1.0
    )
    
    # Simulate plugin loading
    for plugin in \"\${plugins[@]}\"; do
      _pulse_parse_plugin_spec \"\$plugin\"
      _pulse_clone_plugin \"\$plugin_url\" \"\$plugin_name\" \"\$plugin_ref\"
      _pulse_load_plugin \"\$plugin_name\" \"\$plugin_path\" \"\$stage\"
    done
    
    # Check lock file was created
    [[ -f '${PULSE_LOCK_FILE}' ]] && echo 'LOCK_CREATED'
  "

  [ "$status" -eq 0 ]
  [[ "$output" =~ "LOCK_CREATED" ]]
  
  # Verify lock file contains plugin entry
  run zsh -c "
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    pulse_read_lock_entry 'plugin-a'
  "
  
  [ "$status" -eq 0 ]
  # Should return: url ref commit timestamp stage
  [[ "$output" =~ "plugin-a" ]]
}

# Test: Lock file should be updated when plugin version changes
@test "updates lock file on plugin update" {
  skip "Integration not yet wired up (T015)"
  
  # Install plugin initially
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    # Install plugin at v1.0
    _pulse_clone_plugin '${MOCK_PLUGINS_DIR}/plugin-a' 'plugin-a' 'v1.0'
    
    # Get initial commit
    cd '${PULSE_DIR}/plugins/plugin-a'
    git rev-parse HEAD
  "
  [ "$status" -eq 0 ]
  local initial_commit="$output"
  
  # Update plugin to @latest
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    # Update plugin to latest
    cd '${PULSE_DIR}/plugins/plugin-a'
    git checkout main
    git pull
    
    # Get updated commit
    git rev-parse HEAD
  "
  [ "$status" -eq 0 ]
  local updated_commit="$output"
  
  # Verify lock file was updated with new commit
  run zsh -c "
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    pulse_read_lock_entry 'plugin-a' | awk '{print \$3}'
  "
  
  [ "$status" -eq 0 ]
  # Lock file should have the updated commit
  [[ "$output" == "$updated_commit" ]]
}

# Test: Corrupted lock file should be regenerated
@test "regenerates corrupted lock file" {
  skip "Integration not yet wired up (T015)"
  
  # Install plugin first
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    # Install plugin
    _pulse_clone_plugin '${MOCK_PLUGINS_DIR}/plugin-a' 'plugin-a' 'v1.0'
  "
  [ "$status" -eq 0 ]
  
  # Corrupt the lock file
  echo "INVALID CONTENT" > "$PULSE_LOCK_FILE"
  
  # Verify lock file is now invalid
  run zsh -c "
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    pulse_validate_lock_file
  "
  [ "$status" -ne 0 ]
  
  # Re-load plugin engine (should detect corruption and regenerate)
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    # Should regenerate lock file
    # Check if warning was displayed
    echo 'WARNING_CHECK'
  "
  
  [ "$status" -eq 0 ]
  
  # Verify lock file is now valid
  run zsh -c "
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    pulse_validate_lock_file
  "
  [ "$status" -eq 0 ]
}

# Test: Lock file should record exact commit SHA
@test "records exact commit SHA in lock file" {
  skip "Integration not yet wired up (T015)"
  
  # Install plugin
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    # Install plugin
    _pulse_clone_plugin '${MOCK_PLUGINS_DIR}/plugin-a' 'plugin-a' 'v1.0'
    
    # Get actual commit SHA
    cd '${PULSE_DIR}/plugins/plugin-a'
    git rev-parse HEAD
  "
  [ "$status" -eq 0 ]
  local actual_commit="$output"
  
  # Verify lock file contains exact commit
  run zsh -c "
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    pulse_read_lock_entry 'plugin-a' | awk '{print \$3}'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == "$actual_commit" ]]
}

# Test: Lock file should record plugin stage
@test "records plugin stage in lock file" {
  skip "Integration not yet wired up (T015)"
  
  # Install plugin with early stage
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    # Install plugin (stage detected automatically)
    _pulse_clone_plugin '${MOCK_PLUGINS_DIR}/plugin-a' 'plugin-a' 'v1.0'
  "
  [ "$status" -eq 0 ]
  
  # Verify lock file contains stage
  run zsh -c "
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    pulse_read_lock_entry 'plugin-a' | awk '{print \$5}'
  "
  
  [ "$status" -eq 0 ]
  # Should be one of: early, path, fpath, completions, defer
  [[ "$output" =~ ^(early|path|fpath|completions|defer)$ ]]
}
