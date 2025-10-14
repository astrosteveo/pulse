#!/usr/bin/env bats
# Integration tests for pulse CLI command

load ../test_helper

setup() {
  # Create test environment
  export PULSE_DIR="${PULSE_ROOT}"
  export PULSE_CACHE_DIR="${PULSE_CACHE_DIR}"
  
  # Create mock plugins directory
  mkdir -p "${PULSE_DIR}/plugins/test-plugin"
  mkdir -p "${PULSE_DIR}/plugins/test-syntax-highlighting"
  mkdir -p "${PULSE_DIR}/plugins/test-completions"
  
  # Create mock plugin files
  echo "# Test plugin" > "${PULSE_DIR}/plugins/test-plugin/test-plugin.zsh"
  echo "# Syntax plugin" > "${PULSE_DIR}/plugins/test-syntax-highlighting/test-syntax-highlighting.zsh"
  mkdir -p "${PULSE_DIR}/plugins/test-completions/completions"
  echo "# Completion plugin" > "${PULSE_DIR}/plugins/test-completions/_test"
}

teardown() {
  # Clean up test plugins
  rm -rf "${PULSE_DIR}/plugins/test-plugin"
  rm -rf "${PULSE_DIR}/plugins/test-syntax-highlighting"
  rm -rf "${PULSE_DIR}/plugins/test-completions"
}

# =============================================================================
# Basic Command Tests
# =============================================================================

@test "pulse command exists and is executable" {
  [ -x "${PULSE_ROOT}/bin/pulse" ]
}

@test "pulse help shows usage information" {
  run "${PULSE_ROOT}/bin/pulse" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pulse - The Heartbeat of Your Zsh"* ]]
  [[ "$output" == *"USAGE"* ]]
  [[ "$output" == *"COMMANDS"* ]]
}

@test "pulse --help shows usage information" {
  run "${PULSE_ROOT}/bin/pulse" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pulse - The Heartbeat of Your Zsh"* ]]
}

@test "pulse version shows version information" {
  run "${PULSE_ROOT}/bin/pulse" version
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pulse version"* ]]
}

@test "pulse --version shows version information" {
  run "${PULSE_ROOT}/bin/pulse" --version
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pulse version"* ]]
}

@test "pulse without arguments shows help" {
  run "${PULSE_ROOT}/bin/pulse"
  [ "$status" -eq 0 ]
  [[ "$output" == *"USAGE"* ]]
}

@test "pulse with invalid command shows error" {
  run "${PULSE_ROOT}/bin/pulse" invalid-command
  [ "$status" -eq 2 ]
  [[ "$output" == *"Unknown command"* ]]
}

# =============================================================================
# pulse list Tests
# =============================================================================

@test "pulse list shows installed plugins in table format" {
  run "${PULSE_ROOT}/bin/pulse" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Plugin"* ]]
  [[ "$output" == *"Status"* ]]
  [[ "$output" == *"Type"* ]]
  [[ "$output" == *"test-plugin"* ]]
  [[ "$output" == *"test-syntax-highlighting"* ]]
  [[ "$output" == *"test-completions"* ]]
}

@test "pulse list detects plugin types correctly" {
  run "${PULSE_ROOT}/bin/pulse" list
  [ "$status" -eq 0 ]
  # syntax-highlighting plugins should be detected as syntax type
  [[ "$output" == *"syntax"* ]]
  # completions should be detected as completion type
  [[ "$output" == *"completion"* ]]
}

@test "pulse list --format=json outputs valid JSON" {
  run "${PULSE_ROOT}/bin/pulse" list --format=json
  [ "$status" -eq 0 ]
  [[ "$output" == *'"plugins"'* ]]
  [[ "$output" == *'"stats"'* ]]
  [[ "$output" == *'"name"'* ]]
  [[ "$output" == *'"test-plugin"'* ]]
}

@test "pulse list --format=simple outputs one plugin per line" {
  run "${PULSE_ROOT}/bin/pulse" list --format=simple
  [ "$status" -eq 0 ]
  # Output should contain plugin names without formatting
  [[ "$output" == *"test-plugin"* ]]
  [[ "$output" == *"test-syntax-highlighting"* ]]
  [[ "$output" == *"test-completions"* ]]
  # Should not contain table headers
  [[ "$output" != *"Plugin"* ]]
  [[ "$output" != *"Status"* ]]
}

@test "pulse list with invalid format shows error" {
  run "${PULSE_ROOT}/bin/pulse" list --format=invalid
  [ "$status" -eq 2 ]
  [[ "$output" == *"Invalid format"* ]]
}

