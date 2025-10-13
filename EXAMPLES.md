# Pulse Usage Examples

This document provides practical examples of using Pulse's auto-installation and plugin management features.

---

## Installation Examples

### Quick Installation

```bash
# One-command install (recommended)
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/install.sh | bash

# Then restart your shell
exec zsh
```

### Custom Installation Location

```bash
# Set custom installation directory
export PULSE_DIR="$HOME/custom/path/pulse"

# Run installer
git clone https://github.com/astrosteveo/pulse.git /tmp/pulse
cd /tmp/pulse
./install.sh
```

---

## Plugin Configuration Examples

### Basic Plugin Setup

```zsh
# In your ~/.zshrc
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)

source ~/.local/share/pulse/pulse.zsh
```

When you restart your shell, Pulse will automatically:
1. Clone `zsh-autosuggestions` from GitHub
2. Clone `zsh-syntax-highlighting` from GitHub
3. Load both plugins in the correct order

### Version-Locked Plugins

```zsh
# Lock to specific versions/tags
plugins=(
  zsh-users/zsh-autosuggestions@v0.7.0
  zsh-users/zsh-syntax-highlighting@0.7.1
  zsh-users/zsh-completions@0.34.0
)

source ~/.local/share/pulse/pulse.zsh
```

### Branch-Specific Plugins

```zsh
# Use specific branches
plugins=(
  zsh-users/zsh-autosuggestions@develop
  zsh-users/zsh-syntax-highlighting@master
)

source ~/.local/share/pulse/pulse.zsh
```

### Mixed Plugin Sources

```zsh
plugins=(
  # GitHub shorthand
  zsh-users/zsh-autosuggestions
  
  # Version locked
  zsh-users/zsh-syntax-highlighting@v0.7.1
  
  # Full Git URL
  https://github.com/romkatv/powerlevel10k.git
  
  # Local plugin (no auto-install)
  ~/.local/share/my-custom-plugin
  
  # Absolute path
  /opt/company/zsh-plugins/work-plugin
)

source ~/.local/share/pulse/pulse.zsh
```

---

## CLI Command Examples

### Installing Plugins

```bash
# Install a single plugin
pulse install zsh-users/zsh-autosuggestions

# Install multiple plugins
pulse install zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting

# Install with version locking
pulse install zsh-users/zsh-autosuggestions@v0.7.0

# Install from full URL
pulse install https://github.com/zsh-users/zsh-completions.git

# Install all plugins defined in .zshrc
pulse install
```

### Updating Plugins

```bash
# Update all plugins
pulse update

# Update specific plugins
pulse update zsh-autosuggestions zsh-syntax-highlighting

# Update a single plugin
pulse update zsh-autosuggestions
```

### Listing Plugins

```bash
# List all installed plugins
pulse list

# Example output:
# Installed plugins:
# 
#   • zsh-autosuggestions           (git: v0.7.0)
#   • zsh-syntax-highlighting       (git: master)
#   • zsh-completions               (git: 0.34.0)
```

### Removing Plugins

```bash
# Remove a single plugin
pulse remove zsh-autosuggestions

# Remove multiple plugins
pulse remove zsh-autosuggestions zsh-syntax-highlighting
```

---

## Advanced Configuration Examples

### Development Setup

```zsh
# ~/.zshrc for development
plugins=(
  # Git enhancements
  https://github.com/wfxr/forgit.git
  
  # Docker completions
  https://github.com/greymd/docker-zsh-completion.git
  
  # Better directory navigation
  https://github.com/agkozak/zsh-z.git
  
  # Syntax highlighting (must be last)
  zsh-users/zsh-syntax-highlighting
)

# Load Pulse
source ~/.local/share/pulse/pulse.zsh

# Custom aliases
alias gst='git status'
alias gco='git checkout'
```

### Minimal Setup

```zsh
# Minimal .zshrc with just essentials
plugins=(
  zsh-users/zsh-autosuggestions
)

source ~/.local/share/pulse/pulse.zsh
```

### Power User Setup

```zsh
# Power user .zshrc with many plugins
plugins=(
  # Completions
  zsh-users/zsh-completions
  
  # Auto-suggestions
  zsh-users/zsh-autosuggestions
  
  # History search
  https://github.com/zsh-users/zsh-history-substring-search.git
  
  # Better directory navigation
  https://github.com/agkozak/zsh-z.git
  
  # Git helpers
  https://github.com/wfxr/forgit.git
  
  # Syntax highlighting (MUST be last)
  zsh-users/zsh-syntax-highlighting
)

# Custom Pulse settings
export PULSE_DEBUG=0  # Disable debug output

# Load Pulse
source ~/.local/share/pulse/pulse.zsh

# Custom prompt (after Pulse loads)
autoload -Uz vcs_info
precmd() { vcs_info }
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f ${vcs_info_msg_0_}$ '
```

### Version Pinning for Stability

```zsh
# Pin all plugins to specific versions for reproducibility
plugins=(
  # Locked to specific commits/tags
  zsh-users/zsh-autosuggestions@v0.7.0
  zsh-users/zsh-syntax-highlighting@0.7.1
  zsh-users/zsh-completions@0.34.0
)

source ~/.local/share/pulse/pulse.zsh
```

