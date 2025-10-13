#!/usr/bin/env bash
# Pulse Installation Script
# Installs Pulse framework and sets up .zshrc

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default installation directory
PULSE_INSTALL_DIR="${PULSE_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/pulse}"
ZSHRC_FILE="${HOME}/.zshrc"

# Print colored output
print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

# Banner
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Pulse Installation Script      ║${NC}"
echo -e "${BLUE}║  Intelligent Zsh Plugin Framework    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
echo ""

# Check if zsh is installed
if ! command -v zsh >/dev/null 2>&1; then
  print_error "Zsh is not installed. Please install zsh first."
  exit 1
fi

print_success "Zsh detected: $(zsh --version)"

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
  print_error "Git is not installed. Please install git first."
  exit 1
fi

print_success "Git detected: $(git --version | head -n1)"

# Determine installation method
if [[ -d ".git" ]] && [[ -f "pulse.zsh" ]]; then
  # Running from cloned repository
  print_info "Installing from local repository..."
  INSTALL_FROM_LOCAL=1
  SOURCE_DIR="$(pwd)"
else
  # Need to clone from GitHub
  INSTALL_FROM_LOCAL=0
  REPO_URL="https://github.com/astrosteveo/pulse.git"
fi

# Create installation directory
print_info "Installation directory: ${PULSE_INSTALL_DIR}"

if [[ -d "${PULSE_INSTALL_DIR}" ]]; then
  print_warning "Pulse is already installed at ${PULSE_INSTALL_DIR}"
  read -p "Do you want to reinstall? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled."
    exit 0
  fi
  print_info "Removing existing installation..."
  rm -rf "${PULSE_INSTALL_DIR}"
fi

mkdir -p "$(dirname "${PULSE_INSTALL_DIR}")"

# Install Pulse
if [[ $INSTALL_FROM_LOCAL -eq 1 ]]; then
  print_info "Copying Pulse files..."
  cp -r "${SOURCE_DIR}" "${PULSE_INSTALL_DIR}"
  print_success "Pulse installed from local repository"
else
  print_info "Cloning Pulse from GitHub..."
  if git clone --quiet "${REPO_URL}" "${PULSE_INSTALL_DIR}"; then
    print_success "Pulse cloned successfully"
  else
    print_error "Failed to clone Pulse from GitHub"
    exit 1
  fi
fi

# Create plugins directory
mkdir -p "${PULSE_INSTALL_DIR}/plugins"

# Add pulse command to PATH
print_info "Setting up pulse command..."

# Detect shell RC file to add PATH to
if [[ -f "${HOME}/.zshenv" ]]; then
  SHELL_ENV_FILE="${HOME}/.zshenv"
elif [[ -f "${HOME}/.zprofile" ]]; then
  SHELL_ENV_FILE="${HOME}/.zprofile"
else
  SHELL_ENV_FILE="${HOME}/.zshenv"
fi

# Check if already in PATH
if [[ ":$PATH:" != *":${PULSE_INSTALL_DIR}/bin:"* ]]; then
  # Add to shell environment file
  if ! grep -q "${PULSE_INSTALL_DIR}/bin" "${SHELL_ENV_FILE}" 2>/dev/null; then
    echo "" >> "${SHELL_ENV_FILE}"
    echo "# Pulse - Add to PATH" >> "${SHELL_ENV_FILE}"
    echo "export PATH=\"${PULSE_INSTALL_DIR}/bin:\$PATH\"" >> "${SHELL_ENV_FILE}"
    print_success "Added pulse to PATH in ${SHELL_ENV_FILE}"
  fi
else
  print_success "Pulse already in PATH"
fi

# Setup .zshrc
print_info "Setting up .zshrc..."

# Backup existing .zshrc if it exists
if [[ -f "${ZSHRC_FILE}" ]]; then
  BACKUP_FILE="${ZSHRC_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
  cp "${ZSHRC_FILE}" "${BACKUP_FILE}"
  print_success "Backed up existing .zshrc to ${BACKUP_FILE}"
  
  # Check if Pulse is already configured
  if grep -q "source.*pulse.zsh" "${ZSHRC_FILE}" 2>/dev/null; then
    print_warning "Pulse appears to be already configured in .zshrc"
    read -p "Do you want to update the configuration? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      print_info "Skipping .zshrc configuration"
      SKIP_ZSHRC=1
    fi
  fi
fi

# Add Pulse configuration to .zshrc
if [[ "${SKIP_ZSHRC}" != "1" ]]; then
  cat >> "${ZSHRC_FILE}" <<'EOF'

# ============================================
# Pulse - Intelligent Zsh Plugin Framework
# ============================================

# Define your plugins (uncomment and add your own)
plugins=(
  # Examples (uncomment to enable):
  # zsh-users/zsh-autosuggestions
  # zsh-users/zsh-syntax-highlighting
  # zsh-users/zsh-completions
)

# Load Pulse
source "${HOME}/.local/share/pulse/pulse.zsh"
EOF

  print_success "Added Pulse configuration to .zshrc"
else
  print_info "Skipped .zshrc configuration (already exists)"
fi

# Installation complete
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete! 🎉        ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
echo ""

print_info "Next steps:"
echo ""
echo "  1. Edit your ~/.zshrc and uncomment plugins you want:"
echo "     \$ nano ~/.zshrc"
echo ""
echo "  2. Restart your shell to activate Pulse:"
echo "     \$ exec zsh"
echo ""
echo "  3. Or manually install plugins with:"
echo "     \$ ${PULSE_INSTALL_DIR}/bin/pulse install zsh-users/zsh-autosuggestions"
echo ""

print_info "Available commands:"
echo "  • pulse install [plugin]  - Install plugins"
echo "  • pulse update            - Update all plugins"
echo "  • pulse list              - List installed plugins"
echo "  • pulse remove [plugin]   - Remove a plugin"
echo ""

print_info "Plugin specifications:"
echo "  • user/repo               - GitHub shorthand (latest)"
echo "  • user/repo@v1.0.0       - Specific version/tag"
echo "  • user/repo@branch       - Specific branch"
echo ""

print_info "For more information, visit:"
echo "  https://github.com/astrosteveo/pulse"
echo ""
