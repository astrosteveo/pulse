#!/usr/bin/env zsh
# pulse update command - Update installed plugins
# Usage: pulse update [plugin-name] [--force] [--check-only]

_pulse_cmd_update() {
  # Ensure PULSE_DIR is set
  : ${PULSE_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/pulse}
  : ${PULSE_LOCK_FILE:=${PULSE_DIR}/plugins.lock}
  
  # Source required libraries
  local update_lib="${PULSE_CLI_LIB_DIR:-${0:A:h}/../lib}/update-check.zsh"
  local lock_lib="${PULSE_CLI_LIB_DIR:-${0:A:h}/../lib}/lock-file.zsh"
  
  if [[ ! -f "$update_lib" ]] || [[ ! -f "$lock_lib" ]]; then
    echo "Error: Required libraries not found" >&2
    return 1
  fi
  
  source "$update_lib"
  source "$lock_lib"
  
  # Parse arguments
  local target_plugin=""
  local force=0
  local check_only=0
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)
        force=1
        shift
        ;;
      --check-only)
        check_only=1
        shift
        ;;
      -*)
        echo "Unknown option: $1" >&2
        return 1
        ;;
      *)
        target_plugin="$1"
        shift
        ;;
    esac
  done
  
  # Check if lock file exists
  if [[ ! -f "$PULSE_LOCK_FILE" ]]; then
    echo "No plugins installed (lock file not found)" >&2
    echo "Add plugins to your .zshrc and restart your shell." >&2
    return 2
  fi
  
  # Acquire lock to prevent concurrent updates
  local lock_fd
  local lock_file="${PULSE_DIR}/.update.lock"
  
  # Open lock file descriptor
  exec {lock_fd}>"$lock_file"
  
  # Try to acquire exclusive lock (wait up to 5 seconds)
  if ! command -v flock >/dev/null 2>&1; then
    # flock not available - proceed without locking (may have race conditions)
    if [[ -n "$PULSE_DEBUG" ]]; then
      echo "[Pulse] flock not available - proceeding without lock" >&2
    fi
  else
    if ! flock -w 5 "$lock_fd"; then
      echo "Error: Could not acquire update lock (another update in progress?)" >&2
      exec {lock_fd}>&-  # Close file descriptor
      return 1
    fi
    if [[ -n "$PULSE_DEBUG" ]]; then
      echo "[Pulse] Acquired update lock" >&2
    fi
  fi
  
  # Read all plugins from lock file
  local plugins_list=($(pulse_read_lock_file))
  
  if [[ ${#plugins_list[@]} -eq 0 ]]; then
    echo "No plugins installed" >&2
    exec {lock_fd}>&-  # Release lock
    return 2
  fi
  
  # Filter to target plugin if specified
  if [[ -n "$target_plugin" ]]; then
    if [[ ! " ${plugins_list[@]} " =~ " $target_plugin " ]]; then
      echo "Plugin not found: $target_plugin" >&2
      exec {lock_fd}>&- 2>/dev/null || true  # Release lock
      return 1
    fi
    plugins_list=("$target_plugin")
  fi
  
  # Counters for summary
  local updated=0
  local up_to_date=0
  local skipped=0
  local errors=0
  
  # Process each plugin
  for plugin_name in ${plugins_list[@]}; do
    # Read lock entry
    local lock_data
    lock_data=$(pulse_read_lock_entry "$plugin_name")
    
    if [[ -z "$lock_data" ]]; then
      echo "Warning: Could not read lock entry for $plugin_name" >&2
      : $((errors++))
      continue
    fi
    
    # Parse lock data: url|ref|commit|timestamp|stage
    local url ref commit timestamp stage
    IFS='|' read -r url ref commit timestamp stage <<< "$lock_data"
    
    # Skip local plugins (no URL) - these can't be updated
    if [[ -z "$url" ]]; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Skipping local plugin: $plugin_name" >&2 || true
      : $((skipped++))
      continue
    fi
    
    # Determine plugin path (only git-cloned plugins with URLs have standard paths)
    local plugin_path="${PULSE_DIR}/plugins/${plugin_name}"
    
    if [[ ! -d "$plugin_path" ]]; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Plugin directory not found: $plugin_name" >&2 || true
      : $((skipped++))
      continue
    fi
    
    # Check for local changes (unless --force)
    if [[ $force -eq 0 ]] && [[ -d "$plugin_path/.git" ]]; then
      if ! git -C "$plugin_path" diff-index --quiet HEAD 2>/dev/null; then
        echo "Skipping $plugin_name (local changes detected, use --force to override)" >&2
        : $((skipped++))
        continue
      fi
    fi
    
    # Check if update is available
    if ! pulse_needs_update "$plugin_name" "$commit" "$url" "$ref"; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] $plugin_name is up-to-date" >&2 || true
      : $((up_to_date++))
      continue
    fi
    
    echo "Updating $plugin_name..."
    
    # If check-only mode, just report and continue
    if [[ $check_only -eq 1 ]]; then
      echo "  Update available for $plugin_name"
      continue
    fi
    
    # Perform update (git pull)
    if [[ ! -d "$plugin_path/.git" ]]; then
      echo "  Warning: Not a git repository, skipping" >&2
      : $((errors++))
      continue
    fi
    
    # Save current commit for rollback if needed
    local old_commit=$(git -C "$plugin_path" rev-parse HEAD 2>/dev/null)
    
    # Pull updates
    if git -C "$plugin_path" pull --quiet 2>&1 | grep -q "Already up to date"; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] $plugin_name was already up-to-date" >&2 || true
      : $((up_to_date++))
      continue
    elif [[ ${PIPESTATUS[0]} -ne 0 ]]; then
      echo "  Error: Failed to update $plugin_name" >&2
      : $((errors++))
      continue
    fi
    
    # Get new commit SHA
    local new_commit=$(git -C "$plugin_path" rev-parse HEAD 2>/dev/null)
    
    if [[ -z "$new_commit" ]] || [[ "$new_commit" == "$old_commit" ]]; then
      [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] No changes for $plugin_name" >&2 || true
      : $((up_to_date++))
      continue
    fi
    
    # Update lock file entry
    local new_timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%S 2>/dev/null || echo "unknown")
    
    # Remove old entry
    pulse_remove_lock_entry "$plugin_name"
    
    # Add new entry with updated commit
    pulse_write_lock_entry "$plugin_name" "$url" "$ref" "$new_commit" "$new_timestamp" "$stage"
    
    echo "  Updated: ${old_commit:0:7} → ${new_commit:0:7}"
    : $((updated++))
  done
  
  # Release lock
  if [[ -n "$lock_fd" ]]; then
    exec {lock_fd}>&- 2>/dev/null || true
    [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Released update lock" >&2 || true
  fi
  
  # Print summary
  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Printing summary: updated=$updated, up_to_date=$up_to_date, skipped=$skipped, errors=$errors" >&2 || true
  
  printf "\n"
  printf "Update summary:\n"
  [[ $updated -gt 0 ]] && printf "  Updated: %d\n" "$updated"
  [[ $up_to_date -gt 0 ]] && printf "  Up-to-date: %d\n" "$up_to_date"
  [[ $skipped -gt 0 ]] && printf "  Skipped: %d\n" "$skipped"
  [[ $errors -gt 0 ]] && printf "  Errors: %d\n" "$errors"
  
  # Return success if no errors
  local exit_code=0
  [[ $errors -gt 0 ]] && exit_code=1
  [[ -n "$PULSE_DEBUG" ]] && echo "[Pulse] Returning exit code: $exit_code" >&2 || true
  return $exit_code
}
