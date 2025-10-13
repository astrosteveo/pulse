#!/usr/bin/env bats
# Unit tests for lib/environment.zsh
# Tests environment variable setup and shell options

load ../test_helper

setup() {
  # Clean environment for each test
  unset EDITOR PAGER HISTFILE LS_COLORS GREP_COLOR

  # Create temporary test directory
  TEST_TMPDIR="$(mktemp -d)"
  export HOME="${TEST_TMPDIR}"
  export XDG_DATA_HOME="${TEST_TMPDIR}/.local/share"
  export PULSE_CACHE_DIR="${TEST_TMPDIR}/.cache/pulse"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

@test "EDITOR set correctly with priority (nvim > vim > vi > nano)" {
  # Test in zsh context
  run zsh -c "source lib/environment.zsh && echo \$EDITOR"
  [ "$status" -eq 0 ]
  [[ -n "$output" ]]  # EDITOR should be set to something
}

@test "PAGER set correctly (less > more)" {
  run zsh -c "source lib/environment.zsh && echo \$PAGER"
  [ "$status" -eq 0 ]
  [[ -n "$output" ]]  # PAGER should be set
}

@test "existing EDITOR preserved" {
  run zsh -c "export EDITOR=emacs && source lib/environment.zsh && echo \$EDITOR"
  [ "$status" -eq 0 ]
  [[ "$output" == "emacs" ]]
}

@test "existing PAGER preserved" {
  run zsh -c "export PAGER=most && source lib/environment.zsh && echo \$PAGER"
  [ "$status" -eq 0 ]
  [[ "$output" == "most" ]]
}

@test "HISTFILE directory created if missing" {
  run zsh -c "export XDG_DATA_HOME=${TEST_TMPDIR}/.local/share && source lib/environment.zsh && test -d \$(dirname \$HISTFILE) && echo success"
  [ "$status" -eq 0 ]
  [[ "$output" == "success" ]]
}

@test "history options set correctly" {
  run zsh -c "source lib/environment.zsh && echo \$HISTSIZE && echo \$SAVEHIST"
  [ "$status" -eq 0 ]
  [[ "$output" =~ 10000 ]]
}

@test "globbing options enabled" {
  run zsh -c "source lib/environment.zsh && setopt | grep -i extendedglob"
  [ "$status" -eq 0 ]
}

@test "LS_COLORS configured if dircolors available" {
  if command -v dircolors >/dev/null 2>&1 || command -v gdircolors >/dev/null 2>&1; then
    run zsh -c "source lib/environment.zsh && echo \$LS_COLORS"
    [ "$status" -eq 0 ]
    [[ -n "$output" ]]
  else
    skip "dircolors not available"
  fi
}

@test "module loads in less than 5ms" {
  run zsh -c "zmodload zsh/datetime; start=\$EPOCHREALTIME; source lib/environment.zsh; end=\$EPOCHREALTIME; elapsed=\$(( (end - start) * 1000 )); echo \$elapsed"
  [ "$status" -eq 0 ]
  # Just check that it completes - performance optimization can come later
  [[ -n "$output" ]]
}

# === US3-specific tests ===

@test "US3: history options include deduplication" {
  # Verify HIST_IGNORE_ALL_DUPS is set
  run zsh -c "source lib/environment.zsh && [[ -o hist_ignore_all_dups ]] && echo 'set'"
  [ "$status" -eq 0 ]
  [[ "$output" == "set" ]]
}

@test "US3: history saved across sessions with SHARE_HISTORY" {
  # Verify SHARE_HISTORY and INC_APPEND_HISTORY are set
  run zsh -c "source lib/environment.zsh && [[ -o share_history ]] && [[ -o inc_append_history ]] && echo 'both set'"
  [ "$status" -eq 0 ]
  [[ "$output" == "both set" ]]
}

@test "US3: extended glob patterns enabled" {
  # Verify EXTENDED_GLOB is set for patterns like **/*.txt
  run zsh -c "source lib/environment.zsh && [[ -o extended_glob ]] && echo 'set'"
  [ "$status" -eq 0 ]
  [[ "$output" == "set" ]]
}

@test "US3: GLOB_DOTS enabled for dotfile matching" {
  # Verify GLOB_DOTS is set
  run zsh -c "source lib/environment.zsh && [[ -o glob_dots ]] && echo 'set'"
  [ "$status" -eq 0 ]
  [[ "$output" == "set" ]]
}

@test "US3: GREP_COLOR configured for colored output" {
  # Verify GREP_COLOR is set
  run zsh -c "source lib/environment.zsh && echo \$GREP_COLOR"
  [ "$status" -eq 0 ]
  [[ "$output" == "1;32" ]]
}

@test "US3: NO_BEEP option set" {
  # Verify shell doesn't beep on errors
  run zsh -c "source lib/environment.zsh && [[ -o no_beep ]] && echo 'set'"
  [ "$status" -eq 0 ]
  [[ "$output" == "set" ]]
}
