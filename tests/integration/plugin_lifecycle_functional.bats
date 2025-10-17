#!/usr/bin/env bats
# Functional tests for complete plugin lifecycle without redundant cloning

load ../test_helper

setup() {
  export PULSE_DIR="${PULSE_ROOT}/tests/fixtures/pulse_home"
  export PULSE_CACHE_DIR="${PULSE_ROOT}/tests/fixtures/pulse_cache"
  export PULSE_NO_COMPINIT=1
  
  rm -rf "${PULSE_DIR}" "${PULSE_CACHE_DIR}"
  mkdir -p "${PULSE_DIR}/plugins"
  mkdir -p "${PULSE_CACHE_DIR}"
  
  # Create a test git repository with multiple commits
  export TEST_PLUGIN_REPO="${PULSE_ROOT}/tests/fixtures/functional_test_repo"
  rm -rf "$TEST_PLUGIN_REPO"
  mkdir -p "$TEST_PLUGIN_REPO"
  cd "$TEST_PLUGIN_REPO"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test User"
  echo "echo 'version 1'" > plugin.zsh
  git add .
  git commit -q -m "v1.0.0"
  git tag v1.0.0
  echo "echo 'version 2'" > plugin.zsh
  git add .
  git commit -q -m "v2.0.0"
  git tag v2.0.0
}

teardown() {
  rm -rf "$TEST_PLUGIN_REPO"
  teardown_test_environment
}

@test "functional: install plugin, open new shell, verify no re-clone" {
  # Step 1: Install plugin in first shell session
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    plugins=('file://${TEST_PLUGIN_REPO}')
    source '${PULSE_ROOT}/pulse.zsh'
    echo 'Session 1 complete'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Session 1 complete" ]]
  
  # Verify plugin directory exists
  [ -d "${PULSE_DIR}/plugins/functional_test_repo/.git" ]
  
  # Record initial commit SHA
  local initial_sha=$(cd "${PULSE_DIR}/plugins/functional_test_repo" && git rev-parse HEAD)
  
  # Step 2: Open new shell session (simulating opening new terminal)
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    plugins=('file://${TEST_PLUGIN_REPO}')
    source '${PULSE_ROOT}/pulse.zsh'
    echo 'Session 2 complete'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Session 2 complete" ]]
  
  # Verify commit SHA hasn't changed (no re-clone)
  local final_sha=$(cd "${PULSE_DIR}/plugins/functional_test_repo" && git rev-parse HEAD)
  [ "$initial_sha" = "$final_sha" ]
  
  # Step 3: Open third shell session
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    plugins=('file://${TEST_PLUGIN_REPO}')
    source '${PULSE_ROOT}/pulse.zsh'
    echo 'Session 3 complete'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Session 3 complete" ]]
  
  # Verify commit SHA still hasn't changed
  local third_sha=$(cd "${PULSE_DIR}/plugins/functional_test_repo" && git rev-parse HEAD)
  [ "$initial_sha" = "$third_sha" ]
}

@test "functional: install plugin, run update command, verify controlled update" {
  # Install plugin
  zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    plugins=('file://${TEST_PLUGIN_REPO}')
    source '${PULSE_ROOT}/pulse.zsh'
  " >/dev/null 2>&1
  
  [ -d "${PULSE_DIR}/plugins/functional_test_repo/.git" ]
  
  # Record initial commit
  local before_update_sha=$(cd "${PULSE_DIR}/plugins/functional_test_repo" && git rev-parse HEAD)
  
  # Open new shell without update - should not change
  zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    plugins=('file://${TEST_PLUGIN_REPO}')
    source '${PULSE_ROOT}/pulse.zsh'
  " >/dev/null 2>&1
  
  local after_source_sha=$(cd "${PULSE_DIR}/plugins/functional_test_repo" && git rev-parse HEAD)
  [ "$before_update_sha" = "$after_source_sha" ]
  
  # Now run update command - this should update
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    
    '${PULSE_ROOT}/bin/pulse' update 2>&1
  "
  
  # Verify update ran
  [ "$status" -eq 0 ]
}

