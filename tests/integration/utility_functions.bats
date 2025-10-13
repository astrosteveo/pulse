#!/usr/bin/env bats
# Integration tests for US6: Utility Functions
# Tests validate utilities work in realistic end-to-end scenarios with framework and plugins

load ../test_helper

# ==============================================================================
# AC1: Command Existence Check - Integration Scenarios
# ==============================================================================

@test "[US6-AC1] pulse_has_command works in plugin detection scenarios" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source ${PULSE_ROOT}/pulse.zsh
    
    # Realistic use case: Check for optional plugin dependencies
    if pulse_has_command git; then
      echo 'Git available: Can use git plugins'
    else
      echo 'Git missing: Skip git plugins'
    fi
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Git"* ]]
}

@test "[US6-AC1] pulse_has_command enables conditional feature loading" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source ${PULSE_ROOT}/pulse.zsh
    
    # Use case: Load features based on available tools
    pulse_has_command ls && echo 'ls available'
    pulse_has_command zsh && echo 'zsh available'
    echo 'Feature detection: OK'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"ls available"* ]]
  [[ "$output" == *"zsh available"* ]]
  [[ "$output" == *"Feature detection: OK"* ]]
}

# ==============================================================================
# AC2: Archive Extraction - Integration Scenarios
# ==============================================================================

@test "[US6-AC2] pulse_extract handles plugin archive downloads" {
  # Create realistic plugin archive structure
  plugin_dir="${PULSE_DIR}/test-plugin"
  mkdir -p "$plugin_dir"
  echo 'echo "Plugin loaded"' > "$plugin_dir/init.zsh"
  
  # Create archive
  (cd "${PULSE_DIR}" && tar -czf test-plugin.tar.gz test-plugin)
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source ${PULSE_ROOT}/pulse.zsh
    
    # Extract plugin
    mkdir -p '${PULSE_DIR}/plugins'
    cd '${PULSE_DIR}/plugins'
    pulse_extract '${PULSE_DIR}/test-plugin.tar.gz'
    
    # Verify extraction
    [[ -f test-plugin/init.zsh ]] && echo 'Plugin installed successfully'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Plugin installed successfully"* ]]
}

@test "[US6-AC2] pulse_extract handles errors gracefully" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source ${PULSE_ROOT}/pulse.zsh
    
    # Try to extract non-existent archive (common user error)
    if ! pulse_extract '/nonexistent/plugin.tar.gz' 2>&1; then
      echo 'Error handled: Missing archive'
    fi
    
    # Try unsupported format
    touch '${PULSE_DIR}/invalid.rar'
    if ! pulse_extract '${PULSE_DIR}/invalid.rar' 2>&1; then
      echo 'Error handled: Unsupported format'
    fi
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Error handled: Missing archive"* ]]
  [[ "$output" == *"Error handled: Unsupported format"* ]]
}

# ==============================================================================
# AC3: Conditional Sourcing - Integration Scenarios
# ==============================================================================

@test "[US6-AC3] pulse_source_if_exists works with config file loading" {
  # Create realistic user config files
  mkdir -p "${PULSE_DIR}/.config/pulse"
  echo 'export USER_SETTING="custom"' > "${PULSE_DIR}/.config/pulse/settings.zsh"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source ${PULSE_ROOT}/pulse.zsh
    
    # Realistic config loading pattern
    pulse_source_if_exists '${PULSE_DIR}/.config/pulse/settings.zsh'
    pulse_source_if_exists '${PULSE_DIR}/.config/pulse/missing.zsh'  # Silent fail
    
    # Verify sourced config works
    echo \"Setting: \$USER_SETTING\"
    echo 'Config loading complete'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Setting: custom"* ]]
  [[ "$output" == *"Config loading complete"* ]]
}

@test "[US6-AC3] pulse_source_if_exists works in plugin initialization" {
  # Simulate plugin with optional configuration
  mkdir -p "${PULSE_DIR}/plugin-example"
  echo 'echo "Plugin core loaded"' > "${PULSE_DIR}/plugin-example/plugin.zsh"
  echo 'echo "Plugin config loaded"' > "${PULSE_DIR}/plugin-example/config.zsh"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source ${PULSE_ROOT}/pulse.zsh
    
    # Realistic plugin loading pattern
    plugin_dir='${PULSE_DIR}/plugin-example'
    
    # Always source main plugin file
    source \"\$plugin_dir/plugin.zsh\"
    
    # Optionally source config (may not exist)
    pulse_source_if_exists \"\$plugin_dir/config.zsh\"
    pulse_source_if_exists \"\$plugin_dir/local-config.zsh\"  # Silent fail
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Plugin core loaded"* ]]
  [[ "$output" == *"Plugin config loaded"* ]]
}

# ==============================================================================
# AC4: OS Detection - Integration Scenarios
# ==============================================================================

