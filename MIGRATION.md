# Migration Guide

This guide helps users upgrade to Pulse v1.1.0 with auto-installation features.

---

## Upgrading from v1.0.0 to v1.1.0

### What's New

Pulse v1.1.0 introduces automatic plugin installation, version locking, and a CLI tool. Your existing configuration will continue to work without changes, but you can now take advantage of these new features.

### Automatic Changes

When you upgrade and restart your shell:
- ✅ **Missing plugins will be auto-installed** from GitHub
- ✅ **No manual cloning needed anymore**
- ✅ **Existing plugins continue to work**

### Step-by-Step Upgrade

#### 1. Update Pulse

```bash
cd ~/.local/share/pulse
git pull origin main
```

#### 2. Add Pulse CLI to PATH (Optional but Recommended)

Add this to your `~/.zshenv` or `~/.zprofile`:

```bash
export PATH="$HOME/.local/share/pulse/bin:$PATH"
```

Then reload:
```bash
source ~/.zshenv
# or
source ~/.zprofile
```

#### 3. Restart Your Shell

```bash
exec zsh
```

That's it! Your plugins will now auto-install if they're missing.

---

## Configuration Changes

### No Changes Required

Your existing `.zshrc` configuration will continue to work:

```zsh
# This still works exactly as before
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)

source ~/.local/share/pulse/pulse.zsh
```

### Optional: Add Version Locking

You can now lock plugins to specific versions:

```zsh
# Old way (still works)
plugins=(
  zsh-users/zsh-autosuggestions
)

# New way (with version locking)
plugins=(
  zsh-users/zsh-autosuggestions@v0.7.0  # Lock to v0.7.0
  zsh-users/zsh-syntax-highlighting@master  # Use master branch
)

source ~/.local/share/pulse/pulse.zsh
```

---

## Behavior Changes

### Before v1.1.0

1. Add plugin to `plugins` array
2. Manually clone plugin:
   ```bash
   cd ~/.local/share/pulse/plugins
   git clone https://github.com/zsh-users/zsh-autosuggestions
   ```
3. Restart shell

### After v1.1.0

1. Add plugin to `plugins` array
2. Restart shell (plugin clones automatically)

**That's it!** Manual cloning is no longer needed.

---

## New Features You Can Use

### 1. Auto-Installation

Simply add a plugin to your `.zshrc` and restart:

```zsh
plugins=(
  zsh-users/zsh-autosuggestions  # Auto-installs on next start
)

source ~/.local/share/pulse/pulse.zsh
```

### 2. Version Locking

Lock plugins to specific versions for stability:

```zsh
plugins=(
  zsh-users/zsh-autosuggestions@v0.7.0
  zsh-users/zsh-syntax-highlighting@0.7.1
)
```

### 3. CLI Commands

Manage plugins from the command line:

```bash
# Install plugins
pulse install zsh-users/zsh-autosuggestions

# Update all plugins
pulse update

# List installed plugins
pulse list

# Remove a plugin
pulse remove zsh-autosuggestions
```

---

## Common Migration Scenarios

### Scenario 1: Fresh Install

If you're installing Pulse for the first time:

```bash
# Use the new installation script
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/install.sh | bash

# Edit .zshrc (installer already set it up)
nano ~/.zshrc

# Add plugins (they'll auto-install)
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)

# Restart shell
exec zsh
```

### Scenario 2: Existing Installation

If you already have Pulse v1.0.0:

```bash
# 1. Update Pulse
cd ~/.local/share/pulse && git pull

# 2. Add CLI to PATH (optional)
echo 'export PATH="$HOME/.local/share/pulse/bin:$PATH"' >> ~/.zshenv

# 3. Restart shell
exec zsh

# Your plugins will auto-install if missing
```

### Scenario 3: Manually Cloned Plugins

If you have manually cloned plugins:

```bash
# Your plugins will continue to work
# No changes needed!

# But now you can update them easily:
pulse update

# And install new ones without manual cloning:
pulse install zsh-users/zsh-completions
```

### Scenario 4: Version Pinning for Stability

