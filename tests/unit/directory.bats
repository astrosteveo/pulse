#!/usr/bin/env bats
# Unit tests for lib/directory.zsh
# Tests directory navigation and management features

load ../test_helper

setup() {
  # Create isolated test environment
  export PULSE_TEST_DIR="${BATS_TEST_TMPDIR}/pulse_test_$$"
  export PULSE_DIR="${PULSE_TEST_DIR}/pulse"
  export PULSE_CACHE_DIR="${PULSE_TEST_DIR}/.cache/pulse"

  mkdir -p "$PULSE_DIR/lib"
  mkdir -p "$PULSE_CACHE_DIR"

  # Copy directory module to test directory (will be created by implementation)
  if [[ -f "${BATS_TEST_DIRNAME}/../../lib/directory.zsh" ]]; then
    cp "${BATS_TEST_DIRNAME}/../../lib/directory.zsh" "$PULSE_DIR/lib/"
  fi
}

teardown() {
  rm -rf "$PULSE_TEST_DIR"
}

@test "AUTO_CD option enabled" {
  # Verify AUTO_CD allows changing directory without cd command

  run zsh -c "
    source '$PULSE_DIR/lib/directory.zsh'

    # Check if AUTO_CD option is set
    [[ -o auto_cd ]] && echo 'set'
  "

  [[ $status -eq 0 ]]
  [[ "$output" == "set" ]]
}

@test "AUTO_PUSHD option enabled" {
  # Verify AUTO_PUSHD saves directories to stack automatically

  run zsh -c "
    source '$PULSE_DIR/lib/directory.zsh'

    # Check if AUTO_PUSHD option is set
    [[ -o auto_pushd ]] && echo 'set'
  "

  [[ $status -eq 0 ]]
  [[ "$output" == "set" ]]
}

@test "PUSHD_IGNORE_DUPS prevents duplicates in directory stack" {
  # Verify duplicate directories aren't added to stack

  run zsh -c "
    source '$PULSE_DIR/lib/directory.zsh'

    # Check if PUSHD_IGNORE_DUPS option is set
    [[ -o pushd_ignore_dups ]] && echo 'set'
  "

  [[ $status -eq 0 ]]
  [[ "$output" == "set" ]]
}

@test "PUSHD_SILENT reduces noise" {
  # Verify PUSHD_SILENT suppresses directory stack output

  run zsh -c "
    source '$PULSE_DIR/lib/directory.zsh'

    # Check if PUSHD_SILENT option is set
    [[ -o pushd_silent ]] && echo 'set'
  "

  [[ $status -eq 0 ]]
  [[ "$output" == "set" ]]
}

@test "directory stack alias 'd' works" {
  # Verify 'd' alias shows directory stack

  run zsh -c "
    source '$PULSE_DIR/lib/directory.zsh'

    # Check if 'd' alias is defined
    alias d | grep -q 'dirs -v'
  "

  [[ $status -eq 0 ]]
}

@test "navigation alias '..' works" {
  # Verify '..' alias for parent directory

  run zsh -c "
    source '$PULSE_DIR/lib/directory.zsh'

    # Check if '..' alias is defined
    alias .. | grep -q 'cd ..'
  "

  [[ $status -eq 0 ]]
}

@test "navigation alias '...' works" {
  # Verify '...' alias for two levels up

  run zsh -c "
    source '$PULSE_DIR/lib/directory.zsh'

    # Check if '...' alias is defined
    alias ... | grep -q 'cd ../..'
  "

  [[ $status -eq 0 ]]
}

@test "navigation alias '-' works" {
  # Verify '-' alias for previous directory

  run zsh -c "
    source '$PULSE_DIR/lib/directory.zsh'

    # Check if '-' alias is defined
    alias -- - | grep -q 'cd -'
  "

  [[ $status -eq 0 ]]
}

@test "ls aliases configured for current OS" {
  # Verify ls aliases are set appropriately for the OS

  run zsh -c "
    source '$PULSE_DIR/lib/directory.zsh'

    # Check if basic ls aliases exist
    alias ls && alias ll && alias la && echo 'aliases set'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "aliases set" ]]
}

@test "ls alias includes color support" {
  # Verify ls alias has color enabled

  run zsh -c "
    source '$PULSE_DIR/lib/directory.zsh'

    # Check ls alias for color option
    alias ls | grep -E '(--color|-G)'
  "

  [[ $status -eq 0 ]]
}

@test "ll alias shows long format" {
  # Verify ll alias uses long format with human-readable sizes

  run zsh -c "
    source '$PULSE_DIR/lib/directory.zsh'

    # Check ll alias for -l and -h flags
    alias ll | grep -E 'lh|l.*h'
  "

  [[ $status -eq 0 ]]
}

@test "la alias shows hidden files" {
  # Verify la alias shows all files including hidden

  run zsh -c "
    source '$PULSE_DIR/lib/directory.zsh'

    # Check la alias for -A flag
    alias la | grep -E '.*-[lA]{2}|.*-A.*-l|.*-l.*-A'
  "

  [[ $status -eq 0 ]]
}

@test "module loads in less than 5ms" {
  # Verify performance target

  run zsh -c "
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

@test "PUSHD_TO_HOME disabled to preserve standard cd behavior" {
  # Verify pushd without arguments doesn't go to HOME

  run zsh -c "
    source '$PULSE_DIR/lib/directory.zsh'

    # Check if PUSHD_TO_HOME is NOT set (we want standard behavior)
    if [[ -o pushd_to_home ]]; then
      echo 'enabled'
    else
      echo 'disabled'
    fi
  "

  [[ $status -eq 0 ]]
  [[ "$output" == "disabled" ]]
}

@test "directory options don't conflict with environment module" {
  # Verify directory options work with environment module

  run zsh -c "
    # Load environment first (as it would in pulse.zsh)
    source '${BATS_TEST_DIRNAME}/../../lib/environment.zsh'
    source '$PULSE_DIR/lib/directory.zsh'

    # Verify both modules loaded correctly
    [[ -o auto_cd ]] && [[ -o extended_glob ]] && echo 'both working'
  "

  [[ $status -eq 0 ]]
  [[ "$output" == "both working" ]]
}
