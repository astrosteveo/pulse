#!/usr/bin/env zsh
# pulse list command - Display installed plugins
# Usage: pulse list

_pulse_cmd_list() {
  # Ensure PULSE_DIR is set
  : ${PULSE_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/pulse}
  : ${PULSE_LOCK_FILE:=${PULSE_DIR}/plugins.lock}

  # Source required libraries
  # Compute base library directories from a common root
  # bin/pulse sets these; fallback resolves relative to this file using ${(%):-%x}
  local root_lib_dir="${PULSE_LIB_DIR:-${${(%):-%x}:A:h:h:h:h}/lib}"
  local cli_lib_dir="${PULSE_CLI_LIB_DIR:-${root_lib_dir}/cli/lib}"
  
  local lock_lib="${cli_lib_dir}/lock-file.zsh"
  local utilities_lib="${root_lib_dir}/utilities.zsh"

  if [[ -f "$lock_lib" ]]; then
    source "$lock_lib"
  else
    echo "Error: Lock file library not found at $lock_lib" >&2
    return 1
  fi
  
  if [[ -f "$utilities_lib" ]]; then
    source "$utilities_lib"
  else
    echo "Error: Utilities library not found at $utilities_lib" >&2
    return 1
  fi
  
  # Check if lock file exists
  if [[ ! -f "$PULSE_LOCK_FILE" ]]; then
    echo "No plugins installed." >&2
    echo "Add plugins to your .zshrc and restart your shell." >&2
    return 2
  fi

  # Read all plugins from lock file
  local plugins_list=($(pulse_read_lock_file))

  if [[ ${#plugins_list[@]} -eq 0 ]]; then
    echo "No plugins installed." >&2
    echo "Add plugins to your .zshrc and restart your shell." >&2
    return 2
  fi

  # Print table header
  printf "%-30s %-20s %-10s\n" "PLUGIN" "VERSION" "COMMIT"
  printf "%-30s %-20s %-10s\n" "$(printf '%.0s-' {1..30})" "$(printf '%.0s-' {1..20})" "$(printf '%.0s-' {1..10})"

  # Sort plugins alphabetically and print each one
  local has_security_warnings=0
  local url ref commit timestamp stage lock_data
  for plugin_name in ${(o)plugins_list}; do
    # Reset variables to prevent stale values from previous iteration
    url='' ref='' commit='' timestamp='' stage=''
    
    # Read lock entry for this plugin
    lock_data=$(pulse_read_lock_entry "$plugin_name")

    if [[ -n "$lock_data" ]]; then
      # Parse lock data: url|ref|commit|timestamp|stage (pipe-separated)
      {
        IFS='|' read -r url ref commit timestamp stage
      } <<< "$lock_data"

      # Convert "-" placeholders back to empty strings
      [[ "$url" == "-" ]] && url=""
      [[ "$ref" == "-" ]] && ref=""
      [[ "$commit" == "-" ]] && commit=""
      [[ "$timestamp" == "-" ]] && timestamp=""
      [[ "$stage" == "-" ]] && stage=""

      # Security check for SSH URLs (if _pulse_check_ssh_security is available)
      if pulse_has_function _pulse_check_ssh_security && [[ -n "$url" ]]; then
        if ! _pulse_check_ssh_security "$url" "$plugin_name"; then
          : $((has_security_warnings++))
        fi
      fi

      # Truncate commit to 7 characters
      local short_commit="${commit:0:7}"

      # Use ref or show "(default)" if empty
      local version="${ref:-(default)}"

      # Print row
      printf "%-30s %-20s %-10s\n" "$plugin_name" "$version" "$short_commit"
    fi
  done

  # Print security summary if warnings were found
  if [[ $has_security_warnings -gt 0 ]]; then
    echo "" >&2
    echo "💡 Tip: Use 'pulse doctor' to check your installation health" >&2
  fi

  return 0
}
