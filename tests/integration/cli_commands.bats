#!/usr/bin/env bats
# Integration tests for CLI commands
# Tests pulse list, update, and doctor commands (US2)

load ../test_helper

setup() {
  # Create temporary test directory
  TEST_TMPDIR="$(mktemp -d)"
  export HOME="${TEST_TMPDIR}"
  export PULSE_DIR="${TEST_TMPDIR}/.local/share/pulse"
  export PULSE_CACHE_DIR="${TEST_TMPDIR}/.cache/pulse"
  export PULSE_LOCK_FILE="${PULSE_DIR}/plugins.lock"
  mkdir -p "${PULSE_DIR}/plugins"
  mkdir -p "${PULSE_CACHE_DIR}"

  # Use mock plugins from fixtures
  export MOCK_PLUGINS_DIR="${PULSE_ROOT}/tests/fixtures/mock-plugins"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

# Test: pulse list shows installed plugins in table format
@test "pulse list shows installed plugins in table format" {
  # Setup: Install 3 plugins and create lock file
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'

    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh

    # Initialize and install plugins
    _pulse_init_engine

    plugins=(
      '${MOCK_PLUGINS_DIR}/plugin-a'
      '${MOCK_PLUGINS_DIR}/plugin-b'
      '${MOCK_PLUGINS_DIR}/plugin-c'
    )

    _pulse_discover_plugins
  "

  [ "$status" -eq 0 ]

    # Now run pulse list command with environment variables
  run env PULSE_DIR="${PULSE_DIR}" PULSE_LOCK_FILE="${PULSE_LOCK_FILE}" ${PULSE_ROOT}/bin/pulse list

  [ "$status" -eq 0 ]
  [[ "$output" =~ "PLUGIN" ]]  # Table header
  [[ "$output" =~ "VERSION" ]] # Table header
  [[ "$output" =~ "COMMIT" ]]  # Table header
  [[ "$output" =~ "plugin-a" ]]
  [[ "$output" =~ "plugin-b" ]]
  [[ "$output" =~ "plugin-c" ]]
}

# Test: pulse list with no plugins shows helpful message
@test "pulse list with no plugins shows helpful message" {
  # Clean environment - no plugins installed
  run ${PULSE_ROOT}/bin/pulse list

  [ "$status" -eq 2 ]
  [[ "$output" =~ "No plugins installed" ]]
}

# ============================================================================
# pulse update command tests (T019)
# ============================================================================

# Test: pulse update with no lock file shows error
@test "pulse update with no lock file shows helpful message" {
  # Clean environment - no plugins installed
  run ${PULSE_ROOT}/bin/pulse update

  [ "$status" -eq 2 ]
  [[ "$output" =~ "No plugins installed" ]]
}

# Test: pulse update with nonexistent plugin shows error
@test "pulse update with nonexistent plugin shows error" {
  # Setup: Create lock file with one plugin
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source ${PULSE_ROOT}/lib/cli/lib/lock-file.zsh
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    plugins=('${MOCK_PLUGINS_DIR}/plugin-a')
    _pulse_discover_plugins
  "

  # Try to update nonexistent plugin
  run ${PULSE_ROOT}/bin/pulse update nonexistent-plugin

  [ "$status" -eq 1 ]
  [[ "$output" =~ "Plugin not found" ]]
}

# Test: pulse update skips local plugins (no URL)
@test "pulse update skips local plugins" {
  # Setup: Create a lock file with a local plugin (no URL)
  cat > "${PULSE_LOCK_FILE}" <<'EOF'
[plugin-a]
url =
ref =
commit =
timestamp = 2024-01-01T00:00:00Z
stage = normal
EOF

  # Run update (should skip local plugin)
  run ${PULSE_ROOT}/bin/pulse update

  [ "$status" -eq 0 ]  # Success
  [[ "$output" =~ "summary" ]]
  [[ "$output" =~ "Skipped: 1" ]] || [[ "$output" =~ "Up-to-date: 1" ]]
}

# Test: pulse update --check-only shows available updates without updating
@test "pulse update --check-only shows updates without applying them" {
  skip "Complex test - requires mock git remotes with different commits"

  # This test would require:
  # 1. Creating mock git repos with remote tracking
  # 2. Installing plugins from those mocks
  # 3. Advancing the remote repo (new commit)
  # 4. Running pulse update --check-only
  # 5. Verifying plugin directory unchanged but update reported
}

#
# pulse doctor tests
#

# Test: pulse doctor checks git availability
@test "pulse doctor checks git availability" {
  run ${PULSE_ROOT}/bin/pulse doctor

  [ "$status" -eq 0 ]  # Should pass (git installed on test system)
  [[ "$output" =~ "git" ]] || [[ "$output" =~ "Git" ]]
  [[ "$output" =~ "✓" ]] || [[ "$output" =~ "✔" ]] || [[ "$output" =~ "[OK]" ]]
}

# Test: pulse doctor checks network connectivity
@test "pulse doctor checks network connectivity" {
  run ${PULSE_ROOT}/bin/pulse doctor

  [ "$status" -eq 0 ]
  [[ "$output" =~ "network" ]] || [[ "$output" =~ "Network" ]] || [[ "$output" =~ "github" ]]
}

# Test: pulse doctor validates lock file
@test "pulse doctor validates lock file" {
  # Setup: Create invalid lock file
  cat > "${PULSE_LOCK_FILE}" <<'EOF'
[plugin-a]
invalid syntax here
no equals signs
EOF

  run ${PULSE_ROOT}/bin/pulse doctor

  # Should fail due to invalid lock file
  [ "$status" -eq 1 ]
  [[ "$output" =~ "lock" ]] || [[ "$output" =~ "Lock" ]]
  [[ "$output" =~ "✗" ]] || [[ "$output" =~ "✘" ]] || [[ "$output" =~ "[FAIL]" ]]
}

# Test: pulse doctor shows all checks passed
@test "pulse doctor shows all checks passed" {
  # Setup: Valid lock file
  cat > "${PULSE_LOCK_FILE}" <<'EOF'
[plugin-a]
url = https://github.com/user/plugin-a
ref = main
commit = abc123
timestamp = 2024-01-01T00:00:00Z
stage = normal
EOF

  # Ensure plugin directory exists
  mkdir -p "${PULSE_DIR}/plugins/plugin-a/.git"

  run ${PULSE_ROOT}/bin/pulse doctor

  [ "$status" -eq 0 ]  # All checks passed
  [[ "$output" =~ "✓" ]] || [[ "$output" =~ "✔" ]] || [[ "$output" =~ "[OK]" ]]
}
