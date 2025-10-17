#!/usr/bin/env bats
#
# Test helper verification tests
# Ensures test_helper.bash functions work correctly

load test_helper

@test "setup_clean_environment creates TEST_HOME" {
  setup_clean_environment
  [ -n "$TEST_HOME" ]
  [ -d "$TEST_HOME" ]
  teardown_test_environment
}

@test "setup_clean_environment sets environment variables" {
  setup_clean_environment
  [ "$PULSE_INSTALL_DIR" = "$TEST_HOME/.local/share/pulse" ]
  [ "$PULSE_ZSHRC" = "$TEST_HOME/.zshrc" ]
  [ "$PULSE_SKIP_BACKUP" = "false" ]
  teardown_test_environment
}

@test "teardown_test_environment cleans up TEST_HOME" {
  setup_clean_environment
  local test_home_path="$TEST_HOME"
  teardown_test_environment
  [ ! -d "$test_home_path" ]
}

@test "create_mock_zshrc creates file" {
  create_mock_zshrc "# Test content"
  [ -f "$PULSE_ZSHRC" ]
  grep -q "# Test content" "$PULSE_ZSHRC"
}

@test "has_pulse_block detects Pulse configuration" {
  create_mock_zshrc "# BEGIN Pulse Configuration"
  has_pulse_block
}

@test "has_pulse_block returns false when no block" {
  create_mock_zshrc "# Regular content"
  ! has_pulse_block
}

@test "verify_config_order detects correct order" {
  cat > "$PULSE_ZSHRC" << 'EOF'
plugins=()
source ~/.local/share/pulse/pulse.zsh
EOF
  verify_config_order
}

@test "verify_config_order detects wrong order" {
  cat > "$PULSE_ZSHRC" << 'EOF'
source ~/.local/share/pulse/pulse.zsh
plugins=()
EOF
  ! verify_config_order
}

@test "create_mock_pulse_installation creates structure" {
  create_mock_pulse_installation
  [ -d "$PULSE_INSTALL_DIR" ]
  [ -f "$PULSE_INSTALL_DIR/pulse.zsh" ]
  [ -d "$PULSE_INSTALL_DIR/.git" ]
}

@test "assert_file_exists succeeds for existing file" {
  touch "$TEST_HOME/testfile"
  assert_file_exists "$TEST_HOME/testfile"
}

@test "assert_dir_exists succeeds for existing directory" {
  mkdir -p "$TEST_HOME/testdir"
  assert_dir_exists "$TEST_HOME/testdir"
}

@test "count_in_file counts occurrences" {
  echo "test" > "$TEST_HOME/file"
  echo "test" >> "$TEST_HOME/file"
  result=$(count_in_file "test" "$TEST_HOME/file")
  [ "$result" -eq 2 ]
}