@test "pulse list with no plugins shows helpful message" {
  # Remove all plugins temporarily
  rm -rf "${PULSE_DIR}/plugins"/*
  
  run "${PULSE_ROOT}/bin/pulse" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"No plugins installed"* ]]
}

# =============================================================================
# pulse info Tests
# =============================================================================

@test "pulse info shows detailed plugin information" {
  run "${PULSE_ROOT}/bin/pulse" info test-plugin
  [ "$status" -eq 0 ]
  [[ "$output" == *"Plugin: test-plugin"* ]]
  [[ "$output" == *"Status:"* ]]
  [[ "$output" == *"Type:"* ]]
  [[ "$output" == *"Path:"* ]]
  [[ "$output" == *"Files:"* ]]
}

@test "pulse info detects plugin type correctly" {
  run "${PULSE_ROOT}/bin/pulse" info test-syntax-highlighting
  [ "$status" -eq 0 ]
  [[ "$output" == *"Type:"* ]]
  [[ "$output" == *"syntax"* ]]
}

@test "pulse info lists plugin files" {
  run "${PULSE_ROOT}/bin/pulse" info test-plugin
  [ "$status" -eq 0 ]
  [[ "$output" == *"test-plugin.zsh"* ]]
}

@test "pulse info with nonexistent plugin shows error" {
  run "${PULSE_ROOT}/bin/pulse" info nonexistent-plugin
  [ "$status" -eq 1 ]
  [[ "$output" == *"Plugin not found"* ]]
}

@test "pulse info without plugin name shows error" {
  run "${PULSE_ROOT}/bin/pulse" info
  [ "$status" -eq 2 ]
  [[ "$output" == *"Plugin name required"* ]]
}

# =============================================================================
# pulse doctor Tests
# =============================================================================

@test "pulse doctor checks system health" {
  run "${PULSE_ROOT}/bin/pulse" doctor
  # Should succeed or return 1 for warnings (not 2 for errors)
  [ "$status" -le 1 ]
  [[ "$output" == *"Pulse Diagnostics"* ]]
  [[ "$output" == *"Zsh version"* ]]
  [[ "$output" == *"Git available"* ]]
  [[ "$output" == *"Pulse directory"* ]]
}

@test "pulse doctor checks for Zsh" {
  run "${PULSE_ROOT}/bin/pulse" doctor
  [[ "$output" == *"Zsh version"* ]]
}

@test "pulse doctor checks for Git" {
  run "${PULSE_ROOT}/bin/pulse" doctor
  [[ "$output" == *"Git available"* ]]
}

@test "pulse doctor checks directories" {
  run "${PULSE_ROOT}/bin/pulse" doctor
  [[ "$output" == *"Pulse directory"* ]]
  [[ "$output" == *"Cache directory"* ]]
}

# =============================================================================
# pulse cache Tests
# =============================================================================

@test "pulse cache clear clears cache directory" {
  # Create cache directory with test file
  mkdir -p "${PULSE_CACHE_DIR}"
  touch "${PULSE_CACHE_DIR}/test-cache-file"
  
  run "${PULSE_ROOT}/bin/pulse" cache clear
  [ "$status" -eq 0 ]
  [[ "$output" == *"Cleared cache"* ]]
  
  # Verify cache file was removed
  [ ! -f "${PULSE_CACHE_DIR}/test-cache-file" ]
}

@test "pulse cache clear with nonexistent directory succeeds" {
  # Remove cache directory
  rm -rf "${PULSE_CACHE_DIR}"
  
  run "${PULSE_ROOT}/bin/pulse" cache clear
  [ "$status" -eq 0 ]
  [[ "$output" == *"does not exist"* ]]
}

@test "pulse cache without subcommand shows error" {
  run "${PULSE_ROOT}/bin/pulse" cache
  [ "$status" -eq 2 ]
  [[ "$output" == *"Invalid cache command"* ]]
}

# =============================================================================
# Placeholder Command Tests
# =============================================================================

@test "pulse update shows not implemented message" {
  run "${PULSE_ROOT}/bin/pulse" update
  [ "$status" -eq 1 ]
  [[ "$output" == *"not yet implemented"* ]]
}

@test "pulse install shows not implemented message" {
  run "${PULSE_ROOT}/bin/pulse" install
  [ "$status" -eq 1 ]
  [[ "$output" == *"not yet implemented"* ]]
}

@test "pulse remove shows not implemented message" {
  run "${PULSE_ROOT}/bin/pulse" remove
  [ "$status" -eq 1 ]
  [[ "$output" == *"not yet implemented"* ]]
}

@test "pulse benchmark shows not implemented message" {
  run "${PULSE_ROOT}/bin/pulse" benchmark
  [ "$status" -eq 1 ]
  [[ "$output" == *"not yet implemented"* ]]
}

@test "pulse validate shows not implemented message" {
  run "${PULSE_ROOT}/bin/pulse" validate
  [ "$status" -eq 1 ]
  [[ "$output" == *"not yet implemented"* ]]
}
