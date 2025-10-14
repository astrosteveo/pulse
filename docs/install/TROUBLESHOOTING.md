# Pulse Installer Troubleshooting

Common issues and solutions for the Pulse installer.

## Prerequisites

### Zsh Not Found or Wrong Version

**Error**: `Zsh 5.0+ is required`

**Solution**:

```bash
# macOS
brew install zsh

# Ubuntu/Debian
sudo apt-get install zsh

# Fedora/RHEL
sudo dnf install zsh
```

Verify installation:

```bash
zsh --version
```

### Git Not Found

**Error**: `Git not found. Install: brew/apt-get install git`

**Solution**:

```bash
# macOS
brew install git

# Ubuntu/Debian
sudo apt-get install git

# Fedora/RHEL
sudo dnf install git
```

### Cannot Write to Installation Directory

**Error**: `Cannot write to ~/.local/share/pulse`

**Solutions**:

1. **Create parent directory**:

   ```bash
   mkdir -p ~/.local/share
   ```

2. **Use custom directory**:

   ```bash
   PULSE_INSTALL_DIR=~/pulse curl -fsSL https://... | bash
   ```

3. **Check permissions**:

   ```bash
   ls -la ~/.local/share
   ```

## Installation Issues

### Network Errors

**Error**: `Failed to clone Pulse repository`

**Causes**:

- No internet connection
- GitHub is unreachable
- Corporate firewall blocking Git

**Solutions**:

1. Check internet connection
2. Verify GitHub access: `git ls-remote https://github.com/astrosteveo/pulse.git`
3. Use Git over HTTPS (default) instead of SSH
4. Contact network administrator if behind corporate firewall

### Partial Installation

**Error**: Installation failed mid-process

**Solution**:

The installer creates backups automatically. To restore:

```bash
# Find your backup
ls -la ~/.zshrc.pulse-backup-*

# Restore from backup
cp ~/.zshrc.pulse-backup-TIMESTAMP ~/.zshrc

# Clean up partial installation
rm -rf ~/.local/share/pulse

# Re-run installer
curl -fsSL https://... | bash
```

## Configuration Issues

### Pulse Block Already Exists

**Symptom**: Re-running installer reports "Existing Pulse configuration detected"

**This is expected behavior**. The installer is idempotent and will:

- Detect existing Pulse installation
- Validate configuration order
- Auto-fix if plugins array comes after source statement
- Preserve your customizations

No action needed unless you want to upgrade:

```bash
# Force update (pulls latest Pulse)
curl -fsSL https://... | bash
```

### Wrong Configuration Order

**Error**: `Configuration order invalid`

**This should auto-fix**. The installer automatically corrects the order to ensure `plugins=()` comes before `source pulse.zsh`.

If auto-fix fails:

1. Restore from backup: `cp ~/.zshrc.pulse-backup-TIMESTAMP ~/.zshrc`
2. Re-run installer with debug: `PULSE_DEBUG=1 curl -fsSL https://... | bash`
3. Report issue with debug output

### Conflicting Plugin Managers

**Warning**: `Detected [Oh My Zsh/Prezto]; Pulse may conflict`

**Recommendation**: Choose one plugin manager:

**Option 1**: Migrate to Pulse

1. Note your current plugins from Oh My Zsh/Prezto
2. Remove Oh My Zsh/Prezto initialization from `.zshrc`
3. Add plugins to Pulse `plugins=()` array
4. Restart shell

**Option 2**: Use alongside (advanced)

- Pulse can coexist with other frameworks
- Load Pulse last in your `.zshrc`
- Some plugin conflicts may occur

## Verification Issues

### Verification Failed

**Error**: `Verification failed. Restore backup and retry with PULSE_DEBUG=1`

**Common causes**:

1. **Syntax error in .zshrc**:

   ```bash
   # Test syntax
   zsh -n ~/.zshrc
   ```

2. **Missing pulse.zsh file**:

   ```bash
   # Verify installation
   ls -la ~/.local/share/pulse/pulse.zsh
   ```

3. **Plugin loading failure**:
   - Check plugin names in `plugins=()` array
   - Ensure GitHub repo format: `user/repo`

**Debug steps**:

```bash
# Enable debug mode
PULSE_DEBUG=1 PULSE_SKIP_VERIFY=true curl -fsSL https://... | bash

# Test manually
zsh -c 'source ~/.zshrc; echo $PULSE_VERSION'
```

### Shell Still Shows Old Configuration

**Symptom**: After installation, shell doesn't load Pulse

**Solution**:

```bash
# Restart shell (required after installation)
exec zsh

# Or open new terminal window
```

## Advanced Issues

### Symlinked .zshrc

**Scenario**: Your `.zshrc` is a symlink to a dotfiles repo

**Behavior**: Installer will modify the symlink target

**Recommendation**:

1. Review changes in your dotfiles repo
2. Commit Pulse configuration block
3. Push to your dotfiles repo

### Sourced Configuration Files

**Scenario**: Your `.zshrc` sources other files (e.g., `source ~/.zsh/plugins.zsh`)

**Behavior**: Installer adds Pulse block to main `.zshrc` only

**If plugins are managed elsewhere**:

1. Move the Pulse configuration block to your plugins file
2. Ensure `plugins=()` comes before `source pulse.zsh`

### Custom Zsh Configuration Paths

**Scenario**: Using `ZDOTDIR` or custom Zsh paths

**Solution**:

```bash
PULSE_ZSHRC="$ZDOTDIR/.zshrc" curl -fsSL https://... | bash
```

## Getting Help

If issues persist:

1. **Check existing issues**: <https://github.com/astrosteveo/pulse/issues>
2. **Create new issue** with:
   - Output of `zsh --version`
   - Output of `uname -a`
   - Contents of `~/.zshrc` (sanitized)
   - Full error message
   - Debug output (`PULSE_DEBUG=1`)
3. **Join discussions**: <https://github.com/astrosteveo/pulse/discussions>

## Manual Installation

If automated installer fails, install manually:

```bash
# 1. Clone repository
git clone https://github.com/astrosteveo/pulse.git ~/.local/share/pulse

# 2. Backup .zshrc
cp ~/.zshrc ~/.zshrc.backup

# 3. Add to .zshrc
cat >> ~/.zshrc << 'EOF'

# BEGIN Pulse Configuration
plugins=(
  # Add your plugins here
)
source "$HOME/.local/share/pulse/pulse.zsh"
# END Pulse Configuration
EOF

# 4. Restart shell
exec zsh
```

---

**Still stuck?** Open an issue on GitHub with the `installer` label.
