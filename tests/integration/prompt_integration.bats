#!/usr/bin/env bats
# Integration tests for US5: Prompt Integration
# Tests end-to-end prompt system behavior

load ../test_helper

setup() {
    # Create isolated test environment
    export PULSE_TEST_HOME="${BATS_TEST_TMPDIR}/pulse_test_$$"
    export PULSE_DIR="${PULSE_TEST_HOME}/pulse"
    export PULSE_CACHE_DIR="${PULSE_TEST_HOME}/.cache/pulse"
    export HOME="${PULSE_TEST_HOME}/home"
    
    mkdir -p "$PULSE_DIR"
    mkdir -p "$PULSE_CACHE_DIR"
    mkdir -p "$HOME"
    
    # Copy pulse framework to test directory
    cp -r "${BATS_TEST_DIRNAME}/../../lib" "$PULSE_DIR/"
    cp "${BATS_TEST_DIRNAME}/../../pulse.zsh" "$PULSE_DIR/"
    
    # Create minimal plugin engine mock
    cat > "$PULSE_DIR/lib/plugin-engine.zsh" << 'MOCK_EOF'
pulse_plugins=()
_pulse_init_engine() { typeset -ga pulse_plugins; typeset -gA pulse_plugin_meta; }
_pulse_discover_plugins() { : }
_pulse_load_stages() { : }
MOCK_EOF
    
    # Change to test home for relative paths
    cd "$PULSE_TEST_HOME"
}

teardown() {
    cd /
    rm -rf "${PULSE_TEST_HOME}"
}

# ============================================================================
# US5 Acceptance Criteria Tests
# ============================================================================

# US5-AC1: User-defined prompt is respected
@test "US5-AC1: user-defined prompt is never overridden" {
    # User sets custom PROMPT before loading
    cat > "$PULSE_TEST_HOME/test.zsh" << 'TEST_EOF'
export PROMPT='custom> '
source pulse/pulse.zsh
echo "PROMPT=$PROMPT"
TEST_EOF
    
    output=$(zsh "$PULSE_TEST_HOME/test.zsh" 2>&1)
    
    [[ "$output" =~ "PROMPT=custom> " ]]
}

# US5-AC2: Default prompt shows directory
@test "US5-AC2: default prompt shows current directory" {
    cat > "$PULSE_TEST_HOME/test.zsh" << 'TEST_EOF'
source pulse/pulse.zsh
echo "PROMPT=$PROMPT"
TEST_EOF
    
    output=$(zsh "$PULSE_TEST_HOME/test.zsh" 2>&1)
    
    # Should contain %~ (Zsh directory expansion)
    [[ "$output" =~ %~ ]]
}

# US5-AC3: Default prompt shows user indicator
@test "US5-AC3: default prompt shows user type indicator" {
    cat > "$PULSE_TEST_HOME/test.zsh" << 'TEST_EOF'
source pulse/pulse.zsh
echo "PROMPT=$PROMPT"
TEST_EOF
    
    output=$(zsh "$PULSE_TEST_HOME/test.zsh" 2>&1)
    
    # Should contain %# (% for user, # for root)
    [[ "$output" =~ "%#" ]]
}

# US5-AC4: Prompt allows plugin override
@test "US5-AC4: PULSE_PROMPT_SET prevents default prompt" {
    # Simulate a plugin that sets PULSE_PROMPT_SET before prompt module loads
    cat > "$PULSE_TEST_HOME/test.zsh" << 'TEST_EOF'
export PULSE_PROMPT_SET=1
export PROMPT='plugin-prompt> '
source pulse/pulse.zsh
echo "PROMPT=$PROMPT"
TEST_EOF
    
    output=$(zsh "$PULSE_TEST_HOME/test.zsh" 2>&1)
    
    # Plugin prompt should be preserved (not overwritten)
    [[ "$output" =~ "PROMPT=plugin-prompt> " ]]
}

# ============================================================================
# US5 Integration Tests
# ============================================================================

# US5-Integration: Complete prompt system test
@test "US5-Integration: prompt system loads and functions" {
    cat > "$PULSE_TEST_HOME/test.zsh" << 'TEST_EOF'
source pulse/pulse.zsh

# Test 1: PROMPT is set
[[ -n "$PROMPT" ]] || exit 1

# Test 2: PULSE_PROMPT_SET flag is set
[[ "$PULSE_PROMPT_SET" == "1" ]] || exit 2

# Test 3: Prompt contains directory
[[ "$PROMPT" =~ %~ ]] || exit 3

# Test 4: Prompt contains user indicator
[[ "$PROMPT" =~ "%#" ]] || exit 4

echo "All prompt tests passed"
TEST_EOF
    
    run zsh "$PULSE_TEST_HOME/test.zsh"
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "All prompt tests passed" ]]
}

# US5-Functionality: Prompt respects PS1 (Bash compatibility)
@test "US5-Functionality: respects existing PS1 variable" {
    cat > "$PULSE_TEST_HOME/test.zsh" << 'TEST_EOF'
export PS1='bash-style> '
source pulse/pulse.zsh
echo "PS1=$PS1"
echo "PROMPT=$PROMPT"
TEST_EOF
    
    output=$(zsh "$PULSE_TEST_HOME/test.zsh" 2>&1)
    
    # PS1 should be unchanged
    [[ "$output" =~ "PS1=bash-style> " ]]
    # PROMPT should not be set (PS1 takes precedence)
    [[ "$output" =~ "PROMPT=$" ]] || [[ "$output" =~ "PROMPT=bash-style> " ]]
}

# US5-Functionality: Default prompt is clean and simple
@test "US5-Functionality: default prompt is concise" {
    cat > "$PULSE_TEST_HOME/test.zsh" << 'TEST_EOF'
source pulse/pulse.zsh
echo "LENGTH=${#PROMPT}"
TEST_EOF
    
    output=$(zsh "$PULSE_TEST_HOME/test.zsh" 2>&1)
    
    # Extract length
    length=$(echo "$output" | grep -o 'LENGTH=[0-9]*' | cut -d= -f2)
    [[ $length -lt 50 ]]
}

# US5-Functionality: Prompt works without colors (dumb terminal)
@test "US5-Functionality: works in dumb terminal" {
    cat > "$PULSE_TEST_HOME/test.zsh" << 'TEST_EOF'
export TERM=dumb
source pulse/pulse.zsh
echo "PROMPT=$PROMPT"
TEST_EOF
    
    output=$(zsh "$PULSE_TEST_HOME/test.zsh" 2>&1)
    
    # Should still set prompt (plain text version)
    [[ "$output" =~ "PROMPT=%~ %#" ]]
}

# US5-Performance: Prompt module loads quickly
@test "US5-Performance: prompt module loads in <100ms" {
    cat > "$PULSE_TEST_HOME/test.zsh" << 'TEST_EOF'
start=$(date +%s%N)
source pulse/pulse.zsh
end=$(date +%s%N)
elapsed=$(( (end - start) / 1000000 ))
echo "prompt load time: ${elapsed}ms"
TEST_EOF
    
    output=$(zsh "$PULSE_TEST_HOME/test.zsh" 2>&1)
    
    # Extract elapsed time
    elapsed=$(echo "$output" | grep -o 'prompt load time: [0-9]*ms' | grep -o '[0-9]*')
    echo "prompt load time: ${elapsed}ms"
    
    [[ $elapsed -lt 100 ]]
}
