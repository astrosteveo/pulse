#!/usr/bin/env bats
# Integration tests for plugin cloning behavior

load ../test_helper

setup() {
  export PULSE_DIR="${PULSE_ROOT}/tests/fixtures/pulse_home"
  export PULSE_CACHE_DIR="${PULSE_ROOT}/tests/fixtures/pulse_cache"
  export PULSE_NO_COMPINIT=1
  
  rm -rf "${PULSE_DIR}" "${PULSE_CACHE_DIR}"
  mkdir -p "${PULSE_DIR}/plugins"
  mkdir -p "${PULSE_CACHE_DIR}"
}

teardown() {
  teardown_test_environment
}

@test "sourcing pulse.zsh multiple times does not re-clone existing plugins" {
  # Create a mock git repo
  local fake_repo="${PULSE_ROOT}/tests/fixtures/fake_clone_test_repo"
  rm -rf "$fake_repo"
  mkdir -p "$fake_repo"
  cd "$fake_repo"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "echo 'test plugin'" > plugin.zsh
  git add .
  git commit -q -m "Initial commit"
  
  # First source - should clone
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    export PULSE_DEBUG=1
    
    plugins=('file://${fake_repo}')
    source '${PULSE_ROOT}/pulse.zsh' 2>&1 | grep -c 'Installing' || true
  "
  
  first_install_count="$output"
  
  # Second source - should NOT clone
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    export PULSE_DEBUG=1
    
    plugins=('file://${fake_repo}')
    source '${PULSE_ROOT}/pulse.zsh' 2>&1 | grep -c 'Installing' || true
  "
  
  second_install_count="$output"
  
  # First time should have installed (count > 0)
  [[ "$first_install_count" =~ [1-9] ]]
  # Second time should not have installed (count = 0)
  [[ "$second_install_count" == "0" ]]
  
  rm -rf "$fake_repo"
}

@test "opening multiple terminal sessions does not re-clone plugins" {
  # Create a mock git repo
  local fake_repo="${PULSE_ROOT}/tests/fixtures/fake_multisession_repo"
  rm -rf "$fake_repo"
  mkdir -p "$fake_repo"
  cd "$fake_repo"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "echo 'multisession test'" > plugin.zsh
  git add .
  git commit -q -m "Initial commit"
  
  # Session 1 - install plugin
  zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    plugins=('file://${fake_repo}')
    source '${PULSE_ROOT}/pulse.zsh' 2>&1
  " >/dev/null 2>&1
  
  # Verify plugin was installed
  [ -d "${PULSE_DIR}/plugins/fake_multisession_repo/.git" ]
  
  # Session 2 - should not reinstall
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    export PULSE_DEBUG=1
    
    plugins=('file://${fake_repo}')
    source '${PULSE_ROOT}/pulse.zsh' 2>&1
  "
  
  [ "$status" -eq 0 ]
  # Should not see "Installing" message
  [[ ! "$output" =~ "Installing fake_multisession_repo" ]]
  
  # Session 3 - still should not reinstall
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    export PULSE_DEBUG=1
    
    plugins=('file://${fake_repo}')
    source '${PULSE_ROOT}/pulse.zsh' 2>&1
  "
  
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "Installing fake_multisession_repo" ]]
  
  rm -rf "$fake_repo"
}

@test "plugin is cloned only once even with multiple plugins in array" {
  # Create a mock git repo
  local fake_repo="${PULSE_ROOT}/tests/fixtures/fake_single_clone_repo"
  rm -rf "$fake_repo"
  mkdir -p "$fake_repo"
  cd "$fake_repo"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "echo 'single clone test'" > plugin.zsh
  git add .
  git commit -q -m "Initial commit"
  
  # Source with plugin listed multiple times (error scenario)
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    export PULSE_DEBUG=1
    
    plugins=('file://${fake_repo}' 'file://${fake_repo}' 'file://${fake_repo}')
    source '${PULSE_ROOT}/pulse.zsh' 2>&1 | grep -c 'Installing' || true
  "
  
  install_count="$output"
  
  # Should only install once, even though listed 3 times
  [[ "$install_count" == "1" ]] || [[ "$install_count" == "0" ]]
  
  rm -rf "$fake_repo"
}

@test "CLI operations do not trigger plugin re-cloning" {
  # Create and install a plugin first
  local fake_repo="${PULSE_ROOT}/tests/fixtures/fake_cli_test_repo"
  rm -rf "$fake_repo"
  mkdir -p "$fake_repo"
  cd "$fake_repo"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "echo 'cli test'" > plugin.zsh
  git add .
  git commit -q -m "Initial commit"
  
  # Install the plugin
  zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    plugins=('file://${fake_repo}')
    source '${PULSE_ROOT}/pulse.zsh' 2>&1
  " >/dev/null 2>&1
  
  # Verify plugin was installed
  [ -d "${PULSE_DIR}/plugins/fake_cli_test_repo/.git" ]
  
  # Record the commit SHA
  local original_sha=$(cd "${PULSE_DIR}/plugins/fake_cli_test_repo" && git rev-parse HEAD)
  
  # Run CLI list command - should not trigger re-cloning
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    
    '${PULSE_ROOT}/bin/pulse' list 2>&1
  "
  
  [ "$status" -eq 0 ]
  
  # Verify the plugin directory is unchanged (same commit)
  local after_sha=$(cd "${PULSE_DIR}/plugins/fake_cli_test_repo" && git rev-parse HEAD)
  [ "$original_sha" = "$after_sha" ]
  
  rm -rf "$fake_repo"
}

@test "missing plugin is installed on first source but not on subsequent sources" {
  # Create a mock git repo
  local fake_repo="${PULSE_ROOT}/tests/fixtures/fake_first_install_repo"
  rm -rf "$fake_repo"
  mkdir -p "$fake_repo"
  cd "$fake_repo"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "echo 'first install'" > plugin.zsh
  git add .
  git commit -q -m "Initial commit"
  
  # First source - plugin should be installed
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    export PULSE_DEBUG=1
    
    plugins=('file://${fake_repo}')
    source '${PULSE_ROOT}/pulse.zsh' 2>&1
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing" ]] || [[ "$output" =~ "Installed" ]]
  [ -d "${PULSE_DIR}/plugins/fake_first_install_repo/.git" ]
  
  # Second source - should not reinstall
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    export PULSE_DEBUG=1
    
    plugins=('file://${fake_repo}')
    source '${PULSE_ROOT}/pulse.zsh' 2>&1
  "
  
  [ "$status" -eq 0 ]
  # Should not see installation messages
  [[ ! "$output" =~ "Installing fake_first_install_repo" ]]
  
  rm -rf "$fake_repo"
}
