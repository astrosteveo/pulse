# Pulse Installer Quickstart

One-command installation for the Pulse Zsh framework.

## Quick Install

Run this single command to install Pulse:

```bash
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh | bash
```

## What Happens During Installation

The installer will:

1. ✓ Verify prerequisites (Zsh 5.0+, Git, writable directories)
2. ✓ Clone Pulse repository to `~/.local/share/pulse`
3. ✓ Backup your existing `.zshrc` (timestamped)
4. ✓ Add Pulse configuration block to `.zshrc`
5. ✓ Verify installation by loading Pulse in a test shell
6. ✓ Set up CLI commands (`pulse list`, `pulse update`, `pulse doctor`)
7. ✓ Display next steps

**Total time**: ~2 minutes

## What You Get

After installation, you'll have:

- **Core Framework**: 7 modules (environment, completions, keybindings, directory, prompt, utilities, compinit)
- **Plugin Engine**: Automatic plugin loading with smart type detection
- **Version Management**: Support for `@latest`, `@tag`, `@branch`, `@commit` version pinning
- **Lock File**: Automatic `plugins.lock` for reproducible environments
- **CLI Commands**: `pulse list`, `pulse update`, `pulse doctor` for plugin management

## After Installation

Restart your shell to start using Pulse:

```bash
exec zsh
```

Verify Pulse is loaded:

```bash
echo $PULSE_VERSION
```

Try CLI commands:

```bash
# List installed plugins
pulse list

# Update plugins
pulse update

# Run system diagnostics
pulse doctor
```

## Customization

### Custom Installation Directory

```bash
PULSE_INSTALL_DIR=~/my-pulse curl -fsSL https://... | bash
```

### Custom .zshrc Location

```bash
PULSE_ZSHRC=~/.config/zsh/.zshrc curl -fsSL https://... | bash
```

### Skip Backup Creation

```bash
PULSE_SKIP_BACKUP=1 curl -fsSL https://... | bash
```

### Skip Verification Step

```bash
PULSE_SKIP_VERIFY=1 curl -fsSL https://... | bash
```

## Adding Plugins

After installation, edit your `.zshrc` and add plugins to the `plugins` array:

```bash
# In ~/.zshrc, find the Pulse Configuration block:
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)
```

Restart your shell to load new plugins.

### Version Pinning

Pin plugins to specific versions for reproducible environments:

```bash
plugins=(
  # Always use latest (default)
  zsh-users/zsh-autosuggestions@latest

  # Pin to specific version tag
  zsh-users/zsh-syntax-highlighting@v0.8.0

  # Pin to branch
  romkatv/powerlevel10k@main

  # Pin to specific commit
  some-user/plugin@abc123def
)
```

The `plugins.lock` file automatically tracks exact versions for each plugin.

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

## Uninstall

To uninstall Pulse:

1. Remove the Pulse configuration block from `~/.zshrc`
2. Remove installation directory: `rm -rf ~/.local/share/pulse`
3. Restart your shell

## Documentation

- [Main README](../../README.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Feature Specification](../../specs/003-implement-an-install/spec.md)

---

**Note**: This installer follows the zero-configuration principle. The `plugins` array is always declared before `source pulse.zsh` to ensure proper loading order.
