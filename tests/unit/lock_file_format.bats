#!/usr/bin/env bats
# Unit tests for lock file format and operations
# Tests lock file write/read functionality (US3)

load ../test_helper

setup() {
  # Create temporary test directory
  TEST_TMPDIR="$(mktemp -d)"
  export PULSE_DIR="${TEST_TMPDIR}/.local/share/pulse"
  export PULSE_LOCK_FILE="${PULSE_DIR}/plugins.lock"
  mkdir -p "${PULSE_DIR}/plugins"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

# Test: Write lock entry in INI format
@test "writes lock entry in INI format" {
  # Source the lock file library
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source lib/cli/lib/lock-file.zsh

    # Write a lock entry
    pulse_write_lock_entry 'zsh-syntax-highlighting' \
      'https://github.com/zsh-users/zsh-syntax-highlighting.git' \
      'master' \
      'abc123def456' \
      '2025-10-14T03:00:00Z' \
      'defer'

    # Verify lock file was created and contains entry
    [[ -f '${PULSE_LOCK_FILE}' ]] || exit 1
    cat '${PULSE_LOCK_FILE}'
  "

  [ "$status" -eq 0 ]

  # Verify INI format
  [[ "$output" =~ "[zsh-syntax-highlighting]" ]]
  [[ "$output" =~ "url = https://github.com/zsh-users/zsh-syntax-highlighting.git" ]]
  [[ "$output" =~ "ref = master" ]]
  [[ "$output" =~ "commit = abc123def456" ]]
  [[ "$output" =~ "timestamp = 2025-10-14T03:00:00Z" ]]
  [[ "$output" =~ "stage = defer" ]]
}

# Test: Creates lock file with header if missing
@test "creates lock file with header if missing" {
  # Ensure lock file doesn't exist
  [[ ! -f "${PULSE_LOCK_FILE}" ]]

  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source lib/cli/lib/lock-file.zsh

    # Write first entry
    pulse_write_lock_entry 'plugin-a' \
      'https://github.com/user/plugin-a.git' \
      '' \
      'commit123' \
      '2025-10-14T03:00:00Z' \
      'early'

    cat '${PULSE_LOCK_FILE}'
  "

  [ "$status" -eq 0 ]

  # Verify header exists
  [[ "$output" =~ "# Pulse Plugin Lock File" ]]
  [[ "$output" =~ "# Version:" ]]
  [[ "$output" =~ "# Generated:" ]]
  [[ "$output" =~ "# DO NOT EDIT" ]]
}

# Test: Appends to existing lock file without duplicating header
@test "appends to existing lock file without duplicating header" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source lib/cli/lib/lock-file.zsh

    # Write first entry
    pulse_write_lock_entry 'plugin-a' 'https://github.com/user/plugin-a.git' '' 'abc123' '2025-10-14T03:00:00Z' 'early'

    # Write second entry
    pulse_write_lock_entry 'plugin-b' 'https://github.com/user/plugin-b.git' 'v1.0.0' 'def456' '2025-10-14T03:01:00Z' 'defer'

    cat '${PULSE_LOCK_FILE}'
  "

  [ "$status" -eq 0 ]

  # Verify both entries exist
  [[ "$output" =~ "[plugin-a]" ]]
  [[ "$output" =~ "[plugin-b]" ]]

  # Verify header only appears once
  local header_count=$(echo "$output" | grep -c "# Pulse Plugin Lock File")
  [[ "$header_count" -eq 1 ]]
}

# Test: Handles empty ref (default branch)
@test "handles empty ref correctly in lock entry" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source lib/cli/lib/lock-file.zsh

    # Write entry with empty ref
    pulse_write_lock_entry 'plugin-latest' \
      'https://github.com/user/plugin-latest.git' \
      '' \
      'xyz789' \
      '2025-10-14T03:00:00Z' \
      'path'

    cat '${PULSE_LOCK_FILE}'
  "

  [ "$status" -eq 0 ]

  # Verify empty ref is stored correctly
  [[ "$output" =~ "[plugin-latest]" ]]
  [[ "$output" =~ "ref = " ]]
  [[ "$output" =~ "commit = xyz789" ]]
}

# Test: Escapes special characters in plugin names
@test "escapes special characters in INI section names" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source lib/cli/lib/lock-file.zsh

    # Write entry with special chars (dots, hyphens)
    pulse_write_lock_entry 'zsh-users/plugin.v2' \
      'https://github.com/user/repo.git' \
      'main' \
      'abc123' \
      '2025-10-14T03:00:00Z' \
      'fpath'

    cat '${PULSE_LOCK_FILE}'
  "

  [ "$status" -eq 0 ]

  # Verify section name is properly formatted
  [[ "$output" =~ "[zsh-users/plugin.v2]" ]]
}

