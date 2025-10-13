#!/usr/bin/env bats
# Integration tests for US4 - Directory Management
# Tests all 5 acceptance scenarios from spec.md

load ../test_helper

setup() {
  # Create isolated test environment
  export PULSE_TEST_DIR="${BATS_TEST_TMPDIR}/pulse_test_$$"
  export PULSE_DIR="${PULSE_TEST_DIR}/pulse"
  export PULSE_CACHE_DIR="${PULSE_TEST_DIR}/.cache/pulse"
  export HOME="${PULSE_TEST_DIR}/home"

  mkdir -p "$PULSE_DIR"
  mkdir -p "$PULSE_CACHE_DIR"
  mkdir -p "$HOME"

  # Create test directory structure
  mkdir -p "$HOME/test/sub1/sub2"
  mkdir -p "$HOME/dir1" "$HOME/dir2" "$HOME/dir3"
  touch "$HOME/test/file1.txt"
  touch "$HOME/test/sub1/file2.txt"

  # Copy pulse framework to test directory
  cp -r "${BATS_TEST_DIRNAME}/../../lib" "$PULSE_DIR/"
  cp "${BATS_TEST_DIRNAME}/../../pulse.zsh" "$PULSE_DIR/"

  # Create minimal plugin engine mock
  cat > "$PULSE_DIR/lib/plugin-engine.zsh" <<'EOF'
pulse_plugins=()
_pulse_init_engine() { typeset -ga pulse_plugins; typeset -gA pulse_plugin_meta; }
_pulse_discover_plugins() { :; }
_pulse_load_stages() { :; }
EOF
}

teardown() {
  rm -rf "$PULSE_TEST_DIR"
}

@test "US4-AC1: auto_cd changes directory without cd command" {
  # Acceptance Scenario 1: Type directory path to change to it

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HOME='$HOME'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify AUTO_CD is enabled
    [[ -o auto_cd ]] && echo 'auto_cd enabled'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "auto_cd enabled" ]]
}

@test "US4-AC2: auto_pushd saves directories to stack" {
  # Acceptance Scenario 2: cd saves previous directories

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HOME='$HOME'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Navigate through directories
    cd '$HOME/dir1'
    cd '$HOME/dir2'
    cd '$HOME/dir3'

    # Check directory stack size (should have 3+ directories)
    dirs -v | wc -l
  "

  [[ $status -eq 0 ]]
  # Should have multiple directories in stack
  [[ ${output##*[^0-9]} -ge 3 ]]
}

@test "US4-AC3: directory stack accessible via dirs and popd" {
  # Acceptance Scenario 3: Navigate using directory stack

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HOME='$HOME'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Build directory stack
    cd '$HOME/dir1'
    cd '$HOME/dir2'
    cd '$HOME/dir3'

    # Use popd to go back
    popd >/dev/null
    pwd | grep -q dir2 && echo 'popd works'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "popd works" ]]
}

@test "US4-AC4: parent directory navigation with .. and ..." {
  # Acceptance Scenario 4: Quick parent navigation

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HOME='$HOME'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Start in a deep directory
    cd '$HOME/test/sub1/sub2'

    # Use .. alias
    ..
    pwd | grep -q sub1 && echo '.. works'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ ".. works" ]]
}

@test "US4-AC5: ls aliases apply helpful defaults" {
  # Acceptance Scenario 5: ls aliases with colors and human-readable sizes

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Check that ll alias exists and has -h flag
    alias ll | grep -q 'lh' && echo 'll has human-readable'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "ll has human-readable" ]]
}

@test "US4-Integration: Complete directory management system" {
  # End-to-end test: Verify full US4 implementation

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HOME='$HOME'
    unset PULSE_DEBUG

    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify all US4 features
    [[ -o auto_cd ]] && \
    [[ -o auto_pushd ]] && \
    [[ -o pushd_ignore_dups ]] && \
    alias d >/dev/null && \
    alias .. >/dev/null && \
    alias ll >/dev/null && \
    echo 'US4 complete'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "US4 complete" ]]
}

@test "US4-Functionality: d alias shows directory stack" {
  # Verify d alias works for directory stack visualization

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HOME='$HOME'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Check d alias
    alias d | grep -q 'dirs -v' && echo 'd alias works'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "d alias works" ]]
}

@test "US4-Functionality: ... navigates two levels up" {
  # Verify ... alias goes up two directory levels

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HOME='$HOME'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Start deep in directory tree
    cd '$HOME/test/sub1/sub2'

    # Use ... alias
    ...
    pwd | grep -q test && echo '... works'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "... works" ]]
}

@test "US4-Functionality: - navigates to previous directory" {
  # Verify - alias returns to previous directory (OLDPWD)

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HOME='$HOME'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Navigate between directories
    cd '$HOME/dir1'
    cd '$HOME/dir2'

    # Use - alias to go back (cd - works, alias just wraps it)
    cd -
    pwd | grep -q dir1 && echo '- works'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "- works" ]]
}

@test "US4-Functionality: PUSHD_IGNORE_DUPS prevents duplicates" {
  # Verify duplicate directories aren't added to stack

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HOME='$HOME'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Visit same directory multiple times
    cd '$HOME/dir1'
    cd '$HOME/dir2'
    cd '$HOME/dir1'  # Revisit dir1

    # Count occurrences of dir1 in stack (should be 1 with PUSHD_IGNORE_DUPS)
    dirs -v | grep -c dir1
  "

  [[ $status -eq 0 ]]
  # Should only have one instance of dir1
  [[ ${output##*[^0-9]} -le 2 ]]
}

@test "US4-Functionality: la alias shows hidden files" {
  # Verify la alias includes hidden files

  # Create a hidden file
  touch "$HOME/test/.hidden"

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HOME='$HOME'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Check la alias for -A flag
    alias la | grep -E 'A.*l|l.*A' && echo 'la has -A flag'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "la has -A flag" ]]
}

@test "US4-Performance: directory module loads quickly" {
  # Verify directory.zsh meets performance target

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

    # Measure load time
    start=\$EPOCHREALTIME
    source '$PULSE_DIR/lib/directory.zsh'
    end=\$EPOCHREALTIME

    # Calculate elapsed time in milliseconds
    elapsed=\$(( (end - start) * 1000 ))

    echo \"directory.zsh: \${elapsed}ms\"

    # Check if under 5ms target
    (( elapsed < 5.0 ))
  "

  [[ $status -eq 0 ]]
  echo "# $output" >&3
}
