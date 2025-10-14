#!/usr/bin/env bats
# T013: Configuration management tests (RED phase)

load test_helper

setup() {
  setup_clean_environment
  # Source the installer to load functions
  source "$BATS_TEST_DIRNAME/../../scripts/pulse-install.sh" 2>/dev/null || true
}

teardown() {
  teardown_test_environment
}

@test "add_pulse_config creates new .zshrc with configuration" {
  # No existing .zshrc
  run add_pulse_config "$PULSE_ZSHRC" "$INSTALL_DIR"
  assert_success
  assert_file_exists "$PULSE_ZSHRC"
  assert_string_in_file "BEGIN Pulse Configuration" "$PULSE_ZSHRC"
  assert_string_in_file "source $INSTALL_DIR/pulse.zsh" "$PULSE_ZSHRC"
}

@test "add_pulse_config adds block to existing .zshrc" {
  # Create existing .zshrc
  create_mock_zshrc "# My custom config
export PATH=\$HOME/bin:\$PATH"

  run add_pulse_config "$PULSE_ZSHRC" "$INSTALL_DIR"
  assert_success

  # Should preserve existing content
  assert_string_in_file "My custom config" "$PULSE_ZSHRC"
  assert_string_in_file "BEGIN Pulse Configuration" "$PULSE_ZSHRC"
}

@test "add_pulse_config does not duplicate existing block" {
  # Create .zshrc with existing Pulse block
  create_mock_zshrc "# BEGIN Pulse Configuration
plugins=(git zsh-syntax-highlighting)
source $INSTALL_DIR/pulse.zsh
# END Pulse Configuration"

  run add_pulse_config "$PULSE_ZSHRC" "$INSTALL_DIR"
  assert_success

  # Should only have one BEGIN/END pair
  local begin_count
  begin_count=$(count_in_file "BEGIN Pulse Configuration" "$PULSE_ZSHRC")
  [ "$begin_count" -eq 1 ]
}

@test "add_pulse_config updates existing block with new path" {
  # Create .zshrc with old installation path
  create_mock_zshrc "# BEGIN Pulse Configuration
plugins=()
source /old/path/pulse.zsh
# END Pulse Configuration"

  run add_pulse_config "$PULSE_ZSHRC" "$INSTALL_DIR"
  assert_success

  # Should update to new path
  assert_string_in_file "source $INSTALL_DIR/pulse.zsh" "$PULSE_ZSHRC"

  # Should not contain old path
  if grep -q "/old/path/pulse.zsh" "$PULSE_ZSHRC"; then
    echo "Old path should be removed"
    return 1
  fi
}

@test "add_pulse_config preserves correct plugin order" {
  # Create .zshrc with wrong order (source before plugins)
  create_mock_zshrc "# BEGIN Pulse Configuration
source $INSTALL_DIR/pulse.zsh
plugins=(git)
# END Pulse Configuration"

  run add_pulse_config "$PULSE_ZSHRC" "$INSTALL_DIR"
  assert_success

  # Should fix order: plugins before source
  verify_config_order || {
    echo "Configuration order should be: plugins declaration, then source"
    return 1
  }
}

@test "add_pulse_config handles .zshrc in non-existent directory" {
  # Set .zshrc path in directory that doesn't exist
  local custom_zshrc="$TEST_HOME/custom/dir/.zshrc"

  run add_pulse_config "$custom_zshrc" "$INSTALL_DIR"
  assert_success
  assert_file_exists "$custom_zshrc"
}
