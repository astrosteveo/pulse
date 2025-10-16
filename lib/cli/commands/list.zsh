#!/usr/bin/env zsh
# pulse list command - Display installed plugins
# Usage: pulse list

_pulse_cmd_list() {
  # Ensure PULSE_DIR is set
  : ${PULSE_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/pulse}
  : ${PULSE_LOCK_FILE:=${PULSE_DIR}/plugins.lock}

  # Source lock file library
  # Use PULSE_CLI_LIB_DIR if set (from bin/pulse), otherwise calculate relative path
  local lock_lib="${PULSE_CLI_LIB_DIR:-${0:A:h}/../lib}/lock-file.zsh"

  if [[ -f "$lock_lib" ]]; then
    source "$lock_lib"
  else
    echo "Error: Lock file library not found at $lock_lib" >&2
    return 1
  fi  # Check if lock file exists
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
  for plugin_name in ${(o)plugins_list}; do
    # Read lock entry for this plugin
    local lock_data=$(pulse_read_lock_entry "$plugin_name")

    if [[ -n "$lock_data" ]]; then
      # Parse lock data: url|ref|commit|timestamp|stage
      local url ref commit timestamp stage
      {
        IFS='|' read -r url ref commit timestamp stage
      } <<< "$lock_data"

      # Truncate commit to 7 characters
      local short_commit="${commit:0:7}"

      # Use ref or show "(default)" if empty
      local version="${ref:-(default)}"

      # Print row
      printf "%-30s %-20s %-10s\n" "$plugin_name" "$version" "$short_commit"
    fi
  done

  return 0
}
