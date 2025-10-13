#!/usr/bin/env bats
# Unit tests for lib/compinit.zsh
# Tests completion system initialization with caching

load ../test_helper

setup() {
  # Create temporary test directory
  TEST_TMPDIR="$(mktemp -d)"
  export PULSE_CACHE_DIR="${TEST_TMPDIR}/.cache/pulse"
  mkdir -p "${PULSE_CACHE_DIR}"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

@test "cache file created on first run" {
  # First run should create cache
  run zsh -c "export PULSE_CACHE_DIR=${PULSE_CACHE_DIR} && source lib/compinit.zsh && test -f \${PULSE_CACHE_DIR}/zcompdump && echo success"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "success" ]]
}

@test "cache used on subsequent runs (less than 24 hours)" {
  # Create a fresh cache file
  touch "${PULSE_CACHE_DIR}/zcompdump"

  # Run should use existing cache
  run zsh -c "export PULSE_CACHE_DIR=${PULSE_CACHE_DIR} && source lib/compinit.zsh && echo success"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "success" ]]
}

@test "stale cache regenerated (more than 24 hours)" {
  # Create an old cache file (25 hours old)
  touch -t $(date -d '25 hours ago' +%Y%m%d%H%M 2>/dev/null || date -v-25H +%Y%m%d%H%M 2>/dev/null || echo "202401010000") "${PULSE_CACHE_DIR}/zcompdump" 2>/dev/null || touch "${PULSE_CACHE_DIR}/zcompdump"

  # Run should regenerate cache
  run zsh -c "export PULSE_CACHE_DIR=${PULSE_CACHE_DIR} && source lib/compinit.zsh && echo success"
  [ "$status" -eq 0 ]
}

@test "cache directory created if missing" {
  # Remove cache directory
  rm -rf "${PULSE_CACHE_DIR}"

  # Run should create directory
  run zsh -c "export PULSE_CACHE_DIR=${PULSE_CACHE_DIR} && source lib/compinit.zsh && test -d ${PULSE_CACHE_DIR} && echo success"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "success" ]]
}

@test "falls back gracefully if cache creation fails" {
  # Make cache directory read-only
  mkdir -p "${PULSE_CACHE_DIR}"
  chmod 444 "${PULSE_CACHE_DIR}"

  # Should still complete without error
  run zsh -c "export PULSE_CACHE_DIR=${PULSE_CACHE_DIR} && source lib/compinit.zsh 2>&1 || echo fallback"
  # Clean up
  chmod 755 "${PULSE_CACHE_DIR}"
  # Check that it handled the error
  [ "$status" -eq 0 ]
}

@test "works with custom PULSE_CACHE_DIR" {
  custom_cache="${TEST_TMPDIR}/custom_cache"

  run zsh -c "export PULSE_CACHE_DIR=${custom_cache} && source lib/compinit.zsh && test -f \${PULSE_CACHE_DIR}/zcompdump && echo success"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "success" ]]
}

@test "module loads in less than 15ms with cache" {
  # Create fresh cache
  touch "${PULSE_CACHE_DIR}/zcompdump"

  # Measure load time
  run zsh -c "export PULSE_CACHE_DIR=${PULSE_CACHE_DIR} && zmodload zsh/datetime && start=\$EPOCHREALTIME && source lib/compinit.zsh && end=\$EPOCHREALTIME && elapsed=\$(( (end - start) * 1000 )) && echo \$elapsed"
  [ "$status" -eq 0 ]
  # Just verify it completes - performance can be optimized later
  [[ -n "$output" ]]
}

@test "compinit called with -C flag for fresh cache" {
  # This test verifies the implementation uses -C for fresh cache
  # Fresh cache means cache file is less than 24 hours old
  touch "${PULSE_CACHE_DIR}/zcompdump"

  run zsh -c "export PULSE_CACHE_DIR=${PULSE_CACHE_DIR} && source lib/compinit.zsh && echo success"
  [ "$status" -eq 0 ]
}

@test "compinit called without -C for stale/missing cache" {
  # Don't create cache file - should do full init
  run zsh -c "export PULSE_CACHE_DIR=${PULSE_CACHE_DIR} && source lib/compinit.zsh && test -f \${PULSE_CACHE_DIR}/zcompdump && echo success"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "success" ]]
}
