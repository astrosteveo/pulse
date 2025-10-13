#!/usr/bin/env bats
# Integration tests for plugin loading pipeline

load ../test_helper

@test "standard plugin is loaded in the normal stage" {
  # Create a mock standard plugin
  create_mock_plugin "test-standard" "standard"

  # Source pulse.zsh in a subshell to test loading
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=(test-standard)
    source ${PULSE_ROOT}/pulse.zsh
    echo \${pulse_plugin_stages[test-standard]}
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"normal"* ]]
}

@test "completion plugin is loaded in the compinit stage" {
  # Create a mock completion plugin
  create_mock_plugin "test-completion" "completion"

  # Source pulse.zsh in a subshell to test loading
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=(test-completion)
    source ${PULSE_ROOT}/pulse.zsh
    echo \${pulse_plugin_stages[test-completion]}
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"early"* ]]
}

@test "syntax highlighting plugin is loaded in the late stage" {
  # Create a mock syntax highlighting plugin
  create_mock_plugin "zsh-syntax-highlighting" "syntax"

  # Source pulse.zsh in a subshell to test loading
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=(zsh-syntax-highlighting)
    source ${PULSE_ROOT}/pulse.zsh
    echo \${pulse_plugin_stages[zsh-syntax-highlighting]}
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"late"* ]]
}

@test "invalid plugin path fails gracefully with an error message" {
  # Source pulse.zsh in a subshell to test error handling
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_DEBUG=1
    plugins=(nonexistent-plugin)
    source ${PULSE_ROOT}/pulse.zsh 2>&1
  "

  # Should not crash, but should produce a warning/error message
  [[ "$output" == *"nonexistent-plugin"* ]] || [[ "$output" == *"not found"* ]] || [[ "$output" == *"missing"* ]]
}

@test "plugins load in correct order: early, compinit, normal, late" {
  # Create multiple plugins of different types
  create_mock_plugin "plugin-completion" "completion"
  create_mock_plugin "plugin-standard" "standard"
  create_mock_plugin "zsh-syntax-highlighting" "syntax"

  # Source pulse.zsh and check load order
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    plugins=(plugin-standard plugin-completion zsh-syntax-highlighting)
    source ${PULSE_ROOT}/pulse.zsh
    # Output stage assignments to verify correct classification
    echo \"completion:\${pulse_plugin_stages[plugin-completion]}\"
    echo \"standard:\${pulse_plugin_stages[plugin-standard]}\"
    echo \"syntax:\${pulse_plugin_stages[zsh-syntax-highlighting]}\"
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"completion:early"* ]]
  [[ "$output" == *"standard:normal"* ]]
  [[ "$output" == *"syntax:late"* ]]
}
