#!/usr/bin/env bats
# Unit tests for _pulse_resolve_plugin_source function

load ../test_helper

@test "_pulse_resolve_plugin_source handles standard GitHub shorthand (user/repo)" {
  # Source the plugin engine to get the resolution function
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test standard GitHub shorthand
  run _pulse_resolve_plugin_source "zsh-users/zsh-autosuggestions"

  [ "$status" -eq 0 ]
  [[ "$output" == "${PULSE_DIR}/plugins/zsh-autosuggestions" ]]
}

@test "_pulse_resolve_plugin_source handles GitHub shorthand with dots in repo name" {
  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test with dots in repo name (common for packages like node.js, etc.)
  run _pulse_resolve_plugin_source "user/my.plugin"

  [ "$status" -eq 0 ]
  [[ "$output" == "${PULSE_DIR}/plugins/my.plugin" ]]
}

@test "_pulse_resolve_plugin_source handles GitHub shorthand with dots in owner name" {
  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test with dots in owner name (less common but valid on GitHub)
  run _pulse_resolve_plugin_source "user.name/plugin"

  [ "$status" -eq 0 ]
  [[ "$output" == "${PULSE_DIR}/plugins/plugin" ]]
}

@test "_pulse_resolve_plugin_source handles GitHub shorthand with underscores" {
  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test with underscores in both owner and repo
  run _pulse_resolve_plugin_source "user_name/repo_name"

  [ "$status" -eq 0 ]
  [[ "$output" == "${PULSE_DIR}/plugins/repo_name" ]]
}

@test "_pulse_resolve_plugin_source handles full GitHub URL" {
  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test full GitHub URL
  run _pulse_resolve_plugin_source "https://github.com/zsh-users/zsh-autosuggestions.git"

  [ "$status" -eq 0 ]
  [[ "$output" == "${PULSE_DIR}/plugins/zsh-autosuggestions" ]]
}

@test "_pulse_resolve_plugin_source handles full GitHub URL with dots in repo name" {
  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test full GitHub URL with dots in repo name
  run _pulse_resolve_plugin_source "https://github.com/user/repo.name.git"

  [ "$status" -eq 0 ]
  [[ "$output" == "${PULSE_DIR}/plugins/repo.name" ]]
}

@test "_pulse_resolve_plugin_source handles GitLab URL" {
  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test GitLab URL
  run _pulse_resolve_plugin_source "https://gitlab.com/user/plugin.git"

  [ "$status" -eq 0 ]
  [[ "$output" == "${PULSE_DIR}/plugins/plugin" ]]
}

@test "_pulse_resolve_plugin_source handles SSH Git URL" {
  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test SSH Git URL
  run _pulse_resolve_plugin_source "git@github.com:user/plugin.git"

  [ "$status" -eq 0 ]
  [[ "$output" == "${PULSE_DIR}/plugins/plugin" ]]
}

@test "_pulse_resolve_plugin_source handles absolute local path" {
  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test absolute local path
  run _pulse_resolve_plugin_source "/absolute/path/to/plugin"

  [ "$status" -eq 0 ]
  [[ "$output" == "/absolute/path/to/plugin" ]]
}

@test "_pulse_resolve_plugin_source handles relative local path" {
  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Create a temporary directory to test relative path
  local test_dir="${PULSE_DIR}/test-relative"
  mkdir -p "$test_dir"

  # Test relative path (we need to cd to the parent first)
  run bash -c "cd '${PULSE_DIR}' && source '${PULSE_ROOT}/lib/plugin-engine.zsh' && _pulse_resolve_plugin_source './test-relative'"

  [ "$status" -eq 0 ]
  [[ "$output" == "$test_dir" ]]
}

@test "_pulse_resolve_plugin_source handles plain plugin name" {
  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test plain plugin name (should default to PULSE_DIR/plugins)
  run _pulse_resolve_plugin_source "my-plugin"

  [ "$status" -eq 0 ]
  [[ "$output" == "${PULSE_DIR}/plugins/my-plugin" ]]
}
