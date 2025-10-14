#!/usr/bin/env zsh
# Plugin Engine for Pulse Framework
# Handles plugin detection, classification, and loading across 5 stages

# NOTE: This code assumes default zsh array indexing (1-based).
# If KSH_ARRAYS is set, array indexing will be 0-based and break this code.
# This is intentional - Pulse requires standard zsh behavior.

# Initialize plugin state tracking associative arrays
typeset -gA pulse_plugins          # name -> path
typeset -gA pulse_plugin_types     # name -> type
typeset -gA pulse_plugin_stages    # name -> stage
typeset -gA pulse_plugin_status    # name -> status
typeset -gA pulse_plugin_basenames # name -> basename (for framework plugins)
typeset -ga pulse_load_order       # ordered list of plugins to load

# Define load stages
typeset -gA PULSE_STAGES
PULSE_STAGES=(
  early 1
  compinit 2
  normal 3
  late 4
  deferred 5
)

#
# Plugin Type Detection
#

# Detect plugin type based on file structure and naming patterns
# Usage: _pulse_detect_plugin_type <plugin_dir>
# Returns: completion, syntax, theme, or standard
_pulse_detect_plugin_type() {
  local plugin_dir="$1"

  # Handle non-existent directory
  [[ ! -d "$plugin_dir" ]] && echo "standard" && return 0

  # Check for completion plugin indicators
  if [[ -d "$plugin_dir/completions" ]] || \
     [[ -n "$(find "$plugin_dir" -maxdepth 1 -name '_*' -type f 2>/dev/null)" ]]; then
    echo "completion"
    return 0
  fi

  # Check for syntax highlighting plugins by name pattern
  local plugin_name="${plugin_dir:t}"
  if [[ "$plugin_name" == *-syntax-highlighting ]] || \
     [[ "$plugin_name" == *-highlighters ]]; then
    echo "syntax"
    return 0
  fi

  # Check for theme plugins
  if [[ -n "$(find "$plugin_dir" -maxdepth 1 -name '*.zsh-theme' -type f 2>/dev/null)" ]]; then
    echo "theme"
    return 0
  fi

  # Default to standard plugin
  echo "standard"
  return 0
}

#
# Plugin Source Detection
#

