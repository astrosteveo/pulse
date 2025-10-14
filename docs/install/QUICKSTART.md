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
6. ✓ Display next steps

**Total time**: ~2 minutes

## After Installation

Restart your shell to start using Pulse:

```bash
exec zsh
```

Verify Pulse is loaded:

```bash
echo $PULSE_VERSION
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
