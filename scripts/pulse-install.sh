#!/usr/bin/env bash
#
# Pulse Framework Installer
# Version: 0.1.0-beta
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

# Parse version selection (FR-010)
readonly PULSE_VERSION="${PULSE_VERSION:-}"

# Parse boolean flags (1=true, 0=false)
SKIP_BACKUP="${PULSE_SKIP_BACKUP:-0}"
DEBUG="${PULSE_DEBUG:-0}"
SKIP_VERIFY="${PULSE_SKIP_VERIFY:-0}"
VERBOSE="0"

# Backup file path for rollback (FR-009)
BACKUP_FILE=""

# Parse command-line arguments (FR-011) - Only when executed, not sourced
parse_arguments() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -v|--verbose)
        VERBOSE="1"
        DEBUG="1"
        shift
        ;;
      --skip-backup)
        SKIP_BACKUP="1"
        shift
        ;;
      --skip-verify)
        SKIP_VERIFY="1"
        shift
        ;;
      -h|--help)
        cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Pulse Framework Installer - Zero-configuration Zsh framework installation

OPTIONS:
  -v, --verbose      Enable verbose logging output
  --skip-backup      Skip .zshrc backup creation
  --skip-verify      Skip post-install verification
  -h, --help         Show this help message

ENVIRONMENT VARIABLES:
  PULSE_INSTALL_DIR  Installation directory (default: ~/.local/share/pulse)
  PULSE_ZSHRC        Target .zshrc file (default: ~/.zshrc)
  PULSE_VERSION      Install specific version (default: latest)
  PULSE_SKIP_BACKUP  Skip backup creation (default: false)
  PULSE_DEBUG        Enable debug output (default: false)
  PULSE_SKIP_VERIFY  Skip verification (default: false)

EXAMPLES:
  # Standard installation
  ./pulse-install.sh

  # Install with verbose output
  ./pulse-install.sh --verbose

  # Install specific version
  PULSE_VERSION=v1.0.0 ./pulse-install.sh

  # Custom installation directory
  PULSE_INSTALL_DIR=~/my-pulse ./pulse-install.sh

For more information: https://github.com/astrosteveo/pulse
EOF
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
  done
}

# Note: SKIP_BACKUP, DEBUG, SKIP_VERIFY, VERBOSE are mutable runtime flags
# They can be overridden by CLI arguments via parse_arguments()
# Do NOT mark as readonly or CLI flags will fail to update them

#
# Output Formatting Functions (T004)
#

# Print formatted header banner
print_header() {
  printf "\n"
  printf "%b\n" "${COLOR_BOLD}${COLOR_BLUE}╔═══════════════════════════════════════╗${COLOR_RESET}"
  printf "%b\n" "${COLOR_BOLD}${COLOR_BLUE}║                                       ║${COLOR_RESET}"
  printf "%b\n" "${COLOR_BOLD}${COLOR_BLUE}║       Pulse Framework Installer       ║${COLOR_RESET}"
  printf "%b\n" "${COLOR_BOLD}${COLOR_BLUE}║                                       ║${COLOR_RESET}"
  printf "%b\n" "${COLOR_BOLD}${COLOR_BLUE}╚═══════════════════════════════════════╝${COLOR_RESET}"
  printf "\n"
}

# Print a step with checkmark
# Usage: print_step "Step description"
print_step() {
  local message="$1"
  printf "%b\n" "${COLOR_GREEN}✓${COLOR_RESET} ${message}"
}

# Print verbose/debug output (FR-011)
# Usage: print_verbose "Debug message"
print_verbose() {
  if [ "$VERBOSE" = "1" ] || [ "$DEBUG" = "1" ]; then
    local message="$1"
    printf "%b\n" "${COLOR_BLUE}[DEBUG]${COLOR_RESET} ${message}" >&2
  fi
}

# Print an error message with error marker
# Usage: print_error "Error description"
print_error() {
  local message="$1"
  printf "%b\n" "${COLOR_RED}✗${COLOR_RESET} ${message}" >&2
}