# Parse plugin specification into components
# Usage: _pulse_parse_plugin_spec <source_spec>
# Returns: plugin_url plugin_name plugin_ref (space-separated)
# Supports: user/repo, user/repo@tag, URLs, local paths, framework paths
_pulse_parse_plugin_spec() {
  local source_spec="$1"
  local plugin_url=""
  local plugin_name=""
  local plugin_ref=""

  # Trim leading/trailing whitespace
  source_spec="${source_spec##[[:space:]]}"
  source_spec="${source_spec%%[[:space:]]}"

  # Skip empty specs
  if [[ -z "$source_spec" ]]; then
    echo "" "" ""
    return 0
  fi

  # Case 1: Local absolute or relative path
  if [[ "$source_spec" == /* ]] || [[ "$source_spec" == ./* ]] || [[ "$source_spec" == ../* ]]; then
    echo "" "" ""  # No URL for local paths
    return 0
  fi
  
  # Case 2: Framework-specific paths (ohmyzsh/ohmyzsh/plugins/*, sorin-ionescu/prezto/modules/*)
  # These need special handling to preserve the full path structure
  if [[ "$source_spec" =~ ^ohmyzsh/ohmyzsh/plugins/ ]]; then
    # Extract plugin name and construct URL
    local omz_plugin="${source_spec#ohmyzsh/ohmyzsh/plugins/}"
    plugin_url="https://github.com/ohmyzsh/ohmyzsh.git"
    plugin_name="ohmyzsh"
    echo "$plugin_url" "$plugin_name" "$plugin_ref"
    return 0
  fi
  
  if [[ "$source_spec" =~ ^sorin-ionescu/prezto/modules/ ]]; then
    # Extract module name and construct URL
    local prezto_module="${source_spec#sorin-ionescu/prezto/modules/}"
    plugin_url="https://github.com/sorin-ionescu/prezto.git"
    plugin_name="prezto"
    echo "$plugin_url" "$plugin_name" "$plugin_ref"
    return 0
  fi

  # Case 3: Git SSH URL (git@host:user/repo.git or git@host:user/repo.git@ref)
  # Must check BEFORE general @ splitting to avoid breaking SSH URLs
  if [[ "$source_spec" =~ ^git@[^:]+: ]]; then
    # SSH URL format: git@host:path.git or git@host:path.git@ref
    # Split ONLY on the LAST @ if there are multiple
    if [[ "$source_spec" =~ @[^@]+$ ]] && [[ "$source_spec" =~ \.git@[^@]+$ ]]; then
      # Has version spec after .git
      plugin_ref="${source_spec##*.git@}"
      source_spec="${source_spec%.git@*}.git"
    fi
    plugin_url="$source_spec"
    plugin_name="${source_spec##*/}"
    plugin_name="${plugin_name%.git}"
    echo "$plugin_url" "$plugin_name" "$plugin_ref"
    return 0
  fi

  # Extract version/branch/tag if specified (e.g., user/repo@v1.0.0)
  # Only for non-SSH URLs
  if [[ "$source_spec" == *@* ]]; then
    # Check for multiple @ symbols (excluding SSH URL case already handled)
    local at_count=$(echo "$source_spec" | grep -o '@' | wc -l)
    if [[ $at_count -gt 1 ]]; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Warning: Multiple @ symbols in spec: $source_spec" >&2
    fi
    plugin_ref="${source_spec##*@}"
    source_spec="${source_spec%@*}"
    
    # Validate ref is not empty (handles trailing @)
    if [[ -z "$plugin_ref" ]]; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Warning: Empty version ref in spec (trailing @): $1" >&2
      plugin_ref=""
    fi
  fi

  # Case 4: GitHub shorthand (user/repo)
  if [[ "$source_spec" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
    plugin_url="https://github.com/${source_spec}.git"
    plugin_name="${source_spec##*/}"
    echo "$plugin_url" "$plugin_name" "$plugin_ref"
    return 0
  fi

  # Case 5: Full Git URL (https://... or http://...)
  if [[ "$source_spec" =~ ^https?:// ]]; then
    plugin_url="$source_spec"
    plugin_name="${source_spec##*/}"
    plugin_name="${plugin_name%.git}"
    echo "$plugin_url" "$plugin_name" "$plugin_ref"
    return 0
  fi

  # Default: treat as plugin name only
  echo "" "$source_spec" ""
  return 0
}

# Resolve plugin source specification to a full path
# Usage: _pulse_resolve_plugin_source <source_spec>
# Supports: GitHub user/repo, full URLs, local paths, framework paths
# Returns: Full path to plugin directory
_pulse_resolve_plugin_source() {
  local source_spec="$1"
  local plugin_dir=""

  # Strip version spec if present
  source_spec="${source_spec%@*}"

  # Case 1: Local absolute path
  if [[ "$source_spec" == /* ]]; then
    echo "$source_spec"
    return 0
  fi

  # Case 2: Local relative path (starts with ./ or ../)
  if [[ "$source_spec" == ./* ]] || [[ "$source_spec" == ../* ]]; then
    echo "$(cd "$source_spec" 2>/dev/null && pwd)"
    return 0
  fi
  
  # Case 3: Oh-My-Zsh plugin path (ohmyzsh/ohmyzsh/plugins/*)
  if [[ "$source_spec" =~ ^ohmyzsh/ohmyzsh/plugins/ ]]; then
    local omz_plugin="${source_spec#ohmyzsh/ohmyzsh/plugins/}"
    plugin_dir="${PULSE_DIR}/plugins/ohmyzsh/plugins/${omz_plugin}"
    echo "$plugin_dir"
    return 0
  fi
  
  # Case 4: Prezto module path (sorin-ionescu/prezto/modules/*)
  if [[ "$source_spec" =~ ^sorin-ionescu/prezto/modules/ ]]; then
    local prezto_module="${source_spec#sorin-ionescu/prezto/modules/}"
    plugin_dir="${PULSE_DIR}/plugins/prezto/modules/${prezto_module}"
    echo "$plugin_dir"
    return 0
  fi

  # Case 5: GitHub shorthand (user/repo)
  if [[ "$source_spec" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
    local plugin_name="${source_spec##*/}"
    plugin_dir="${PULSE_DIR}/plugins/${plugin_name}"
    echo "$plugin_dir"
    return 0
  fi

  # Case 6: Full Git URL (https://... or git@...)
  if [[ "$source_spec" =~ ^(https?://|git@) ]]; then
    # Extract plugin name from URL (last component without .git)
    local plugin_name="${source_spec##*/}"
    plugin_name="${plugin_name%.git}"
    plugin_dir="${PULSE_DIR}/plugins/${plugin_name}"
    echo "$plugin_dir"
    return 0
  fi

  # Default: assume it's a plugin name in PULSE_DIR
  echo "${PULSE_DIR}/plugins/${source_spec}"
  return 0
}

#
# Plugin Installation
#

# Clone a plugin from a Git URL
# Usage: _pulse_clone_plugin <plugin_url> <plugin_name> [plugin_ref] [sparse_path]
# Returns: 0 on success, 1 on failure
# sparse_path: Optional subdirectory path for sparse checkout (e.g., "plugins/kubectl" for omz)
_pulse_clone_plugin() {
  local plugin_url="$1"
  local plugin_name="$2"
  local plugin_ref="${3:-}"
  local sparse_path="${4:-}"
  local plugin_dir="${PULSE_DIR}/plugins/${plugin_name}"

  # Check if git is available
  if ! command -v git >/dev/null 2>&1; then
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: git not found, cannot clone plugins" >&2
    return 1
  fi

  # Create plugins directory if it doesn't exist
  mkdir -p "${PULSE_DIR}/plugins"

  # Determine if we should use sparse checkout
  local use_sparse=0
  if [[ -n "$sparse_path" ]]; then
    use_sparse=1
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Using sparse checkout for $plugin_name (path: $sparse_path)..." >&2
  fi

  # Clone the plugin
  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Cloning $plugin_name from $plugin_url..." >&2
  
  if [[ $use_sparse -eq 1 ]]; then
    # Sparse checkout approach for framework plugins
    # This significantly reduces disk usage by only fetching needed files
    
    # Step 1: Clone with --filter=blob:none --no-checkout
    if ! git clone --quiet --filter=blob:none --no-checkout "$plugin_url" "$plugin_dir" 2>/dev/null; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Failed to clone $plugin_name with sparse checkout" >&2
      rm -rf "$plugin_dir" 2>/dev/null
      return 1
    fi
    
    # Step 2: Configure sparse-checkout
    local checkout_failed=0
    local original_dir="$PWD"
    if ! cd "$plugin_dir" 2>/dev/null; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Failed to cd to $plugin_dir" >&2
      cd "$original_dir"
      rm -rf "$plugin_dir" 2>/dev/null
      return 1
    fi
    
    # Enable sparse checkout and set the path
    if ! git sparse-checkout set --no-cone "$sparse_path" 2>/dev/null; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Failed to configure sparse checkout" >&2
      cd "$original_dir"
      rm -rf "$plugin_dir" 2>/dev/null
      return 1
    fi
    
    # Step 3: Checkout the files (defaults to default branch or specified ref)
    if [[ -n "$plugin_ref" ]]; then
      if ! git checkout --quiet "$plugin_ref" 2>/dev/null; then
        [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Failed to checkout $plugin_ref" >&2
        cd "$original_dir"
        rm -rf "$plugin_dir" 2>/dev/null
        return 1
      fi
    else
      if ! git checkout 2>/dev/null; then
        [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Failed to checkout files" >&2
        cd "$original_dir"
        rm -rf "$plugin_dir" 2>/dev/null
        return 1
      fi
    fi
    
    cd "$original_dir"
    
    # Verify checkout succeeded
    if [[ -d "$plugin_dir/.git" ]] && [[ -d "$plugin_dir/$sparse_path" ]]; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Successfully cloned $plugin_name with sparse checkout" >&2
      return 0
    else
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Sparse checkout incomplete for $plugin_name" >&2
      rm -rf "$plugin_dir" 2>/dev/null
      return 1
    fi
    
  elif [[ -n "$plugin_ref" ]]; then
    # Clone specific branch/tag (standard approach)
    local clone_error=""
    if git clone --quiet --depth 1 --branch "$plugin_ref" "$plugin_url" "$plugin_dir" 2>&1 | read -r clone_error; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Successfully cloned $plugin_name@$plugin_ref" >&2
      return 0
    else
      # Fallback: clone without branch and checkout ref
      local fallback_error=""
      if git clone --quiet --depth 1 "$plugin_url" "$plugin_dir" 2>&1 | read -r fallback_error; then
        # Use command grouping instead of subshell to preserve return code
        local checkout_failed=0
        if ! cd "$plugin_dir" 2>/dev/null; then
          [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Failed to cd to $plugin_dir" >&2
          checkout_failed=1
        elif ! git fetch --quiet --depth 1 origin "$plugin_ref" 2>/dev/null; then
          [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Failed to fetch $plugin_ref" >&2
          checkout_failed=1
        elif ! git checkout --quiet "$plugin_ref" 2>/dev/null; then
          [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Failed to checkout $plugin_ref" >&2
          checkout_failed=1
        fi
        cd - >/dev/null
        
        if [[ $checkout_failed -eq 0 ]]; then
          [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Successfully cloned $plugin_name and checked out $plugin_ref" >&2
          return 0
        else
          [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Checkout failed for $plugin_name@$plugin_ref" >&2
          return 1
        fi
      fi
    fi
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Failed to clone $plugin_name@$plugin_ref" >&2
    return 1
  else
    # Clone default branch (standard approach)
    local clone_error=""
    if git clone --quiet --depth 1 "$plugin_url" "$plugin_dir" 2>&1 | read -r clone_error; then
      # Verify clone succeeded by checking .git directory
      if [[ -d "$plugin_dir/.git" ]]; then
        [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Successfully cloned $plugin_name" >&2
        return 0
      else
        [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Clone incomplete for $plugin_name (no .git directory)" >&2
        rm -rf "$plugin_dir" 2>/dev/null
        return 1
      fi
    else
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Failed to clone $plugin_name" >&2
      return 1
    fi
  fi
}

#
# Stage Assignment
#

# Assign a plugin to the appropriate load stage based on its type
# Usage: _pulse_assign_stage <plugin_name> <plugin_type>
# Returns: stage name (early, normal, late, deferred)
_pulse_assign_stage() {
  local plugin_name="$1"
  local plugin_type="$2"

  # Check for manual override
  if [[ -n "${pulse_plugin_stage[$plugin_name]}" ]]; then
    echo "${pulse_plugin_stage[$plugin_name]}"
    return 0
  fi

  # Assign stage based on type
  case "$plugin_type" in
    completion)
      echo "early"
      ;;
    syntax)
      echo "late"
      ;;
    theme)
      echo "late"
      ;;
    standard|*)
      echo "normal"
      ;;
  esac

  return 0
}

#
# Framework Support
#

# Set up framework-specific environment variables
# Usage: _pulse_setup_framework_env <plugin_path>
_pulse_setup_framework_env() {
  local plugin_path="$1"
  
  # Check if this is an oh-my-zsh plugin
  if [[ "$plugin_path" == */ohmyzsh/plugins/* ]]; then
    # Set up Oh-My-Zsh environment variables
    # Extract the path up to and including /ohmyzsh
    local omz_root="${plugin_path%/plugins/*}"
    export ZSH="$omz_root"
    export ZSH_CACHE_DIR="${PULSE_CACHE_DIR}/ohmyzsh"
    export ZSH_CUSTOM="${ZSH}/custom"
    
    # Create cache directory with completions subdirectory
    mkdir -p "${ZSH_CACHE_DIR}/completions"
    
    # Add oh-my-zsh completions to fpath if not already present
    # Check if completions directory is not already in fpath
    if (( ! ${fpath[(Ie)${ZSH_CACHE_DIR}/completions]} )); then
      fpath=("${ZSH_CACHE_DIR}/completions" $fpath)
    fi
    
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Set up Oh-My-Zsh environment: ZSH=$ZSH, ZSH_CACHE_DIR=$ZSH_CACHE_DIR" >&2
    return 0
  fi
  
  # Check if this is a prezto module
  if [[ "$plugin_path" == */prezto/modules/* ]]; then
    # Set up Prezto environment variables
    # Extract the path up to and including /prezto
    local prezto_root="${plugin_path%/modules/*}"
    export ZPREZTODIR="$prezto_root"
    
    # Define pmodload function if not already defined
    if ! typeset -f pmodload >/dev/null 2>&1; then
      # Minimal pmodload implementation for compatibility
      # Prezto modules expect the pmodload function to be defined.
      # This shim loads the init.zsh file for each specified Prezto module.
      pmodload() {
        local pmodule
        for pmodule in "$@"; do
          local pmodule_location="${ZPREZTODIR}/modules/${pmodule}/init.zsh"
          if [[ -f "$pmodule_location" ]]; then
            source "$pmodule_location"
          fi
        done
      }
    fi
    
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Set up Prezto environment: ZPREZTODIR=$ZPREZTODIR" >&2
    return 0
  fi
  
  return 0
}

#
# Plugin Loading
#

# Load a single plugin by sourcing its main file
# Usage: _pulse_load_plugin <plugin_name> <plugin_path>
_pulse_load_plugin() {
  local plugin_name="$1"
  local plugin_path="$2"

  # Check if plugin directory exists
  if [[ ! -d "$plugin_path" ]]; then
    pulse_plugin_status[$plugin_name]="missing"
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Warning: Plugin '$plugin_name' not found at $plugin_path" >&2
    return 1
  fi

  # Mark as loading
  pulse_plugin_status[$plugin_name]="loading"
  
  # Set up framework-specific environment if needed
  _pulse_setup_framework_env "$plugin_path"

  # Find and source the main plugin file
  local plugin_file=""
  
  # Determine the actual plugin basename to use for file lookup
  # For framework plugins, use the stored basename; otherwise use plugin_name
  local plugin_basename="${pulse_plugin_basenames[$plugin_name]:-$plugin_name}"
  
  # If no basename stored, extract from path as fallback
  if [[ -z "$plugin_basename" ]]; then
    plugin_basename="${plugin_path##*/}"
  fi

  # Common plugin file patterns (in order of preference)
  local patterns=(
    "${plugin_path}/${plugin_basename}.plugin.zsh"
    "${plugin_path}/${plugin_basename}.zsh"
    "${plugin_path}/init.zsh"
    "${plugin_path}/${plugin_basename}.sh"
  )

  for pattern in "${patterns[@]}"; do
    if [[ -f "$pattern" ]]; then
      plugin_file="$pattern"
      break
    fi
  done

  # If no standard plugin file found, try to source any .zsh file
  if [[ -z "$plugin_file" ]]; then
    plugin_file="$(find "$plugin_path" -maxdepth 1 -name '*.zsh' -type f 2>/dev/null | head -n 1)"
  fi

  # Source the plugin file if found
  if [[ -n "$plugin_file" && -f "$plugin_file" ]]; then
    source "$plugin_file"
    pulse_plugin_status[$plugin_name]="loaded"
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Loaded: $plugin_name" >&2
    return 0
  else
    pulse_plugin_status[$plugin_name]="error"
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: No loadable file found for plugin '$plugin_name'" >&2
    return 1
  fi
}

#
# 5-Stage Loading Pipeline
#

# Execute the 5-stage loading pipeline for all configured plugins
# Usage: _pulse_load_stages
_pulse_load_stages() {
  # Stage 1: Early (before compinit)
  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Stage 1: Early" >&2
  for plugin_name in "${(@k)pulse_plugins}"; do
    if [[ "${pulse_plugin_stages[$plugin_name]}" == "early" ]]; then
      local plugin_path="${pulse_plugins[$plugin_name]}"

      # For completion plugins, add to fpath before sourcing
      if [[ "${pulse_plugin_types[$plugin_name]}" == "completion" ]]; then
        # Add plugin directory to fpath
        fpath=("$plugin_path" $fpath)

        # Also add completions subdirectory if it exists
        [[ -d "$plugin_path/completions" ]] && fpath=("$plugin_path/completions" $fpath)
      fi

      _pulse_load_plugin "$plugin_name" "$plugin_path"
    fi
  done

  # Stage 2: Compinit (run completion system)
  if [[ -z "$PULSE_NO_COMPINIT" ]]; then
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Stage 2: Compinit" >&2
    autoload -Uz compinit
    compinit -d "${PULSE_CACHE_DIR}/zcompdump"
  fi

  # Stage 3: Normal (standard plugins)
  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Stage 3: Normal" >&2
  for plugin_name in "${(@k)pulse_plugins}"; do
    if [[ "${pulse_plugin_stages[$plugin_name]}" == "normal" ]]; then
      _pulse_load_plugin "$plugin_name" "${pulse_plugins[$plugin_name]}"
    fi
  done

  # Stage 4: Late (syntax highlighting, themes)
  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Stage 4: Late" >&2
  for plugin_name in "${(@k)pulse_plugins}"; do
    if [[ "${pulse_plugin_stages[$plugin_name]}" == "late" ]]; then
      _pulse_load_plugin "$plugin_name" "${pulse_plugins[$plugin_name]}"
    fi
  done

  # Stage 5: Deferred (lazy loading - not executed here)
  # Deferred plugins are loaded on-demand via command wrappers
  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Stage 5: Deferred (on-demand)" >&2
}

#
# Plugin Discovery and Registration
#

# Discover and register all plugins from the plugins array
# Usage: _pulse_discover_plugins
_pulse_discover_plugins() {
  # Ensure plugins array exists
  if [[ ! -v plugins ]]; then
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] No plugins array defined" >&2
    return 0
  fi

  # Process each plugin specification
  for plugin_spec in "${plugins[@]}"; do
    # Skip if in disabled list
    if [[ -n "${pulse_disabled_plugins[(r)$plugin_spec]}" ]]; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Skipping disabled plugin: $plugin_spec" >&2
      continue
    fi

    # Parse plugin specification
    local parsed=($(_pulse_parse_plugin_spec "$plugin_spec"))
    local plugin_url="${parsed[1]}"
    local plugin_name="${parsed[2]}"
    local plugin_ref="${parsed[3]}"

    # Fallback: extract plugin name from spec if parsing failed
    if [[ -z "$plugin_name" ]]; then
      plugin_name="${plugin_spec##*/}"
      plugin_name="${plugin_name%.git}"
      plugin_name="${plugin_name%@*}"
    fi
    
    # For framework plugins, extract the basename and use a simpler registry key
    # Store the basename separately for correct file lookup
    # Use underscore as delimiter since colon and slash cause issues in Zsh subscripts
    local plugin_registry_name="$plugin_name"
    local plugin_basename=""
    if [[ "$plugin_spec" =~ ^ohmyzsh/ohmyzsh/plugins/ ]]; then
      plugin_basename="${plugin_spec##*/}"
      # Use omz_ prefix to avoid collisions while keeping it readable
      plugin_registry_name="omz_${plugin_basename}"
    elif [[ "$plugin_spec" =~ ^sorin-ionescu/prezto/modules/ ]]; then
      plugin_basename="${plugin_spec##*/}"
      # Use prezto_ prefix to avoid collisions while keeping it readable
      plugin_registry_name="prezto_${plugin_basename}"
    fi

    # Validate plugin name is not empty and doesn't contain path traversal
    if [[ -z "$plugin_name" ]] || [[ "$plugin_name" == *..* ]] || [[ "$plugin_name" == /* ]]; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Invalid plugin name: $plugin_spec" >&2
      continue
    fi

    # Resolve to full path
    local plugin_path=$(_pulse_resolve_plugin_source "$plugin_spec")

    # Auto-install if missing and we have a URL
    if [[ ! -d "$plugin_path" ]] && [[ -n "$plugin_url" ]]; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Plugin '$plugin_registry_name' not found, attempting to install..." >&2
      
      # Ensure plugins directory exists before creating lock
      mkdir -p "${PULSE_DIR}/plugins"
      
      # For framework plugins, we use sparse checkout to only fetch needed files
      # Determine the actual target directory for cloning
      local clone_target_dir="${PULSE_DIR}/plugins/${plugin_name}"
      
      # For framework plugins, determine sparse path and check if already cloned
      local framework_root=""
      local sparse_path=""
      if [[ "$plugin_spec" =~ ^ohmyzsh/ohmyzsh/plugins/ ]]; then
        framework_root="${PULSE_DIR}/plugins/ohmyzsh"
        # Extract the plugin subdirectory path (e.g., "plugins/kubectl")
        local omz_plugin="${plugin_spec#ohmyzsh/ohmyzsh/}"
        sparse_path="$omz_plugin"
      elif [[ "$plugin_spec" =~ ^sorin-ionescu/prezto/modules/ ]]; then
        framework_root="${PULSE_DIR}/plugins/prezto"
        # Extract the module subdirectory path (e.g., "modules/git")
        local prezto_module="${plugin_spec#sorin-ionescu/prezto/}"
        sparse_path="$prezto_module"
      fi
      
      # Check if the specific plugin/module path already exists
      local plugin_already_exists=0
      if [[ -n "$framework_root" ]] && [[ -d "$plugin_path" ]]; then
        plugin_already_exists=1
        [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Plugin already installed at $plugin_path" >&2
      fi
      
      if [[ $plugin_already_exists -eq 0 ]]; then
        # Create lock file to prevent race conditions
        local lock_file="${PULSE_DIR}/plugins/.${plugin_name}.lock"
        local lock_acquired=0
        
        # Try to acquire lock with timeout
        for i in {1..30}; do
          if mkdir "$lock_file" 2>/dev/null; then
            lock_acquired=1
            break
          fi
          [[ -n "$PULSE_DEBUG" ]] && [[ $i -eq 1 ]] && echo "[Pulse] Waiting for lock on $plugin_name..." >&2
          sleep 0.1
        done
        
        if [[ $lock_acquired -eq 1 ]]; then
          # Check again if plugin path exists (another shell may have created it)
          if [[ ! -d "$plugin_path" ]]; then
            # For framework plugins with existing repo, add sparse path
            if [[ -n "$framework_root" ]] && [[ -d "$framework_root/.git" ]] && [[ -n "$sparse_path" ]]; then
              [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Adding $sparse_path to existing framework at $framework_root..." >&2
              
              # Add the new sparse path to existing checkout
              local original_dir="$PWD"
              if cd "$framework_root" 2>/dev/null; then
                # Add the new path to sparse-checkout
                if git sparse-checkout add "$sparse_path" 2>/dev/null; then
                  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Successfully added $sparse_path to framework" >&2
                else
                  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Warning: Failed to add $sparse_path to framework" >&2
                fi
                cd "$original_dir"
              fi
            else
              # Clone the plugin (with sparse checkout for frameworks)
              if _pulse_clone_plugin "$plugin_url" "$plugin_name" "$plugin_ref" "$sparse_path"; then
                [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Successfully installed $plugin_name" >&2
              else
                [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Warning: Failed to install $plugin_name" >&2
              fi
            fi
          fi
          # Release lock
          rmdir "$lock_file" 2>/dev/null
        else
          [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Warning: Could not acquire lock for $plugin_name" >&2
        fi
      fi
    fi

    # Detect plugin type
    local plugin_type=$(_pulse_detect_plugin_type "$plugin_path")

    # Assign load stage
    local plugin_stage=$(_pulse_assign_stage "$plugin_registry_name" "$plugin_type")

    # Register plugin with unique name
    pulse_plugins[$plugin_registry_name]="$plugin_path"
    pulse_plugin_types[$plugin_registry_name]="$plugin_type"
    pulse_plugin_stages[$plugin_registry_name]="$plugin_stage"
    pulse_plugin_status[$plugin_registry_name]="registered"
    
    # Store basename for framework plugins to enable correct file lookup
    if [[ -n "$plugin_basename" ]]; then
      pulse_plugin_basenames[$plugin_registry_name]="$plugin_basename"
    fi

    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Registered: $plugin_registry_name (type=$plugin_type, stage=$plugin_stage, path=$plugin_path)" >&2
  done
}

# Initialize the plugin engine
_pulse_init_engine() {
  # Set default PULSE_DIR if not set
  : ${PULSE_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/pulse}
  : ${PULSE_CACHE_DIR:=${XDG_CACHE_HOME:-$HOME/.cache}/pulse}

  # Create directories if they don't exist
  [[ ! -d "$PULSE_DIR" ]] && mkdir -p "$PULSE_DIR/plugins"
  [[ ! -d "$PULSE_CACHE_DIR" ]] && mkdir -p "$PULSE_CACHE_DIR"

  # Initialize disabled plugins array if not set
  typeset -ga pulse_disabled_plugins 2>/dev/null

  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Engine initialized (PULSE_DIR=$PULSE_DIR)" >&2
}
