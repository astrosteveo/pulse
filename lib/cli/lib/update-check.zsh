#!/usr/bin/env zsh
# Update checking library for Pulse CLI
# Provides functions to check for plugin updates and manage update cache

# Check for available updates for a plugin
# Usage: pulse_check_updates <plugin_name> <url> <ref>
# Returns: Remote commit SHA on stdout (0 if found, 1 if error)
pulse_check_updates() {
  local plugin_name="$1"
  local url="$2"
  local ref="$3"

  # Ensure PULSE_DIR is set
  : ${PULSE_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/pulse}

  local cache_dir="${PULSE_DIR}/.update-cache"
  local cache_file="${cache_dir}/${plugin_name}.cache"

  # Create cache directory if needed
  mkdir -p "$cache_dir"

  # Check if cache is fresh (<24 hours)
  local cache_age=0
  if [[ -f "$cache_file" ]]; then
    local cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)
    local current_time=$(date +%s)
    cache_age=$((current_time - cache_mtime))
  fi

  # Cache fresh if less than 24 hours (86400 seconds)
  if [[ $cache_age -lt 86400 ]] && [[ -f "$cache_file" ]]; then
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Using cached update data for $plugin_name (age: ${cache_age}s)" >&2
    cat "$cache_file"
    return 0
  fi

  # Cache stale or missing - fetch from remote
  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Fetching remote update data for $plugin_name" >&2

  # Handle local plugins (no URL)
  if [[ -z "$url" ]]; then
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Local plugin $plugin_name - no remote updates" >&2
    return 1
  fi

  # Query remote repository
  local remote_data
  if ! remote_data=$(git ls-remote --heads --tags "$url" 2>/dev/null); then
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Failed to query remote for $plugin_name" >&2
    return 1
  fi

  # Parse remote commit SHA
  local remote_commit=""

  if [[ -n "$ref" ]]; then
    # Specific ref requested - look for exact match
    # Try as branch first (refs/heads/), then tag (refs/tags/)
    remote_commit=$(echo "$remote_data" | awk -v ref="$ref" '
      $2 == "refs/heads/" ref || $2 == "refs/tags/" ref { print $1; exit }
    ')
  fi

  # If no ref specified or ref not found, try to get HEAD or main/master
  if [[ -z "$remote_commit" ]]; then
    # Try HEAD first
    remote_commit=$(echo "$remote_data" | awk '$2 == "HEAD" { print $1; exit }')

    # If no HEAD, try main branch
    if [[ -z "$remote_commit" ]]; then
      remote_commit=$(echo "$remote_data" | awk '$2 == "refs/heads/main" { print $1; exit }')
    fi

    # If no main, try master branch
    if [[ -z "$remote_commit" ]]; then
      remote_commit=$(echo "$remote_data" | awk '$2 == "refs/heads/master" { print $1; exit }')
    fi
  fi

  if [[ -z "$remote_commit" ]]; then
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Could not determine remote commit for $plugin_name" >&2
    return 1
  fi

  # Cache the result
  echo "$remote_commit" > "$cache_file"

  # Output result
  echo "$remote_commit"
  return 0
}

# Check if a plugin needs updating
# Usage: pulse_needs_update <plugin_name> <local_commit> <url> <ref>
# Returns: 0 if update available, 1 if up-to-date or error
pulse_needs_update() {
  local plugin_name="$1"
  local local_commit="$2"
  local url="$3"
  local ref="$4"

  # Get remote commit
  local remote_commit
  if ! remote_commit=$(pulse_check_updates "$plugin_name" "$url" "$ref"); then
    return 1  # Error or no remote
  fi

  # Compare commits
  if [[ "$local_commit" == "$remote_commit" ]]; then
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] $plugin_name is up-to-date" >&2
    return 1  # Up-to-date
  fi

  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] $plugin_name has update available (local: ${local_commit:0:7}, remote: ${remote_commit:0:7})" >&2
  return 0  # Update available
}

# Clear update cache (useful for testing or forcing refresh)
# Usage: pulse_clear_update_cache [plugin_name]
pulse_clear_update_cache() {
  local plugin_name="$1"

  : ${PULSE_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/pulse}
  local cache_dir="${PULSE_DIR}/.update-cache"

  if [[ -n "$plugin_name" ]]; then
    # Clear specific plugin cache
    rm -f "${cache_dir}/${plugin_name}.cache"
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Cleared update cache for $plugin_name" >&2
  else
    # Clear all caches
    rm -rf "$cache_dir"
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Cleared all update caches" >&2
  fi

  return 0
}
