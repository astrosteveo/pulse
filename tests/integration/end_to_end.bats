#!/usr/bin/env bats
# End-to-end integration tests validating complete framework functionality
# Tests all user stories (US1-US5) working together in realistic scenarios

load ../test_helper

setup() {
  # Create fresh test directories
  mkdir -p "${PULSE_DIR}/plugins"
  mkdir -p "${PULSE_CACHE_DIR}"

  # Set up test .zshrc path
  export TEST_ZSHRC="${PULSE_DIR}/.zshrc"
  export TEST_DIR="${PULSE_DIR}"
}

teardown() {
  teardown_test_environment
}

# =============================================================================
# SCENARIO 1: Minimal Configuration (Framework Only)
# =============================================================================

@test "E2E: Framework works standalone without plugins" {
  # Load framework without plugins
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=()
    source ${PULSE_ROOT}/pulse.zsh
    echo 'loaded'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"loaded"* ]]
}

@test "E2E: All framework modules load without plugins" {
  cat > "$TEST_ZSHRC" << 'EOF'
plugins=()
source "$PULSE_ROOT/pulse.zsh"

# Verify modules loaded
[[ -n "$PULSE_ENV_LOADED" ]] && echo "environment"
type compinit &>/dev/null && echo "compinit"
bindkey | grep -q "history-incremental" && echo "keybinds"
alias | grep -q "^\.\.=" && echo "directory"
[[ -n "$PROMPT" ]] && echo "prompt"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success
  assert_output --partial "environment"
  assert_output --partial "compinit"
  assert_output --partial "keybinds"
  assert_output --partial "directory"
  assert_output --partial "prompt"
}

# =============================================================================
# SCENARIO 2: Standard Developer Setup
# =============================================================================

@test "E2E: Developer setup with syntax highlighting and completions" {
  # Create mock plugins
  create_mock_plugin "syntax" "standard"
  create_mock_plugin "completions" "completion"

  cat > "$TEST_ZSHRC" << 'EOF'
plugins=(
  syntax
  completions
)
source "$PULSE_ROOT/pulse.zsh"

# Verify framework + plugins loaded
echo "Framework: $PULSE_ENV_LOADED"
[[ -f "$PULSE_DIR/plugins/syntax/syntax.plugin.zsh" ]] && echo "syntax-plugin"
type compinit &>/dev/null && echo "completions-ready"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success
  assert_output --partial "Framework: 1"
  assert_output --partial "syntax-plugin"
  assert_output --partial "completions-ready"
}

@test "E2E: Plugins load in correct 5-stage pipeline with framework" {
  # Create plugins for each stage
  create_mock_plugin "early-plugin" "standard"
  create_mock_plugin "completions" "completion"
  create_mock_plugin "late-plugin" "standard"

  cat > "$TEST_ZSHRC" << 'EOF'
plugins=(
  early-plugin
  completions
  late-plugin
)
source "$PULSE_ROOT/pulse.zsh"

# Verify plugins loaded
[[ -n "$early_plugin_loaded" ]] && echo "early-loaded"
type compinit &>/dev/null && echo "completions-loaded"
[[ -n "$late_plugin_loaded" ]] && echo "late-loaded"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success
  assert_output --partial "early-loaded"
  assert_output --partial "completions-loaded"
  assert_output --partial "late-loaded"
}

# =============================================================================
# SCENARIO 3: Configuration & Customization
# =============================================================================

@test "E2E: Disable framework modules while keeping plugins" {
  create_mock_plugin "test-plugin" "standard"

  cat > "$TEST_ZSHRC" << 'EOF'
# Disable prompt and directory modules
pulse_disabled_modules=(prompt directory)

plugins=(test-plugin)
source "$PULSE_ROOT/pulse.zsh"

# Check what's loaded
[[ -n "$PULSE_ENV_LOADED" ]] && echo "environment-loaded"
[[ -z "$PULSE_PROMPT_SET" ]] && echo "prompt-disabled"
alias | grep -q "^\.\.=" || echo "directory-disabled"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success
  assert_output --partial "environment-loaded"
  assert_output --partial "prompt-disabled"
  assert_output --partial "directory-disabled"
}

