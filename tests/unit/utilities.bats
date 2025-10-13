#!/usr/bin/env bats
# Unit tests for utilities.zsh module

load ../test_helper

# =============================================================================
# pulse_has_command() Tests
# =============================================================================

@test "pulse_has_command detects existing command (ls)" {
  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_has_command ls && echo 'found'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"found"* ]]
}

@test "pulse_has_command detects existing command (zsh)" {
  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_has_command zsh && echo 'found'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"found"* ]]
}

@test "pulse_has_command returns false for nonexistent command" {
  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_has_command this_command_does_not_exist_12345 && echo 'found' || echo 'not-found'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"not-found"* ]]
}

@test "pulse_has_command handles empty argument" {
  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_has_command '' && echo 'found' || echo 'not-found'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"not-found"* ]]
}

@test "pulse_has_command works with shell builtins" {
  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_has_command cd && echo 'found'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"found"* ]]
}

# =============================================================================
# pulse_source_if_exists() Tests
# =============================================================================

@test "pulse_source_if_exists sources existing file" {
  # Create a test file
  local test_file="${PULSE_DIR}/test_source.zsh"
  echo "export TEST_VAR='sourced'" > "$test_file"

  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_source_if_exists '$test_file'
    echo \$TEST_VAR
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"sourced"* ]]
}

@test "pulse_source_if_exists silent for missing file" {
  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_source_if_exists '/nonexistent/path/file.zsh'
    echo 'completed'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"completed"* ]]
}

@test "pulse_source_if_exists handles multiple files" {
  # Create test files
  local test_file1="${PULSE_DIR}/test1.zsh"
  local test_file2="${PULSE_DIR}/test2.zsh"
  echo "export VAR1='one'" > "$test_file1"
  echo "export VAR2='two'" > "$test_file2"

  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_source_if_exists '$test_file1'
    pulse_source_if_exists '$test_file2'
    echo \$VAR1-\$VAR2
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"one-two"* ]]
}

@test "pulse_source_if_exists handles empty path" {
  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_source_if_exists ''
    echo 'completed'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"completed"* ]]
}

# =============================================================================
# pulse_os_type() Tests
# =============================================================================

@test "pulse_os_type detects operating system" {
  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    os=\$(pulse_os_type)
    echo \"OS: \$os\"
  "

  [ "$status" -eq 0 ]
  # Should detect one of: linux, macos, freebsd, openbsd, netbsd, other
  [[ "$output" =~ (linux|macos|freebsd|openbsd|netbsd|other) ]]
}

@test "pulse_os_type returns lowercase" {
  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    os=\$(pulse_os_type)
    # Check that output is lowercase
    [[ \$os == \${os:l} ]] && echo 'lowercase'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"lowercase"* ]]
}

@test "pulse_os_type is consistent across calls" {
  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    os1=\$(pulse_os_type)
    os2=\$(pulse_os_type)
    [[ \$os1 == \$os2 ]] && echo 'consistent'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"consistent"* ]]
}

# =============================================================================
# pulse_extract() Tests
# =============================================================================

@test "pulse_extract detects tar.gz format" {
  # Create a test tar.gz
  local test_dir="${PULSE_DIR}/extract_test"
  mkdir -p "$test_dir"
  echo "test content" > "$test_dir/file.txt"

  run zsh -c "
    cd '${PULSE_DIR}'
    tar czf test.tar.gz -C extract_test .
    rm -rf extract_test
    mkdir extract_test

    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_extract test.tar.gz extract_test

    [[ -f extract_test/file.txt ]] && echo 'extracted'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"extracted"* ]]
}

@test "pulse_extract detects zip format" {
  # Skip if zip not available
  command -v zip &>/dev/null || skip "zip not installed"

  local test_dir="${PULSE_DIR}/zip_test"
  mkdir -p "$test_dir"
  echo "zip content" > "$test_dir/file.txt"

  run zsh -c "
    cd '${PULSE_DIR}'
    zip -q -r test.zip zip_test/
    rm -rf zip_test
    mkdir zip_test_out

    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_extract test.zip zip_test_out

    [[ -f zip_test_out/zip_test/file.txt ]] && echo 'extracted'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"extracted"* ]]
}

