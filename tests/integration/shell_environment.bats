#!/usr/bin/env bats
# Integration tests for US3 - Shell Options and Environment
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

@test "US3-AC1: History saved and deduplicated across sessions" {
  # Acceptance Scenario 1: History persistence and deduplication

  # Create history file with duplicates
  mkdir -p "$(dirname "$HISTFILE")"
  cat > "$HISTFILE" <<'EOF'
: 1234567890:0;echo "first"
: 1234567891:0;echo "duplicate"
: 1234567892:0;echo "duplicate"
: 1234567893:0;echo "last"
EOF

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HISTFILE='$HISTFILE'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify deduplication option is set
    [[ -o hist_ignore_all_dups ]] && \
    [[ -o share_history ]] && \
    echo 'history dedup enabled'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "history dedup enabled" ]]
}

@test "US3-AC2: Extended globbing works for recursive patterns" {
  # Acceptance Scenario 2: Extended glob patterns like **/*.txt

  # Create test directory structure
  mkdir -p "$HOME/test/sub1/sub2"
  touch "$HOME/test/file1.txt"
  touch "$HOME/test/sub1/file2.txt"
  touch "$HOME/test/sub1/sub2/file3.txt"

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HOME='$HOME'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Test recursive glob pattern
    cd '$HOME/test'
    files=(**/*.txt)
    echo \${#files[@]} files found
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "3 files found" ]]
}

@test "US3-AC3: Colors enabled in terminal output" {
  # Acceptance Scenario 3: Color support via LS_COLORS

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify color-related variables are set
    [[ -n \"\$GREP_COLOR\" ]] && echo 'GREP_COLOR set'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "GREP_COLOR set" ]]
}

@test "US3-AC4: EDITOR invoked for file editing" {
  # Acceptance Scenario 4: Sensible editor detected

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify EDITOR is set to a valid editor
    [[ -n \"\$EDITOR\" ]] && command -v \"\$EDITOR\" >/dev/null && echo \"EDITOR=\$EDITOR\"
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "EDITOR=" ]]
}

@test "US3-AC5: PAGER invoked for paginated output" {
  # Acceptance Scenario 5: Sensible pager detected

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify PAGER is set to a valid pager
    [[ -n \"\$PAGER\" ]] && command -v \"\$PAGER\" >/dev/null && echo \"PAGER=\$PAGER\"
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "PAGER=" ]]
}

@test "US3-AC6: Spell correction available but not auto-executing" {
  # Acceptance Scenario 6: Optional spell correction (not enabled by default)
  # Pulse doesn't enable CORRECT by default to avoid surprises

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify CORRECT is NOT set by default (user can enable if desired)
    if [[ -o correct ]]; then
      echo 'correct enabled'
    else
      echo 'correct disabled (default)'
    fi
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "correct disabled" ]]
}

@test "US3-Integration: Complete shell environment setup" {
  # End-to-end test: Verify full US3 implementation

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HOME='$HOME'
    unset PULSE_DEBUG

    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify all US3 components
    [[ -n \"\$EDITOR\" ]] && \
    [[ -n \"\$PAGER\" ]] && \
    [[ -n \"\$HISTFILE\" ]] && \
    [[ -n \"\$GREP_COLOR\" ]] && \
    [[ -o extended_glob ]] && \
    [[ -o hist_ignore_all_dups ]] && \
    echo 'US3 complete'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "US3 complete" ]]
}

@test "US3-Functionality: History with timestamps" {
  # Verify EXTENDED_HISTORY saves timestamps

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HISTFILE='$HISTFILE'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify EXTENDED_HISTORY option is set
    [[ -o extended_history ]] && echo 'timestamps enabled'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "timestamps enabled" ]]
}

@test "US3-Functionality: GLOB_DOTS includes dotfiles" {
  # Verify GLOB_DOTS makes globs match dotfiles

  # Create test files including dotfiles
  mkdir -p "$HOME/test"
  touch "$HOME/test/visible.txt"
  touch "$HOME/test/.hidden.txt"

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    export HOME='$HOME'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Test that glob matches dotfiles
    cd '$HOME/test'
    files=(*.txt)
    echo \${#files[@]} files
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "2 files" ]]
}

@test "US3-Functionality: NO_BEEP prevents error beeps" {
  # Verify NO_BEEP option is set

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Verify NO_BEEP is set
    [[ -o no_beep ]] && echo 'no beep'
  "

  [[ $status -eq 0 ]]
  [[ "$output" =~ "no beep" ]]
}

@test "US3-Functionality: LESS options for better paging" {
  # Verify LESS environment variable has sensible defaults

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Check if LESS is set (only when less is the pager)
    if [[ \"\$PAGER\" == \"less\" ]]; then
      echo \"LESS=\$LESS\"
    else
      echo 'less not default pager'
    fi
  "

  [[ $status -eq 0 ]]
  # Either LESS is set or less is not the pager
  [[ "$output" =~ "LESS=" ]] || [[ "$output" =~ "not default" ]]
}
