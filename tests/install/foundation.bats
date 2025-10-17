#!/usr/bin/env bats
#
# Foundation tests for installer core utilities
# Tests for output formatting and prerequisite checking functions

load test_helper

# Output Formatting Tests (T003.5)

@test "print_header outputs formatted header" {
  source scripts/pulse-install.sh
  run print_header
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Pulse" ]]
}

@test "print_step outputs checkmark and step text" {
  source scripts/pulse-install.sh
  run print_step "Test step"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "✓" ]] || [[ "$output" =~ "[OK]" ]]
  [[ "$output" =~ "Test step" ]]
}

@test "print_error outputs error marker and text" {
  source scripts/pulse-install.sh
  run print_error "Test error"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "✗" ]] || [[ "$output" =~ "[ERROR]" ]]
  [[ "$output" =~ "Test error" ]]
}

@test "print_success outputs success banner" {
  source scripts/pulse-install.sh
  run print_success
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Success" ]] || [[ "$output" =~ "complete" ]]
}

@test "pulse.zsh exports PULSE_VERSION" {
  local version
  version=$(zsh -c "source '$BATS_TEST_DIRNAME/../../pulse.zsh'; print -r -- \$PULSE_VERSION" | tail -n 1)
  [ -n "$version" ]
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.+][A-Za-z0-9._-]+)?$ ]]
}
