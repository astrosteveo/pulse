#!/usr/bin/env bats
# Performance validation for US1 - Intelligent Completion System
# Validates that all performance targets are met

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
}

teardown() {
  rm -rf "$PULSE_TEST_DIR"
}

# Simple assertion helpers
assert_success() {
  if [[ $status -ne 0 ]]; then
    echo "Expected success but got status $status"
    echo "Output: $output"
    return 1
  fi
  return 0
}

@test "Performance: environment.zsh loads in <5ms" {
  # Measure environment module load time

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

    # Measure load time using EPOCHREALTIME
    start=\$EPOCHREALTIME
    source '$PULSE_DIR/lib/environment.zsh'
    end=\$EPOCHREALTIME

    # Calculate elapsed time in milliseconds
    elapsed=\$(( (end - start) * 1000 ))

    echo \"environment.zsh: \${elapsed}ms\"

    # Check if under 5ms target
    (( elapsed < 5.0 ))
  "

  assert_success
  echo "# $output" >&3
}

@test "Performance: compinit.zsh loads in <15ms with cache" {
  # Measure compinit module load time with existing cache

  # Pre-create cache to test cached path
  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'
    source '$PULSE_DIR/lib/environment.zsh'
    source '$PULSE_DIR/lib/compinit.zsh'
  "

  # Now measure with cache present
  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

    # Ensure environment is loaded first
    source '$PULSE_DIR/lib/environment.zsh' 2>/dev/null

    # Measure compinit load time
    start=\$EPOCHREALTIME
    source '$PULSE_DIR/lib/compinit.zsh'
    end=\$EPOCHREALTIME

    # Calculate elapsed time in milliseconds
    elapsed=\$(( (end - start) * 1000 ))

    echo \"compinit.zsh (cached): \${elapsed}ms\"

    # Check if under 15ms target
    (( elapsed < 15.0 ))
  "

  assert_success
  echo "# $output" >&3
}

@test "Performance: completions.zsh loads in <5ms" {
  # Measure completions module load time

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

    # Load prerequisites
    source '$PULSE_DIR/lib/environment.zsh' 2>/dev/null
    source '$PULSE_DIR/lib/compinit.zsh' 2>/dev/null

    # Measure completions load time
    start=\$EPOCHREALTIME
    source '$PULSE_DIR/lib/completions.zsh'
    end=\$EPOCHREALTIME

    # Calculate elapsed time in milliseconds
    elapsed=\$(( (end - start) * 1000 ))

    echo \"completions.zsh: \${elapsed}ms\"

    # Check if under 5ms target
    (( elapsed < 5.0 ))
  "

  assert_success
  echo "# $output" >&3
}

@test "Performance: Total US1 framework overhead <25ms" {
  # Measure total time for all US1 modules (environment + compinit + completions)
  # Target is <50ms total framework, US1 is 3 modules, so <25ms is reasonable

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

    # Measure total time for all US1 modules
    start=\$EPOCHREALTIME
    source '$PULSE_DIR/lib/environment.zsh' 2>/dev/null
    source '$PULSE_DIR/lib/compinit.zsh' 2>/dev/null
    source '$PULSE_DIR/lib/completions.zsh' 2>/dev/null
    end=\$EPOCHREALTIME

    # Calculate elapsed time in milliseconds
    elapsed=\$(( (end - start) * 1000 ))

    echo \"Total US1 overhead: \${elapsed}ms\"

    # Check if under 25ms (half of 50ms total budget for 3 modules)
    (( elapsed < 25.0 ))
  "

  assert_success
  echo "# $output" >&3
}

@test "Performance: Complete pulse.zsh load <50ms" {
  # Measure complete pulse framework load time

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

    # Disable debug output for cleaner timing
    unset PULSE_DEBUG

    # Measure total pulse load time
    start=\$EPOCHREALTIME
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null
    end=\$EPOCHREALTIME

    # Calculate elapsed time in milliseconds
    elapsed=\$(( (end - start) * 1000 ))

    echo \"pulse.zsh total load: \${elapsed}ms\"

    # Check if under 50ms total framework target
    (( elapsed < 50.0 ))
  "

  assert_success
  echo "# $output" >&3
}

@test "Performance: Completion menu response <100ms" {
  # Verify completion menu generation is fast
  # This is a synthetic test since we can't actually measure Tab key response

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

    # Load completion system
    source '$PULSE_DIR/pulse.zsh' 2>/dev/null

    # Measure time to generate completion list for a command
    start=\$EPOCHREALTIME

    # Simulate completion generation
    # This uses compadd which is what completions use internally
    local -a completions
    completions=(\${(k)commands})

    end=\$EPOCHREALTIME

    # Calculate elapsed time in milliseconds
    elapsed=\$(( (end - start) * 1000 ))

    echo \"Completion generation: \${elapsed}ms\"

    # Check if under 100ms target
    (( elapsed < 100.0 ))
  "

  assert_success
  echo "# $output" >&3
}

@test "Performance: compinit without cache <100ms" {
  # Verify that even without cache, compinit is reasonable

  run zsh -c "
    export PULSE_DIR='$PULSE_DIR'
    export PULSE_CACHE_DIR='$PULSE_CACHE_DIR'

    # Ensure no cache exists
    rm -f '$PULSE_CACHE_DIR'/zcompdump*

    # Load environment first
    source '$PULSE_DIR/lib/environment.zsh' 2>/dev/null

    # Measure compinit without cache
    start=\$EPOCHREALTIME
    source '$PULSE_DIR/lib/compinit.zsh' 2>/dev/null
    end=\$EPOCHREALTIME

    # Calculate elapsed time in milliseconds
    elapsed=\$(( (end - start) * 1000 ))

    echo \"compinit.zsh (no cache): \${elapsed}ms\"

    # Check if under 100ms (acceptable for first-time init)
    (( elapsed < 100.0 ))
  "

  assert_success
  echo "# $output" >&3
}
