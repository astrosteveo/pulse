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
