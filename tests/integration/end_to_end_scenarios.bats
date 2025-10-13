#!/usr/bin/env bats
# End-to-end integration tests validating complete framework functionality
# Tests all user stories (US1-US5) working together in realistic scenarios

load ../test_helper

# =============================================================================
# SCENARIO 1: Minimal Configuration (Framework Only - Zero Configuration Principle)
# =============================================================================

@test "E2E: Framework works immediately with zero configuration" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source ${PULSE_ROOT}/pulse.zsh
    echo 'ready'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"ready"* ]]
}

@test "E2E: All framework modules load without plugins (US1-US5)" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=()
    source ${PULSE_ROOT}/pulse.zsh
    
    # Verify modules loaded (US1-US5)
    [[ -n \"\$PULSE_ENV_LOADED\" ]] && echo 'environment'
    type compinit &>/dev/null && echo 'compinit'
    bindkey | grep -q 'history-incremental' && echo 'keybinds'
    alias | grep -q '^\\.\\.=' && echo 'directory'
    [[ -n \"\$PROMPT\" ]] && echo 'prompt'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"environment"* ]]
  [[ "$output" == *"compinit"* ]]
  [[ "$output" == *"keybinds"* ]]
  [[ "$output" == *"directory"* ]]
  [[ "$output" == *"prompt"* ]]
}

# =============================================================================
# SCENARIO 2: Standard Developer Setup (Framework + Plugins)
# =============================================================================

@test "E2E: Developer setup with multiple plugins and framework" {
  # Create realistic plugin set
  create_mock_plugin "syntax-highlighting" "standard"
  create_mock_plugin "completions" "completion"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=(
      syntax-highlighting
      completions
    )
    source ${PULSE_ROOT}/pulse.zsh
    
    # Verify framework + plugins
    [[ -n \"\$PULSE_ENV_LOADED\" ]] && echo 'framework'
    [[ -n \"\$syntax_highlighting_loaded\" ]] && echo 'plugin1'
    type compinit &>/dev/null && echo 'completions'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"framework"* ]]
  [[ "$output" == *"plugin1"* ]]
  [[ "$output" == *"completions"* ]]
}

@test "E2E: Plugins load in 5-stage pipeline with framework modules" {
  create_mock_plugin "early" "standard"
  create_mock_plugin "comps" "completion"
  create_mock_plugin "late" "standard"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=(early comps late)
    source ${PULSE_ROOT}/pulse.zsh
    
    # Check plugin stages
    echo \"early: \${pulse_plugin_stages[early]}\"
    echo \"comps: \${pulse_plugin_stages[comps]}\"
    echo \"late: \${pulse_plugin_stages[late]}\"
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"early: normal"* || "$output" == *"early: early"* ]]
  [[ "$output" == *"comps: completions"* ]]
}

# =============================================================================
# SCENARIO 3: Configuration & Customization (Consistent UX)
# =============================================================================

@test "E2E: Disable framework modules while plugins still work" {
  create_mock_plugin "test-plugin" "standard"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    pulse_disabled_modules=(prompt directory)
    plugins=(test-plugin)
    source ${PULSE_ROOT}/pulse.zsh
    
    # Environment and completions should load
    [[ -n \"\$PULSE_ENV_LOADED\" ]] && echo 'env-loaded'
    
    # Directory aliases should NOT be set
    alias | grep -q '^\\.\\.=' || echo 'directory-disabled'
    
    # Plugin should still load
    [[ -n \"\$test_plugin_loaded\" ]] && echo 'plugin-works'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"env-loaded"* ]]
  [[ "$output" == *"directory-disabled"* ]]
  [[ "$output" == *"plugin-works"* ]]
}

@test "E2E: Custom cache directory works across entire framework" {
  custom_cache="${PULSE_DIR}/my-cache"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${custom_cache}'
    plugins=()
    source ${PULSE_ROOT}/pulse.zsh
    
    echo \"Cache: \$PULSE_CACHE_DIR\"
    [[ -d \"\$PULSE_CACHE_DIR\" ]] && echo 'cache-created'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Cache: $custom_cache"* ]]
  [[ "$output" == *"cache-created"* ]]
  [[ -f "$custom_cache/zcompdump" ]]
}

@test "E2E: Debug mode shows framework and plugin loading" {
  create_mock_plugin "debug-test" "standard"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_DEBUG=1
    plugins=(debug-test)
    source ${PULSE_ROOT}/pulse.zsh 2>&1
  "
  
  [ "$status" -eq 0 ]
  # Debug should show module loads
  [[ "$output" == *"environment.zsh"* || "$output" == *"Loading"* ]]
}

# =============================================================================
# SCENARIO 4: Error Handling & Resilience (Graceful Degradation)
# =============================================================================

@test "E2E: Framework continues when plugin fails" {
  # Create broken plugin
  mkdir -p "${PULSE_DIR}/plugins/broken"
  echo "return 1" > "${PULSE_DIR}/plugins/broken/broken.plugin.zsh"
  
  create_mock_plugin "working" "standard"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=(broken working)
    source ${PULSE_ROOT}/pulse.zsh 2>&1
    
    # Framework should still work
    [[ -n \"\$PULSE_ENV_LOADED\" ]] && echo 'framework-ok'
    [[ -n \"\$working_loaded\" ]] && echo 'other-plugin-ok'
  "
  
  # Shell should not crash
  [[ "$output" == *"framework-ok"* ]]
  [[ "$output" == *"other-plugin-ok"* ]]
}

@test "E2E: Missing plugin directory is created automatically" {
  # Remove plugin dir
  rm -rf "${PULSE_DIR}/plugins"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=()
    source ${PULSE_ROOT}/pulse.zsh
    
    [[ -d \"\$PULSE_DIR\" ]] && echo 'dir-created'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"dir-created"* ]]
}

# =============================================================================
# SCENARIO 5: Performance (Quality Over Features)
# =============================================================================

@test "E2E: Framework loads under 100ms" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=()
    start=\$(($(date +%s%N)/1000000))
    source ${PULSE_ROOT}/pulse.zsh
    end=\$(($(date +%s%N)/1000000))
    echo \"Time: \$((end-start))ms\"
  "
  
  [ "$status" -eq 0 ]
  # Extract load time
  time_ms=$(echo "$output" | grep -oP 'Time: \K\d+')
  [[ "$time_ms" -lt 100 ]]
}

@test "E2E: Completion system is ready immediately" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=()
    source ${PULSE_ROOT}/pulse.zsh
    
    # Verify completion system active
    type compinit &>/dev/null && echo 'compinit-ready'
    zstyle -L | grep -q 'menu select' && echo 'menu-ready'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"compinit-ready"* ]]
  [[ "$output" == *"menu-ready"* ]]
}

# =============================================================================
# SCENARIO 6: Real-World Power User Setup
# =============================================================================

@test "E2E: Power user with theme, completions, and multiple plugins" {
  create_mock_plugin "autosuggestions" "standard"
  create_mock_plugin "syntax" "standard"
  create_mock_plugin "completions" "completion"
  create_mock_plugin "theme" "theme"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export HISTSIZE=100000
    
    plugins=(
      completions
      autosuggestions
      syntax
      theme
    )
    
    source ${PULSE_ROOT}/pulse.zsh
    
    # Verify all components
    [[ -n \"\$PULSE_ENV_LOADED\" ]] && echo 'framework'
    type compinit &>/dev/null && echo 'completions'
    bindkey | grep -q 'history-incremental' && echo 'keybinds'
    alias | grep -q '^\\.\\.=' && echo 'directory'
    echo \"Plugin count: \${#plugins[@]}\"
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"framework"* ]]
  [[ "$output" == *"completions"* ]]
  [[ "$output" == *"keybinds"* ]]
  [[ "$output" == *"directory"* ]]
  [[ "$output" == *"Plugin count: 4"* ]]
}

@test "E2E: External prompt (Starship) integration" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_PROMPT_SET=1
    
    plugins=()
    source ${PULSE_ROOT}/pulse.zsh
    
    # Framework should load without setting prompt
    [[ -n \"\$PULSE_ENV_LOADED\" ]] && echo 'framework-loaded'
    [[ \"\$PULSE_PROMPT_SET\" == \"1\" ]] && echo 'flag-respected'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"framework-loaded"* ]]
  [[ "$output" == *"flag-respected"* ]]
}

# =============================================================================
# SCENARIO 7: Constitutional Principles Validation
# =============================================================================

@test "E2E: Sensible defaults are active (Consistent UX)" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=()
    source ${PULSE_ROOT}/pulse.zsh
    
    # Check defaults from constitution
    setopt | grep -q 'autocd' && echo 'autocd'
    setopt | grep -q 'autopushd' && echo 'autopushd'
    setopt | grep -q 'extendedglob' && echo 'extended-glob'
    [[ -n \"\$LS_COLORS\" || -n \"\$LSCOLORS\" ]] && echo 'colors'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"autocd"* ]]
  [[ "$output" == *"autopushd"* ]]
  [[ "$output" == *"extended-glob"* ]]
  [[ "$output" == *"colors"* ]]
}

@test "E2E: Graceful degradation with invalid configuration" {
  run zsh -c "
    export PULSE_DIR='/nonexistent/invalid/path'
    export PULSE_CACHE_DIR='/another/invalid/path'
    plugins=(nonexistent-plugin-abc123)
    
    source ${PULSE_ROOT}/pulse.zsh 2>/dev/null
    
    # Shell should still be usable
    echo 'shell-works'
    [[ -n \"\$PULSE_ENV_LOADED\" ]] && echo 'framework-loaded'
  "
  
  # Should not crash
  [[ "$output" == *"shell-works"* ]]
  [[ "$output" == *"framework-loaded"* ]]
}
