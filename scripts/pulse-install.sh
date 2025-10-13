#!/usr/bin/env bash
#
# Pulse Framework Installer
# Version: 1.0.0
# Description: One-command installer for the Pulse Zsh framework
#
# Usage: curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh | bash
#
# Environment Variables:
#   PULSE_INSTALL_DIR   - Installation directory (default: ~/.local/share/pulse)
#   PULSE_ZSHRC         - Target .zshrc file (default: ~/.zshrc)
#   PULSE_SKIP_BACKUP   - Skip backup creation (default: false)
#   PULSE_DEBUG         - Enable debug output (default: false)
#   PULSE_SKIP_VERIFY   - Skip post-install verification (default: false)

set -e  # Exit on error

# Colors for output formatting
if [ -t 1 ]; then
  # Terminal supports colors
  COLOR_RESET="\033[0m"
  COLOR_GREEN="\033[0;32m"
  COLOR_RED="\033[0;31m"
  COLOR_BLUE="\033[0;34m"
  COLOR_BOLD="\033[1m"
else
  # No color support
  COLOR_RESET=""
  COLOR_GREEN=""
  COLOR_RED=""
  COLOR_BLUE=""
  COLOR_BOLD=""
fi

# Exit codes (T005)
readonly EXIT_SUCCESS=0
readonly EXIT_PREREQ_FAILED=1
readonly EXIT_DOWNLOAD_FAILED=2
readonly EXIT_INSTALL_FAILED=3
readonly EXIT_CONFIG_FAILED=4

# Environment variable parsing (T006)
# Parse installation directory (supports XDG Base Directory Spec)
INSTALL_DIR="${PULSE_INSTALL_DIR:-}"
if [ -z "$INSTALL_DIR" ]; then
  INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/pulse"
fi
readonly INSTALL_DIR

# Parse target .zshrc path
readonly ZSHRC_PATH="${PULSE_ZSHRC:-$HOME/.zshrc}"

# Parse boolean flags (1=true, 0=false)
readonly SKIP_BACKUP="${PULSE_SKIP_BACKUP:-0}"
readonly DEBUG="${PULSE_DEBUG:-0}"
readonly SKIP_VERIFY="${PULSE_SKIP_VERIFY:-0}"

#
# Output Formatting Functions (T004)
#

# Print formatted header banner
print_header() {
  echo ""
  echo "${COLOR_BOLD}${COLOR_BLUE}╔═══════════════════════════════════════╗${COLOR_RESET}"
  echo "${COLOR_BOLD}${COLOR_BLUE}║                                       ║${COLOR_RESET}"
  echo "${COLOR_BOLD}${COLOR_BLUE}║       Pulse Framework Installer       ║${COLOR_RESET}"
  echo "${COLOR_BOLD}${COLOR_BLUE}║                                       ║${COLOR_RESET}"
  echo "${COLOR_BOLD}${COLOR_BLUE}╚═══════════════════════════════════════╝${COLOR_RESET}"
  echo ""
}

# Print a step with checkmark
# Usage: print_step "Step description"
print_step() {
  local message="$1"
  echo "${COLOR_GREEN}✓${COLOR_RESET} ${message}"
}

# Print an error message with error marker
# Usage: print_error "Error description"
print_error() {
  local message="$1"
  echo "${COLOR_RED}✗${COLOR_RESET} ${message}" >&2
}

# Print success completion banner
print_success() {
  echo ""
  echo "${COLOR_BOLD}${COLOR_GREEN}╔═══════════════════════════════════════╗${COLOR_RESET}"
  echo "${COLOR_BOLD}${COLOR_GREEN}║                                       ║${COLOR_RESET}"
  echo "${COLOR_BOLD}${COLOR_GREEN}║   Installation completed successfully! ║${COLOR_RESET}"
  echo "${COLOR_BOLD}${COLOR_GREEN}║                                       ║${COLOR_RESET}"
  echo "${COLOR_BOLD}${COLOR_GREEN}╚═══════════════════════════════════════╝${COLOR_RESET}"
  echo ""
}

#
# Exit Code Handling (T005)
#

# Exit with error message and code
# Usage: error_exit "Error message" EXIT_CODE
error_exit() {
  local message="$1"
  local exit_code="${2:-$EXIT_INSTALL_FAILED}"
  
  print_error "$message"
  exit "$exit_code"
}

#
# Prerequisite Checks (T008-T010)
#

# Check Zsh version is 5.0 or higher
check_zsh_version() {
  # Check if zsh command exists
  if ! command -v zsh >/dev/null 2>&1; then
    print_error "Zsh is not installed"
    return "$EXIT_PREREQ_FAILED"
  fi
  
  # Get Zsh version (zsh command should work if it exists)
  local zsh_version
  if ! zsh_version=$(zsh --version 2>/dev/null | head -n1); then
    print_error "Zsh is not installed"
    return "$EXIT_PREREQ_FAILED"
  fi
  
  # Extract major.minor version (e.g., "5.9" from "zsh 5.9 (x86_64-pc-linux-gnu)")
  local version_number
  version_number=$(echo "$zsh_version" | grep -oE '[0-9]+\.[0-9]+' | head -n1)
  
  if [ -z "$version_number" ]; then
    print_error "Could not detect Zsh version"
    return "$EXIT_PREREQ_FAILED"
  fi
  
  # Compare version (require 5.0+)
  local major minor
  major=$(echo "$version_number" | cut -d. -f1)
  minor=$(echo "$version_number" | cut -d. -f2)
  
  if [ "$major" -lt 5 ]; then
    print_error "Zsh 5.0 or higher required (found $version_number)"
    return "$EXIT_PREREQ_FAILED"
  fi
  
  return "$EXIT_SUCCESS"
}

# Check if Git is installed
check_git() {
  if ! command -v git >/dev/null 2>&1; then
    print_error "Git is not installed"
    return "$EXIT_PREREQ_FAILED"
  fi
  
  return "$EXIT_SUCCESS"
}

# Check write permissions for installation directory
check_write_permissions() {
  local target_dir="$1"
  
  # If directory exists, check if writable
  if [ -d "$target_dir" ]; then
    if [ ! -w "$target_dir" ]; then
      print_error "No write permission for $target_dir"
      return "$EXIT_PREREQ_FAILED"
    fi
  else
    # Check if parent directory exists and is writable
    local parent_dir
    parent_dir=$(dirname "$target_dir")
    
    if [ ! -d "$parent_dir" ] || [ ! -w "$parent_dir" ]; then
      print_error "No write permission for installation directory"
      return "$EXIT_PREREQ_FAILED"
    fi
  fi
  
  return "$EXIT_SUCCESS"
}