# Print success completion banner
print_success() {
  printf "\n"
  printf "%b\n" "${COLOR_BOLD}${COLOR_GREEN}╔═══════════════════════════════════════╗${COLOR_RESET}"
  printf "%b\n" "${COLOR_BOLD}${COLOR_GREEN}║                                       ║${COLOR_RESET}"
  printf "%b\n" "${COLOR_BOLD}${COLOR_GREEN}║   Installation completed successfully! ║${COLOR_RESET}"
  printf "%b\n" "${COLOR_BOLD}${COLOR_GREEN}║                                       ║${COLOR_RESET}"
  printf "%b\n" "${COLOR_BOLD}${COLOR_GREEN}╚═══════════════════════════════════════╝${COLOR_RESET}"
  printf "\n"
}

#
# Exit Code Handling (T005)
#

# Exit with error message and code (FR-009: with rollback support)
# Usage: error_exit "Error message" EXIT_CODE
error_exit() {
  local message="$1"
  local exit_code="${2:-$EXIT_INSTALL_FAILED}"

  print_error "$message"

  # FR-009: Automatic rollback if backup exists
  if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
    print_step "Rolling back changes..."
    print_verbose "Restoring backup: $BACKUP_FILE → $ZSHRC_PATH"
    if cp -p "$BACKUP_FILE" "$ZSHRC_PATH" 2>/dev/null; then
      print_step "Backup restored successfully"
      print_step "Backup preserved at: $BACKUP_FILE"
    else
      print_error "Failed to restore backup (manual recovery required)"
      print_error "Backup location: $BACKUP_FILE"
    fi
  fi

  exit "$exit_code"
}

#
# Prerequisite Checks (T008-T010)
#

# Check Zsh version is 5.0 or higher
check_zsh_version() {
  print_verbose "Checking Zsh installation..."

  # Check if zsh command exists
  if ! command -v zsh >/dev/null 2>&1; then
    print_error "Zsh is not installed"
    return "$EXIT_PREREQ_FAILED"
  fi

  print_verbose "Zsh found at: $(command -v zsh)"

  # Get Zsh version (zsh command should work if it exists)
  local zsh_version
  if ! zsh_version=$(zsh --version 2>/dev/null | head -n1); then
    print_error "Zsh is not installed"
    return "$EXIT_PREREQ_FAILED"
  fi

  print_verbose "Zsh version string: $zsh_version"

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

  print_verbose "Parsed version: $major.$minor (major: $major, minor: $minor)"

  if [ "$major" -lt 5 ]; then
    print_error "Zsh 5.0 or higher required (found $version_number)"
    return "$EXIT_PREREQ_FAILED"
  fi

  print_verbose "Zsh version check passed: $version_number >= 5.0"
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

  print_verbose "Repository URL: $repo_url"
  print_verbose "Target directory: $target_dir"

  # Check if directory exists and has .git
  if [ -d "$target_dir/.git" ]; then
    print_verbose "Existing installation detected"
    # Update existing installation - always just pull latest
    # (PULSE_VERSION is ignored for updates to avoid conflicts with exported env var)
    print_step "Updating existing Pulse installation..."
    print_verbose "Fetching latest changes..."
    if ! git -C "$target_dir" fetch --quiet 2>/dev/null; then
      print_error "Failed to fetch updates"
      return "$EXIT_DOWNLOAD_FAILED"
    fi
    print_verbose "Pulling updates..."
    if ! git -C "$target_dir" pull --quiet 2>/dev/null; then
      print_error "Failed to update repository"
      return "$EXIT_DOWNLOAD_FAILED"
    fi
  else
    # Fresh clone (or repair corrupted installation)
    if [ -d "$target_dir" ]; then
      print_step "Repairing corrupted installation..."
      print_verbose "Removing corrupted directory: $target_dir"
      rm -rf "$target_dir"
    else
      if [ -n "$PULSE_VERSION" ]; then
        print_step "Cloning Pulse repository (version $PULSE_VERSION)..."
      else
        print_step "Cloning Pulse repository..."
      fi
    fi

    # Build git clone command with optional version
    local clone_args="--depth 1 --quiet"
    if [ -n "$PULSE_VERSION" ]; then
      clone_args="$clone_args --branch $PULSE_VERSION"
      print_verbose "Clone args: $clone_args"
    fi

    print_verbose "Executing: git clone $clone_args $repo_url $target_dir"
    # Clone with version-specific branch/tag if specified
    if ! git clone $clone_args "$repo_url" "$target_dir" 2>/dev/null; then
      print_error "Failed to clone repository"
      return "$EXIT_DOWNLOAD_FAILED"
    fi
    print_verbose "Clone completed successfully"
  fi

  return "$EXIT_SUCCESS"
}