# Test: Reads all plugin sections from lock file
@test "reads all plugin sections from lock file" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source lib/cli/lib/lock-file.zsh

    # Write 3 plugin entries
    pulse_write_lock_entry 'plugin-a' 'https://github.com/user/plugin-a.git' '' 'abc123' '2025-10-14T03:00:00Z' 'early'
    pulse_write_lock_entry 'plugin-b' 'https://github.com/user/plugin-b.git' 'v1.0.0' 'def456' '2025-10-14T03:01:00Z' 'path'
    pulse_write_lock_entry 'plugin-c' 'https://github.com/user/plugin-c.git' 'main' 'ghi789' '2025-10-14T03:02:00Z' 'defer'

    # Read all plugins
    pulse_read_lock_file
  "

  [ "$status" -eq 0 ]

  # Verify all 3 plugins are returned
  [[ "$output" =~ "plugin-a" ]]
  [[ "$output" =~ "plugin-b" ]]
  [[ "$output" =~ "plugin-c" ]]

  # Count number of plugins (should be 3)
  local plugin_count=$(echo "$output" | wc -l | tr -d ' ')
  [[ "$plugin_count" -eq 3 ]]
}

# Test: Reads specific plugin entry data
@test "reads specific plugin entry from lock file" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source lib/cli/lib/lock-file.zsh

    # Write test entry
    pulse_write_lock_entry 'test-plugin' \
      'https://github.com/test/plugin.git' \
      'v2.1.0' \
      'sha256abc123def' \
      '2025-10-14T03:00:00Z' \
      'completions'

    # Read the entry
    pulse_read_lock_entry 'test-plugin'
  "

  [ "$status" -eq 0 ]

  # Verify the output contains all expected fields
  [[ "$output" =~ "https://github.com/test/plugin.git" ]]
  [[ "$output" =~ "v2.1.0" ]]
  [[ "$output" =~ "sha256abc123def" ]]
  [[ "$output" =~ "2025-10-14T03:00:00Z" ]]
  [[ "$output" =~ "completions" ]]

  # Verify output is space-separated with 5 fields
  local field_count=$(echo "$output" | wc -w | tr -d ' ')
  [[ "$field_count" -eq 5 ]]
}

# Test: Returns empty/error for non-existent plugin
@test "returns error for non-existent plugin in lock file" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source lib/cli/lib/lock-file.zsh

    # Create lock file with one plugin
    pulse_write_lock_entry 'plugin-a' 'https://github.com/user/plugin-a.git' '' 'abc123' '2025-10-14T03:00:00Z' 'early'

    # Try to read non-existent plugin
    pulse_read_lock_entry 'plugin-does-not-exist'
  "

  # Should exit with success but return empty output
  [ "$status" -eq 0 ]
  [[ -z "$output" ]]
}

# Test: Returns error when lock file doesn't exist
@test "returns error when lock file does not exist" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source lib/cli/lib/lock-file.zsh

    # Try to read from non-existent lock file
    pulse_read_lock_file
  "

  # Should fail with non-zero exit code
  [ "$status" -ne 0 ]
}

# Test: Validates lock file format successfully
@test "validates lock file with correct format" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source lib/cli/lib/lock-file.zsh

    # Create valid lock file
    pulse_write_lock_entry 'plugin-a' \
      'https://github.com/user/plugin-a.git' \
      'v1.0.0' \
      'abc123def456' \
      '2025-10-14T03:00:00Z' \
      'early'

    # Validate it
    pulse_validate_lock_file
  "

  [ "$status" -eq 0 ]
}

# Test: Detects missing version header
@test "detects missing version header in lock file" {
  # Create lock file without header
  cat > "${PULSE_LOCK_FILE}" <<'EOF'
[plugin-a]
url = https://github.com/user/plugin-a.git
ref = v1.0.0
commit = abc123
timestamp = 2025-10-14T03:00:00Z
stage = early
EOF

  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source lib/cli/lib/lock-file.zsh

    pulse_validate_lock_file 2>&1
  "

  # Should return error
  [ "$status" -ne 0 ]

  # Should mention version header
  [[ "$output" =~ "version header" ]] || [[ "$output" =~ "Version:" ]]
}

# Test: Detects missing required fields
@test "detects missing commit field in plugin entry" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source lib/cli/lib/lock-file.zsh

    # Create lock file manually with missing commit field
    pulse_init_lock_file
    cat >> '${PULSE_LOCK_FILE}' <<'EOF'

[plugin-incomplete]
url = https://github.com/user/plugin.git
ref = main
timestamp = 2025-10-14T03:00:00Z
stage = early
EOF

    # Validate - should fail
    pulse_validate_lock_file 2>&1
  "

  # Should return error
  [ "$status" -ne 0 ]

  # Should mention missing commit
  [[ "$output" =~ "commit" ]]
}

# Test: Detects missing stage field
@test "detects missing stage field in plugin entry" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_LOCK_FILE='${PULSE_LOCK_FILE}'
    source lib/cli/lib/lock-file.zsh

    # Create lock file manually with missing stage field
    pulse_init_lock_file
    cat >> '${PULSE_LOCK_FILE}' <<'EOF'

[plugin-no-stage]
url = https://github.com/user/plugin.git
ref = main
commit = abc123def456
timestamp = 2025-10-14T03:00:00Z
EOF

    # Validate - should fail
    pulse_validate_lock_file 2>&1
  "

  # Should return error
  [ "$status" -ne 0 ]

  # Should mention missing stage
  [[ "$output" =~ "stage" ]]
}
