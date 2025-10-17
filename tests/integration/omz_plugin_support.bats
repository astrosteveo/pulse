#!/usr/bin/env bats
# Integration test for omz plugin loading with helm example

load ../test_helper

setup() {
  # Create temporary test directory
  TEST_TMPDIR="$(mktemp -d)"
  export PULSE_DIR="${TEST_TMPDIR}/.local/share/pulse"
  export PULSE_CACHE_DIR="${TEST_TMPDIR}/.cache/pulse"
  mkdir -p "${PULSE_DIR}/plugins"
  mkdir -p "${PULSE_CACHE_DIR}"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

@test "omz plugin loads with ZSH_CACHE_DIR set" {
  # Create a mock omz helm plugin
  local omz_dir="${PULSE_DIR}/plugins/ohmyzsh"
  local helm_plugin="${omz_dir}/plugins/helm"
  mkdir -p "$helm_plugin"
  
  # Create a minimal helm.plugin.zsh that uses ZSH_CACHE_DIR
  cat > "${helm_plugin}/helm.plugin.zsh" << 'EOF'
# Test that ZSH_CACHE_DIR is set
if [[ -z "$ZSH_CACHE_DIR" ]]; then
  echo "ERROR: ZSH_CACHE_DIR not set"
  exit 1
fi

# Test that completions directory exists
if [[ ! -d "$ZSH_CACHE_DIR/completions" ]]; then
  echo "ERROR: ZSH_CACHE_DIR/completions does not exist"
  exit 1
fi

echo "helm plugin loaded with ZSH_CACHE_DIR=$ZSH_CACHE_DIR"
EOF

  # Source the plugin engine and load the plugin
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export ZSH_DISABLE_COMPFIX=1
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    _pulse_load_plugin 'helm' '${helm_plugin}'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"helm plugin loaded"* ]]
  [[ "$output" != *"ERROR"* ]]
}

@test "multiple omz plugins share same ohmyzsh repo" {
  # Source plugin-engine and test with multiple plugins
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export ZSH_DISABLE_COMPFIX=1
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    
    # Parse multiple omz plugin specs
    result1=(\$(_pulse_parse_plugin_spec 'omz:plugins/git'))
    result2=(\$(_pulse_parse_plugin_spec 'omz:plugins/kubectl'))
    result3=(\$(_pulse_parse_plugin_spec 'omz:plugins/helm'))
    
    # All should have unique plugin names
    echo \"plugin1: \${result1[2]}\"
    echo \"plugin2: \${result2[2]}\"
    echo \"plugin3: \${result3[2]}\"
    
    # But share the same URL (ohmyzsh repo)
    echo \"url1: \${result1[1]}\"
    echo \"url2: \${result2[1]}\"
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"plugin1: git"* ]]
  [[ "$output" == *"plugin2: kubectl"* ]]
  [[ "$output" == *"plugin3: helm"* ]]
  [[ "$output" == *"url1: https://github.com/ohmyzsh/ohmyzsh.git"* ]]
  [[ "$output" == *"url2: https://github.com/ohmyzsh/ohmyzsh.git"* ]]
}

@test "ZSH environment variable points to ohmyzsh directory" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export ZSH_DISABLE_COMPFIX=1
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    echo \$ZSH
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"${PULSE_DIR}/plugins/ohmyzsh"* ]]
}

@test "ZPREZTODIR environment variable points to prezto directory" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export ZSH_DISABLE_COMPFIX=1
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    echo \$ZPREZTODIR
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"${PULSE_DIR}/plugins/prezto"* ]]
}

@test "ZSH_CACHE_DIR/completions directory is created" {
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export ZSH_DISABLE_COMPFIX=1
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    [[ -d \$ZSH_CACHE_DIR/completions ]] && echo 'directory exists'
  "

  [ "$status" -eq 0 ]
  [[ "$output" == *"directory exists"* ]]
}
