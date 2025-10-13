#!/usr/bin/env bats
# Unit tests for keybinds.zsh module
# Tests keyboard shortcuts and line editing functionality

load ../test_helper

setup() {
  # Create isolated test environment
  export PULSE_TEST_DIR="${BATS_TEST_TMPDIR}/pulse_test_$$"
  export PULSE_DIR="${PULSE_TEST_DIR}/pulse"
  export PULSE_CACHE_DIR="${PULSE_TEST_DIR}/.cache/pulse"

  mkdir -p "$PULSE_DIR/lib"
  mkdir -p "$PULSE_CACHE_DIR"

  # Copy keybinds module to test directory (will be created by implementation)
  if [[ -f "${BATS_TEST_DIRNAME}/../../lib/keybinds.zsh" ]]; then
    cp "${BATS_TEST_DIRNAME}/../../lib/keybinds.zsh" "$PULSE_DIR/lib/"
  fi
}

teardown() {
  rm -rf "$PULSE_TEST_DIR"
}

@test "emacs mode set as default" {
  # Verify that emacs mode is the default binding mode

  run zsh -c "
    source '$PULSE_DIR/lib/keybinds.zsh'

    # Check that emacs mode is active (bindkey -l shows current keymap)
    bindkey -l | grep -q '^emacs$'
  "

  [[ $status -eq 0 ]]
}

@test "Ctrl+R triggers reverse history search" {
  # Verify Ctrl+R is bound to reverse-i-search

  run zsh -c "
    source '$PULSE_DIR/lib/keybinds.zsh'

    # Check the binding for ^R
    bindkey | grep '\"\\^R\"' | grep -q 'history-incremental-search-backward'
  "

  [[ $status -eq 0 ]]
}

@test "Ctrl+S triggers forward history search" {
  # Verify Ctrl+S is bound to forward search (if not blocked by terminal)

  run zsh -c "
    source '$PULSE_DIR/lib/keybinds.zsh'

    # Check the binding for ^S
    bindkey | grep '\"\\^S\"' | grep -q 'history-incremental-search-forward'
  "

  [[ $status -eq 0 ]]
}

@test "arrows and Ctrl+P/N navigate history" {
  # Verify history navigation keys are bound

  run zsh -c "
    source '$PULSE_DIR/lib/keybinds.zsh'

    # Check up arrow or Ctrl+P for previous history
    (bindkey | grep 'up-line-or-history' || bindkey | grep 'history-substring-search-up') && \
    (bindkey | grep 'down-line-or-history' || bindkey | grep 'history-substring-search-down')
  "

  [[ $status -eq 0 ]]
}

@test "Ctrl+A/E moves to line start/end" {
  # Verify line start/end navigation

  run zsh -c "
    source '$PULSE_DIR/lib/keybinds.zsh'

    # Check Ctrl+A and Ctrl+E bindings
    bindkey | grep '\"\\^A\"' | grep -q 'beginning-of-line' && \
    bindkey | grep '\"\\^E\"' | grep -q 'end-of-line'
  "

  [[ $status -eq 0 ]]
}

@test "Ctrl+W/U/K for word/line deletion" {
  # Verify deletion shortcuts

  run zsh -c "
    source '$PULSE_DIR/lib/keybinds.zsh'

    # Check Ctrl+W (backward-kill-word), Ctrl+U (kill-whole-line), Ctrl+K (kill-line)
    bindkey | grep '\"\\^W\"' | grep -q 'backward-kill-word' && \
    bindkey | grep '\"\\^U\"' | grep -q 'kill-whole-line' && \
    bindkey | grep '\"\\^K\"' | grep -q 'kill-line'
  "

  [[ $status -eq 0 ]]
}

@test "Alt+B/F for word navigation" {
  # Verify word navigation with Alt key

  run zsh -c "
    source '$PULSE_DIR/lib/keybinds.zsh'

    # Check Alt+B (backward-word) and Alt+F (forward-word)
    # Alt sends escape sequences: \\e followed by character
    bindkey | grep -E '(\"\\^\\[b\"|\"\\eb\")' | grep -q 'backward-word' && \
    bindkey | grep -E '(\"\\^\\[f\"|\"\\ef\")' | grep -q 'forward-word'
  "

  [[ $status -eq 0 ]]
}

@test "Alt+. inserts last argument" {
  # Verify Alt+. inserts last argument from previous command

  run zsh -c "
    source '$PULSE_DIR/lib/keybinds.zsh'

    # Check Alt+. binding
    bindkey | grep -E '(\"\\^\\[\\.\"|\"\\e\\.\")' | grep -q 'insert-last-word'
  "

  [[ $status -eq 0 ]]
}

@test "user keybindings can override defaults" {
  # Verify that user-defined bindings take precedence

  run zsh -c "
    source '$PULSE_DIR/lib/keybinds.zsh'

    # Add a custom binding after module loads
    bindkey '^T' transpose-chars

    # Verify custom binding exists
    bindkey | grep '\"\\^T\"' | grep -q 'transpose-chars'
  "

  [[ $status -eq 0 ]]
}

@test "module loads in less than 5ms" {
  # Verify performance target

  run zsh -c "
    # Measure load time
    start=\$EPOCHREALTIME
    source '$PULSE_DIR/lib/keybinds.zsh'
    end=\$EPOCHREALTIME

    # Calculate elapsed time in milliseconds
    elapsed=\$(( (end - start) * 1000 ))

    echo \"keybinds.zsh: \${elapsed}ms\"

    # Check if under 5ms target
    (( elapsed < 5.0 ))
  "

  [[ $status -eq 0 ]]
  echo "# $output" >&3
}

@test "emacs keybindings are consistent" {
  # Verify standard emacs keybindings work together

  run zsh -c "
    source '$PULSE_DIR/lib/keybinds.zsh'

    # Verify multiple emacs bindings in one test
    bindkey | grep '\"\\^A\"' | grep -q 'beginning-of-line' && \
    bindkey | grep '\"\\^E\"' | grep -q 'end-of-line' && \
    bindkey | grep '\"\\^K\"' | grep -q 'kill-line' && \
    bindkey | grep '\"\\^W\"' | grep -q 'backward-kill-word'
  "

  [[ $status -eq 0 ]]
}

@test "no conflicting bindings" {
  # Verify that keybinds module doesn't create conflicts

  run zsh -c "
    source '$PULSE_DIR/lib/keybinds.zsh'

    # Get all keybindings and check for duplicates
    # Each key should only appear once
    bindings=\$(bindkey | awk '{print \$1}' | sort)
    duplicates=\$(echo \"\$bindings\" | uniq -d)

    # Should have no duplicates
    [[ -z \"\$duplicates\" ]]
  "

  [[ $status -eq 0 ]]
}