#
# Configuration Management (T014)
#

# Add or update Pulse configuration in .zshrc (FR-004: with auto-fix)
# Usage: add_pulse_config ZSHRC_PATH INSTALL_DIR
add_pulse_config() {
  local zshrc_path="$1"
  local install_dir="$2"

  print_verbose "Configuring $zshrc_path"

  # Ensure parent directory exists
  local parent_dir
  parent_dir=$(dirname "$zshrc_path")
  mkdir -p "$parent_dir"

  # Configuration block template (use actual install_dir path)
  local config_block="# BEGIN Pulse Configuration
# Managed by Pulse installer - do not edit this block manually
plugins=()
source $install_dir/pulse.zsh
# END Pulse Configuration"

  # Check if .zshrc exists
  if [ ! -f "$zshrc_path" ]; then
    print_verbose "Creating new .zshrc file"
    # Create new .zshrc with Pulse configuration
    echo "$config_block" > "$zshrc_path"
    print_step "Created $zshrc_path with Pulse configuration"
    return "$EXIT_SUCCESS"
  fi

  # Check if Pulse block already exists
  if grep -q "BEGIN Pulse Configuration" "$zshrc_path"; then
    print_verbose "Existing Pulse configuration block found"

    # FR-004: Check if order is correct
    if ! validate_config_order "$zshrc_path"; then
      print_step "Detected incorrect configuration order - auto-fixing..."
      print_verbose "Configuration has 'source' before 'plugins' - this must be corrected"

      # Extract existing plugin entries (preserve user customizations)
      local user_plugins
      user_plugins=$(awk '
        /# BEGIN Pulse Configuration/,/# END Pulse Configuration/ {
          if (/plugins=\(/) { in_plugins=1; next }
          if (in_plugins && /\)/) { in_plugins=0; next }
          if (in_plugins) print
        }
      ' "$zshrc_path")

      print_verbose "Preserving user plugin entries:${user_plugins:+ (found)}"

      # Build corrected config block with user plugins
      local corrected_block="# BEGIN Pulse Configuration
# Managed by Pulse installer - do not edit this block manually
plugins=(
$user_plugins
)
source $install_dir/pulse.zsh
# END Pulse Configuration"

      # Replace with corrected block
      awk -v block="$corrected_block" '
        /# BEGIN Pulse Configuration/ { in_block=1; print block; next }
        /# END Pulse Configuration/ { in_block=0; next }
        !in_block { print }
      ' "$zshrc_path" > "$zshrc_path.tmp"

      mv "$zshrc_path.tmp" "$zshrc_path"
      print_step "Fixed configuration order (plugins now before source)"
    else
      print_verbose "Configuration order is correct"

      # Extract existing plugin entries to preserve user customizations
      local user_plugins
      user_plugins=$(awk '
        /# BEGIN Pulse Configuration/,/# END Pulse Configuration/ {
          if (/plugins=\(.*\)/) { next }  # Skip single-line plugins=()
          if (/plugins=\(/) { in_plugins=1; next }
          if (in_plugins && /\)/) { in_plugins=0; next }
          if (in_plugins) print
        }
      ' "$zshrc_path")

      print_verbose "Preserving user plugins from existing configuration"

      # Build updated config block with preserved plugins
      local updated_block="# BEGIN Pulse Configuration
# Managed by Pulse installer - do not edit this block manually
plugins=(
$user_plugins
)
source $install_dir/pulse.zsh
# END Pulse Configuration"

      # Replace block while preserving plugins
      awk -v block="$updated_block" '
        /# BEGIN Pulse Configuration/ { in_block=1; print block; next }
        /# END Pulse Configuration/ { in_block=0; next }
        !in_block { print }
      ' "$zshrc_path" > "$zshrc_path.tmp"

      mv "$zshrc_path.tmp" "$zshrc_path"
      print_verbose "Updated configuration block (plugins preserved)"
    fi
  else
    # Add new block at the end
    print_verbose "Adding new Pulse configuration block"
    echo "" >> "$zshrc_path"
    echo "$config_block" >> "$zshrc_path"
    print_step "Added Pulse configuration to $zshrc_path"
  fi

  return "$EXIT_SUCCESS"
}
#
# Backup Management (T015)
#

