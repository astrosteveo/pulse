#!/usr/bin/env zsh
# Plugin Engine for Pulse Framework
# Handles plugin detection, classification, and loading across 5 stages

# Initialize plugin state tracking associative arrays
typeset -gA pulse_plugins          # name -> path
typeset -gA pulse_plugin_types     # name -> type
typeset -gA pulse_plugin_stages    # name -> stage
typeset -gA pulse_plugin_status    # name -> status
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
# Supports: user/repo, user/repo@tag, URLs, local paths
_pulse_parse_plugin_spec() {
  local source_spec="$1"
  local plugin_url=""
  local plugin_name=""
  local plugin_ref=""

  # Case 1: Local absolute or relative path
  if [[ "$source_spec" == /* ]] || [[ "$source_spec" == ./* ]] || [[ "$source_spec" == ../* ]]; then
    echo "" "" ""  # No URL for local paths
    return 0
  fi

  # Extract version/branch/tag if specified (e.g., user/repo@v1.0.0)
  if [[ "$source_spec" == *@* ]]; then
    plugin_ref="${source_spec##*@}"
    source_spec="${source_spec%@*}"
  fi

  # Case 2: GitHub shorthand (user/repo)
  if [[ "$source_spec" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
    plugin_url="https://github.com/${source_spec}.git"
    plugin_name="${source_spec##*/}"
    echo "$plugin_url" "$plugin_name" "$plugin_ref"
    return 0
  fi

  # Case 3: Full Git URL (https://... or git@...)
  if [[ "$source_spec" =~ ^(https?://|git@) ]]; then
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
# Supports: GitHub user/repo, full URLs, local paths
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

  # Case 3: GitHub shorthand (user/repo)
  if [[ "$source_spec" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
    local plugin_name="${source_spec##*/}"
    plugin_dir="${PULSE_DIR}/plugins/${plugin_name}"
    echo "$plugin_dir"
    return 0
  fi

  # Case 4: Full Git URL (https://... or git@...)
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
# Usage: _pulse_clone_plugin <plugin_url> <plugin_name> [plugin_ref]
# Returns: 0 on success, 1 on failure
_pulse_clone_plugin() {
  local plugin_url="$1"
  local plugin_name="$2"
  local plugin_ref="${3:-}"
  local plugin_dir="${PULSE_DIR}/plugins/${plugin_name}"

  # Check if git is available
  if ! command -v git >/dev/null 2>&1; then
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: git not found, cannot clone plugins" >&2
    return 1
  fi

  # Create plugins directory if it doesn't exist
  mkdir -p "${PULSE_DIR}/plugins"

  # Clone the plugin
  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Cloning $plugin_name from $plugin_url..." >&2
  
  if [[ -n "$plugin_ref" ]]; then
    # Clone specific branch/tag
    if git clone --quiet --depth 1 --branch "$plugin_ref" "$plugin_url" "$plugin_dir" 2>/dev/null; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Successfully cloned $plugin_name@$plugin_ref" >&2
      return 0
    else
      # Fallback: clone without branch and checkout ref
      if git clone --quiet --depth 1 "$plugin_url" "$plugin_dir" 2>/dev/null; then
        (
          cd "$plugin_dir" || return 1
          git fetch --quiet --depth 1 origin "$plugin_ref" 2>/dev/null && \
          git checkout --quiet "$plugin_ref" 2>/dev/null
        )
        [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Successfully cloned $plugin_name and checked out $plugin_ref" >&2
        return 0
      fi
    fi
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Failed to clone $plugin_name@$plugin_ref" >&2
    return 1
  else
    # Clone default branch
    if git clone --quiet --depth 1 "$plugin_url" "$plugin_dir" 2>/dev/null; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Successfully cloned $plugin_name" >&2
      return 0
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

  # Find and source the main plugin file
  local plugin_file=""

  # Common plugin file patterns (in order of preference)
  local patterns=(
    "${plugin_path}/${plugin_name}.plugin.zsh"
    "${plugin_path}/${plugin_name}.zsh"
    "${plugin_path}/init.zsh"
    "${plugin_path}/${plugin_name}.sh"
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

    # Resolve to full path
    local plugin_path=$(_pulse_resolve_plugin_source "$plugin_spec")

    # Auto-install if missing and we have a URL
    if [[ ! -d "$plugin_path" ]] && [[ -n "$plugin_url" ]]; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Plugin '$plugin_name' not found, attempting to install..." >&2
      if _pulse_clone_plugin "$plugin_url" "$plugin_name" "$plugin_ref"; then
        [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Successfully installed $plugin_name" >&2
      else
        [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Warning: Failed to install $plugin_name" >&2
      fi
    fi

    # Detect plugin type
    local plugin_type=$(_pulse_detect_plugin_type "$plugin_path")

    # Assign load stage
    local plugin_stage=$(_pulse_assign_stage "$plugin_name" "$plugin_type")

    # Register plugin
    pulse_plugins[$plugin_name]="$plugin_path"
    pulse_plugin_types[$plugin_name]="$plugin_type"
    pulse_plugin_stages[$plugin_name]="$plugin_stage"
    pulse_plugin_status[$plugin_name]="registered"

    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Registered: $plugin_name (type=$plugin_type, stage=$plugin_stage)" >&2
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
