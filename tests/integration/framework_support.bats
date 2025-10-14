#!/usr/bin/env bats
# Integration tests for framework support (Oh-My-Zsh and Prezto)

load ../test_helper

@test "oh-my-zsh plugin path is resolved correctly" {
  # Test that ohmyzsh/ohmyzsh/plugins/kubectl spec is parsed correctly
  run zsh -c "
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    export PULSE_DIR='${PULSE_DIR}'
    
    # Parse the oh-my-zsh plugin spec
    parsed=(\$(_pulse_parse_plugin_spec 'ohmyzsh/ohmyzsh/plugins/kubectl'))
    echo \"url=\${parsed[1]}\"
    echo \"name=\${parsed[2]}\"
    
    # Resolve the plugin source
    path=\$(_pulse_resolve_plugin_source 'ohmyzsh/ohmyzsh/plugins/kubectl')
    echo \"path=\${path}\"
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"url=https://github.com/ohmyzsh/ohmyzsh.git"* ]]
  [[ "$output" == *"name=ohmyzsh"* ]]
  [[ "$output" == *"path=${PULSE_DIR}/plugins/ohmyzsh/plugins/kubectl"* ]]
}

@test "prezto module path is resolved correctly" {
  # Test that sorin-ionescu/prezto/modules/git spec is parsed correctly
  run zsh -c "
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    export PULSE_DIR='${PULSE_DIR}'
    
    # Parse the prezto module spec
    parsed=(\$(_pulse_parse_plugin_spec 'sorin-ionescu/prezto/modules/git'))
    echo \"url=\${parsed[1]}\"
    echo \"name=\${parsed[2]}\"
    
    # Resolve the plugin source
    path=\$(_pulse_resolve_plugin_source 'sorin-ionescu/prezto/modules/git')
    echo \"path=\${path}\"
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"url=https://github.com/sorin-ionescu/prezto.git"* ]]
  [[ "$output" == *"name=prezto"* ]]
  [[ "$output" == *"path=${PULSE_DIR}/plugins/prezto/modules/git"* ]]
}

@test "oh-my-zsh environment variables are set when loading omz plugin" {
  # Create a mock oh-my-zsh plugin structure
  local omz_plugin_dir="${PULSE_DIR}/plugins/ohmyzsh/plugins/test-plugin"
  mkdir -p "$omz_plugin_dir"
  
  # Create a simple plugin file that echoes the environment
  cat > "$omz_plugin_dir/test-plugin.plugin.zsh" <<'EOF'
echo "ZSH=${ZSH}"
echo "ZSH_CACHE_DIR=${ZSH_CACHE_DIR}"
EOF
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    
    # Load the plugin
    _pulse_setup_framework_env '$omz_plugin_dir'
    _pulse_load_plugin 'test-plugin' '$omz_plugin_dir'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"ZSH=${PULSE_DIR}/plugins/ohmyzsh"* ]]
  [[ "$output" == *"ZSH_CACHE_DIR=${PULSE_CACHE_DIR}/ohmyzsh"* ]]
}

@test "prezto environment variables are set when loading prezto module" {
  # Create a mock prezto module structure
  local prezto_module_dir="${PULSE_DIR}/plugins/prezto/modules/test-module"
  mkdir -p "$prezto_module_dir"
  
  # Create a simple module file that echoes the environment
  cat > "$prezto_module_dir/init.zsh" <<'EOF'
echo "ZPREZTODIR=${ZPREZTODIR}"
typeset -f pmodload >/dev/null && echo "pmodload=defined"
EOF
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    
    # Load the module
    _pulse_setup_framework_env '$prezto_module_dir'
    _pulse_load_plugin 'test-module' '$prezto_module_dir'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"ZPREZTODIR=${PULSE_DIR}/plugins/prezto"* ]]
  [[ "$output" == *"pmodload=defined"* ]]
}

