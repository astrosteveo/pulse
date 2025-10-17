#!/usr/bin/env bats
# Unit tests for plugin installation checking optimization

load ../test_helper

setup() {
  # Create a clean test environment
  export PULSE_DIR="${PULSE_ROOT}/tests/fixtures/pulse_home"
  export PULSE_CACHE_DIR="${PULSE_ROOT}/tests/fixtures/pulse_cache"
  export PULSE_DEBUG=1
  
  # Clean up any existing test data
  rm -rf "${PULSE_DIR}" "${PULSE_CACHE_DIR}"
  mkdir -p "${PULSE_DIR}/plugins"
  mkdir -p "${PULSE_CACHE_DIR}"
}

teardown() {
  teardown_test_environment
}

@test "plugin installation check is skipped when already checked in session" {
  # Create a mock plugin with .git directory
  local plugin_name="test-plugin"
  local plugin_dir="${PULSE_DIR}/plugins/${plugin_name}"
  mkdir -p "${plugin_dir}/.git"
  echo "test" > "${plugin_dir}/${plugin_name}.plugin.zsh"
  
  # Source pulse in a single shell session with multiple plugins
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_DEBUG=1
    
    # Disable compinit to avoid interactive prompts
    export PULSE_NO_COMPINIT=1
    
    # Define plugins array (same plugin referenced multiple times)
    plugins=('${plugin_dir}' '${plugin_dir}')
    
    # Source the plugin engine
    source '${PULSE_ROOT}/lib/plugin-engine.zsh'
    _pulse_init_engine
    _pulse_discover_plugins
    
    # Count how many times the installation check was performed
    echo \${#_pulse_installation_checked[@]}
  "
  
  [ "$status" -eq 0 ]
  # Should only check once, not twice
  [[ "$output" =~ "1" ]]
}

@test "session tracking prevents redundant directory existence checks" {
  # Create a fake git repo
  local fake_repo="${PULSE_ROOT}/tests/fixtures/fake_session_test_repo"
  rm -rf "$fake_repo"
  mkdir -p "$fake_repo"
  cd "$fake_repo"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "test" > plugin.zsh
  git add .
  git commit -q -m "Initial commit"
  
  # Source pulse twice in the same session
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    export PULSE_DEBUG=1
    
    # First discovery - will clone
    plugins=('file://${fake_repo}')
    source '${PULSE_ROOT}/lib/plugin-engine.zsh'
    _pulse_init_engine
    _pulse_discover_plugins 2>&1 | grep -c 'Successfully installed' || echo '0'
    
    # Second discovery in same session - should skip check
    _pulse_discover_plugins 2>&1 | grep -c 'Skipping installation check' || echo '0'
  "
  
  [ "$status" -eq 0 ]
  # First run should install (count = 1)
  # Second run should skip (count = 1)
  [[ "$output" =~ "1" ]]
  
  rm -rf "$fake_repo"
}

@test "installation marker file is created after successful plugin installation" {
  # Create a mock git repo to simulate cloning
  local fake_repo="${PULSE_ROOT}/tests/fixtures/fake_plugin_repo"
  rm -rf "$fake_repo"
  mkdir -p "$fake_repo"
  cd "$fake_repo"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "echo 'plugin loaded'" > plugin.zsh
  git add .
  git commit -q -m "Initial commit"
  
  # Test that the marker file is created
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    typeset -ga pulse_disabled_modules
    export PULSE_NO_COMPINIT=1
    
    plugins=('file://${fake_repo}')
    source '${PULSE_ROOT}/pulse.zsh' 2>&1
    
    # Check if marker file exists
    if [[ -f '${PULSE_DIR}/plugins/fake_plugin_repo/.pulse-installed' ]]; then
      echo 'MARKER_EXISTS'
    fi
  "
  
  [[ "$output" =~ "MARKER_EXISTS" ]]
  
  # Clean up
  rm -rf "$fake_repo"
}

@test "plugins with .git directory are not cloned again" {
  # Create a mock plugin with .git directory (simulating already installed)
  local plugin_name="already-installed"
  local plugin_dir="${PULSE_DIR}/plugins/${plugin_name}"
  mkdir -p "${plugin_dir}/.git"
  echo "test" > "${plugin_dir}/${plugin_name}.plugin.zsh"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    export PULSE_DEBUG=1
    
    # This should not trigger cloning since directory exists
    plugins=('${plugin_dir}')
    source '${PULSE_ROOT}/pulse.zsh' 2>&1
  "
  
  [ "$status" -eq 0 ]
  # Should not see any "Installing" or "git clone" messages
  [[ ! "$output" =~ "Installing" ]]
  [[ ! "$output" =~ "git clone" ]]
}

@test "session tracking is reset between different zsh instances" {
  # First instance
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    # Create a mock plugin
    mkdir -p '${PULSE_DIR}/plugins/test-reset/.git'
    echo 'test' > '${PULSE_DIR}/plugins/test-reset/test-reset.plugin.zsh'
    
    plugins=('${PULSE_DIR}/plugins/test-reset')
    source '${PULSE_ROOT}/lib/plugin-engine.zsh'
    _pulse_init_engine
    _pulse_discover_plugins
    
    echo \${_pulse_installation_checked[test-reset]}
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "1" ]]
  
  # Second instance - should have fresh tracking
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    
    plugins=('${PULSE_DIR}/plugins/test-reset')
    source '${PULSE_ROOT}/lib/plugin-engine.zsh'
    _pulse_init_engine
    
    # Check if tracking is empty at start of new session
    echo \${#_pulse_installation_checked[@]}
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "0" ]]
}
