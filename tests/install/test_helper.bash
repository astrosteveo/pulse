#!/usr/bin/env bash
#
# Test helper functions for Pulse installer tests
# Provides common fixtures and utilities for bats test suites

# Setup a clean test environment before each test
setup_clean_environment() {
  # Create temporary home directory for isolated testing
  export TEST_HOME=$(mktemp -d)
  export HOME=$TEST_HOME

  # Set default environment variables for testing
  export PULSE_INSTALL_DIR="$TEST_HOME/.local/share/pulse"
  export PULSE_ZSHRC="$TEST_HOME/.zshrc"
  export PULSE_SKIP_BACKUP=false
  export PULSE_DEBUG=false
  export PULSE_SKIP_VERIFY=false

  # Ensure clean state
  mkdir -p "$TEST_HOME/.local/share"
}

# Teardown test environment after each test
teardown_test_environment() {
  # Clean up temporary directory
  if [ -n "$TEST_HOME" ] && [ -d "$TEST_HOME" ]; then
    rm -rf "$TEST_HOME"
  fi

  # Restore original HOME if it was backed up
  if [ -n "$ORIGINAL_HOME" ]; then
    export HOME="$ORIGINAL_HOME"
    unset ORIGINAL_HOME
  fi
}

# Common setup function for all tests
setup() {
  setup_clean_environment
}

# Common teardown function for all tests
teardown() {
  teardown_test_environment
}

# Helper: Create a mock .zshrc file with content
create_mock_zshrc() {
  local content="${1:-# Empty .zshrc}"
  echo "$content" > "$PULSE_ZSHRC"
}

# Helper: Check if Pulse block exists in .zshrc
has_pulse_block() {
  grep -q "BEGIN Pulse Configuration" "$PULSE_ZSHRC" 2>/dev/null
}

# Helper: Get line number of plugins declaration
get_plugins_line() {
  grep -n "plugins=" "$PULSE_ZSHRC" 2>/dev/null | head -1 | cut -d: -f1
}

# Helper: Get line number of source statement
get_source_line() {
  grep -n "source.*pulse.zsh" "$PULSE_ZSHRC" 2>/dev/null | head -1 | cut -d: -f1
}

# Helper: Verify configuration order is correct
verify_config_order() {
  local plugins_line=$(get_plugins_line)
  local source_line=$(get_source_line)

  [ -n "$plugins_line" ] && [ -n "$source_line" ] && [ "$plugins_line" -lt "$source_line" ]
}

# Helper: Create a mock Pulse installation
create_mock_pulse_installation() {
  mkdir -p "$PULSE_INSTALL_DIR"
  cat > "$PULSE_INSTALL_DIR/pulse.zsh" << 'EOF'
# Mock Pulse framework for testing
export PULSE_VERSION="1.0.0-test"
echo "Pulse loaded successfully (test mode)"
EOF

  # Create .git directory to simulate cloned repo
  mkdir -p "$PULSE_INSTALL_DIR/.git"
}

# Helper: Assert file exists
assert_file_exists() {
  local file="$1"
  [ -f "$file" ] || {
    echo "Expected file to exist: $file"
    return 1
  }
}

# Helper: Assert directory exists
assert_dir_exists() {
  local dir="$1"
  [ -d "$dir" ] || {
    echo "Expected directory to exist: $dir"
    return 1
  }
}

# Helper: Assert string in file
assert_string_in_file() {
  local string="$1"
  local file="$2"
  grep -qF "$string" "$file" || {
    echo "Expected to find '$string' in $file"
    return 1
  }
}

# Helper: Count occurrences of string in file
count_in_file() {
  local string="$1"
  local file="$2"
  grep -c "$string" "$file" 2>/dev/null || echo "0"
}
