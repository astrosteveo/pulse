#!/usr/bin/env bash
# Test helper library for Pulse framework tests
# Provides utilities for mocking user configurations, files, and environment variables

# Get the absolute path to the project root
PULSE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Set up test environment variables
export PULSE_TEST_MODE=1
export PULSE_DIR="${PULSE_ROOT}/tests/fixtures/pulse_home"
export PULSE_CACHE_DIR="${PULSE_ROOT}/tests/fixtures/pulse_cache"

# Create test directories if they don't exist
mkdir -p "${PULSE_DIR}/plugins"
mkdir -p "${PULSE_CACHE_DIR}"

# Clean up function to be called after each test
teardown_test_environment() {
  # Remove test directories
  rm -rf "${PULSE_DIR}"
  rm -rf "${PULSE_CACHE_DIR}"

  # Recreate empty directories for next test
  mkdir -p "${PULSE_DIR}/plugins"
  mkdir -p "${PULSE_CACHE_DIR}"
}

# Create a mock plugin directory
# Usage: create_mock_plugin <plugin_name> <plugin_type>
# Plugin types: standard, completion, syntax, theme
create_mock_plugin() {
  local plugin_name="$1"
  local plugin_type="${2:-standard}"
  local plugin_dir="${PULSE_DIR}/plugins/${plugin_name}"

  mkdir -p "${plugin_dir}"

  case "${plugin_type}" in
    completion)
      # Create a completion plugin with _commands
      touch "${plugin_dir}/_test_completion"
      echo "# Completion plugin" > "${plugin_dir}/${plugin_name}.plugin.zsh"
      ;;
    syntax)
      # Create a syntax highlighting plugin
      echo "# Syntax highlighting plugin" > "${plugin_dir}/${plugin_name}.zsh"
      echo "# Must be loaded last" >> "${plugin_dir}/${plugin_name}.zsh"
      ;;
    theme)
      # Create a theme plugin
      echo "# Theme" > "${plugin_dir}/${plugin_name}.zsh-theme"
      ;;
    standard|*)
      # Create a standard plugin
      echo "# Standard plugin" > "${plugin_dir}/${plugin_name}.plugin.zsh"
      echo "export ${plugin_name}_loaded=1" >> "${plugin_dir}/${plugin_name}.plugin.zsh"
      ;;
  esac

  echo "${plugin_dir}"
}

# Create a mock .zshrc configuration file
# Usage: create_mock_zshrc <content>
create_mock_zshrc() {
  local content="$1"
  local zshrc_path="${PULSE_DIR}/.zshrc"

  echo "${content}" > "${zshrc_path}"
  echo "${zshrc_path}"
}

# Source the pulse.zsh file in a test context
source_pulse() {
  # Source the main pulse.zsh file
  source "${PULSE_ROOT}/pulse.zsh"
}

# Assert that a variable is set
# Usage: assert_variable_set <var_name>
assert_variable_set() {
  local var_name="$1"

  if [[ -z "${!var_name}" ]]; then
    echo "FAIL: Variable '${var_name}' is not set" >&2
    return 1
  fi

  return 0
}

# Assert that a file exists
# Usage: assert_file_exists <file_path>
assert_file_exists() {
  local file_path="$1"

  if [[ ! -f "${file_path}" ]]; then
    echo "FAIL: File '${file_path}' does not exist" >&2
    return 1
  fi

  return 0
}

# Assert that a directory exists
# Usage: assert_directory_exists <dir_path>
assert_directory_exists() {
  local dir_path="$1"

  if [[ ! -d "${dir_path}" ]]; then
    echo "FAIL: Directory '${dir_path}' does not exist" >&2
    return 1
  fi

  return 0
}

# Set up a clean test environment before each test
setup() {
  # Create fresh test directories
  mkdir -p "${PULSE_DIR}/plugins"
  mkdir -p "${PULSE_CACHE_DIR}"
}

# Clean up test environment after each test
teardown() {
  teardown_test_environment
}