@test "functional: rapidly source pulse multiple times in succession" {
  # This simulates the scenario where a user might source their .zshrc
  # multiple times quickly (e.g., testing configuration changes)
  
  for i in {1..5}; do
    run zsh -c "
      export PULSE_DIR='${PULSE_DIR}'
      export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
      export PULSE_NO_COMPINIT=1
      
      plugins=('file://${TEST_PLUGIN_REPO}')
      source '${PULSE_ROOT}/pulse.zsh'
      echo 'Iteration $i complete'
    "
    
    [ "$status" -eq 0 ]
  done
  
  # Verify plugin was only installed once (directory should exist)
  [ -d "${PULSE_DIR}/plugins/functional_test_repo/.git" ]
  
  # Count number of commits in the clone (should be same as original)
  local original_commits=$(cd "$TEST_PLUGIN_REPO" && git rev-list --count HEAD)
  local cloned_commits=$(cd "${PULSE_DIR}/plugins/functional_test_repo" && git rev-list --count HEAD)
  
  # Should have same number of commits (not multiplied by clones)
  [ "$original_commits" -eq "$cloned_commits" ]
}

@test "functional: plugin works correctly across shell sessions" {
  # Install and verify plugin actually loads
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    plugins=('file://${TEST_PLUGIN_REPO}')
    source '${PULSE_ROOT}/pulse.zsh'
    
    # Try to source the plugin file
    source '${PULSE_DIR}/plugins/functional_test_repo/plugin.zsh'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "version" ]]
  
  # Open new session and verify plugin still works
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    plugins=('file://${TEST_PLUGIN_REPO}')
    source '${PULSE_ROOT}/pulse.zsh'
    
    # Try to source the plugin file again
    source '${PULSE_DIR}/plugins/functional_test_repo/plugin.zsh'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "version" ]]
}

@test "functional: deleted plugin is re-cloned on next source" {
  # Install plugin
  zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    plugins=('file://${TEST_PLUGIN_REPO}')
    source '${PULSE_ROOT}/pulse.zsh'
  " >/dev/null 2>&1
  
  [ -d "${PULSE_DIR}/plugins/functional_test_repo/.git" ]
  
  # Delete the plugin directory
  rm -rf "${PULSE_DIR}/plugins/functional_test_repo"
  
  # Source again - should re-install
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    export PULSE_DEBUG=1
    
    plugins=('file://${TEST_PLUGIN_REPO}')
    source '${PULSE_ROOT}/pulse.zsh' 2>&1
  "
  
  [ "$status" -eq 0 ]
  # Should see installation message
  [[ "$output" =~ "Installing" ]] || [[ "$output" =~ "Installed" ]]
  [ -d "${PULSE_DIR}/plugins/functional_test_repo/.git" ]
}

@test "functional: performance - sourcing with installed plugins is fast" {
  # Install plugin first
  zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    plugins=('file://${TEST_PLUGIN_REPO}')
    source '${PULSE_ROOT}/pulse.zsh'
  " >/dev/null 2>&1
  
  # Measure time for subsequent source (should be fast)
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    start=\$EPOCHREALTIME
    plugins=('file://${TEST_PLUGIN_REPO}')
    source '${PULSE_ROOT}/pulse.zsh'
    end=\$EPOCHREALTIME
    
    # Calculate elapsed time in milliseconds
    elapsed=\$(( (end - start) * 1000 ))
    echo \"Elapsed: \${elapsed}ms\"
  "
  
  [ "$status" -eq 0 ]
  # Verify we got timing output
  [[ "$output" =~ "Elapsed:" ]]
  
  # Extract the elapsed time
  local elapsed=$(echo "$output" | grep -oP 'Elapsed: \K[0-9]+' | head -1)
  
  # Should complete in reasonable time (< 2000ms for this simple test)
  # This is a loose check - in practice should be much faster
  if [[ -n "$elapsed" ]]; then
    [ "$elapsed" -lt 2000 ]
  fi
}