---

## Workflow Examples

### First Time Setup

```bash
# 1. Install Pulse
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/install.sh | bash

# 2. Edit your .zshrc to add plugins
nano ~/.zshrc

# 3. Add plugins (installer already added this section)
# plugins=(
#   zsh-users/zsh-autosuggestions
#   zsh-users/zsh-syntax-highlighting
# )

# 4. Restart shell (plugins auto-install)
exec zsh

# 5. Verify plugins loaded
pulse list
```

### Adding a New Plugin

```bash
# Method 1: Edit .zshrc and restart shell
echo "  zsh-users/zsh-completions" >> ~/.zshrc
exec zsh  # Auto-installs and loads

# Method 2: Use CLI, then add to .zshrc
pulse install zsh-users/zsh-completions
echo "  zsh-users/zsh-completions" >> ~/.zshrc
```

### Updating All Plugins

```bash
# Simple update workflow
pulse update

# Then restart shell to load updated versions
exec zsh
```

### Troubleshooting Plugin Issues

```bash
# 1. Enable debug mode
export PULSE_DEBUG=1
exec zsh

# 2. Check which plugins loaded
pulse list

# 3. Remove problematic plugin
pulse remove problematic-plugin

# 4. Try installing again
pulse install problematic-plugin
```

---

## Integration Examples

### With Oh-My-Zsh Plugins

Pulse can use Oh-My-Zsh plugins (individual plugins, not the full framework):

```zsh
plugins=(
  # Individual oh-my-zsh plugins work fine
  https://github.com/ohmyzsh/ohmyzsh.git  # Clone the repo
  
  # Use local path for OMZ plugins
  ~/.local/share/pulse/plugins/ohmyzsh/plugins/git
  ~/.local/share/pulse/plugins/ohmyzsh/plugins/docker
)

source ~/.local/share/pulse/pulse.zsh
```

### With Powerlevel10k Theme

```zsh
plugins=(
  # Regular plugins
  zsh-users/zsh-autosuggestions
  
  # Powerlevel10k theme (loads in late stage automatically)
  https://github.com/romkatv/powerlevel10k.git
)

source ~/.local/share/pulse/pulse.zsh

# Powerlevel10k configuration wizard will run on first start
```

### Portable Configuration

```zsh
# Create a portable .zshrc that works across machines
plugins=(
  # Use version locking for consistency
  zsh-users/zsh-autosuggestions@v0.7.0
  zsh-users/zsh-syntax-highlighting@0.7.1
)

# Detect OS-specific plugins
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS specific
  plugins+=(https://github.com/osx-cross/homebrew-zsh-completion.git)
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux specific
  plugins+=(custom-linux-plugin)
fi

source ~/.local/share/pulse/pulse.zsh
```

---

## Performance Tips

### Minimal Startup Time

```zsh
# Use only essential plugins for fastest startup
plugins=(
  zsh-users/zsh-autosuggestions  # ~50ms
  zsh-users/zsh-syntax-highlighting  # ~100ms
)

source ~/.local/share/pulse/pulse.zsh
# Total: <200ms startup time
```

### Disable Debug Output

```zsh
# Ensure debug is off for production use
export PULSE_DEBUG=0

plugins=(...)
source ~/.local/share/pulse/pulse.zsh
```

---

## Common Use Cases

### Case 1: Migrating from Oh-My-Zsh

```bash
# 1. Identify your OMZ plugins
grep "^plugins=" ~/.zshrc

# 2. Convert to Pulse format
# OMZ: plugins=(git docker kubectl)
# Pulse: Use individual GitHub repos or find equivalents

# 3. Update .zshrc
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-completions
)

source ~/.local/share/pulse/pulse.zsh
```

### Case 2: Team Configuration

```bash
# Share a common .zshrc across team
# team-zshrc.zsh
plugins=(
  zsh-users/zsh-autosuggestions@v0.7.0
  zsh-users/zsh-syntax-highlighting@0.7.1
  company/internal-plugin@v2.1.0
)

source ~/.local/share/pulse/pulse.zsh

# Team members source this file
echo "source ~/team-config/team-zshrc.zsh" >> ~/.zshrc
```

### Case 3: Testing a New Plugin

```bash
# Quick test without modifying .zshrc
pulse install new-user/test-plugin

# Test in current shell
source ~/.local/share/pulse/plugins/test-plugin/test-plugin.plugin.zsh

# If good, add to .zshrc permanently
echo "  new-user/test-plugin" >> ~/.zshrc
```

---

## FAQ

**Q: Do plugins auto-update?**
A: No, plugins remain at the version installed. Use `pulse update` to update manually.

**Q: Can I use private Git repositories?**
A: Yes, if you have SSH keys configured: `plugins=(git@github.com:user/private-repo.git)`

**Q: What if a plugin fails to install?**
A: Pulse will continue loading other plugins. Check with `PULSE_DEBUG=1` for details.

**Q: Can I override where plugins are stored?**
A: Yes, set `PULSE_DIR` before sourcing pulse.zsh: `export PULSE_DIR=~/my-plugins`

**Q: How do I temporarily disable a plugin?**
A: Comment it out in .zshrc or add to `pulse_disabled_plugins` array.
