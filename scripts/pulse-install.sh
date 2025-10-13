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

#
# Repository Management (T012)
#

# Clone or update the Pulse repository
# Usage: clone_or_update_repo REPO_URL TARGET_DIR
clone_or_update_repo() {
  local repo_url="$1"
  local target_dir="$2"

  # Check if directory exists and has .git
  if [ -d "$target_dir/.git" ]; then
    # Update existing installation
    print_step "Updating existing Pulse installation..."
    if ! git -C "$target_dir" pull --quiet 2>/dev/null; then
      print_error "Failed to update repository"
      return "$EXIT_DOWNLOAD_FAILED"
    fi
  else
    # Fresh clone (or repair corrupted installation)
    if [ -d "$target_dir" ]; then
      print_step "Repairing corrupted installation..."
      rm -rf "$target_dir"
    else
      print_step "Cloning Pulse repository..."
    fi

    # Clone with depth 1 for faster download
    if ! git clone --depth 1 --quiet "$repo_url" "$target_dir" 2>/dev/null; then
      print_error "Failed to clone repository"
      return "$EXIT_DOWNLOAD_FAILED"
    fi
  fi

  return "$EXIT_SUCCESS"
}

#
# Configuration Management (T014)
#

# Add or update Pulse configuration in .zshrc
# Usage: add_pulse_config ZSHRC_PATH INSTALL_DIR
add_pulse_config() {
  local zshrc_path="$1"
  local install_dir="$2"

  # Ensure parent directory exists
  local parent_dir
  parent_dir=$(dirname "$zshrc_path")
  mkdir -p "$parent_dir"

  # Configuration block template
  local config_block="# BEGIN Pulse Configuration
# Managed by Pulse installer - do not edit this block manually
plugins=()
source $install_dir/pulse.zsh
# END Pulse Configuration"

  # Check if .zshrc exists
  if [ ! -f "$zshrc_path" ]; then
    # Create new .zshrc with Pulse configuration
    echo "$config_block" > "$zshrc_path"
    return "$EXIT_SUCCESS"
  fi

  # Check if Pulse block already exists
  if grep -q "BEGIN Pulse Configuration" "$zshrc_path"; then
    # Update existing block - remove old block and insert new one
    # Use awk for more reliable block replacement
    awk -v block="$config_block" '
      /# BEGIN Pulse Configuration/ { in_block=1; print block; next }
      /# END Pulse Configuration/ { in_block=0; next }
      !in_block { print }
    ' "$zshrc_path" > "$zshrc_path.tmp"

    mv "$zshrc_path.tmp" "$zshrc_path"
  else
    # Add new block at the end
    echo "" >> "$zshrc_path"
    echo "$config_block" >> "$zshrc_path"
  fi

  return "$EXIT_SUCCESS"
}
#
# Backup Management (T015)
#

# Create timestamped backup of .zshrc
# Usage: backup_zshrc ZSHRC_PATH
backup_zshrc() {
  local zshrc_path="$1"
  
  # Skip if SKIP_BACKUP is set
  if [ "$SKIP_BACKUP" = "1" ]; then
    return "$EXIT_SUCCESS"
  fi
  
  # Only backup if file exists
  if [ ! -f "$zshrc_path" ]; then
    return "$EXIT_SUCCESS"
  fi
  
  # Create backup with timestamp
  local backup_path="${zshrc_path}.pulse-backup-$(date +%Y%m%d-%H%M%S)"
  if ! cp -p "$zshrc_path" "$backup_path" 2>/dev/null; then
    print_error "Failed to create backup"
    return "$EXIT_CONFIG_FAILED"
  fi
  
  print_step "Backup created: $backup_path"
  return "$EXIT_SUCCESS"
}

#
# Configuration Validation (T016)
#

# Validate plugins array comes before source statement
# Usage: validate_config_order ZSHRC_PATH
validate_config_order() {
  local zshrc_path="$1"
  
  if [ ! -f "$zshrc_path" ]; then
    return "$EXIT_CONFIG_FAILED"
  fi
  
  # Find line numbers
  local plugins_line
  plugins_line=$(grep -n "plugins=" "$zshrc_path" | head -1 | cut -d: -f1)
  
  local source_line
  source_line=$(grep -n "source.*pulse.zsh" "$zshrc_path" | head -1 | cut -d: -f1)
  
  # Check both exist
  if [ -z "$plugins_line" ] || [ -z "$source_line" ]; then
    return "$EXIT_CONFIG_FAILED"
  fi
  
  # Verify order
  if [ "$plugins_line" -lt "$source_line" ]; then
    return "$EXIT_SUCCESS"
  else
    return "$EXIT_CONFIG_FAILED"
  fi
}

#
# Post-Install Verification (T017)
#

# Verify Pulse loads in a test shell
# Usage: verify_installation ZSHRC_PATH
verify_installation() {
  local zshrc_path="$1"
  
  # Skip if requested
  if [ "$SKIP_VERIFY" = "1" ]; then
    print_step "Skipping verification (PULSE_SKIP_VERIFY=1)"
    return "$EXIT_SUCCESS"
  fi
  
  print_step "Verifying installation..."
  
  # Test in subshell
  if zsh -c "source $zshrc_path 2>/dev/null && echo PULSE_OK" 2>/dev/null | grep -q "PULSE_OK"; then
    print_step "Pulse loads successfully ✓"
    return "$EXIT_SUCCESS"
  else
    print_error "Verification failed - Pulse did not load correctly"
    print_error "To debug: PULSE_DEBUG=1 zsh -c 'source $zshrc_path'"
    return "$EXIT_CONFIG_FAILED"
  fi
}

#
# Main Installer Orchestration (T018)
#

# Main entry point
main() {
  print_header
  
  print_step "Installation directory: $INSTALL_DIR"
  print_step "Configuration file: $ZSHRC_PATH"
  
  # Phase 1: Validate prerequisites
  print_step "Checking prerequisites..."
  
  if ! check_zsh_version; then
    error_exit "Zsh 5.0+ is required"
  fi
  
  if ! check_git; then
    error_exit "Git is not installed"
  fi
  
  if ! check_write_permissions "$INSTALL_DIR"; then
    error_exit "No write permission for installation directory"
  fi
  
  print_step "Prerequisites validated ✓"
  
  # Phase 2: Install/update repository
  if ! clone_or_update_repo "https://github.com/astrosteveo/pulse.git" "$INSTALL_DIR"; then
    error_exit "Failed to install Pulse repository"
  fi
  
  # Phase 3: Configure .zshrc
  if ! backup_zshrc "$ZSHRC_PATH"; then
    error_exit "Failed to create backup"
  fi
  
  if ! add_pulse_config "$ZSHRC_PATH" "$INSTALL_DIR"; then
    error_exit "Failed to configure .zshrc"
  fi
  
  # Phase 4: Validate configuration
  if ! validate_config_order "$ZSHRC_PATH"; then
    error_exit "Configuration order validation failed"
  fi
  
  # Phase 5: Verify installation
  if ! verify_installation "$ZSHRC_PATH"; then
    error_exit "Installation verification failed"
  fi
  
  # Success!
  print_success
  
  echo ""
  echo "Next steps:"
  echo "  1. Restart your shell: ${COLOR_BOLD}exec zsh${COLOR_RESET}"
  echo "  2. Verify Pulse is loaded: ${COLOR_BOLD}echo \$PULSE_VERSION${COLOR_RESET}"
  echo ""
  echo "For documentation: https://github.com/astrosteveo/pulse"
  
  return "$EXIT_SUCCESS"
}

# Run main if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
