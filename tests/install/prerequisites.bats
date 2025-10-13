#!/usr/bin/env bats
# T007.5: Prerequisite check tests (RED phase)

load test_helper

setup() {
  # Source the installer to load functions (but prevent execution)
  source "$BATS_TEST_DIRNAME/../../scripts/pulse-install.sh" 2>/dev/null || true
}

@test "check_zsh_version succeeds with Zsh 5.0+" {
  # Mock Zsh version check
  zsh() { echo "zsh 5.9 (x86_64-pc-linux-gnu)"; }
  export -f zsh
  
  run check_zsh_version
  assert_success
}

@test "check_zsh_version fails with Zsh 4.x" {
  # Mock old Zsh version
  zsh() { echo "zsh 4.3.17 (x86_64-pc-linux-gnu)"; }
  export -f zsh
  
  run check_zsh_version
  assert_failure
  assert_output --partial "Zsh 5.0"
}

@test "check_zsh_version fails when zsh not found" {
  # Mock missing zsh
  zsh() { return 127; }
  export -f zsh
  
  run check_zsh_version
  assert_failure
  assert_output --partial "not installed"
}

@test "check_git succeeds when git is installed" {
  # Most systems have git, use real command
  run check_git
  assert_success
}

@test "check_git fails when git not found" {
  # Mock missing git
  git() { return 127; }
  export -f git
  
  run check_git
  assert_failure
  assert_output --partial "Git"
}

@test "check_write_permissions succeeds for writable directory" {
  local test_dir="$BATS_TEST_TMPDIR/writable"
  mkdir -p "$test_dir"
  
  run check_write_permissions "$test_dir"
  assert_success
}

@test "check_write_permissions fails for non-existent parent" {
  local test_dir="/nonexistent/path/pulse"
  
  run check_write_permissions "$test_dir"
  assert_failure
  assert_output --partial "permission"
}

@test "check_write_permissions fails for read-only directory" {
  local test_dir="$BATS_TEST_TMPDIR/readonly"
  mkdir -p "$test_dir"
  chmod 444 "$test_dir"
  
  run check_write_permissions "$test_dir/pulse"
  assert_failure
  
  # Cleanup
  chmod 755 "$test_dir"
}
