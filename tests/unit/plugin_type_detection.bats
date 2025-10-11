#!/usr/bin/env bats
# Unit tests for _pulse_detect_plugin_type function

load ../test_helper

@test "_pulse_detect_plugin_type identifies completion plugin by _* files" {
  # Create a plugin with completion files
  local plugin_dir=$(create_mock_plugin "test-comp-1" "completion")

  # Source the plugin engine to get the detection function
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test the detection function
  run _pulse_detect_plugin_type "${plugin_dir}"

  [ "$status" -eq 0 ]
  [[ "$output" == "completion" ]]
}

@test "_pulse_detect_plugin_type identifies completion plugin by completions/ directory" {
  # Create a plugin with completions directory
  local plugin_dir="${PULSE_DIR}/plugins/test-comp-2"
  mkdir -p "${plugin_dir}/completions"
  touch "${plugin_dir}/completions/_test"

  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test the detection function
  run _pulse_detect_plugin_type "${plugin_dir}"

  [ "$status" -eq 0 ]
  [[ "$output" == "completion" ]]
}

@test "_pulse_detect_plugin_type identifies syntax highlighting plugin by name pattern" {
  # Create a plugin with syntax highlighting name pattern
  local plugin_dir="${PULSE_DIR}/plugins/zsh-syntax-highlighting"
  mkdir -p "${plugin_dir}"
  touch "${plugin_dir}/zsh-syntax-highlighting.zsh"

  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test the detection function
  run _pulse_detect_plugin_type "${plugin_dir}"

  [ "$status" -eq 0 ]
  [[ "$output" == "syntax" ]]
}

@test "_pulse_detect_plugin_type identifies theme plugin by .zsh-theme file" {
  # Create a theme plugin
  local plugin_dir=$(create_mock_plugin "test-theme" "theme")

  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test the detection function
  run _pulse_detect_plugin_type "${plugin_dir}"

  [ "$status" -eq 0 ]
  [[ "$output" == "theme" ]]
}

@test "_pulse_detect_plugin_type defaults to standard for unknown plugins" {
  # Create a standard plugin
  local plugin_dir=$(create_mock_plugin "test-standard" "standard")

  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test the detection function
  run _pulse_detect_plugin_type "${plugin_dir}"

  [ "$status" -eq 0 ]
  [[ "$output" == "standard" ]]
}

@test "_pulse_detect_plugin_type handles non-existent directory gracefully" {
  # Source the plugin engine
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"

  # Test with a non-existent directory
  run _pulse_detect_plugin_type "/nonexistent/path"

  # Should return standard as default or handle error gracefully
  [ "$status" -eq 0 ]
  [[ "$output" == "standard" ]] || [[ "$output" == "" ]]
}
