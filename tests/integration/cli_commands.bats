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

# Test: pulse list does not show verbose debug output (regression test)
@test "pulse list shows clean output without verbose debug info" {
  # Create lock file with multiple plugins
  cat > "${PULSE_LOCK_FILE}" <<'EOF'
[plugin-a]
url = https://github.com/user/plugin-a
ref = main
commit = abc123def456
timestamp = 2024-01-01T00:00:00Z
stage = normal

[plugin-b]
url = https://github.com/user/plugin-b
ref = 
commit = 111222333444
timestamp = 2024-01-01T00:00:00Z
stage = defer

[plugin-c]
url = https://github.com/user/plugin-c
ref = v1.0.0
commit = fedcba987654
timestamp = 2024-01-01T00:00:00Z
stage = early
EOF

  run ${PULSE_ROOT}/bin/pulse list

  [ "$status" -eq 0 ]
  
  # Verify header is present with proper formatting
  [[ "$output" =~ ^PLUGIN[[:space:]]+VERSION[[:space:]]+COMMIT ]]
  
  # Should NOT contain verbose field output like "url=..." or "ref=..." or "commit=..."
  [[ ! "$output" =~ "url=" ]]
  [[ ! "$output" =~ "ref=" ]]
  [[ ! "$output" =~ "commit=" ]]
  [[ ! "$output" =~ "timestamp=" ]]
  [[ ! "$output" =~ "stage=" ]]
  
  # Should contain the plugin names in clean table format
  [[ "$output" =~ "plugin-a" ]]
  [[ "$output" =~ "plugin-b" ]]
  [[ "$output" =~ "plugin-c" ]]
  
  # Verify specific ref values: plugin-b with empty ref shows "(default)"
  [[ "$output" =~ plugin-b[[:space:]]+\(default\) ]]
  # plugin-a should show "main"
  [[ "$output" =~ plugin-a[[:space:]]+main ]]
  # plugin-c should show "v1.0.0"
  [[ "$output" =~ plugin-c[[:space:]]+v1\.0\.0 ]]
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

@test "pulse update reports git pull failures" {
  local remote_dir="${TEST_TMPDIR}/remotes/plugin-fail.git"
  local source_dir="${TEST_TMPDIR}/sources/plugin-fail"
  local plugin_dir="${PULSE_DIR}/plugins/plugin-fail"

  mkdir -p "$(dirname "$remote_dir")" "$(dirname "$source_dir")" "$(dirname "$plugin_dir")"

  git init --bare -q "$remote_dir"
  git init -q "$source_dir"
  git -C "$source_dir" config user.email "test@example.com"
  git -C "$source_dir" config user.name "Test User"

  echo "Initial" > "${source_dir}/README.md"
  git -C "$source_dir" add README.md
  git -C "$source_dir" commit -q -m "Initial commit"
  git -C "$source_dir" branch -M main
  git -C "$source_dir" remote add origin "$remote_dir"
  git -C "$source_dir" push -q origin main

  git clone -q -b main "$remote_dir" "$plugin_dir"
  local local_commit
  local_commit=$(git -C "$plugin_dir" rev-parse HEAD)

  echo "Update" >> "${source_dir}/README.md"
  git -C "$source_dir" add README.md
  git -C "$source_dir" commit -q -m "Remote update"
  git -C "$source_dir" push -q origin main

  cat > "${PULSE_LOCK_FILE}" <<EOF
[plugin-fail]
url = $remote_dir
ref = main
commit = ${local_commit}
timestamp = 2024-01-01T00:00:00Z
stage = normal
EOF

  local mock_bin="${TEST_TMPDIR}/mock-bin"
  mkdir -p "$mock_bin"
  cat > "${mock_bin}/git" <<'EOF'
#!/usr/bin/env bash
for arg in "$@"; do
  if [[ "$arg" == "pull" ]]; then
    echo "mock git pull failure" >&2
    exit 1
  fi
done
exec /usr/bin/git "$@"
EOF
  chmod +x "${mock_bin}/git"

  run env PATH="${mock_bin}:$PATH" ${PULSE_ROOT}/bin/pulse update plugin-fail

  [ "$status" -eq 1 ]
  [[ "$output" =~ "Failed to update plugin-fail" ]]
  [[ "$output" =~ "Errors: 1" ]]
}

#
# pulse doctor tests
#

# Test: pulse doctor checks git availability
@test "pulse doctor checks git availability" {
  run ${PULSE_ROOT}/bin/pulse doctor

  # Don't check exit code - other checks may fail
  [[ "$output" =~ "git" ]] || [[ "$output" =~ "Git" ]]
  [[ "$output" =~ "✓" ]] || [[ "$output" =~ "✔" ]] || [[ "$output" =~ "[OK]" ]]
}

# Test: pulse doctor checks network connectivity
@test "pulse doctor checks network connectivity" {
  run ${PULSE_ROOT}/bin/pulse doctor

  # Just check that network is mentioned (may pass or fail depending on connectivity)
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

# Test: pulse doctor shows summary and completes
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

  # Just verify doctor runs and shows summary (exit code may vary based on environment)
  [[ "$output" =~ "Summary:" ]]
  [[ "$output" =~ "checks passed" ]]
  [[ "$output" =~ "✓" ]] || [[ "$output" =~ "✔" ]] || [[ "$output" =~ "[OK]" ]]
}

#
# CLI exit code tests
#

# Test: CLI returns 0 on success
@test "CLI returns 0 on successful list command" {
  # Setup: Valid lock file with plugin
  cat > "${PULSE_LOCK_FILE}" <<'EOF'
[plugin-a]
url = https://github.com/user/plugin-a
ref = main
commit = abc123
timestamp = 2024-01-01T00:00:00Z
stage = normal
EOF

  run ${PULSE_ROOT}/bin/pulse list

  [ "$status" -eq 0 ]  # Success exit code
}

# Test: CLI returns 2 on usage error
@test "CLI returns 2 on invalid command" {
  run ${PULSE_ROOT}/bin/pulse invalid-command-xyz

  [ "$status" -eq 2 ]  # Usage error
  [[ "$output" =~ "unknown command" ]]
  [[ "$output" =~ "pulse help" ]]
}

# Test: CLI returns proper code on missing lock file
@test "CLI returns 2 when no lock file exists" {
  # Ensure lock file doesn't exist
  rm -f "${PULSE_LOCK_FILE}"

  run ${PULSE_ROOT}/bin/pulse list

  [ "$status" -eq 2 ]  # No plugins installed
  [[ "$output" =~ "No lock file" ]] || [[ "$output" =~ "No plugins" ]]
}
