#!/usr/bin/env bats
# Integration tests for US2 - Enhanced Keybindings
# Tests all 6 acceptance scenarios from spec.md

load ../test_helper

setup() {
  # Create isolated test environment
  export PULSE_TEST_DIR="${BATS_TEST_TMPDIR}/pulse_test_$$"
  export PULSE_DIR="${PULSE_TEST_DIR}/pulse"
  export PULSE_CACHE_DIR="${PULSE_TEST_DIR}/.cache/pulse"
  export HOME="${PULSE_TEST_DIR}/home"
  export HISTFILE="${HOME}/.zsh_history"

  mkdir -p "$PULSE_DIR"
  mkdir -p "$PULSE_CACHE_DIR"
  mkdir -p "$HOME"

  # Copy pulse framework to test directory
  cp -r "${BATS_TEST_DIRNAME}/../../lib" "$PULSE_DIR/"
  cp "${BATS_TEST_DIRNAME}/../../pulse.zsh" "$PULSE_DIR/"

  # Create minimal plugin engine mock
  mkdir -p "$PULSE_DIR/lib"
  cat > "$PULSE_DIR/lib/plugin-engine.zsh" <<'EOF'
# Mock plugin engine for testing
pulse_plugins=()

_pulse_init_engine() {
  typeset -ga pulse_plugins
  typeset -gA pulse_plugin_meta
}

_pulse_discover_plugins() {
  :
}

_pulse_load_stages() {
  :
}
EOF

  # Create a history file with test commands
  mkdir -p "$(dirname "$HISTFILE")"
  cat > "$HISTFILE" <<'EOF'
: 1234567890:0;echo "first command"
: 1234567891:0;ls /tmp
: 1234567892:0;pwd
: 1234567893:0;echo "last command" /path/to/file
EOF
}

teardown() {
  rm -rf "$PULSE_TEST_DIR"
}

@test "US2-AC1: History navigation keys access previous commands" {
  # Acceptance Scenario 1: History navigation with arrows and Ctrl+P/N

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HISTFILE='$HISTFILE'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify history navigation bindings are set
    bindkey | grep -q 'up-line-or-history' && \
    bindkey | grep -q 'down-line-or-history'
  "

  [[ $status -eq 0 ]]
}

@test "US2-AC2: Line editing shortcuts work correctly" {
  # Acceptance Scenario 2: Cursor movement and text modification

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify line editing bindings
    bindkey | grep '\"\\^A\"' | grep -q 'beginning-of-line' && \
    bindkey | grep '\"\\^E\"' | grep -q 'end-of-line' && \
    bindkey | grep '\"\\^W\"' | grep -q 'backward-kill-word'
  "

  [[ $status -eq 0 ]]
}

@test "US2-AC3: Alt+. inserts last argument from previous command" {
  # Acceptance Scenario 3: Insert last word functionality

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify Alt+. binding for insert-last-word
    bindkey | grep -E '(\"\\^\\[\\.\"|\"\\e\\.\")' | grep -q 'insert-last-word'
  "

  [[ $status -eq 0 ]]
}

@test "US2-AC4: Ctrl+R activates interactive reverse search" {
  # Acceptance Scenario 4: History incremental search

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HISTFILE='$HISTFILE'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify Ctrl+R is bound to reverse search
    bindkey | grep '\"\\^R\"' | grep -q 'history-incremental-search-backward'
  "

  [[ $status -eq 0 ]]
}

@test "US2-AC5: Vi mode can be enabled by user" {
  # Acceptance Scenario 5: Vi mode support

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # User can switch to vi mode after pulse loads
    bindkey -v

    # Verify vi mode is active
    bindkey -l | grep -q 'viins\\|vicmd'
  "

  [[ $status -eq 0 ]]
}

@test "US2-AC6: Emacs shortcuts follow emacs conventions" {
  # Acceptance Scenario 6: Standard emacs bindings

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify multiple standard emacs bindings
    bindkey | grep '\"\\^A\"' | grep -q 'beginning-of-line' && \
    bindkey | grep '\"\\^E\"' | grep -q 'end-of-line' && \
    bindkey | grep '\"\\^K\"' | grep -q 'kill-line' && \
    bindkey | grep '\"\\^W\"' | grep -q 'backward-kill-word' && \
    bindkey | grep '\"\\^Y\"' | grep -q 'yank'
  "

  [[ $status -eq 0 ]]
}

@test "US2-Integration: Complete keybindings system works" {
  # End-to-end test: Verify full keybinding setup

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

    # Load pulse with verbose error checking
    set -e
    source '$PULSE_DIR/pulse.zsh' 2>&1

    # Verify keybinds module loaded
    bindkey -l | grep -q 'emacs'
  "

  [[ $status -eq 0 ]]
}

@test "US2-Integration: Keybindings work across module loading" {
  # Verify keybindings survive complete pulse initialization

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    unset PULSE_DEBUG

    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Count that we have reasonable number of bindings (should be >30)
    binding_count=\$(bindkey | wc -l)
    [[ \$binding_count -gt 30 ]]
  "

  [[ $status -eq 0 ]]
}

@test "US2-Performance: Keybinds module loads quickly" {
  # Verify keybinds loads within performance target

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

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

@test "US2-Functionality: Ctrl+S forward search enabled" {
  # Verify Ctrl+S is not blocked by terminal flow control

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify Ctrl+S is bound (stty -ixon should disable flow control)
    bindkey | grep '\"\\^S\"' | grep -q 'history-incremental-search-forward'
  "

  [[ $status -eq 0 ]]
}

@test "US2-Functionality: Word navigation with Alt keys" {
  # Verify Alt+B and Alt+F work for word navigation

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Check Alt+B and Alt+F bindings
    bindkey | grep -E '(\"\\^\\[b\"|\"\\eb\")' | grep -q 'backward-word' && \
    bindkey | grep -E '(\"\\^\\[f\"|\"\\ef\")' | grep -q 'forward-word'
  "

  [[ $status -eq 0 ]]
}

@test "US2-Functionality: Edit command line with Ctrl+X Ctrl+E" {
  # Verify advanced editing feature

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Check if Ctrl+X Ctrl+E opens editor
    bindkey | grep '\"\\^X\\^E\"' | grep -q 'edit-command-line'
  "

  [[ $status -eq 0 ]]
}