@test "oh-my-zsh plugin creates unique registry name" {
  # Test that multiple oh-my-zsh plugins get unique names
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    typeset -ga pulse_disabled_modules
    pulse_disabled_modules=(compinit completions)
    
    # Create mock plugin directories
    mkdir -p '${PULSE_DIR}/plugins/ohmyzsh/plugins/git'
    mkdir -p '${PULSE_DIR}/plugins/ohmyzsh/plugins/docker'
    
    echo 'echo git-plugin' > '${PULSE_DIR}/plugins/ohmyzsh/plugins/git/git.plugin.zsh'
    echo 'echo docker-plugin' > '${PULSE_DIR}/plugins/ohmyzsh/plugins/docker/docker.plugin.zsh'
    
    plugins=(
      ohmyzsh/ohmyzsh/plugins/git
      ohmyzsh/ohmyzsh/plugins/docker
    )
    
    source ${PULSE_ROOT}/pulse.zsh
    
    # Check that both plugins are registered with unique names
    echo \"git=\${pulse_plugins[omz-git]}\"
    echo \"docker=\${pulse_plugins[omz-docker]}\"
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"git=${PULSE_DIR}/plugins/ohmyzsh/plugins/git"* ]]
  [[ "$output" == *"docker=${PULSE_DIR}/plugins/ohmyzsh/plugins/docker"* ]]
}

@test "prezto module creates unique registry name" {
  # Test that multiple prezto modules get unique names
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    typeset -ga pulse_disabled_modules
    pulse_disabled_modules=(compinit completions)
    
    # Create mock module directories
    mkdir -p '${PULSE_DIR}/plugins/prezto/modules/git'
    mkdir -p '${PULSE_DIR}/plugins/prezto/modules/terminal'
    
    echo 'echo git-module' > '${PULSE_DIR}/plugins/prezto/modules/git/init.zsh'
    echo 'echo terminal-module' > '${PULSE_DIR}/plugins/prezto/modules/terminal/init.zsh'
    
    plugins=(
      sorin-ionescu/prezto/modules/git
      sorin-ionescu/prezto/modules/terminal
    )
    
    source ${PULSE_ROOT}/pulse.zsh
    
    # Check that both modules are registered with unique names
    echo \"git=\${pulse_plugins[prezto-git]}\"
    echo \"terminal=\${pulse_plugins[prezto-terminal]}\"
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"git=${PULSE_DIR}/plugins/prezto/modules/git"* ]]
  [[ "$output" == *"terminal=${PULSE_DIR}/plugins/prezto/modules/terminal"* ]]
}

@test "oh-my-zsh cache directory is created" {
  # Create a mock oh-my-zsh plugin
  local omz_plugin_dir="${PULSE_DIR}/plugins/ohmyzsh/plugins/test"
  mkdir -p "$omz_plugin_dir"
  echo 'echo loaded' > "$omz_plugin_dir/test.plugin.zsh"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    
    # Set up framework environment
    _pulse_setup_framework_env '$omz_plugin_dir'
    
    # Check that cache directories were created
    [[ -d '${PULSE_CACHE_DIR}/ohmyzsh' ]] && echo 'cache-dir-created'
    [[ -d '${PULSE_CACHE_DIR}/ohmyzsh/completions' ]] && echo 'completions-dir-created'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"cache-dir-created"* ]]
  [[ "$output" == *"completions-dir-created"* ]]
}

@test "oh-my-zsh completions directory is added to fpath" {
  # Create a mock oh-my-zsh plugin
  local omz_plugin_dir="${PULSE_DIR}/plugins/ohmyzsh/plugins/test"
  mkdir -p "$omz_plugin_dir"
  echo 'echo loaded' > "$omz_plugin_dir/test.plugin.zsh"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    
    # Set up framework environment
    _pulse_setup_framework_env '$omz_plugin_dir'
    
    # Check that completions directory is in fpath
    echo \"\${fpath}\" | grep -q '${PULSE_CACHE_DIR}/ohmyzsh/completions' && echo 'in-fpath'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"in-fpath"* ]]
}