@test "pulse_extract handles tar.bz2 format" {
  # Create a test tar.bz2
  local test_dir="${PULSE_DIR}/bz2_test"
  mkdir -p "$test_dir"
  echo "bz2 content" > "$test_dir/file.txt"

  run zsh -c "
    cd '${PULSE_DIR}'
    tar cjf test.tar.bz2 -C bz2_test .
    rm -rf bz2_test
    mkdir bz2_test

    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_extract test.tar.bz2 bz2_test

    [[ -f bz2_test/file.txt ]] && echo 'extracted'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"extracted"* ]]
}

@test "pulse_extract handles tar.xz format" {
  # Skip if xz not available
  command -v xz &>/dev/null || skip "xz not installed"

  local test_dir="${PULSE_DIR}/xz_test"
  mkdir -p "$test_dir"
  echo "xz content" > "$test_dir/file.txt"

  run zsh -c "
    cd '${PULSE_DIR}'
    tar cJf test.tar.xz -C xz_test .
    rm -rf xz_test
    mkdir xz_test

    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_extract test.tar.xz xz_test

    [[ -f xz_test/file.txt ]] && echo 'extracted'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"extracted"* ]]
}

@test "pulse_extract fails gracefully for unknown format" {
  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_extract unknown.xyz /tmp/test 2>&1
  "

  # Should fail or output error message
  [[ "$status" -ne 0 ]] || [[ "$output" == *"unsupported"* ]] || [[ "$output" == *"unknown"* ]]
}

@test "pulse_extract creates target directory if needed" {
  local test_dir="${PULSE_DIR}/auto_create_test"
  mkdir -p "$test_dir"
  echo "content" > "$test_dir/file.txt"

  run zsh -c "
    cd '${PULSE_DIR}'
    tar czf test_auto.tar.gz -C auto_create_test .
    rm -rf auto_create_test

    source ${PULSE_ROOT}/lib/utilities.zsh
    pulse_extract test_auto.tar.gz new_dir_created

    [[ -d new_dir_created ]] && echo 'dir-created'
    [[ -f new_dir_created/file.txt ]] && echo 'file-exists'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"dir-created"* ]]
  [[ "$output" == *"file-exists"* ]]
}

# =============================================================================
# Performance Tests
# =============================================================================

@test "utilities module loads in <3ms" {
  run zsh -c "
    start=\$(($(date +%s%N)/1000000))
    source ${PULSE_ROOT}/lib/utilities.zsh
    end=\$(($(date +%s%N)/1000000))
    elapsed=\$((end - start))
    echo \"Load time: \${elapsed}ms\"
    [[ \$elapsed -lt 3 ]] && echo 'performance-ok'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"performance-ok"* ]]
}

@test "pulse_has_command executes quickly" {
  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh
    start=\$(($(date +%s%N)/1000000))
    pulse_has_command ls >/dev/null
    pulse_has_command zsh >/dev/null
    pulse_has_command nonexistent >/dev/null
    end=\$(($(date +%s%N)/1000000))
    elapsed=\$((end - start))
    # 3 checks should be <10ms total
    [[ \$elapsed -lt 10 ]] && echo 'fast'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"fast"* ]]
}

# =============================================================================
# Integration with Framework
# =============================================================================

@test "utilities module works with other framework modules" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'

    source ${PULSE_ROOT}/lib/environment.zsh
    source ${PULSE_ROOT}/lib/utilities.zsh

    # Use utilities
    pulse_has_command ls && echo 'has-ls'
    os=\$(pulse_os_type)
    echo \"OS: \$os\"

    # Verify environment still works
    [[ -n \$EDITOR ]] && echo 'editor-set'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"has-ls"* ]]
  [[ "$output" =~ OS:\ (linux|macos|freebsd|openbsd|netbsd|other) ]]
  [[ "$output" == *"editor-set"* ]]
}

@test "utilities respect pulse_ prefix convention" {
  run zsh -c "
    source ${PULSE_ROOT}/lib/utilities.zsh

    # Check that functions are properly prefixed
    type pulse_has_command &>/dev/null && echo 'has_command'
    type pulse_source_if_exists &>/dev/null && echo 'source_if_exists'
    type pulse_os_type &>/dev/null && echo 'os_type'
    type pulse_extract &>/dev/null && echo 'extract'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"has_command"* ]]
  [[ "$output" == *"source_if_exists"* ]]
  [[ "$output" == *"os_type"* ]]
  [[ "$output" == *"extract"* ]]
}
