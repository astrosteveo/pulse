#!/usr/bin/env zsh
# Plugin Engine for Pulse Framework
# Handles plugin detection, classification, and loading across 5 stages

# NOTE: This code assumes default zsh array indexing (1-based).
# If KSH_ARRAYS is set, array indexing will be 0-based and break this code.
# This is intentional - Pulse requires standard zsh behavior.

# Source lock file library for reproducible installs
# Only source if lock-file.zsh exists and hasn't been sourced yet
if [[ -f "${0:A:h}/cli/lib/lock-file.zsh" ]] && [[ ! -v PULSE_LOCK_FILE_SOURCED ]]; then
  source "${0:A:h}/cli/lib/lock-file.zsh"
  typeset -g PULSE_LOCK_FILE_SOURCED=1
fi

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

  # Case 2: Git SSH URL (git@host:user/repo.git or git@host:user/repo.git@ref)
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
    # Only output ref if non-empty (for accurate word count)
    if [[ -n "$plugin_ref" ]]; then
      echo "$plugin_url" "$plugin_name" "$plugin_ref"
    else
      echo "$plugin_url" "$plugin_name"
    fi
    return 0
  fi

  # Extract version/branch/tag if specified (e.g., user/repo@v1.0.0)
  # Only for non-SSH URLs
  if [[ "$source_spec" == *@* ]]; then
    # Check for multiple @ symbols (excluding SSH URL case already handled)
    # Silently handle - caller can validate if needed
    plugin_ref="${source_spec##*@}"
    source_spec="${source_spec%@*}"

    # Treat @latest as empty ref (clone default branch)
    # This provides explicit self-documenting syntax for default branch
    if [[ "$plugin_ref" == "latest" ]]; then
      plugin_ref=""
    fi

    # Clear empty ref (handles trailing @)
    if [[ -z "$plugin_ref" ]]; then
      plugin_ref=""
    fi
  fi

  # Case 3: GitHub shorthand (user/repo)
  if [[ "$source_spec" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
    plugin_url="https://github.com/${source_spec}.git"
    plugin_name="${source_spec##*/}"
    # Only output ref if non-empty (for accurate word count)
    if [[ -n "$plugin_ref" ]]; then
      echo "$plugin_url" "$plugin_name" "$plugin_ref"
    else
      echo "$plugin_url" "$plugin_name"
    fi
    return 0
  fi

  # Case 4: Full Git URL (https://... or http://...)
  if [[ "$source_spec" =~ ^https?:// ]]; then
    plugin_url="$source_spec"
    plugin_name="${source_spec##*/}"
    plugin_name="${plugin_name%.git}"
    # Only output ref if non-empty (for accurate word count)
    if [[ -n "$plugin_ref" ]]; then
      echo "$plugin_url" "$plugin_name" "$plugin_ref"
    else
      echo "$plugin_url" "$plugin_name"
    fi
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
    # Clone default branch
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

    # Validate plugin name is not empty and doesn't contain path traversal
    if [[ -z "$plugin_name" ]] || [[ "$plugin_name" == *..* ]] || [[ "$plugin_name" == /* ]]; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Invalid plugin name: $plugin_spec" >&2
      continue
    fi

    # Resolve to full path
    local plugin_path=$(_pulse_resolve_plugin_source "$plugin_spec")

    # Auto-install if missing and we have a URL
    if [[ ! -d "$plugin_path" ]] && [[ -n "$plugin_url" ]]; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Plugin '$plugin_name' not found, attempting to install..." >&2

      # Ensure plugins directory exists before creating lock
      mkdir -p "${PULSE_DIR}/plugins"

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
        # Check again if directory exists (another shell may have created it)
        if [[ ! -d "$plugin_path" ]]; then
          if _pulse_clone_plugin "$plugin_url" "$plugin_name" "$plugin_ref"; then
            [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Successfully installed $plugin_name" >&2
          else
            [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Warning: Failed to install $plugin_name" >&2
          fi
        fi
        # Release lock
        rmdir "$lock_file" 2>/dev/null
      else
        [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Warning: Could not acquire lock for $plugin_name" >&2
      fi
    fi

    # Detect plugin type
    local plugin_type=$(_pulse_detect_plugin_type "$plugin_path")

    # Assign load stage
    local plugin_stage=$(_pulse_assign_stage "$plugin_name" "$plugin_type")

    # Update lock file with plugin installation (if library is available)
    if [[ -n "$PULSE_LOCK_FILE_SOURCED" ]] && [[ -d "$plugin_path/.git" ]]; then
      # Extract exact commit SHA
      local commit_sha=""
      commit_sha=$(git -C "$plugin_path" rev-parse HEAD 2>/dev/null)

      if [[ -n "$commit_sha" ]]; then
        # Get current timestamp in ISO8601 format
        local timestamp=""
        if command -v date >/dev/null 2>&1; then
          timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
        fi

        # Write lock entry (create lock file if it doesn't exist)
        if [[ ! -f "${PULSE_LOCK_FILE:-${PULSE_DIR}/plugins.lock}" ]]; then
          pulse_init_lock_file
        fi

        pulse_write_lock_entry "$plugin_name" "$plugin_url" "${plugin_ref:-}" "$commit_sha" "$timestamp" "$plugin_stage"
        [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Lock file updated for $plugin_name (commit: ${commit_sha:0:7})" >&2
      fi
    fi

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

  # Validate lock file and regenerate if corrupted (if lock library available)
  if [[ -n "$PULSE_LOCK_FILE_SOURCED" ]]; then
    local lock_file="${PULSE_LOCK_FILE:-${PULSE_DIR}/plugins.lock}"

    # Only validate if lock file exists
    if [[ -f "$lock_file" ]]; then
      if ! pulse_validate_lock_file 2>/dev/null; then
        [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Lock file invalid, regenerating..." >&2

        # Backup corrupted lock file
        mv "$lock_file" "${lock_file}.corrupted.$(date +%s)" 2>/dev/null

        # Regenerate lock file from installed plugins
        pulse_init_lock_file

        # Scan installed plugins and recreate entries
        if [[ -d "${PULSE_DIR}/plugins" ]]; then
          # Use setopt to enable NULL_GLOB for this section
          setopt local_options null_glob
          for plugin_dir in "${PULSE_DIR}/plugins"/*; do
            # Skip if not a directory
            [[ ! -d "$plugin_dir" ]] && continue

            local plugin_name="${plugin_dir:t}"

            # Skip if not a git repository
            [[ ! -d "$plugin_dir/.git" ]] && continue

            # Extract git information
            local commit_sha=$(git -C "$plugin_dir" rev-parse HEAD 2>/dev/null)
            local remote_url=$(git -C "$plugin_dir" config --get remote.origin.url 2>/dev/null)

            # Get current branch or tag
            local ref=$(git -C "$plugin_dir" symbolic-ref --short HEAD 2>/dev/null)
            [[ -z "$ref" ]] && ref=$(git -C "$plugin_dir" describe --tags --exact-match 2>/dev/null)

            # Get timestamp from last commit
            local timestamp=$(git -C "$plugin_dir" log -1 --format=%cI 2>/dev/null)

            # Detect type and stage
            local plugin_type=$(_pulse_detect_plugin_type "$plugin_dir")
            local plugin_stage=$(_pulse_assign_stage "$plugin_name" "$plugin_type")

            # Write lock entry
            if [[ -n "$commit_sha" ]] && [[ -n "$remote_url" ]]; then
              pulse_write_lock_entry "$plugin_name" "$remote_url" "$ref" "$commit_sha" "$timestamp" "$plugin_stage"
            fi
          done
        fi

        [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Lock file regenerated from installed plugins" >&2
      fi
    fi
  fi

  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Engine initialized (PULSE_DIR=$PULSE_DIR)" >&2
}
