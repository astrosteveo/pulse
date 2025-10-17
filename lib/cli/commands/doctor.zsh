#!/usr/bin/env zsh
# pulse doctor command - Run system diagnostics
# Usage: pulse doctor

_pulse_cmd_doctor() {
  # Ensure PULSE_DIR is set
  : ${PULSE_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/pulse}
  : ${PULSE_LOCK_FILE:=${PULSE_DIR}/plugins.lock}

  # Source required libraries
  local lock_lib="${PULSE_CLI_LIB_DIR:-${0:A:h}/../lib}/lock-file.zsh"

  if [[ -f "$lock_lib" ]]; then
    source "$lock_lib"
  fi

  # Track results
  local checks_passed=0
  local checks_total=0
  local has_errors=0

  echo "Pulse System Diagnostics"
  echo "========================"
  echo ""

  # Check 1: Git availability
  : $((checks_total++))
  if command -v git >/dev/null 2>&1; then
    local git_version=$(git --version 2>/dev/null | head -n1)
    echo "[✓] Git: $git_version"
    : $((checks_passed++))
  else
    echo "[✗] Git: Not found"
    echo "    → Install git: https://git-scm.com/downloads"
    has_errors=1
  fi

  # Check 2: Network connectivity (GitHub) - non-fatal, just informational
  : $((checks_total++))
  local network_ok=0
  if command -v curl >/dev/null 2>&1; then
    if curl -fsSL --connect-timeout 5 --max-time 10 https://github.com >/dev/null 2>&1; then
      network_ok=1
    fi
  elif command -v wget >/dev/null 2>&1; then
    if wget --spider --quiet --timeout=5 --tries=1 https://github.com 2>&1; then
      network_ok=1
    fi
  fi

  if [[ $network_ok -eq 1 ]]; then
    echo "[✓] Network: GitHub accessible"
    : $((checks_passed++))
  else
    echo "[~] Network: Cannot reach github.com (optional)"
    echo "    → Plugin operations require internet connection"
    : $((checks_passed++))  # Don't fail on this
  fi

  # Check 3: Plugin directory
  : $((checks_total++))
  if [[ -d "$PULSE_DIR/plugins" ]]; then
    local plugin_count=$(ls -1 "$PULSE_DIR/plugins" 2>/dev/null | wc -l)
    echo "[✓] Plugin directory: $PULSE_DIR/plugins ($plugin_count plugins)"
    : $((checks_passed++))
  else
    echo "[✗] Plugin directory: Not found"
    echo "    → Directory will be created when first plugin is installed"
    has_errors=1
  fi

  # Check 4: Lock file validity
  : $((checks_total++))
  if [[ ! -f "$PULSE_LOCK_FILE" ]]; then
    echo "[✓] Lock file: Not present (no plugins installed)"
    : $((checks_passed++))
  elif [[ -f "$lock_lib" ]] && pulse_validate_lock_file 2>/dev/null; then
    local entry_count=$(grep -c '^\[.*\]$' "$PULSE_LOCK_FILE" 2>/dev/null || echo 0)
    echo "[✓] Lock file: Valid ($entry_count entries)"
    : $((checks_passed++))
  else
    echo "[✗] Lock file: Invalid or corrupted"
    echo "    → Run: rm $PULSE_LOCK_FILE && restart shell"
    has_errors=1
  fi

  # Check 5: Plugin integrity (only if lock file exists)
  : $((checks_total++))
  if [[ -f "$PULSE_LOCK_FILE" ]] && [[ -f "$lock_lib" ]]; then
    local plugins_list=($(pulse_read_lock_file 2>/dev/null))
    local broken=0

    for plugin_name in ${plugins_list[@]}; do
      local lock_data=$(pulse_read_lock_entry "$plugin_name" 2>/dev/null)
      # Use space as delimiter since pulse_read_lock_entry returns space-separated values
      local url=$(echo "$lock_data" | awk '{print $1}')
      local commit=$(echo "$lock_data" | awk '{print $3}')

      # Only check git-cloned plugins (have URL)
      if [[ -n "$url" ]] && [[ "$url" != "-" ]]; then
        local plugin_path="${PULSE_DIR}/plugins/${plugin_name}"
        if [[ ! -d "$plugin_path/.git" ]]; then
          : $((broken++))
        fi
      fi
    done

    if [[ $broken -eq 0 ]]; then
      echo "[✓] Plugin integrity: All plugins valid"
      : $((checks_passed++))
    else
      echo "[✗] Plugin integrity: $broken plugin(s) missing .git directory"
      echo "    → Run: pulse update --force"
      has_errors=1
    fi
  else
    echo "[✓] Plugin integrity: No plugins to check"
    : $((checks_passed++))
  fi

  # Check 6: CLI installation
  : $((checks_total++))
  # Use PULSE_CLI_DIR if set (from main pulse script), otherwise try to resolve from $0
  local cli_path="${PULSE_CLI_DIR:+${PULSE_CLI_DIR}/pulse}"
  if [[ -z "$cli_path" ]]; then
    cli_path="${0:A}"
  fi
  
  if [[ -f "$cli_path" ]] && [[ -r "$cli_path" ]]; then
    echo "[✓] CLI: Installed at $cli_path"
    : $((checks_passed++))
  else
    echo "[✗] CLI: Not found or not readable"
    echo "    → Check installation"
    has_errors=1
  fi

  # Check 7: PATH configuration (check if pulse command is accessible)
  : $((checks_total++))
  if command -v pulse >/dev/null 2>&1; then
    local pulse_which=$(command -v pulse)
    echo "[✓] PATH: pulse command accessible ($pulse_which)"
    : $((checks_passed++))
  else
    echo "[~] PATH: pulse command not in PATH (optional)"
    echo "    → Modern Zsh best practice - add to your ~/.zshrc:"
    echo "       typeset -TUx PATH path"
    echo "       path=(\$HOME/.local/bin \$path[@])"
    echo ""
    echo "    → Or traditional method:"
    echo "       export PATH=\"\${HOME}/.local/bin:\${PATH}\""
    : $((checks_passed++))  # Don't fail on this
  fi

  # Check 8: Framework installation (check alternate locations)
  : $((checks_total++))
  local framework_main="${PULSE_DIR}/pulse.zsh"
  local alt_framework_main="${0:A:h:h}/pulse.zsh"  # ../pulse.zsh from bin/

  if [[ -f "$framework_main" ]]; then
    echo "[✓] Framework: Installed at $framework_main"
    : $((checks_passed++))
  elif [[ -f "$alt_framework_main" ]]; then
    echo "[✓] Framework: Installed at $alt_framework_main"
    : $((checks_passed++))
  else
    echo "[✗] Framework: pulse.zsh not found"
    echo "    → Reinstall Pulse"
    has_errors=1
  fi

  # Summary
  echo ""
  echo "Summary: $checks_passed/$checks_total checks passed"

  if [[ $has_errors -eq 0 ]]; then
    echo ""
    echo "All systems operational! 🚀"
    return 0
  else
    echo ""
    echo "Some issues detected. Follow the suggestions above to fix them."
    return 1
  fi
}
