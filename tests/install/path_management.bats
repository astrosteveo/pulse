#!/usr/bin/env bats
# PATH management tests for installer

load test_helper

setup() {
  setup_clean_environment
  # Source the installer to load functions
  source "$BATS_TEST_DIRNAME/../../scripts/pulse-install.sh" 2>/dev/null || true
}

teardown() {
  teardown_test_environment
}

@test "add_pulse_config adds PATH management section to new .zshrc" {
  # No existing .zshrc
  run add_pulse_config "$PULSE_ZSHRC" "$INSTALL_DIR"
  assert_success
  assert_file_exists "$PULSE_ZSHRC"
  
  # Should contain modern Zsh PATH management
  assert_string_in_file "typeset -TUx PATH path" "$PULSE_ZSHRC"
  
  # Should contain ~/.local/bin in path array
  assert_string_in_file "path=(" "$PULSE_ZSHRC"
  assert_string_in_file "\$HOME/.local/bin" "$PULSE_ZSHRC"
}

@test "add_pulse_config preserves existing PATH configuration" {
  # Create existing .zshrc with custom PATH
  create_mock_zshrc "# My custom config
export PATH=\$HOME/bin:\$PATH
export EDITOR=vim"

  run add_pulse_config "$PULSE_ZSHRC" "$INSTALL_DIR"
  assert_success
  
  # Should preserve existing PATH export
  assert_string_in_file "export PATH=\$HOME/bin:\$PATH" "$PULSE_ZSHRC"
}

@test "add_pulse_config does not duplicate PATH setup in existing Pulse block" {
  # Create .zshrc with existing Pulse block that has PATH setup
  create_mock_zshrc "# PATH Configuration
typeset -TUx PATH path
path=(
  \$HOME/.local/bin
  \$path[@]
)

# BEGIN Pulse Configuration
plugins=()
source $INSTALL_DIR/pulse.zsh
# END Pulse Configuration"

  run add_pulse_config "$PULSE_ZSHRC" "$INSTALL_DIR"
  assert_success
  
  # Should only have one typeset -TUx PATH path
  local count
  count=$(count_in_file "typeset -TUx PATH path" "$PULSE_ZSHRC")
  [ "$count" -eq 1 ]
}

@test "template file contains modern PATH management" {
  local template_file="$BATS_TEST_DIRNAME/../../pulse.zshrc.template"
  
  # Template should exist
  assert_file_exists "$template_file"
  
  # Should contain modern Zsh PATH management
  assert_string_in_file "typeset -TUx PATH path" "$template_file"
  
  # Should mention ~/.local/bin
  grep -q ".local/bin" "$template_file" || {
    echo "Template should mention ~/.local/bin"
    return 1
  }
}

@test "installer uses template for new .zshrc" {
  # Ensure no .zshrc exists
  [ ! -f "$PULSE_ZSHRC" ]
  
  # Add config should use template content
  run add_pulse_config "$PULSE_ZSHRC" "$INSTALL_DIR"
  assert_success
  
  # Result should have template-like structure with PATH setup
  assert_string_in_file "typeset -TUx PATH path" "$PULSE_ZSHRC"
  assert_string_in_file "BEGIN Pulse Configuration" "$PULSE_ZSHRC"
}
