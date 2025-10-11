# Pulse MVP Quick Start Guide

**Get started with Pulse in under 5 minutes.**

---

## What is Pulse?

Pulse is a minimal, intelligent Zsh plugin orchestrator that automatically handles plugin loading, compinit timing, and optimal ordering—so you don't have to.

**Key Features:**

- ✨ Intelligent plugin loading (automatic ordering)
- 🚀 Fast startup (<500ms with 15 plugins)
- 📦 Zero configuration by default
- 🎯 Declarative configuration
- 🔧 Compatible with all standard Zsh plugins

---

## Installation

### Quick Install (Recommended)

```bash
# 1. Clone Pulse
git clone https://github.com/astrosteveo/pulse ~/.local/share/pulse

# 2. Copy the template configuration
cp ~/.local/share/pulse/pulse.zshrc.template ~/.zshrc

# 3. Edit ~/.zshrc and uncomment plugins you want
$EDITOR ~/.zshrc

# 4. Restart your shell
exec zsh
```

### Manual Install

If you already have a `.zshrc`, add these lines:

```zsh
# Declare your plugins FIRST
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)

# Then load Pulse
source ~/.local/share/pulse/pulse.zsh
```

Then restart your shell: `exec zsh`

---

## Basic Usage

### Adding Plugins

Add plugins to the `plugins` array in your `.zshrc`:

```zsh
plugins=(
  zsh-users/zsh-autosuggestions           # GitHub shorthand
  zsh-users/zsh-syntax-highlighting
  https://gitlab.com/user/repo.git         # Full URL
  /path/to/local/plugin                    # Local path
)
```

**Note**: In this MVP, you'll need to manually clone plugins first:

```bash
# Create plugins directory
mkdir -p ~/.local/share/pulse/plugins

# Clone plugins manually
cd ~/.local/share/pulse/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting
```

Future versions will handle cloning automatically.

### Plugin Formats Supported

- **GitHub shorthand**: `owner/repo`
- **Full Git URL**: `https://github.com/owner/repo.git`
- **Local path**: `/absolute/path/to/plugin`

---

## Example Configurations

### Minimal Setup

```zsh
plugins=(
  zsh-users/zsh-autosuggestions
)

source ~/.local/share/pulse/pulse.zsh
```

### Developer Setup (Recommended)

```zsh
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-completions
)

source ~/.local/share/pulse/pulse.zsh
```

---

## How Pulse Works

Pulse automatically determines the correct load order:

1. **Early Stage**: Completion plugins (before compinit)
2. **Compinit**: Zsh completion system
3. **Normal Stage**: Standard plugins
4. **Late Stage**: Syntax highlighting, themes

Example - even if you list plugins in "wrong" order:

```zsh
plugins=(
  zsh-users/zsh-syntax-highlighting  # Should be last
  zsh-users/zsh-completions          # Should be first
  zsh-users/zsh-autosuggestions      # Middle
)
```

Pulse will load them correctly:

1. zsh-completions (early stage)
2. Run compinit
3. zsh-autosuggestions (normal stage)
4. zsh-syntax-highlighting (late stage) ✅

---

## Advanced Configuration

### Temporarily Disable a Plugin

```zsh
pulse_disabled_plugins=(unwanted-plugin)
```

### Override Load Stage

```zsh
typeset -gA pulse_plugin_stage
pulse_plugin_stage[my-custom-plugin]="late"
```

### Custom Directories

```zsh
export PULSE_DIR="${HOME}/.pulse"
export PULSE_CACHE_DIR="${HOME}/.pulse/cache"
```

### Enable Debug Mode

```zsh
export PULSE_DEBUG=1
exec zsh
```

Shows:

- Plugin detection logic
- Load order decisions
- Timing information
- Errors and warnings

---

## Troubleshooting

### Plugin Not Loading

Check if disabled:

```zsh
echo ${pulse_disabled_plugins[@]}
```

Enable debug mode:

```zsh
PULSE_DEBUG=1 exec zsh
```

Verify plugin exists:

```zsh
ls -la ~/.local/share/pulse/plugins/
```

### Verify Plugin Status

After sourcing your `.zshrc`, check plugin state:

```zsh
# Check if plugin was registered
echo ${pulse_plugins[@]}

# Check plugin stage assignment
echo ${pulse_plugin_stages[plugin-name]}

# Check plugin status
echo ${pulse_plugin_status[plugin-name]}
```

---

## Common Workflows

### Trying a New Plugin

1. Clone the plugin:

   ```bash
   cd ~/.local/share/pulse/plugins
   git clone https://github.com/user/plugin-name
   ```

2. Add to `.zshrc`:

   ```zsh
   plugins+=(user/plugin-name)
   ```

3. Reload shell:

   ```bash
   exec zsh
   ```

### Removing a Plugin

1. Remove from `plugins` array in `.zshrc`
2. Delete plugin directory:

   ```bash
   rm -rf ~/.local/share/pulse/plugins/plugin-name
   ```

### Updating Plugins

Manually update each plugin:

```bash
cd ~/.local/share/pulse/plugins/plugin-name
git pull
```

Or update all plugins:

```bash
for plugin in ~/.local/share/pulse/plugins/*; do
  (cd "$plugin" && git pull)
done
```

---

## Performance Tips

### Profile Your Startup

Time your shell startup:

```bash
time zsh -ic exit
```

Enable debug mode to see per-plugin timing:

```bash
PULSE_DEBUG=1 zsh
```

### Keep It Minimal

The fastest plugin is the one you don't load! Review your plugins periodically and remove ones you don't use.

---

## MVP Limitations

This is an MVP release. The following features are coming in future versions:

**Not Yet Implemented:**

- ❌ Automatic plugin installation (must clone manually)
- ❌ CLI commands (`pulse install`, `pulse update`, `pulse list`)
- ❌ Plugin metadata caching
- ❌ Lazy loading for heavy plugins
- ❌ `pulse doctor` diagnostics

**What Works Now:**

- ✅ Intelligent plugin detection and ordering
- ✅ Declarative configuration
- ✅ Manual overrides and customization
- ✅ Debug mode
- ✅ Error handling

---

## Getting Help

### Enable Debug Mode

```bash
export PULSE_DEBUG=1
exec zsh
```

### Check Test Results

See [TEST_RESULTS.md](../../TEST_RESULTS.md) for comprehensive test coverage.

### Report Issues

Found a bug? Open an issue at: <https://github.com/astrosteveo/pulse/issues>

Include:

- Debug output (`PULSE_DEBUG=1`)
- Your `.zshrc` configuration
- Zsh version (`zsh --version`)
- OS information

---

## What's Next?

Future releases will add:

- **v1.1**: Automatic plugin installation, CLI commands
- **v1.2**: Plugin caching, performance optimization
- **v1.3**: Lazy loading, diagnostic tools

---

## Quick Reference

```bash
# Manual plugin management (MVP)
cd ~/.local/share/pulse/plugins
git clone https://github.com/user/repo
cd repo && git pull              # Update
rm -rf plugin-name               # Remove

# Configuration (in .zshrc)
plugins=(owner/repo ...)           # Declare plugins
pulse_disabled_plugins=(name ...)  # Disable plugins
pulse_plugin_stage[name]="stage"   # Override load stage
export PULSE_DEBUG=1               # Enable debug mode

# Available stages
# - early    (completion plugins)
# - normal   (standard plugins)
# - late     (syntax highlighting, themes)
```

---

**Welcome to Pulse MVP!** Enjoy your intelligent Zsh plugin management. 🚀
