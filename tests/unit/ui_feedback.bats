#!/usr/bin/env bats
# Unit tests for UI feedback library

load ../test_helper

setup() {
  setup_test_environment
  source "${PULSE_ROOT}/lib/cli/lib/ui-feedback.zsh"
}

teardown() {
  teardown_test_environment
}

# =============================================================================
# Symbol and Color Initialization Tests
# =============================================================================

@test "UI feedback: symbols are defined" {
  [[ -n "$PULSE_CHECK_MARK" ]]
  [[ -n "$PULSE_CROSS_MARK" ]]
  [[ -n "$PULSE_INFO_MARK" ]]
  [[ -n "$PULSE_SPINNER_MARK" ]]
}

@test "UI feedback: color variables are defined" {
  # Variables should be defined (may be empty if terminal doesn't support colors)
  [[ -v PULSE_COLOR_GREEN ]]
  [[ -v PULSE_COLOR_RED ]]
  [[ -v PULSE_COLOR_YELLOW ]]
  [[ -v PULSE_COLOR_BLUE ]]
  [[ -v PULSE_COLOR_RESET ]]
}

@test "UI feedback: spinner frames are defined" {
  [[ ${#PULSE_SPINNER_FRAMES[@]} -gt 0 ]]
}

# =============================================================================
# Basic Message Function Tests
# =============================================================================

@test "UI feedback: pulse_success displays success message" {
  run pulse_success "Test success message"
  assert_success
  assert_output --partial "Test success message"
}

@test "UI feedback: pulse_error displays error message" {
  run pulse_error "Test error message"
  assert_success
  assert_output --partial "Test error message"
}

@test "UI feedback: pulse_info displays info message" {
  run pulse_info "Test info message"
  assert_success
  assert_output --partial "Test info message"
}

@test "UI feedback: pulse_warning displays warning message" {
  run pulse_warning "Test warning message"
  assert_success
  assert_output --partial "Test warning message"
}

# =============================================================================
# Spinner Tests (non-TTY mode)
# =============================================================================

@test "UI feedback: pulse_start_spinner works in non-TTY mode" {
  # In bats, stdout is not a TTY, so spinner should show simple message
  run pulse_start_spinner "Installing plugin..."
  # Spinner will show the message and return immediately
  # May have output depending on TTY detection
  assert_success
}

@test "UI feedback: pulse_stop_spinner with success status" {
  pulse_start_spinner "Testing..."
  run pulse_stop_spinner success "Test completed"
  assert_success
  assert_output --partial "Test completed"
}

@test "UI feedback: pulse_stop_spinner with error status" {
  pulse_start_spinner "Testing..."
  run pulse_stop_spinner error "Test failed"
  assert_success
  assert_output --partial "Test failed"
}

@test "UI feedback: pulse_stop_spinner with info status" {
  pulse_start_spinner "Testing..."
  run pulse_stop_spinner info "Test info"
  assert_success
  assert_output --partial "Test info"
}

# =============================================================================
# Cleanup Tests
# =============================================================================

@test "UI feedback: pulse_cleanup_spinner stops background job" {
  # Start a spinner
  pulse_start_spinner "Test spinner"
  local pid="$PULSE_SPINNER_PID"
  
  # Clean up
  pulse_cleanup_spinner
  
  # Verify PID is cleared
  [[ -z "$PULSE_SPINNER_PID" ]]
  
  # Verify background job is stopped (if it was started)
  if [[ -n "$pid" ]]; then
    run kill -0 "$pid"
    assert_failure
  fi
}

# =============================================================================
# Integration Tests
# =============================================================================

@test "UI feedback: functions work when called in sequence" {
  run zsh -c "
    source '${PULSE_ROOT}/lib/cli/lib/ui-feedback.zsh'
    pulse_info 'Starting test'
    pulse_success 'Test passed'
    pulse_warning 'Minor issue'
    pulse_error 'Test error'
  "
  assert_success
  assert_output --partial "Starting test"
  assert_output --partial "Test passed"
  assert_output --partial "Minor issue"
  assert_output --partial "Test error"
}

@test "UI feedback: spinner can be started and stopped multiple times" {
  pulse_start_spinner "First operation"
  pulse_stop_spinner success "First complete"
  
  pulse_start_spinner "Second operation"
  pulse_stop_spinner success "Second complete"
  
  # Both should succeed without errors
  assert_success
}