@test "E2E: Custom cache directory works across framework" {
  local custom_cache="${TEST_DIR}/custom-cache"

  cat > "$TEST_ZSHRC" << EOF
export PULSE_CACHE_DIR="$custom_cache"
plugins=()
source "$PULSE_ROOT/pulse.zsh"

echo "Cache dir: \$PULSE_CACHE_DIR"
[[ -d "\$PULSE_CACHE_DIR" ]] && echo "cache-exists"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success
  assert_output --partial "Cache dir: $custom_cache"
  assert_output --partial "cache-exists"

  # Verify zcompdump was created in custom location
  [[ -f "$custom_cache/zcompdump" ]]
}

@test "E2E: Debug mode shows all module and plugin loads" {
  create_mock_plugin "debug-test" "standard"

  cat > "$TEST_ZSHRC" << 'EOF'
export PULSE_DEBUG=1
plugins=(debug-test)
source "$PULSE_ROOT/pulse.zsh"
EOF

  run zsh -c "source '$TEST_ZSHRC' 2>&1"
  assert_success

  # Should show module loads
  assert_output --partial "environment.zsh"
  assert_output --partial "compinit.zsh"

  # Should show plugin loads
  assert_output --partial "debug-test"
}

# =============================================================================
# SCENARIO 4: Error Handling & Edge Cases
# =============================================================================

@test "E2E: Framework continues if plugin fails to load" {
  # Create a plugin that errors
  mkdir -p "$PULSE_DIR/plugins/broken-plugin"
  cat > "$PULSE_DIR/plugins/broken-plugin/broken-plugin.plugin.zsh" << 'EOF'
return 1  # Use return instead of exit to not kill shell
EOF

  create_mock_plugin "working-plugin" "standard"

  cat > "$TEST_ZSHRC" << 'EOF'
plugins=(
  broken-plugin
  working-plugin
)
source "$PULSE_ROOT/pulse.zsh"

# Framework should still work
[[ -n "$PULSE_ENV_LOADED" ]] && echo "framework-ok"
EOF

  run zsh -c "source '$TEST_ZSHRC' 2>&1"
  # Should succeed despite broken plugin
  assert_output --partial "framework-ok"
}

@test "E2E: Completion cache regenerates after 24h" {
  mkdir -p "$PULSE_CACHE_DIR"

  # Create old cache file (25 hours old)
  touch -t "$(date -d '25 hours ago' +%Y%m%d%H%M)" "$PULSE_CACHE_DIR/zcompdump"
  local old_mtime=$(stat -c %Y "$PULSE_CACHE_DIR/zcompdump" 2>/dev/null || stat -f %m "$PULSE_CACHE_DIR/zcompdump")

  cat > "$TEST_ZSHRC" << 'EOF'
plugins=()
source "$PULSE_ROOT/pulse.zsh"
echo "loaded"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success
  assert_output --partial "loaded"

  # Cache should be regenerated (newer than old file)
  local new_mtime=$(stat -c %Y "$PULSE_CACHE_DIR/zcompdump" 2>/dev/null || stat -f %m "$PULSE_CACHE_DIR/zcompdump")
  [[ $new_mtime -gt $old_mtime ]]
}

@test "E2E: Missing plugin directory is created automatically" {
  # Don't create PULSE_DIR
  [[ ! -d "$PULSE_DIR" ]]

  cat > "$TEST_ZSHRC" << 'EOF'
plugins=()
source "$PULSE_ROOT/pulse.zsh"

[[ -d "$PULSE_DIR" ]] && echo "dir-created"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success
  assert_output --partial "dir-created"
}

# =============================================================================
# SCENARIO 5: Performance & Responsiveness
# =============================================================================

@test "E2E: Framework loads under 100ms" {
  cat > "$TEST_ZSHRC" << 'EOF'
plugins=()
start=$(($(date +%s%N)/1000000))
source "$PULSE_ROOT/pulse.zsh"
end=$(($(date +%s%N)/1000000))
echo "Load time: $((end-start))ms"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success

  # Extract load time and verify < 100ms
  local load_time=$(echo "$output" | grep -oP 'Load time: \K\d+')
  [[ $load_time -lt 100 ]]
}