# Create timestamped backup of .zshrc (FR-009: supports rollback)
# Usage: backup_zshrc ZSHRC_PATH
backup_zshrc() {
  local zshrc_path="$1"

  # Skip if SKIP_BACKUP is set
  if [ "$SKIP_BACKUP" = "1" ]; then
    print_verbose "Skipping backup (SKIP_BACKUP=1)"
    return "$EXIT_SUCCESS"
  fi

  # Only backup if file exists
  if [ ! -f "$zshrc_path" ]; then
    print_verbose "No existing .zshrc to backup"
    return "$EXIT_SUCCESS"
  fi

  # Create backup with timestamp
  BACKUP_FILE="${zshrc_path}.pulse-backup-$(date +%Y%m%d-%H%M%S)"
  print_verbose "Creating backup: $BACKUP_FILE"

  if ! cp -p "$zshrc_path" "$BACKUP_FILE" 2>/dev/null; then
    print_error "Failed to create backup"
    return "$EXIT_CONFIG_FAILED"
  fi

  print_step "Backup created: $BACKUP_FILE"
  export BACKUP_FILE  # Make available to error_exit for rollback
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

  # Extract only the Pulse Configuration block to avoid false positives
  # from unrelated plugins/source lines outside the block
  local pulse_block
  pulse_block=$(sed -n '/# BEGIN Pulse Configuration/,/# END Pulse Configuration/p' "$zshrc_path")

  if [ -z "$pulse_block" ]; then
    # No Pulse block found
    return "$EXIT_CONFIG_FAILED"
  fi

  # Find line numbers within the extracted block
  local plugins_line
  plugins_line=$(echo "$pulse_block" | grep -n "plugins=" | head -1 | cut -d: -f1)

  local source_line
  source_line=$(echo "$pulse_block" | grep -n "source.*pulse.zsh" | head -1 | cut -d: -f1)

  # Check both exist
  if [ -z "$plugins_line" ] || [ -z "$source_line" ]; then
    return "$EXIT_CONFIG_FAILED"
  fi

  # Verify order (within block)
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

  # Only show version for fresh installs (not updates)
  if [ -n "$PULSE_VERSION" ] && [ ! -d "$INSTALL_DIR/.git" ]; then
    print_step "Target version: $PULSE_VERSION"
  fi

  if [ "$VERBOSE" = "1" ]; then
    print_verbose "Verbose logging enabled"
    print_verbose "SKIP_BACKUP: $SKIP_BACKUP"
    print_verbose "SKIP_VERIFY: $SKIP_VERIFY"
  fi

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
    error_exit "Failed to install Pulse repository" "$EXIT_DOWNLOAD_FAILED"
  fi

  # Phase 3: Configure .zshrc
  if ! backup_zshrc "$ZSHRC_PATH"; then
    error_exit "Failed to create backup" "$EXIT_CONFIG_FAILED"
  fi

  if ! add_pulse_config "$ZSHRC_PATH" "$INSTALL_DIR"; then
    error_exit "Failed to configure .zshrc" "$EXIT_CONFIG_FAILED"
  fi

  # Phase 4: Validate configuration
  if ! validate_config_order "$ZSHRC_PATH"; then
    error_exit "Configuration order validation failed" "$EXIT_CONFIG_FAILED"
  fi

  # Phase 5: Verify installation
  if ! verify_installation "$ZSHRC_PATH"; then
    error_exit "Installation verification failed" "$EXIT_VERIFY_FAILED"
  fi

  # Success!
  print_success

  printf "\n"
  printf "Next steps:\n"
  printf "  1. Restart your shell: %b\n" "${COLOR_BOLD}exec zsh${COLOR_RESET}"
  printf "  2. Verify Pulse is loaded: %b\n" "${COLOR_BOLD}echo \$PULSE_VERSION${COLOR_RESET}"
  printf "\n"
  printf "For documentation: https://github.com/astrosteveo/pulse\n"

  return "$EXIT_SUCCESS"
}

# Run main if executed directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ] || [ -z "${BASH_SOURCE[0]}" ]; then
  parse_arguments "$@"
  main "$@"
fi