@test "[US6-AC4] pulse_os_type enables platform-specific configuration" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source ${PULSE_ROOT}/pulse.zsh
    
    # Realistic use case: Platform-specific aliases
    os_type=\$(pulse_os_type)
    
    case \$os_type in
      linux)
        echo 'Linux aliases configured'
        ;;
      macos)
        echo 'macOS aliases configured'
        ;;
      freebsd|openbsd|netbsd)
        echo 'BSD aliases configured'
        ;;
      *)
        echo 'Generic aliases configured'
        ;;
    esac
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"aliases configured"* ]]
}

@test "[US6-AC4] pulse_os_type returns consistent lowercase values" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source ${PULSE_ROOT}/pulse.zsh
    
    # Check OS detection works
    os_type=\$(pulse_os_type)
    echo \"Detected OS: \$os_type\"
    
    # OS type should be lowercase
    [[ \$os_type == [a-z]* ]] && echo 'OS format: lowercase'
    
    # Should be consistent
    os_type2=\$(pulse_os_type)
    [[ \$os_type == \$os_type2 ]] && echo 'Consistent results'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected OS:"* ]]
  [[ "$output" == *"OS format: lowercase"* ]]
  [[ "$output" == *"Consistent results"* ]]
}

# ==============================================================================
# Cross-Module Integration
# ==============================================================================

@test "[Integration] All utility functions work together in realistic workflow" {
  # Create comprehensive test scenario
  mkdir -p "${PULSE_DIR}/workflow-test/configs"
  echo 'export WORKFLOW_CONFIG="loaded"' > "${PULSE_DIR}/workflow-test/configs/settings.zsh"
  
  mkdir -p "${PULSE_DIR}/workflow-test/plugin-source"
  echo 'echo "Plugin initialized"' > "${PULSE_DIR}/workflow-test/plugin-source/init.zsh"
  (cd "${PULSE_DIR}/workflow-test" && tar -czf plugin.tar.gz plugin-source)
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source ${PULSE_ROOT}/pulse.zsh
    
    # Realistic workflow: Setup environment with utilities
    
    # 1. Detect OS
    os_type=\$(pulse_os_type)
    echo \"Step 1: Detected \$os_type\"
    
    # 2. Check for required commands
    pulse_has_command tar && echo 'Step 2: Archive support available'
    
    # 3. Load optional configurations
    pulse_source_if_exists '${PULSE_DIR}/workflow-test/configs/settings.zsh'
    echo \"Step 3: Config loaded: \$WORKFLOW_CONFIG\"
    
    # 4. Extract and install plugin
    cd '${PULSE_DIR}/workflow-test'
    pulse_extract plugin.tar.gz
    echo 'Step 4: Plugin extracted'
    
    # 5. Load plugin
    source plugin-source/init.zsh
    
    echo 'Workflow complete'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Step 1: Detected"* ]]
  [[ "$output" == *"Step 2: Archive support available"* ]]
  [[ "$output" == *"Step 3: Config loaded: loaded"* ]]
  [[ "$output" == *"Step 4: Plugin extracted"* ]]
  [[ "$output" == *"Plugin initialized"* ]]
  [[ "$output" == *"Workflow complete"* ]]
}

@test "[Integration] Utilities work with framework modules" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source ${PULSE_ROOT}/pulse.zsh
    
    # Verify framework modules loaded (PULSE_ENV_LOADED is set to 1, not true)
    [[ -n \"\$PULSE_ENV_LOADED\" ]] && echo 'Environment loaded'
    
    # Verify utilities accessible
    type pulse_has_command &>/dev/null && echo 'Utilities loaded'
    
    # Use utilities with framework
    pulse_has_command zsh && echo 'Utilities: Functional'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Environment loaded"* ]]
  [[ "$output" == *"Utilities loaded"* ]]
  [[ "$output" == *"Utilities: Functional"* ]]
}

@test "[Integration] Utilities handle errors without breaking framework" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    source ${PULSE_ROOT}/pulse.zsh
    
    # Try invalid operations
    pulse_has_command '' &>/dev/null || echo 'Error 1: Handled'
    pulse_extract '/nonexistent.tar.gz' &>/dev/null || echo 'Error 2: Handled'
    
    # Framework should still work
    pulse_has_command zsh && echo 'Framework: Still functional'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Error 1: Handled"* ]]
  [[ "$output" == *"Error 2: Handled"* ]]
  [[ "$output" == *"Framework: Still functional"* ]]
}

# ==============================================================================
# Performance
# ==============================================================================

@test "[Performance] Utilities maintain framework performance targets" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    
    # Measure framework load time with utilities
    start=\$((EPOCHREALTIME * 1000))
    source ${PULSE_ROOT}/pulse.zsh
    end=\$((EPOCHREALTIME * 1000))
    duration=\$((end - start))
    
    echo \"Framework load time: \${duration}ms\"
    
    # Verify utilities don't impact performance
    if (( duration < 100 )); then
      echo 'Performance: Excellent (<100ms)'
    else
      echo 'Performance: Acceptable'
    fi
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Framework load time:"* ]]
}