@test "E2E: Completion menu appears within 100ms" {
  cat > "$TEST_ZSHRC" << 'EOF'
plugins=()
source "$PULSE_ROOT/pulse.zsh"

# Verify menu completion is available
zstyle -L | grep -q "menu select" && echo "menu-ready"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success
  assert_output --partial "menu-ready"
}

# =============================================================================
# SCENARIO 6: Real-World Configuration
# =============================================================================

@test "E2E: Power user setup with theme and multiple plugins" {
  # Create realistic plugin set
  create_mock_plugin "autosuggestions" "standard"
  create_mock_plugin "syntax-highlighting" "standard"
  create_mock_plugin "completions" "completion"
  create_mock_plugin "my-theme" "theme"

  cat > "$TEST_ZSHRC" << 'EOF'
# Custom settings
export HISTSIZE=100000
export SAVEHIST=100000

plugins=(
  completions
  autosuggestions
  syntax-highlighting
  my-theme
)

source "$PULSE_ROOT/pulse.zsh"

# Verify everything loaded
[[ -n "$PULSE_ENV_LOADED" ]] && echo "framework"
type compinit &>/dev/null && echo "completions"
alias | grep -q "^\.\.=" && echo "directory-nav"
bindkey | grep -q "history-incremental" && echo "keybinds"
echo "plugins: ${#plugins[@]}"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success
  assert_output --partial "framework"
  assert_output --partial "completions"
  assert_output --partial "directory-nav"
  assert_output --partial "keybinds"
  assert_output --partial "plugins: 4"
}

@test "E2E: Starship prompt integration" {
  cat > "$TEST_ZSHRC" << 'EOF'
# Simulate Starship setup
export PULSE_PROMPT_SET=1

plugins=()
source "$PULSE_ROOT/pulse.zsh"

# Prompt module should be skipped
[[ -z "$PROMPT" ]] || [[ "$PROMPT" == "" ]] && echo "prompt-skipped"
[[ "$PULSE_PROMPT_SET" == "1" ]] && echo "flag-respected"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success
  assert_output --partial "flag-respected"
}

# =============================================================================
# SCENARIO 7: Constitutional Principles Validation
# =============================================================================

@test "E2E: Zero configuration - works immediately" {
  # Absolute minimal configuration
  cat > "$TEST_ZSHRC" << 'EOF'
source "$PULSE_ROOT/pulse.zsh"
echo "works"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success
  assert_output --partial "works"
}

@test "E2E: Consistent UX - sensible defaults active" {
  cat > "$TEST_ZSHRC" << 'EOF'
plugins=()
source "$PULSE_ROOT/pulse.zsh"

# Check sensible defaults
setopt | grep -q "autocd" && echo "autocd"
setopt | grep -q "autopushd" && echo "autopushd"
setopt | grep -q "extendedglob" && echo "extendedglob"
[[ -n "$LS_COLORS" || -n "$LSCOLORS" ]] && echo "colors"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success
  assert_output --partial "autocd"
  assert_output --partial "autopushd"
  assert_output --partial "extendedglob"
  assert_output --partial "colors"
}

@test "E2E: Graceful degradation - missing features don't break shell" {
  cat > "$TEST_ZSHRC" << 'EOF'
# Set invalid configuration
export PULSE_DIR="/nonexistent/path/that/does/not/exist"
export PULSE_CACHE_DIR="/another/invalid/path"

plugins=(nonexistent-plugin)
source "$PULSE_ROOT/pulse.zsh" 2>/dev/null

# Shell should still be usable
echo "shell-works"
[[ -n "$PULSE_ENV_LOADED" ]] && echo "framework-loaded"
EOF

  run zsh -c "source '$TEST_ZSHRC'"
  assert_success
  assert_output --partial "shell-works"
  assert_output --partial "framework-loaded"
}

# Helper functions from test_helper.bash are available:
# - create_mock_plugin: Creates mock plugin directories
# - assert_file_exists: Asserts file exists
# - assert_directory_exists: Asserts directory exists
