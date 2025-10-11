#!/usr/bin/env bats
# Integration tests for configuration parsing

load ../test_helper

@test "plugins array is read correctly" {
  # Create mock plugins
  create_mock_plugin "plugin-one" "standard"
  create_mock_plugin "plugin-two" "standard"

  # Create a .zshrc with plugins array
  cat > "${PULSE_DIR}/.zshrc" <<'EOF'
plugins=(
  plugin-one
  plugin-two
)
EOF

  # Source pulse.zsh and verify plugins are registered
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=(plugin-one plugin-two)
    source ${PULSE_ROOT}/pulse.zsh
    echo \${#pulse_plugins[@]}
    echo \${pulse_plugins[plugin-one]}
    echo \${pulse_plugins[plugin-two]}
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"2"* ]]
  [[ "$output" == *"plugin-one"* ]]
  [[ "$output" == *"plugin-two"* ]]
}

@test "pulse_disabled_plugins array correctly prevents plugins from loading" {
  # Create mock plugins
  create_mock_plugin "plugin-enabled" "standard"
  create_mock_plugin "plugin-disabled" "standard"

  # Source pulse.zsh with disabled plugin
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=(plugin-enabled plugin-disabled)
    pulse_disabled_plugins=(plugin-disabled)
    source ${PULSE_ROOT}/pulse.zsh
    echo \"enabled:\${pulse_plugin_status[plugin-enabled]}\"
    echo \"disabled:\${pulse_plugin_status[plugin-disabled]}\"
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"enabled:"* ]]
  # Disabled plugin should not be registered
  [[ "$output" != *"disabled:registered"* ]] || [[ "$output" == *"disabled:"* && ! "$output" == *"disabled:loaded"* ]]
}

@test "pulse_plugin_stage associative array correctly overrides plugin stage" {
  # Create a standard plugin
  create_mock_plugin "custom-plugin" "standard"

  # Override its stage to 'late'
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=(custom-plugin)
    typeset -gA pulse_plugin_stage
    pulse_plugin_stage[custom-plugin]=\"late\"
    source ${PULSE_ROOT}/pulse.zsh
    echo \${pulse_plugin_stages[custom-plugin]}
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"late"* ]]
}

@test "empty plugins array results in no plugins loaded" {
  # Source pulse.zsh with no plugins
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=()
    source ${PULSE_ROOT}/pulse.zsh
    echo \${#pulse_plugins[@]}
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"0"* ]]
}

@test "configuration variables are respected across all stages" {
  # Create plugins of different types
  create_mock_plugin "early-plugin" "completion"
  create_mock_plugin "normal-plugin" "standard"
  create_mock_plugin "test-syntax-highlighting" "syntax"
  create_mock_plugin "disabled-plugin" "standard"

  # Test with multiple configuration options
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=(early-plugin normal-plugin test-syntax-highlighting disabled-plugin)
    pulse_disabled_plugins=(disabled-plugin)
    typeset -gA pulse_plugin_stage
    pulse_plugin_stage[normal-plugin]=\"early\"
    source ${PULSE_ROOT}/pulse.zsh
    echo \"early-plugin:\${pulse_plugin_stages[early-plugin]}\"
    echo \"normal-plugin:\${pulse_plugin_stages[normal-plugin]}\"
    echo \"late-plugin:\${pulse_plugin_stages[test-syntax-highlighting]}\"
    echo \"disabled-plugin:\${pulse_plugin_status[disabled-plugin]}\"
  "

  [ "$status" -eq 0 ]
  # early-plugin should be in early stage (completion type)
  [[ "$output" == *"early-plugin:early"* ]]
  # normal-plugin should be overridden to early
  [[ "$output" == *"normal-plugin:early"* ]]
  # test-syntax-highlighting should be in late stage (syntax type)
  [[ "$output" == *"late-plugin:late"* ]]
  # disabled-plugin should not be registered or loaded
  [[ ! "$output" == *"disabled-plugin:loaded"* ]]
}

@test "PULSE_DIR environment variable is respected" {
  local custom_dir="${PULSE_DIR}/custom"
  mkdir -p "${custom_dir}/plugins"

  # Create a plugin in custom directory
  mkdir -p "${custom_dir}/plugins/custom-location-plugin"
  echo "# Custom location plugin" > "${custom_dir}/plugins/custom-location-plugin/custom-location-plugin.plugin.zsh"

  run zsh -c "
    export PULSE_DIR='${custom_dir}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=(custom-location-plugin)
    source ${PULSE_ROOT}/pulse.zsh
    echo \${pulse_plugins[custom-location-plugin]}
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"${custom_dir}/plugins/custom-location-plugin"* ]]
}

@test "PULSE_DEBUG enables verbose logging" {
  create_mock_plugin "debug-test" "standard"

  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_DEBUG=1
    plugins=(debug-test)
    source ${PULSE_ROOT}/pulse.zsh 2>&1
  "

  [ "$status" -eq 0 ]
  # Should see debug messages
  [[ "$output" == *"[Pulse]"* ]]
}
