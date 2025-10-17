#!/usr/bin/env zsh
# Plugin Engine for Pulse Framework
# Handles plugin detection, classification, and loading across 5 stages

# NOTE: This code assumes default zsh array indexing (1-based).
# If KSH_ARRAYS is set, array indexing will be 0-based and break this code.
# This is intentional - Pulse requires standard zsh behavior.

# Source UI feedback library for visual installation feedback
# Only source if ui-feedback.zsh exists and hasn't been sourced yet
if [[ -f "${0:A:h}/cli/lib/ui-feedback.zsh" ]] && [[ ! -v PULSE_UI_FEEDBACK_SOURCED ]]; then
  source "${0:A:h}/cli/lib/ui-feedback.zsh"
  typeset -g PULSE_UI_FEEDBACK_SOURCED=1
fi

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
# Returns: plugin_url plugin_name plugin_ref plugin_subpath plugin_kind (space-separated)
# Supports: 
#   - user/repo, user/repo@tag
#   - user/repo path:subdir - Load specific subdirectory
#   - omz:plugins/kubectl - Oh-My-Zsh plugin shorthand
#   - prezto:modules/git - Prezto module shorthand
#   - URLs, local paths
_pulse_parse_plugin_spec() {
  local source_spec="$1"
  local plugin_url=""
  local plugin_name=""
  local plugin_ref=""
  local plugin_subpath=""
  local plugin_kind=""

  # Trim leading/trailing whitespace
  source_spec="${source_spec##[[:space:]]}"
  source_spec="${source_spec%%[[:space:]]}"

  # Skip empty specs
  if [[ -z "$source_spec" ]]; then
    echo "-" "-" "-" "-" "-"
    return 0
  fi

  # Extract annotations (path:, kind:, stage:, etc.)
  # Format: "repo path:subdir kind:defer"
  local annotations=""
  if [[ "$source_spec" == *\ *:* ]]; then
    # Split on first space to separate repo from annotations
    local repo_part="${source_spec%% *}"
    annotations="${source_spec#* }"
    source_spec="$repo_part"
    
    # Parse each annotation (space-separated)
    local IFS=' '
    for annotation in $annotations; do
      if [[ "$annotation" == path:* ]]; then
        plugin_subpath="${annotation#path:}"
      elif [[ "$annotation" == kind:* ]]; then
        plugin_kind="${annotation#kind:}"
      fi
      # Future: stage:, etc.
    done
  fi

  # Handle framework shorthands
  if [[ "$source_spec" == omz:* ]]; then
    # Oh-My-Zsh shorthand: omz:plugins/kubectl or omz:lib/git
    local omz_path="${source_spec#omz:}"
    plugin_url="${PULSE_OMZ_REPO:-https://github.com/ohmyzsh/ohmyzsh.git}"
    plugin_name="ohmyzsh"
    plugin_subpath="$omz_path"
    # Derive kind from path if not specified
    if [[ -z "$plugin_kind" ]] && [[ "$omz_path" == plugins/* ]]; then
      plugin_kind="path"
    elif [[ -z "$plugin_kind" ]] && [[ "$omz_path" == lib/* ]]; then
      plugin_kind="path"
    elif [[ -z "$plugin_kind" ]] && [[ "$omz_path" == themes/* ]]; then
      plugin_kind="fpath"
    fi
    # Always output exactly 5 values (use "-" for empty fields)
    echo "$plugin_url" "$plugin_name" "${plugin_ref:--}" "$plugin_subpath" "${plugin_kind:-path}"
    return 0
  fi

  if [[ "$source_spec" == prezto:* ]]; then
    # Prezto shorthand: prezto:modules/git
    local prezto_path="${source_spec#prezto:}"
    plugin_url="${PULSE_PREZTO_REPO:-https://github.com/sorin-ionescu/prezto.git}"
    plugin_name="prezto"
    plugin_subpath="$prezto_path"
    plugin_kind="${plugin_kind:-path}"
    # Always output exactly 5 values (use "-" for empty fields)
    echo "$plugin_url" "$plugin_name" "${plugin_ref:--}" "$plugin_subpath" "$plugin_kind"
    return 0
  fi

  # Case 1: Local absolute or relative path
  if [[ "$source_spec" == /* ]] || [[ "$source_spec" == ./* ]] || [[ "$source_spec" == ../* ]]; then
    # For local paths, use the full path as the name and return early
    echo "-" "$source_spec" "-" "${plugin_subpath:--}" "${plugin_kind:--}"
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
    # Add subpath to name if present
    if [[ -n "$plugin_subpath" ]]; then
      plugin_name="${plugin_name}_${plugin_subpath//\//_}"
    fi
    echo "$plugin_url" "$plugin_name" "${plugin_ref:--}" "${plugin_subpath:--}" "${plugin_kind:--}"
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
    # Add subpath to name if present
    if [[ -n "$plugin_subpath" ]]; then
      plugin_name="${plugin_name}_${plugin_subpath//\//_}"
    fi
    echo "$plugin_url" "$plugin_name" "${plugin_ref:--}" "${plugin_subpath:--}" "${plugin_kind:--}"
    return 0
  fi

  # Case 4: Full Git URL (https://... or http://...)
  if [[ "$source_spec" =~ ^https?:// ]]; then
    plugin_url="$source_spec"
    plugin_name="${source_spec##*/}"
    plugin_name="${plugin_name%.git}"
    # Add subpath to name if present
    if [[ -n "$plugin_subpath" ]]; then
      plugin_name="${plugin_name}_${plugin_subpath//\//_}"
    fi
    echo "$plugin_url" "$plugin_name" "${plugin_ref:--}" "${plugin_subpath:--}" "${plugin_kind:--}"
    return 0
  fi

  # Default: treat as plugin name only
  echo "-" "$source_spec" "-" "${plugin_subpath:--}" "${plugin_kind:--}"
  return 0
}

# Resolve plugin source specification to a full path
# Usage: _pulse_resolve_plugin_source <source_spec>
# Supports: GitHub user/repo, full URLs, local paths, with optional subpaths
# Returns: Full path to plugin directory (including subpath if specified)
_pulse_resolve_plugin_source() {
  local source_spec="$1"
  local plugin_dir=""
  local plugin_subpath=""

  # Extract subpath annotation if present
  if [[ "$source_spec" == *\ path:* ]]; then
    local repo_part="${source_spec%% *}"
    local annotations="${source_spec#* }"
    source_spec="$repo_part"
    
    local IFS=' '
    for annotation in $annotations; do
      if [[ "$annotation" == path:* ]]; then
        plugin_subpath="${annotation#path:}"
        break
      fi
    done
  fi

  # Handle framework shorthands
  if [[ "$source_spec" == omz:* ]]; then
    local omz_path="${source_spec#omz:}"
    plugin_dir="${PULSE_DIR}/plugins/ohmyzsh"
    if [[ -n "$omz_path" ]]; then
      plugin_dir="${plugin_dir}/${omz_path}"
    fi
    echo "$plugin_dir"
    return 0
  fi

  if [[ "$source_spec" == prezto:* ]]; then
    local prezto_path="${source_spec#prezto:}"
    plugin_dir="${PULSE_DIR}/plugins/prezto"
    if [[ -n "$prezto_path" ]]; then
      plugin_dir="${plugin_dir}/${prezto_path}"
    fi
    echo "$plugin_dir"
    return 0
  fi

  # Strip version spec if present (but not for SSH URLs where @ is part of the URL)
  # SSH URLs: git@host:path - don't strip the @ that's part of the SSH format
  if [[ ! "$source_spec" =~ ^git@ ]]; then
    source_spec="${source_spec%@*}"
  fi

  # Case 1: Local absolute path
  if [[ "$source_spec" == /* ]]; then
    if [[ -n "$plugin_subpath" ]]; then
      echo "${source_spec}/${plugin_subpath}"
    else
      echo "$source_spec"
    fi
    return 0
  fi

  # Case 2: Local relative path (starts with ./ or ../)
  if [[ "$source_spec" == ./* ]] || [[ "$source_spec" == ../* ]]; then
    local resolved_path="$(cd "$source_spec" 2>/dev/null && pwd)"
    if [[ -n "$plugin_subpath" ]]; then
      echo "${resolved_path}/${plugin_subpath}"
    else
      echo "$resolved_path"
    fi
    return 0
  fi

  # Case 3: GitHub shorthand (user/repo)
  if [[ "$source_spec" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
    local plugin_name="${source_spec##*/}"
    plugin_dir="${PULSE_DIR}/plugins/${plugin_name}"
    if [[ -n "$plugin_subpath" ]]; then
      plugin_dir="${plugin_dir}/${plugin_subpath}"
    fi
    echo "$plugin_dir"
    return 0
  fi

  # Case 4: Full Git URL (https://... or git@...)
  if [[ "$source_spec" =~ ^(https?://|git@) ]]; then
    # Extract plugin name from URL (last component without .git)
    local plugin_name="${source_spec##*/}"
    plugin_name="${plugin_name%.git}"
    plugin_dir="${PULSE_DIR}/plugins/${plugin_name}"
    if [[ -n "$plugin_subpath" ]]; then
      plugin_dir="${plugin_dir}/${plugin_subpath}"
    fi
    echo "$plugin_dir"
    return 0
  fi

  # Default: assume it's a plugin name in PULSE_DIR
  plugin_dir="${PULSE_DIR}/plugins/${source_spec}"
  if [[ -n "$plugin_subpath" ]]; then
    plugin_dir="${plugin_dir}/${plugin_subpath}"
  fi
  echo "$plugin_dir"
  return 0
}

#
# Plugin Installation
#

# Check if UI feedback functions are available
# Usage: _pulse_has_feedback
# Returns: 0 if feedback available, 1 otherwise
_pulse_has_feedback() {
  command -v pulse_start_spinner >/dev/null 2>&1
}

_pulse_unique_paths() {
  typeset -A _pulse_seen_paths
  local -a _pulse_unique

  for _pulse_path in "$@"; do
    [[ -z "$_pulse_path" ]] && continue
    if [[ -z "${_pulse_seen_paths[$_pulse_path]}" ]]; then
      _pulse_seen_paths[$_pulse_path]=1
      _pulse_unique+=("$_pulse_path")
    fi
  done

  reply=("${_pulse_unique[@]}")
}

_pulse_extract_framework_sources() {
  local source_file="$1"
  local mode="$2"

  reply=()
  [[ ! -f "$source_file" ]] && return 0

  local python_cmd
  if command -v python3 >/dev/null 2>&1; then
    python_cmd=python3
  else
    python_cmd=python
  fi

  if ! command -v "$python_cmd" >/dev/null 2>&1; then
    return 0
  fi

  local script
  if [[ "$mode" == "omz" ]]; then
    script=$'import re,sys\npath=sys.argv[1]\npattern=re.compile(r"\\$ZSH/(lib/[\\w./-]+|plugins/[\\w./-]+)")\npaths=set()\nwith open(path, "r", encoding="utf-8") as handle:\n    for line in handle:\n        line=line.split("#",1)[0]\n        for match in pattern.findall(line):\n            paths.add(match)\nfor item in sorted(paths):\n    print(item)'
  else
    script=$'import re,sys\npath=sys.argv[1]\npattern=re.compile(r"\\$ZPREZTODIR/modules/([\\w./-]+)")\npaths=set()\nwith open(path, "r", encoding="utf-8") as handle:\n    for line in handle:\n        line=line.split("#",1)[0]\n        for match in pattern.findall(line):\n            paths.add(f"modules/{match}")\nfor item in sorted(paths):\n    print(item)'
  fi

  local -a extracted
  extracted=("${(@f)$( "$python_cmd" -c "$script" "$source_file" 2>/dev/null )}")

  reply=("${extracted[@]}")
}

_pulse_collect_omz_dependencies() {
  local repo_path="$1"
  local plugin_subpath="$2"

  reply=()

  [[ -z "$repo_path" ]] && return 0

  local -a dependencies=()
  if [[ "$plugin_subpath" == lib/* ]]; then
    local lib_file="${repo_path}/${plugin_subpath}.zsh"
    _pulse_extract_framework_sources "$lib_file" "omz"
    dependencies=("${reply[@]}")
  else
    local plugin_name="${plugin_subpath#plugins/}"
    local plugin_file="${repo_path}/${plugin_subpath}/${plugin_name}.plugin.zsh"
    if [[ ! -f "$plugin_file" ]]; then
      plugin_file="${repo_path}/${plugin_subpath}/${plugin_name}.zsh"
    fi
    _pulse_extract_framework_sources "$plugin_file" "omz"
    dependencies=("${reply[@]}")
  fi

  _pulse_unique_paths "${dependencies[@]}"
}

_pulse_collect_prezto_dependencies() {
  local repo_path="$1"
  local plugin_subpath="$2"

  reply=()

  [[ -z "$repo_path" ]] && return 0

  local module_file="${repo_path}/${plugin_subpath}/init.zsh"
  if [[ ! -f "$module_file" ]]; then
    module_file="${repo_path}/${plugin_subpath}/${plugin_subpath:t}.zsh"
  fi

  _pulse_extract_framework_sources "$module_file" "prezto"
  local -a dependencies=("${reply[@]}")

  _pulse_unique_paths "${dependencies[@]}"
}

_pulse_compute_sparse_paths() {
  local plugin_spec="$1"
  local plugin_subpath="$2"
  local repo_path="$3"

  reply=()
  [[ -z "$plugin_subpath" ]] && return 0

  local -a sparse_paths
  sparse_paths+=("$plugin_subpath")

  if [[ "$plugin_spec" == omz:* ]]; then
    _pulse_collect_omz_dependencies "$repo_path" "$plugin_subpath"
    sparse_paths+=("${reply[@]}")
  elif [[ "$plugin_spec" == prezto:* ]]; then
    _pulse_collect_prezto_dependencies "$repo_path" "$plugin_subpath"
    sparse_paths+=("${reply[@]}")
  fi

  _pulse_unique_paths "${sparse_paths[@]}"
}

_pulse_git_default_branch() {
  local repo_path="$1"
  local default_branch=""

  default_branch=$(git -C "$repo_path" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  default_branch="${default_branch#origin/}"

  if [[ -z "$default_branch" ]]; then
    default_branch=$(git -C "$repo_path" remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')
  fi

  if [[ -z "$default_branch" ]]; then
    if git -C "$repo_path" show-ref --verify --quiet refs/remotes/origin/master 2>/dev/null; then
      default_branch="master"
    else
      default_branch="main"
    fi
  fi

  echo "$default_branch"
}

# Clone a plugin from a Git URL
# Usage: _pulse_clone_plugin <plugin_url> <plugin_name> [plugin_ref] [plugin_spec] [plugin_subpath] [sparse_paths...]
# Returns: 0 on success, 1 on failure
_pulse_clone_plugin() {
  local plugin_url="$1"
  local plugin_name="$2"
  local plugin_ref="${3:-}"
  shift 3

  local plugin_spec=""
  local plugin_subpath=""

  if [[ $# -gt 0 ]]; then
    plugin_spec="$1"
    shift
  fi

  if [[ $# -gt 0 ]]; then
    plugin_subpath="$1"
    shift
  fi

  local -a sparse_paths=("$@")
  local plugin_dir="${PULSE_DIR}/plugins/${plugin_name}"

  # Check if git is available
  if ! command -v git >/dev/null 2>&1; then
    if _pulse_has_feedback; then
      pulse_error "Git not found - cannot install plugins"
    else
      echo "[Pulse] Error: git not found, cannot clone plugins" >&2
    fi
    return 1
  fi

  # Create plugins directory if it doesn't exist
  mkdir -p "${PULSE_DIR}/plugins"

  # Show user feedback with spinner (if available)
  local show_feedback=0
  local display_name="${plugin_name}"
  [[ -n "$plugin_ref" ]] && display_name="${plugin_name}@${plugin_ref}"
  
  if _pulse_has_feedback; then
    pulse_start_spinner "Installing ${display_name}..."
    show_feedback=1
  else
    # Fallback to simple message
    echo "Installing ${display_name}..."
  fi

  local use_sparse=0
  if (( ${#sparse_paths[@]} > 0 )) && [[ -n "$plugin_subpath" ]]; then
    use_sparse=1
  fi

  local clone_or_update_failed=0

  if [[ ! -d "$plugin_dir/.git" ]]; then
    local -a clone_args=("--filter=blob:none" "--no-checkout" "--depth" "1")
    if [[ -n "$plugin_ref" ]]; then
      clone_args+=("--origin" "origin")
    fi

    if ! git clone --quiet "${clone_args[@]}" "$plugin_url" "$plugin_dir" 2>/dev/null; then
      clone_or_update_failed=1
    else
      if (( use_sparse )); then
        git -C "$plugin_dir" sparse-checkout init --no-cone >/dev/null 2>&1
        git -C "$plugin_dir" sparse-checkout set "${sparse_paths[@]}" >/dev/null 2>&1 || clone_or_update_failed=1
      fi
    fi
  else
    git -C "$plugin_dir" remote set-url origin "$plugin_url" >/dev/null 2>&1

    if (( use_sparse )); then
      git -C "$plugin_dir" sparse-checkout init --no-cone >/dev/null 2>&1
      git -C "$plugin_dir" sparse-checkout set "${sparse_paths[@]}" >/dev/null 2>&1 || clone_or_update_failed=1
    else
      git -C "$plugin_dir" sparse-checkout disable >/dev/null 2>&1
    fi
  fi

  if [[ $clone_or_update_failed -eq 1 ]]; then
    if [[ $show_feedback -eq 1 ]]; then
      pulse_stop_spinner error "Failed to install ${display_name}"
    else
      echo "✗ Failed to install ${display_name}" >&2
    fi
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Failed to prepare repository for $plugin_name" >&2
    return 1
  fi

  local checkout_failed=0
  if [[ -n "$plugin_ref" ]]; then
    if ! git -C "$plugin_dir" fetch --quiet --depth 1 origin "$plugin_ref" 2>/dev/null; then
      checkout_failed=1
    elif ! git -C "$plugin_dir" checkout --quiet FETCH_HEAD 2>/dev/null; then
      checkout_failed=1
    fi
  else
    local default_branch=$(_pulse_git_default_branch "$plugin_dir")
    if ! git -C "$plugin_dir" fetch --quiet --depth 1 origin "$default_branch" 2>/dev/null; then
      checkout_failed=1
    elif ! git -C "$plugin_dir" checkout --quiet "$default_branch" 2>/dev/null; then
      checkout_failed=1
    elif ! git -C "$plugin_dir" reset --quiet --hard "origin/${default_branch}" 2>/dev/null; then
      checkout_failed=1
    fi
  fi

  if [[ $checkout_failed -eq 1 ]]; then
    if [[ $show_feedback -eq 1 ]]; then
      pulse_stop_spinner error "Failed to install ${display_name} (checkout failed)"
    else
      echo "✗ Failed to install ${display_name} (checkout failed)" >&2
    fi
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Checkout failed for $plugin_name" >&2
    return 1
  fi

  if (( use_sparse )) && [[ -n "$plugin_subpath" ]]; then
    _pulse_compute_sparse_paths "$plugin_spec" "$plugin_subpath" "$plugin_dir"
    local -a refreshed_paths=("${reply[@]}")
    if (( ${#refreshed_paths[@]} > 0 )); then
      git -C "$plugin_dir" sparse-checkout set "${refreshed_paths[@]}" >/dev/null 2>&1
      sparse_paths=("${refreshed_paths[@]}")
    fi
  fi

  if (( use_sparse )); then
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Sparse paths for $plugin_name: ${sparse_paths[*]}" >&2
  fi

  if [[ $show_feedback -eq 1 ]]; then
    pulse_stop_spinner success "Installed ${display_name}"
  else
    echo "✓ Installed ${display_name}"
  fi
  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Successfully prepared $plugin_name" >&2
  return 0
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
  
  # Extract the actual directory name for file matching (in case of subpaths)
  local dir_name="${plugin_path:t}"

  # Common plugin file patterns (in order of preference)
  local patterns=(
    "${plugin_path}/${plugin_name}.plugin.zsh"
    "${plugin_path}/${plugin_name}.zsh"
    "${plugin_path}/${dir_name}.plugin.zsh"
    "${plugin_path}/${dir_name}.zsh"
    "${plugin_path}/init.zsh"
    "${plugin_path}/${plugin_name}.sh"
    "${plugin_path}/${dir_name}.sh"
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

    # Parse plugin specification (now returns 5 values: url, name, ref, subpath, kind)
    local parsed=($(_pulse_parse_plugin_spec "$plugin_spec"))
    local plugin_url="${parsed[1]}"
    local plugin_name="${parsed[2]}"
    local plugin_ref="${parsed[3]}"
    local plugin_subpath="${parsed[4]}"
    local plugin_kind="${parsed[5]}"
    
    # Convert "-" placeholders back to empty strings
    [[ "$plugin_url" == "-" ]] && plugin_url=""
    [[ "$plugin_name" == "-" ]] && plugin_name=""
    [[ "$plugin_ref" == "-" ]] && plugin_ref=""
    [[ "$plugin_subpath" == "-" ]] && plugin_subpath=""
    [[ "$plugin_kind" == "-" ]] && plugin_kind=""

    # Fallback: extract plugin name from spec if parsing failed
    if [[ -z "$plugin_name" ]]; then
      plugin_name="${plugin_spec##*/}"
      plugin_name="${plugin_name%.git}"
      plugin_name="${plugin_name%@*}"
      # Strip annotations
      plugin_name="${plugin_name%% *}"
    fi

    # Validate plugin name is not empty and doesn't contain path traversal
    if [[ -z "$plugin_name" ]] || [[ "$plugin_name" == *..* ]] || [[ "$plugin_name" == /* ]]; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Error: Invalid plugin name: $plugin_spec" >&2
      continue
    fi

    # Resolve to full path
    local plugin_path=$(_pulse_resolve_plugin_source "$plugin_spec")

    # For framework plugins with subpaths, clone the parent repo but use the subpath
    local clone_path=""
    local -a sparse_paths=()
    if [[ -n "$plugin_subpath" ]]; then
      # Extract parent repo path for cloning
      if [[ "$plugin_spec" == omz:* ]]; then
        clone_path="${PULSE_DIR}/plugins/ohmyzsh"
      elif [[ "$plugin_spec" == prezto:* ]]; then
        clone_path="${PULSE_DIR}/plugins/prezto"
      elif [[ -n "$plugin_url" ]]; then
        # For repos with path: annotation, clone to repo name
        local repo_name="${plugin_url##*/}"
        repo_name="${repo_name%.git}"
        clone_path="${PULSE_DIR}/plugins/${repo_name}"
      fi

      local repo_root="${clone_path:-${PULSE_DIR}/plugins/${plugin_name}}"
      _pulse_compute_sparse_paths "$plugin_spec" "$plugin_subpath" "$repo_root"
      sparse_paths=("${reply[@]}")
      if (( ${#sparse_paths[@]} == 0 )); then
        sparse_paths=("$plugin_subpath")
      fi
    fi

    # Auto-install if missing and we have a URL
    local check_path="${clone_path:-$plugin_path}"
    local sparse_refresh_needed=0
    if (( ${#sparse_paths[@]} > 0 )) && [[ -n "$clone_path" ]] && [[ -d "$clone_path/.git" ]]; then
      local -a current_sparse=()
      current_sparse=("${(@f)$(git -C "$clone_path" sparse-checkout list 2>/dev/null)}")
      for sparse_path in "${sparse_paths[@]}"; do
        if [[ -z "${current_sparse[(r)$sparse_path]}" ]]; then
          sparse_refresh_needed=1
          break
        fi
      done
    fi

    if { [[ ! -d "$check_path" ]] || [[ $sparse_refresh_needed -eq 1 ]] ; } && [[ -n "$plugin_url" ]]; then
      # Ensure plugins directory exists before creating lock
      mkdir -p "${PULSE_DIR}/plugins"

      # Use repo name for lock if we have a clone_path
      local lock_name="${plugin_name}"
      if [[ -n "$clone_path" ]]; then
        lock_name="${clone_path##*/}"
      fi

      # Create lock file to prevent race conditions
      local lock_file="${PULSE_DIR}/plugins/.${lock_name}.lock"
      local lock_acquired=0

      # Try to acquire lock with timeout
      for i in {1..30}; do
        if mkdir "$lock_file" 2>/dev/null; then
          lock_acquired=1
          break
        fi
        # Only show waiting message once and in debug mode
        [[ -n "$PULSE_DEBUG" ]] && [[ $i -eq 1 ]] && echo "[Pulse] Waiting for lock on $lock_name..." >&2
        sleep 0.1
      done

      if [[ $lock_acquired -eq 1 ]]; then
        local reinstall_needed=0
        if [[ ! -d "$check_path" ]]; then
          reinstall_needed=1
        elif [[ $sparse_refresh_needed -eq 1 ]]; then
          reinstall_needed=1
        fi

        if (( reinstall_needed )); then
          # Install or refresh the plugin (feedback is shown by _pulse_clone_plugin)
          if _pulse_clone_plugin "$plugin_url" "$lock_name" "$plugin_ref" "$plugin_spec" "$plugin_subpath" "${sparse_paths[@]}"; then
            [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Successfully installed $lock_name" >&2
          else
            [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Warning: Failed to install $lock_name" >&2
          fi
        fi
        # Release lock
        rmdir "$lock_file" 2>/dev/null
      else
        [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Warning: Could not acquire lock for $lock_name" >&2
      fi
    fi

    # Detect plugin type
    local plugin_type=$(_pulse_detect_plugin_type "$plugin_path")

    # Assign load stage (use kind annotation if provided)
    local plugin_stage=""
    if [[ "$plugin_kind" == "path" ]]; then
      plugin_stage="normal"
    elif [[ "$plugin_kind" == "fpath" ]]; then
      plugin_stage="early"
    elif [[ "$plugin_kind" == "defer" ]]; then
      plugin_stage="late"
    else
      plugin_stage=$(_pulse_assign_stage "$plugin_name" "$plugin_type")
    fi

    # Update lock file with plugin installation (if library is available)
    # For subpath plugins, check the parent repo for .git
    local git_check_path="${clone_path:-$plugin_path}"
    if [[ -n "$plugin_subpath" ]] && [[ -n "$clone_path" ]]; then
      git_check_path="$clone_path"
    fi
    
    if [[ -n "$PULSE_LOCK_FILE_SOURCED" ]] && [[ -d "$git_check_path/.git" ]]; then
      # Extract exact commit SHA
      local commit_sha=""
      commit_sha=$(git -C "$git_check_path" rev-parse HEAD 2>/dev/null)

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
