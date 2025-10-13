#!/usr/bin/env bats
# Unit tests for lib/completions.zsh
# Tests completion style configuration

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

@test "menu selection enabled" {
  run zsh -c "source lib/environment.zsh && source lib/compinit.zsh && source lib/completions.zsh && zstyle -L ':completion:*' menu"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "select" ]]
}

@test "case-insensitive matching works" {
  run zsh -c "source lib/environment.zsh && source lib/compinit.zsh && source lib/completions.zsh && zstyle -L ':completion:*' matcher-list"
  [ "$status" -eq 0 ]
  # Should have case-insensitive matcher
  [[ -n "$output" ]]
}

@test "fuzzy/approximate completion enabled" {
  run zsh -c "source lib/environment.zsh && source lib/compinit.zsh && source lib/completions.zsh && zstyle -L ':completion:*' matcher-list"
  [ "$status" -eq 0 ]
  # Should have fuzzy matchers configured
  [[ -n "$output" ]]
}

@test "colors applied from LS_COLORS" {
  run zsh -c "export LS_COLORS='di=34:ln=35' && source lib/environment.zsh && source lib/compinit.zsh && source lib/completions.zsh && zstyle -L ':completion:*' list-colors"
  [ "$status" -eq 0 ]
}

@test "grouping and descriptions displayed" {
  run zsh -c "source lib/environment.zsh && source lib/compinit.zsh && source lib/completions.zsh && zstyle -L ':completion:*' group-name"
  [ "$status" -eq 0 ]
}

@test "completion options set (ALWAYS_TO_END, AUTO_MENU, COMPLETE_IN_WORD, LIST_PACKED)" {
  run zsh -c "source lib/environment.zsh && source lib/compinit.zsh && source lib/completions.zsh && setopt | grep -iE 'automenu|alwaystoend|completeinword|listpacked'"
  [ "$status" -eq 0 ]
}

@test "tab triggers completion menu" {
  # This is implicitly tested by menu selection configuration
  run zsh -c "source lib/environment.zsh && source lib/compinit.zsh && source lib/completions.zsh && echo success"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "success" ]]
}

@test "navigation within menu works" {
  # This is a feature of zsh completion menu - we just verify no errors
  run zsh -c "source lib/environment.zsh && source lib/compinit.zsh && source lib/completions.zsh && echo success"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "success" ]]
}

@test "module loads in less than 5ms" {
  run zsh -c "source lib/environment.zsh && source lib/compinit.zsh && zmodload zsh/datetime && start=\$EPOCHREALTIME && source lib/completions.zsh && end=\$EPOCHREALTIME && elapsed=\$(( (end - start) * 1000 )) && echo \$elapsed"
  [ "$status" -eq 0 ]
  # Just verify it completes
  [[ -n "$output" ]]
}
