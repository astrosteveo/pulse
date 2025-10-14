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
    echo \"git=\${pulse_plugins[omz_git]}\"
    echo \"docker=\${pulse_plugins[omz_docker]}\"
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
    echo \"git=\${pulse_plugins[prezto_git]}\"
    echo \"terminal=\${pulse_plugins[prezto_terminal]}\"
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

@test "sparse checkout clones only specified plugin directory plus dependencies" {
  # Skip if git is not available or doesn't support sparse-checkout
  run git sparse-checkout --help
  [ "$status" -eq 0 ] || skip "git sparse-checkout not available"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_DEBUG=1
    
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    
    # Clone with sparse checkout
    _pulse_clone_plugin 'https://github.com/ohmyzsh/ohmyzsh.git' 'ohmyzsh' '' 'plugins/kubectl'
    
    # Check that kubectl plugin was cloned
    [[ -d '${PULSE_DIR}/plugins/ohmyzsh/plugins/kubectl' ]] && echo 'kubectl-exists'
    [[ ! -d '${PULSE_DIR}/plugins/ohmyzsh/plugins/docker' ]] && echo 'docker-not-exists'
    [[ -f '${PULSE_DIR}/plugins/ohmyzsh/plugins/kubectl/kubectl.plugin.zsh' ]] && echo 'plugin-file-exists'
    # Check that lib directory is also included (required for plugin dependencies)
    [[ -d '${PULSE_DIR}/plugins/ohmyzsh/lib' ]] && echo 'lib-exists'
    [[ -f '${PULSE_DIR}/plugins/ohmyzsh/lib/git.zsh' ]] && echo 'lib-git-exists'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"kubectl-exists"* ]]
  [[ "$output" == *"docker-not-exists"* ]]
  [[ "$output" == *"plugin-file-exists"* ]]
  [[ "$output" == *"lib-exists"* ]]
  [[ "$output" == *"lib-git-exists"* ]]
}

@test "sparse checkout adds additional plugin to existing framework" {
  # Skip if git is not available or doesn't support sparse-checkout
  run git sparse-checkout --help
  [ "$status" -eq 0 ] || skip "git sparse-checkout not available"
  
  # First, clone with one plugin
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    
    # Clone with sparse checkout
    _pulse_clone_plugin 'https://github.com/ohmyzsh/ohmyzsh.git' 'ohmyzsh' '' 'plugins/kubectl'
  "
  [ "$status" -eq 0 ]
  
  # Now add another plugin
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_DEBUG=1
    
    cd '${PULSE_DIR}/plugins/ohmyzsh'
    git sparse-checkout add 'plugins/docker'
    
    # Check that both plugins exist
    [[ -d '${PULSE_DIR}/plugins/ohmyzsh/plugins/kubectl' ]] && echo 'kubectl-exists'
    [[ -d '${PULSE_DIR}/plugins/ohmyzsh/plugins/docker' ]] && echo 'docker-exists'
    # Check that lib directory is still present
    [[ -d '${PULSE_DIR}/plugins/ohmyzsh/lib' ]] && echo 'lib-still-exists'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"kubectl-exists"* ]]
  [[ "$output" == *"docker-exists"* ]]
  [[ "$output" == *"lib-still-exists"* ]]
}

@test "sparse checkout reduces disk usage compared to full clone" {
  # Skip if git is not available or doesn't support sparse-checkout
  run git sparse-checkout --help
  [ "$status" -eq 0 ] || skip "git sparse-checkout not available"
  
  # Clone with sparse checkout
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    
    _pulse_clone_plugin 'https://github.com/ohmyzsh/ohmyzsh.git' 'ohmyzsh' '' 'plugins/kubectl'
    
    # Get size in KB
    du -sk '${PULSE_DIR}/plugins/ohmyzsh' | awk '{print \$1}'
  "
  [ "$status" -eq 0 ]
  
  # Parse the size from output
  local sparse_size=$(echo "$output" | tail -1)

  # Now, clone the full repository into a temp dir and measure its size
  local full_clone_dir
  full_clone_dir=$(mktemp -d)
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$full_clone_dir/ohmyzsh" > /dev/null 2>&1
  local full_size=$(du -sk "$full_clone_dir/ohmyzsh" | awk '{print $1}')

  # Clean up the temp dir
  rm -rf "$full_clone_dir"

  # Sparse checkout should be significantly less than full clone (e.g., less than half)
  if [ "$full_size" -eq 0 ]; then
    skip "Full clone size could not be determined"
  fi
  [ "$sparse_size" -lt $(( full_size / 2 )) ]
}

@test "prezto sparse checkout includes helper module dependency" {
  # Skip if git is not available or doesn't support sparse-checkout
  run git sparse-checkout --help
  [ "$status" -eq 0 ] || skip "git sparse-checkout not available"
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_DEBUG=1
    
    source ${PULSE_ROOT}/lib/plugin-engine.zsh
    _pulse_init_engine
    
    # Clone git module with sparse checkout
    _pulse_clone_plugin 'https://github.com/sorin-ionescu/prezto.git' 'prezto' '' 'modules/git'
    
    # Check that git module was cloned
    [[ -d '${PULSE_DIR}/plugins/prezto/modules/git' ]] && echo 'git-module-exists'
    [[ -f '${PULSE_DIR}/plugins/prezto/modules/git/init.zsh' ]] && echo 'git-init-exists'
    # Check that helper module is also included (required dependency for git module)
    [[ -d '${PULSE_DIR}/plugins/prezto/modules/helper' ]] && echo 'helper-module-exists'
    [[ -f '${PULSE_DIR}/plugins/prezto/modules/helper/init.zsh' ]] && echo 'helper-init-exists'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"git-module-exists"* ]]
  [[ "$output" == *"git-init-exists"* ]]
  [[ "$output" == *"helper-module-exists"* ]]
  [[ "$output" == *"helper-init-exists"* ]]
}
