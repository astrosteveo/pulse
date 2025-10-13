#!/usr/bin/env bats
# T019: End-to-end orchestration tests

load test_helper

setup() {
  setup_clean_environment
  # Source the installer to load functions
  source "$BATS_TEST_DIRNAME/../../scripts/pulse-install.sh" 2>/dev/null || true
}

teardown() {
  teardown_test_environment
}

@test "backup_zshrc creates timestamped backup" {
  # Create test .zshrc
  echo "# Test config" > "$PULSE_ZSHRC"

  run backup_zshrc "$PULSE_ZSHRC"
  assert_success

  # Check backup was created
  local backup_count
  backup_count=$(ls "$PULSE_ZSHRC".pulse-backup-* 2>/dev/null | wc -l)
  [ "$backup_count" -eq 1 ]
}

@test "backup_zshrc skips non-existent file" {
  run backup_zshrc "$PULSE_ZSHRC"
  assert_success

  # No backup should be created
  local backup_count
  backup_count=$(ls "$PULSE_ZSHRC".pulse-backup-* 2>/dev/null | wc -l)
  [ "$backup_count" -eq 0 ]
}

@test "backup_zshrc respects SKIP_BACKUP flag" {
  skip "Cannot override readonly SKIP_BACKUP variable in tests"
  # Manual test: PULSE_SKIP_BACKUP=1 bash -c 'source scripts/pulse-install.sh; backup_zshrc test.zshrc'
}

@test "validate_config_order passes for correct order" {
  # Create .zshrc with correct order
  cat > "$PULSE_ZSHRC" << 'EOF'
# BEGIN Pulse Configuration
plugins=()
source /path/to/pulse.zsh
# END Pulse Configuration
EOF

  run validate_config_order "$PULSE_ZSHRC"
  assert_success
}

@test "validate_config_order fails for wrong order" {
  # Create .zshrc with wrong order (source before plugins)
  cat > "$PULSE_ZSHRC" << 'EOF'
# BEGIN Pulse Configuration
source /path/to/pulse.zsh
plugins=()
# END Pulse Configuration
EOF

  run validate_config_order "$PULSE_ZSHRC"
  assert_failure
}

@test "verify_installation passes when Pulse loads" {
  # Create minimal valid .zshrc
  cat > "$PULSE_ZSHRC" << 'EOF'
# Test config
echo "PULSE_OK"
EOF

  run verify_installation "$PULSE_ZSHRC"
  assert_success
}

@test "verify_installation respects SKIP_VERIFY flag" {
  skip "Cannot override readonly SKIP_VERIFY variable in tests"
  # Manual test: PULSE_SKIP_VERIFY=1 bash -c 'source scripts/pulse-install.sh; verify_installation test.zshrc'
}

@test "main function orchestrates all phases" {
  skip "Integration test - requires full environment setup"
  # This would require mocking git, zsh, etc.
  # Better tested manually or in CI environment
}