Lock all plugins to current versions:

```bash
# 1. List current versions
pulse list

# Output:
#   • zsh-autosuggestions (git: v0.7.0)
#   • zsh-syntax-highlighting (git: master)

# 2. Update .zshrc with versions
plugins=(
  zsh-users/zsh-autosuggestions@v0.7.0
  zsh-users/zsh-syntax-highlighting@master
)

# 3. Now these versions are locked
```

---

## Troubleshooting

### Issue: Plugins Not Auto-Installing

**Problem**: Added a plugin to `.zshrc` but it didn't install.

**Solution**:
1. Enable debug mode to see what's happening:
   ```bash
   export PULSE_DEBUG=1
   exec zsh
   ```
2. Check for error messages
3. Manually install if needed:
   ```bash
   pulse install zsh-users/zsh-autosuggestions
   ```

### Issue: Git Not Found

**Problem**: Error message "git not found, cannot clone plugins"

**Solution**: Install git:
```bash
# Ubuntu/Debian
sudo apt-get install git

# macOS
brew install git

# Then restart shell
exec zsh
```

### Issue: Network Connection Failed

**Problem**: Plugin clone failed due to network issues

**Solution**:
1. Check internet connection
2. Try manual install later:
   ```bash
   pulse install zsh-users/zsh-autosuggestions
   ```

### Issue: Wrong Plugin Version

**Problem**: Plugin installed wrong version

**Solution**:
1. Remove the plugin:
   ```bash
   pulse remove plugin-name
   ```
2. Install specific version:
   ```bash
   pulse install user/plugin@v1.0.0
   ```
3. Update `.zshrc` with version:
   ```zsh
   plugins=(user/plugin@v1.0.0)
   ```

### Issue: CLI Command Not Found

**Problem**: `pulse` command not found

**Solution**: Add to PATH in `~/.zshenv`:
```bash
echo 'export PATH="$HOME/.local/share/pulse/bin:$PATH"' >> ~/.zshenv
source ~/.zshenv
```

---

## Rolling Back

If you need to roll back to v1.0.0:

```bash
# 1. Go to Pulse directory
cd ~/.local/share/pulse

# 2. Checkout v1.0.0 tag (if available)
git checkout v1.0.0-mvp

# Or go to previous commit
git log --oneline  # Find the commit
git checkout <commit-hash>

# 3. Restart shell
exec zsh
```

Your manually cloned plugins will continue to work.

---

## Best Practices

### After Upgrading

1. **Enable version locking** for stability:
   ```zsh
   plugins=(
     zsh-users/zsh-autosuggestions@v0.7.0
   )
   ```

2. **Use the CLI** for plugin management:
   ```bash
   pulse install  # Install all
   pulse update   # Update all
   pulse list     # Check status
   ```

3. **Keep Pulse updated**:
   ```bash
   cd ~/.local/share/pulse && git pull
   ```

4. **Review new features** in [EXAMPLES.md](EXAMPLES.md)

---

## Support

If you encounter issues during migration:

1. **Enable debug mode**: `export PULSE_DEBUG=1`
2. **Check the logs**: Look for `[Pulse]` messages
3. **Review documentation**: 
   - [README.md](README.md) - Main documentation
   - [EXAMPLES.md](EXAMPLES.md) - Usage examples
   - [RELEASE_NOTES.md](RELEASE_NOTES.md) - What's new
4. **Open an issue**: https://github.com/astrosteveo/pulse/issues

---

## Summary

**Key Takeaways**:
- ✅ Existing configurations work without changes
- ✅ New auto-install feature makes plugin management easier
- ✅ Version locking available for stability
- ✅ CLI tool available for manual management
- ✅ Backwards compatible with v1.0.0

**Recommended Actions**:
1. Update Pulse: `cd ~/.local/share/pulse && git pull`
2. Add CLI to PATH: `echo 'export PATH="$HOME/.local/share/pulse/bin:$PATH"' >> ~/.zshenv`
3. Restart shell: `exec zsh`
4. Enjoy automatic plugin installation!
