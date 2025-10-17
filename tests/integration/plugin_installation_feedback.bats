#!/usr/bin/env bats
# Integration tests for plugin installation feedback

load ../test_helper

setup() {
  setup_test_environment
  
  # Create a mock git repository for testing
  export MOCK_REPO_DIR="${PULSE_DIR}/mock-repo"
  mkdir -p "${MOCK_REPO_DIR}"
  (
    cd "${MOCK_REPO_DIR}"
    git init --quiet
    echo "# Mock Plugin" > README.md
    echo "echo 'mock plugin loaded'" > mock.plugin.zsh
    git add .
    git config user.email "test@example.com"
    git config user.name "Test User"
    git commit --quiet -m "Initial commit"
  )
}

teardown() {
  teardown_test_environment
  rm -rf "${MOCK_REPO_DIR}"
}

# =============================================================================
# Plugin Installation Feedback Tests
# =============================================================================

@test "Plugin installation: shows success message on successful install" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source '${PULSE_ROOT}/lib/plugin-engine.zsh'
    _pulse_clone_plugin 'file://${MOCK_REPO_DIR}' 'test-plugin' '' '' ''
  "
  assert_success
  assert_output --partial "Installing test-plugin"
  assert_output --partial "Installed test-plugin"
}

@test "Plugin installation: shows error message on git not found" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PATH='/nonexistent'
    source '${PULSE_ROOT}/lib/plugin-engine.zsh'
    _pulse_clone_plugin 'https://github.com/user/repo' 'test-plugin' '' '' ''
  "
  assert_failure
  assert_output --partial "Git not found"
}

@test "Plugin installation: shows error message on clone failure" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source '${PULSE_ROOT}/lib/plugin-engine.zsh'
    _pulse_clone_plugin 'https://github.com/nonexistent/nonexistent-repo-12345' 'test-plugin' '' '' ''
  "
  assert_failure
  assert_output --partial "Installing test-plugin"
  assert_output --partial "Failed to install test-plugin"
}

@test "Plugin installation: includes version in display name when ref specified" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source '${PULSE_ROOT}/lib/plugin-engine.zsh'
    _pulse_clone_plugin 'file://${MOCK_REPO_DIR}' 'test-plugin' 'main' '' ''
  "
  assert_success
  assert_output --partial "test-plugin@main"
}

# =============================================================================
# Auto-install Feedback Tests
# =============================================================================

@test "Auto-install: shows feedback during plugin discovery" {
  # Create a test .zshrc that references a plugin
  cat > "${PULSE_DIR}/test.zshrc" << EOF
plugins=(
  "file://${MOCK_REPO_DIR}"
)
export PULSE_DIR='${PULSE_DIR}'
export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
source '${PULSE_ROOT}/lib/plugin-engine.zsh'
_pulse_init_engine
_pulse_discover_plugins
EOF

  run zsh -c "source '${PULSE_DIR}/test.zshrc'"
  assert_success
  # Should show installation feedback
  assert_output --partial "Installing"
}

@test "Auto-install: skips feedback for already installed plugins" {
  # First install
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source '${PULSE_ROOT}/lib/plugin-engine.zsh'
    _pulse_clone_plugin 'file://${MOCK_REPO_DIR}' 'test-plugin' '' '' ''
  "
  assert_success

  # Second attempt should not show installation feedback
  cat > "${PULSE_DIR}/test.zshrc" << EOF
plugins=(
  "test-plugin"
)
export PULSE_DIR='${PULSE_DIR}'
export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
source '${PULSE_ROOT}/lib/plugin-engine.zsh'
_pulse_init_engine
_pulse_discover_plugins
EOF

  run zsh -c "source '${PULSE_DIR}/test.zshrc'"
  assert_success
  # Should NOT show "Installing" since plugin already exists
  refute_output --partial "Installing test-plugin"
}

# =============================================================================
# Visual Feedback Integration Tests
# =============================================================================

@test "Plugin installation: feedback functions are available in plugin engine" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    source '${PULSE_ROOT}/lib/plugin-engine.zsh'
    command -v pulse_success
  "
  assert_success
}

@test "Plugin installation: feedback works without errors when UI library present" {
  # This test ensures no crashes when UI library is loaded
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source '${PULSE_ROOT}/lib/plugin-engine.zsh'
    [[ -v PULSE_UI_FEEDBACK_SOURCED ]]
  "
  assert_success
}
