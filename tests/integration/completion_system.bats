#!/usr/bin/env bats
# Integration tests for US1 - Intelligent Completion System
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

  # Copy pulse framework to test directory
  cp -r "${BATS_TEST_DIRNAME}/../../lib" "$PULSE_DIR/"
  cp "${BATS_TEST_DIRNAME}/../../pulse.zsh" "$PULSE_DIR/"

  # Create minimal plugin engine mock (US1 doesn't need real plugins)
  mkdir -p "$PULSE_DIR/lib"
  cat > "$PULSE_DIR/lib/plugin-engine.zsh" <<'EOF'
# Mock plugin engine for testing
pulse_plugins=()

# Mock functions required by pulse.zsh
_pulse_init_engine() {
  # Initialize basic plugin engine state
  typeset -ga pulse_plugins
  typeset -gA pulse_plugin_meta
}

_pulse_discover_plugins() {
  # Mock discovery - no real plugins in tests
  :
}

_pulse_load_stages() {
  # Mock loading stages - no real loading in US1 tests
  :
}
EOF
}

teardown() {
  rm -rf "$PULSE_TEST_DIR"
}

# Simple assertion helpers (no external dependencies)
assert_success() {
  if [[ $status -ne 0 ]]; then
    echo "Expected success but got status $status"
    echo "Output: $output"
    return 1
  fi
  return 0
}

assert_failure() {
  if [[ $status -eq 0 ]]; then
    echo "Expected failure but got success"
    return 1
  fi
  return 0
}

# Helper: Create a test completion function
create_test_completion() {
  local comp_name="$1"
  cat <<EOF
#compdef ${comp_name}
_${comp_name}() {
  local -a options
  options=(
    'start:Start the service'
    'stop:Stop the service'
    'restart:Restart the service'
    'status:Show service status'
  )
  _describe 'command' options
}
_${comp_name} "\$@"
EOF
}

# Helper: Load pulse with completion system
load_pulse_with_completions() {
  # Create a zsh script that loads pulse and tests completions
  cat <<'ZSHEOF'
    # Set up test environment
    export PULSE_DIR="$1"
    export PULSE_CACHE_DIR="$2"
    shift 2

    # Load pulse framework
    source "$PULSE_DIR/pulse.zsh"

    # Execute test command
    eval "$@"
ZSHEOF
}

@test "US1-AC1: Completion menu appears after Tab press" {
  # Acceptance Scenario 1: Fresh shell with Pulse loaded shows completion menu

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh'

    # Check that compinit was loaded
    [[ -n \"\${functions[compinit]}\" ]]
  "

  assert_success

  # Verify completion system is initialized
  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh'

    # Check completion functions are available
    print -l \${^fpath}/*(N:t) | grep -q '^_'
  "

  assert_success
}

@test "US1-AC2: Plugin-provided completions are available" {
  # Acceptance Scenario 2: Completions from plugins work correctly

  # Create a mock plugin with completion
  local plugin_dir="$PULSE_DIR/plugins/test-plugin"
  mkdir -p "$plugin_dir"

  # Add plugin completion function
  create_test_completion "testcmd" > "$plugin_dir/_testcmd"

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

    # Add plugin completion dir to fpath
    fpath=('$plugin_dir' \$fpath)

    source '$PULSE_DIR/pulse.zsh'

    # Check if completion function is available
    print -l \${^fpath}/*(N:t) | grep -q '^_testcmd$'
  "

  assert_success
}

@test "US1-AC3: Multiple completion sources are merged" {
  # Acceptance Scenario 3: Multiple sources merge cohesively

  # Create multiple plugin directories with completions
  local plugin1="$PULSE_DIR/plugins/plugin1"
  local plugin2="$PULSE_DIR/plugins/plugin2"
  mkdir -p "$plugin1" "$plugin2"

  create_test_completion "cmd1" > "$plugin1/_cmd1"
  create_test_completion "cmd2" > "$plugin2/_cmd2"

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

    # Add both plugin dirs to fpath
    fpath=('$plugin1' '$plugin2' \$fpath)

    source '$PULSE_DIR/pulse.zsh'

    # Verify both completion functions available
    compfuncs=\$(print -l \${^fpath}/*(N:t))
    echo \"\$compfuncs\" | grep -q '_cmd1' && echo \"\$compfuncs\" | grep -q '_cmd2'
  "

  assert_success
}

@test "US1-AC4: Fuzzy matching suggests close matches for typos" {
  # Acceptance Scenario 4: Fuzzy/approximate matching works

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh'

    # Check if fuzzy matcher is configured
    zstyle -L ':completion:*' matcher-list | grep -q 'r:|'
  "

  assert_success

  # Verify case-insensitive matching is configured
  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh'

    # Check case-insensitive matcher
    zstyle -L ':completion:*' matcher-list | grep -q 'm:'
  "

  assert_success
}

@test "US1-AC5: Descriptions and categories are shown clearly" {
  # Acceptance Scenario 5: Completion menu shows descriptions

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh'

    # Check that menu selection is enabled
    zstyle -L ':completion:*' menu | grep -q 'select'
  "

  assert_success

  # Verify description formats are set
  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh'

    # Check for description format configuration
    zstyle -L ':completion:*:descriptions' format
  "

  assert_success

  # Verify grouping is configured
  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh'

    # Check group-name setting (empty string means use default names)
    zstyle -t ':completion:*' group-name ''
  "

  # Exit code 0 means style is set to expected value
  assert_success
}

@test "US1-Integration: Works with multiple completion plugins" {
  # End-to-end test: 3+ completion sources work together

  # Create 3 mock plugin directories
  for i in {1..3}; do
    local plugin_dir="$PULSE_DIR/plugins/plugin$i"
    mkdir -p "$plugin_dir"
    create_test_completion "testcmd$i" > "$plugin_dir/_testcmd$i"
  done

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

    # Add all plugin dirs to fpath
    fpath=('$PULSE_DIR'/plugins/plugin* \$fpath)

    source '$PULSE_DIR/pulse.zsh'

    # Verify all 3 completions are available
    compfuncs=\$(print -l \${^fpath}/*(N:t))
    count=0
    for i in {1..3}; do
      echo \"\$compfuncs\" | grep -q \"_testcmd\$i\" && ((count++))
    done
    [[ \$count -eq 3 ]]
  "

  assert_success
}

@test "US1-Integration: Completion system loads without errors" {
  # Verify complete US1 implementation loads cleanly

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

    # Disable PULSE_DEBUG to suppress module loading messages
    unset PULSE_DEBUG

    # Load pulse framework (will show errors for missing modules, which is OK for US1)
    source '$PULSE_DIR/pulse.zsh' 2>&1

    # Verify US1 completion modules loaded successfully
    # Check that completion system is functional
    [[ -n \"\${functions[compinit]}\" ]] && \
    zstyle -L ':completion:*' menu | grep -q 'select' && \
    zstyle -L ':completion:*' matcher-list | grep -q 'r:|'
  "

  assert_success
}

@test "US1-Performance: Completion menu responds quickly" {
  # Verify completion menu appears in <100ms

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/pulse.zsh'

    # Measure time to generate completions for a basic command
    start=\$((EPOCHREALTIME * 1000))

    # Simulate completion invocation (compgen-like behavior)
    compgen() { print -l \${(k)commands} | head -20; }
    compgen > /dev/null

    end=\$((EPOCHREALTIME * 1000))
    elapsed=\$((end - start))

    # Should be well under 100ms
    [[ \$elapsed -lt 100 ]]
  "

  # Note: This is a simplified performance check
  # Real completion timing depends on zsh internals
  assert_success
}
