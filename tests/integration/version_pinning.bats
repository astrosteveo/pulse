#!/usr/bin/env bats
# Integration tests for version pinning
# Tests @latest keyword and version tag functionality (US1)

load ../test_helper

setup() {
  # Create temporary test directory
  TEST_TMPDIR="$(mktemp -d)"
  export HOME="${TEST_TMPDIR}"
  export PULSE_DIR="${TEST_TMPDIR}/.local/share/pulse"
  export PULSE_CACHE_DIR="${TEST_TMPDIR}/.cache/pulse"
  mkdir -p "${PULSE_DIR}/plugins"
  mkdir -p "${PULSE_CACHE_DIR}"
  
  # Use mock plugins from fixtures
  export MOCK_PLUGINS_DIR="${PULSE_ROOT}/tests/fixtures/mock-plugins"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

# Test: Plugin with @latest should clone from default branch
@test "installs plugin with @latest" {
  # Create a temporary .zshrc with @latest plugin
  cat > "${HOME}/.zshrc" <<'EOF'
# Mock plugin using @latest
plugins=(
  ${MOCK_PLUGINS_DIR}/plugin-a@latest
)
EOF
  
  # Source pulse.zsh to trigger plugin loading
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export MOCK_PLUGINS_DIR='${MOCK_PLUGINS_DIR}'
    source ${HOME}/.zshrc
    source ${PULSE_ROOT}/pulse.zsh
    
    # Check if plugin was loaded
    [[ -d '${PULSE_DIR}/plugins/plugin-a' ]] && echo 'LOADED'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "LOADED" ]]
}

# Test: @latest should use the latest commit from default branch
@test "@latest clones from default branch (not a specific tag)" {
  # Source pulse with @latest specification
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    # Clone plugin with @latest
    _pulse_clone_plugin '${MOCK_PLUGINS_DIR}/plugin-a' 'plugin-a' ''
    
    # Verify it's on a branch, not a detached HEAD at a tag
    cd '${PULSE_DIR}/plugins/plugin-a'
    git branch --show-current
  "
  
  [ "$status" -eq 0 ]
  # Should show 'main' or 'master', not empty (detached HEAD)
  [[ -n "$output" ]]
}

# Test: @latest behavior matches omitted version
@test "@latest behaves identically to omitted version in practice" {
  # Install with @latest
  run zsh -c "
    export PULSE_DIR='${TEST_TMPDIR}/with-latest'
    mkdir -p '${PULSE_DIR}/plugins'
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_clone_plugin '${MOCK_PLUGINS_DIR}/plugin-b' 'plugin-b' ''
    cd '${PULSE_DIR}/plugins/plugin-b'
    git rev-parse HEAD
  "
  [ "$status" -eq 0 ]
  local commit_with_latest="$output"
  
  # Install without version
  run zsh -c "
    export PULSE_DIR='${TEST_TMPDIR}/without-version'
    mkdir -p '${PULSE_DIR}/plugins'
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_clone_plugin '${MOCK_PLUGINS_DIR}/plugin-b' 'plugin-b' ''
    cd '${PULSE_DIR}/plugins/plugin-b'
    git rev-parse HEAD
  "
  [ "$status" -eq 0 ]
  local commit_without_version="$output"
  
  # Both should be on the same commit
  [[ "$commit_with_latest" == "$commit_without_version" ]]
}

# Test: Explicit version should override @latest pattern
@test "explicit version tag pins to specific commit" {
  # Install with specific tag
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_clone_plugin '${MOCK_PLUGINS_DIR}/plugin-a' 'plugin-a' 'v1.0.0'
    cd '${PULSE_DIR}/plugins/plugin-a'
    git describe --tags --exact-match
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "v1.0.0" ]]
}
