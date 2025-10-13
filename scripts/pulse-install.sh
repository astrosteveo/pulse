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
