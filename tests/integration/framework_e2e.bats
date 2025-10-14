#!/usr/bin/env bats
# End-to-end tests for framework support (Oh-My-Zsh and Prezto)
# These tests demonstrate real-world usage scenarios

load ../test_helper

@test "oh-my-zsh kubectl plugin can be loaded and used" {
  # Create a mock oh-my-zsh kubectl plugin similar to the real one
  local kubectl_dir="${PULSE_DIR}/plugins/ohmyzsh/plugins/kubectl"
  mkdir -p "$kubectl_dir"
  
  cat > "$kubectl_dir/kubectl.plugin.zsh" <<'EOF'
# Mock oh-my-zsh kubectl plugin
# This simulates the real kubectl plugin behavior

# Check if kubectl is available
if (( $+commands[kubectl] )); then
  # Would normally generate completions here
  : # no-op
fi

# Define aliases (subset of real plugin)
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
EOF
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    typeset -ga pulse_disabled_modules
    pulse_disabled_modules=(compinit completions)
    
    plugins=(
      ohmyzsh/ohmyzsh/plugins/kubectl
    )
    
    source ${PULSE_ROOT}/pulse.zsh
    
    # Verify environment variables are set
    echo \"ZSH=\${ZSH}\"
    echo \"ZSH_CACHE_DIR=\${ZSH_CACHE_DIR}\"
    
    # Verify aliases are defined
    type k >/dev/null 2>&1 && echo 'alias-k-defined'
    type kgp >/dev/null 2>&1 && echo 'alias-kgp-defined'
    type kgs >/dev/null 2>&1 && echo 'alias-kgs-defined'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"ZSH=${PULSE_DIR}/plugins/ohmyzsh"* ]]
  [[ "$output" == *"ZSH_CACHE_DIR=${PULSE_CACHE_DIR}/ohmyzsh"* ]]
  [[ "$output" == *"alias-k-defined"* ]]
  [[ "$output" == *"alias-kgp-defined"* ]]
  [[ "$output" == *"alias-kgs-defined"* ]]
}

@test "multiple oh-my-zsh plugins can be loaded together" {
  # Create mock oh-my-zsh plugins
  local git_dir="${PULSE_DIR}/plugins/ohmyzsh/plugins/git"
  local docker_dir="${PULSE_DIR}/plugins/ohmyzsh/plugins/docker"
  
  mkdir -p "$git_dir" "$docker_dir"
  
  cat > "$git_dir/git.plugin.zsh" <<'EOF'
alias g=git
alias gst='git status'
EOF
  
  cat > "$docker_dir/docker.plugin.zsh" <<'EOF'
alias d=docker
alias dps='docker ps'
EOF
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    typeset -ga pulse_disabled_modules
    pulse_disabled_modules=(compinit completions)
    
    plugins=(
      ohmyzsh/ohmyzsh/plugins/git
      ohmyzsh/ohmyzsh/plugins/docker
    )
    
    source ${PULSE_ROOT}/pulse.zsh
    
    # Verify both plugins loaded
    type g >/dev/null 2>&1 && echo 'git-alias-g'
    type gst >/dev/null 2>&1 && echo 'git-alias-gst'
    type d >/dev/null 2>&1 && echo 'docker-alias-d'
    type dps >/dev/null 2>&1 && echo 'docker-alias-dps'
    
    # Verify they share the same ZSH environment
    echo \"ZSH=\${ZSH}\"
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"git-alias-g"* ]]
  [[ "$output" == *"git-alias-gst"* ]]
  [[ "$output" == *"docker-alias-d"* ]]
  [[ "$output" == *"docker-alias-dps"* ]]
  [[ "$output" == *"ZSH=${PULSE_DIR}/plugins/ohmyzsh"* ]]
}

@test "prezto git module can be loaded" {
  # Create a mock prezto git module
  local git_module_dir="${PULSE_DIR}/plugins/prezto/modules/git"
  mkdir -p "$git_module_dir"
  
  cat > "$git_module_dir/init.zsh" <<'EOF'
# Mock prezto git module
# Check ZPREZTODIR is set
if [[ -n "${ZPREZTODIR}" ]]; then
  echo "ZPREZTODIR-set"
fi

# Check pmodload function exists
if typeset -f pmodload >/dev/null; then
  echo "pmodload-available"
fi

# Define some aliases
alias g=git
alias gst='git status'
EOF
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    typeset -ga pulse_disabled_modules
    pulse_disabled_modules=(compinit completions)
    
    plugins=(
      sorin-ionescu/prezto/modules/git
    )
    
    source ${PULSE_ROOT}/pulse.zsh
    
    # Verify aliases are defined
    type g >/dev/null 2>&1 && echo 'alias-g-defined'
    type gst >/dev/null 2>&1 && echo 'alias-gst-defined'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"ZPREZTODIR-set"* ]]
  [[ "$output" == *"pmodload-available"* ]]
  [[ "$output" == *"alias-g-defined"* ]]
  [[ "$output" == *"alias-gst-defined"* ]]
}

@test "oh-my-zsh and regular plugins can be mixed" {
  # Create an oh-my-zsh plugin and a regular plugin
  local omz_dir="${PULSE_DIR}/plugins/ohmyzsh/plugins/docker"
  local regular_dir="${PULSE_DIR}/plugins/my-custom-plugin"
  
  mkdir -p "$omz_dir" "$regular_dir"
  
  cat > "$omz_dir/docker.plugin.zsh" <<'EOF'
alias d=docker
EOF
  
  cat > "$regular_dir/my-custom-plugin.plugin.zsh" <<'EOF'
alias mycmd='echo custom'
EOF
  
  run zsh -c "
    export PULSE_DIR='${PULSE_DIR}'
    export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
    export PULSE_NO_COMPINIT=1
    typeset -ga pulse_disabled_modules
    pulse_disabled_modules=(compinit completions)
    
    plugins=(
      ohmyzsh/ohmyzsh/plugins/docker
      my-custom-plugin
    )
    
    source ${PULSE_ROOT}/pulse.zsh
    
    # Verify both plugins loaded
    type d >/dev/null 2>&1 && echo 'omz-alias-loaded'
    type mycmd >/dev/null 2>&1 && echo 'custom-alias-loaded'
  "
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"omz-alias-loaded"* ]]
  [[ "$output" == *"custom-alias-loaded"* ]]
}
