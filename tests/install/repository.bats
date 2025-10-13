#!/usr/bin/env bats
# T011: Repository cloning/updating tests (RED phase)

load test_helper

setup() {
  setup_clean_environment
  # Source the installer to load functions
  source "$BATS_TEST_DIRNAME/../../scripts/pulse-install.sh" 2>/dev/null || true
}

teardown() {
  teardown_test_environment
}

@test "clone_or_update_repo clones fresh repository" {
  # Mock git clone
  git() {
    if [ "$1" = "clone" ]; then
      # Simulate successful clone
      mkdir -p "$4/.git"
      echo "Cloning into '$4'..."
      return 0
    fi
    command git "$@"
  }
  export -f git
  
  run clone_or_update_repo "https://github.com/test/repo.git" "$PULSE_INSTALL_DIR"
  assert_success
  assert_dir_exists "$PULSE_INSTALL_DIR/.git"
}

@test "clone_or_update_repo updates existing repository" {
  # Create mock existing installation
  mkdir -p "$PULSE_INSTALL_DIR/.git"
  
  # Mock git pull
  git() {
    if [ "$1" = "-C" ] && [ "$3" = "pull" ]; then
      echo "Already up to date."
      return 0
    fi
    command git "$@"
  }
  export -f git
  
  run clone_or_update_repo "https://github.com/test/repo.git" "$PULSE_INSTALL_DIR"
  assert_success
  assert_output --partial "up to date"
}

@test "clone_or_update_repo fails on git clone error" {
  # Mock git clone failure
  git() {
    if [ "$1" = "clone" ]; then
      echo "fatal: repository not found" >&2
      return 128
    fi
    command git "$@"
  }
  export -f git
  
  run clone_or_update_repo "https://github.com/invalid/repo.git" "$PULSE_INSTALL_DIR"
  assert_failure
  [ "$status" -eq "$EXIT_DOWNLOAD_FAILED" ]
}

@test "clone_or_update_repo fails on git pull error" {
  # Create mock existing installation
  mkdir -p "$PULSE_INSTALL_DIR/.git"
  
  # Mock git pull failure
  git() {
    if [ "$1" = "-C" ] && [ "$3" = "pull" ]; then
      echo "error: unable to update" >&2
      return 1
    fi
    command git "$@"
  }
  export -f git
  
  run clone_or_update_repo "https://github.com/test/repo.git" "$PULSE_INSTALL_DIR"
  assert_failure
  [ "$status" -eq "$EXIT_DOWNLOAD_FAILED" ]
}

@test "clone_or_update_repo handles missing .git directory gracefully" {
  # Create directory without .git (corrupted state)
  mkdir -p "$PULSE_INSTALL_DIR"
  echo "some file" > "$PULSE_INSTALL_DIR/file.txt"
  
  # Should detect and re-clone
  git() {
    if [ "$1" = "clone" ]; then
      mkdir -p "$4/.git"
      return 0
    fi
    command git "$@"
  }
  export -f git
  
  run clone_or_update_repo "https://github.com/test/repo.git" "$PULSE_INSTALL_DIR"
  assert_success
}
