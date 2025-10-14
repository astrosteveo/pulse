# Pulse Quick Start Guide

**Get your Zsh shell configured and running with intelligent plugin management in under 5 minutes.**

---

## What is Pulse?

Pulse is a minimal, intelligent Zsh plugin orchestrator that removes the complexity from plugin management. You simply declare what plugins you want, and Pulse handles all the orchestration—determining load order, managing compinit timing, and ensuring everything works together.

**Key Features:**

- ✨ Intelligent plugin loading (no manual ordering required)
- 🚀 Fast startup (<500ms with 15 plugins)
- 📦 Zero configuration by default
- 🎯 Declarative configuration (specify state, not steps)
- 🔧 Compatible with all standard Zsh plugins

---

## Installation

### Quick Install (Recommended)

**For new users or fresh setups:**

```bash
# 1. Clone Pulse
git clone https://github.com/astrosteveo/pulse ~/.local/share/pulse

# 2. Copy the template configuration
cp ~/.local/share/pulse/pulse.zshrc.template ~/.zshrc

# 3. Edit ~/.zshrc and uncomment the plugins you want

# 4. Restart your shell
exec zsh
```

The template includes:

- ✨ Popular plugin examples (commented out)
- 📚 Clear documentation for each option
- 🎯 Example configurations (minimal, developer, power user)
- 🔧 Advanced configuration options
- 🐛 Troubleshooting tips

### Manual Install

**For users who already have a .zshrc:**

Clone Pulse:

```bash
git clone https://github.com/astrosteveo/pulse ~/.local/share/pulse
```

Add these lines to your existing `~/.zshrc`:

```zsh
# Load Pulse
export PATH="$HOME/.local/share/pulse/bin:$PATH"
source ~/.local/share/pulse/pulse.zsh

# Declare your plugins (examples - uncomment what you want)
plugins=(
  # zsh-users/zsh-autosuggestions      # Fish-like autosuggestions
  # zsh-users/zsh-syntax-highlighting  # Syntax highlighting (loaded last automatically)
  # zsh-users/zsh-completions          # Additional completions
)
```

Restart your shell:

```bash
exec zsh
```

That's it! Pulse will automatically install and load your plugins on first run.

---

## Basic Usage

### Adding Plugins

Simply add plugin specifications to the `plugins` array in your `.zshrc`:

```zsh
plugins=(
  zsh-users/zsh-autosuggestions           # GitHub shorthand
  zsh-users/zsh-syntax-highlighting
  https://gitlab.com/user/custom-plugin.git  # Full URL
  /path/to/local/plugin                    # Local path
)
```

Save and restart your shell (`exec zsh`), and Pulse will install and load new plugins automatically.

### Plugin Formats

Pulse supports multiple ways to specify plugins:

- **GitHub shorthand**: `owner/repo` → `https://github.com/owner/repo.git`
- **Full Git URL**: `https://github.com/owner/repo.git` or `https://gitlab.com/...`
- **Local path**: `/absolute/path/to/plugin`
- **Oh-My-Zsh plugin**: `ohmyzsh/ohmyzsh/plugins/kubectl`
- **Prezto module**: `sorin-ionescu/prezto/modules/git`

### Updating Plugins

Update all plugins to their latest versions:

```bash
pulse update
```

Update specific plugins:

```bash
pulse update zsh-users/zsh-autosuggestions
```

### Listing Plugins

See what plugins are installed and their status:

```bash
pulse list
```

Output example:

```
Plugin                            Status   Stage    Load Time
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
zsh-users/zsh-autosuggestions     loaded   normal   42ms
zsh-users/zsh-syntax-highlighting loaded   late     67ms
```

---

## Managing Plugins with the CLI

Pulse includes a command-line tool for managing your plugins:

```bash
# List all installed plugins
pulse list

# Show detailed information about a plugin
pulse info zsh-autosuggestions

# Run diagnostics to check for issues
pulse doctor

# Clear the plugin cache
pulse cache clear

# Show Pulse version
pulse version
```

**Available Commands:**

- `pulse list` - Show all installed plugins with their status and type
  - `--format=table` (default) - Formatted table view
  - `--format=json` - JSON output for scripting
  - `--format=simple` - Plain list, one per line

- `pulse info <plugin>` - Show detailed information about a specific plugin
  - Plugin path, type, git info, and files

- `pulse doctor` - Run diagnostic checks
  - Zsh version compatibility
  - Git availability  
  - Directory permissions
  - Plugin state

- `pulse cache clear` - Clear cached plugin metadata
  
- `pulse version` - Show Pulse version and git commit

**Coming Soon:**
- `pulse update` - Update plugins to latest versions
- `pulse install` - Install new plugins without restarting
- `pulse remove` - Remove plugins cleanly
- `pulse benchmark` - Measure shell startup performance
- `pulse validate` - Validate configuration files

The `pulse` command is automatically available after installation.

---

## Example Configurations

### Minimal Setup (Fast Startup)

```zsh
# Just autosuggestions - minimal, fast
plugins=(
  zsh-users/zsh-autosuggestions
)
```

**Startup time:** ~250ms

### Developer Setup (Recommended)

```zsh
# Balanced feature set for development work
plugins=(
  zsh-users/zsh-autosuggestions      # Helpful suggestions
  zsh-users/zsh-syntax-highlighting  # Visual feedback
  zsh-users/zsh-completions          # Extra completions
)
```

**Startup time:** ~350ms

### Power User Setup

```zsh
# Full-featured with lazy loading for heavy plugins
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-completions
  junegunn/fzf                       # Fuzzy finder (loaded on demand)
  zsh-users/zsh-history-substring-search
)
```

**Startup time:** ~450ms (fzf loaded on first use)

---

## How Pulse Works

### Intelligent Load Ordering

Pulse automatically determines the correct load order for your plugins:

1. **Early Stage**: Completion plugins (add to fpath before compinit)
2. **Compinit**: Run Zsh completion system (once)
3. **Normal Stage**: Standard plugins
4. **Late Stage**: Syntax highlighting, themes (must load last)
5. **Deferred Stage**: Heavy plugins (loaded on first use)

**You don't need to think about this**—Pulse figures it out automatically!

### Example

Given this configuration:

```zsh
plugins=(
  zsh-users/zsh-syntax-highlighting  # Needs to be last
  zsh-users/zsh-completions          # Needs compinit
  zsh-users/zsh-autosuggestions      # Standard plugin
)
```

Pulse will load them in the correct order:

1. zsh-completions (early stage)
2. Run compinit
3. zsh-autosuggestions (normal stage)
4. zsh-syntax-highlighting (late stage) ✅

Even though you listed syntax-highlighting first!

---

## Advanced Usage

### Temporarily Disable a Plugin

```zsh
# In .zshrc
pulse_disabled_plugins=(plugin-to-skip)
```

### Override Load Stage

If Pulse's automatic detection doesn't work for a specific plugin:

```zsh
# Force a plugin to load at a specific stage
pulse_plugin_stage[my-custom-plugin]="late"
```

### Enable Debug Mode

See what Pulse is doing behind the scenes:

```zsh
export PULSE_DEBUG=1
exec zsh
```

Debug output shows:

- Plugin detection logic
- Load order decisions
- Timing for each operation
- Errors and warnings

---

## Common Workflows

### Trying Out a New Plugin

1. Add plugin to `plugins` array:

   ```zsh
   plugins+=(new/plugin)
   ```

2. Reload shell:

   ```bash
   exec zsh
   ```

Pulse installs and loads it automatically.

### Removing a Plugin

1. Remove from `plugins` array in `.zshrc`

2. Delete plugin files:

   ```bash
   pulse remove plugin-name
   ```

### Migrating from Oh-My-Zsh

Pulse has **native support** for Oh-My-Zsh plugins! Simply add the path to your favorite plugins:

1. Copy your plugin list from Oh-My-Zsh's `plugins=()` array

2. Convert to Pulse format by adding the full path:

   ```zsh
   # Oh-My-Zsh
   plugins=(git docker kubectl)

   # Pulse (native Oh-My-Zsh support)
   plugins=(
     ohmyzsh/ohmyzsh/plugins/git
     ohmyzsh/ohmyzsh/plugins/docker
     ohmyzsh/ohmyzsh/plugins/kubectl
   )
   ```

3. That's it! Pulse will:
   - Automatically clone the oh-my-zsh repository (if not already present)
   - Set up all required environment variables (`$ZSH`, `$ZSH_CACHE_DIR`)
   - Load your plugins with full compatibility

4. **Or** find equivalent community plugins if you prefer:

   ```zsh
   plugins=(
     peterhurford/git-it-on.zsh  # Modern git plugin alternative
     # Many plugins have standalone versions
   )
   ```

**Note:** Oh-My-Zsh plugins work out of the box - no configuration needed!

### Migrating from Prezto

Pulse also has **native support** for Prezto modules:

```zsh
# Prezto modules in .zpreztorc
zstyle ':prezto:load' pmodule \
  'environment' \
  'terminal' \
  'git'

# Pulse (native Prezto support)
plugins=(
  sorin-ionescu/prezto/modules/environment
  sorin-ionescu/prezto/modules/terminal
  sorin-ionescu/prezto/modules/git
)
```

Pulse will:
- Automatically clone the prezto repository (if not already present)
- Set up required environment variables (`$ZPREZTODIR`)
- Provide the `pmodload` function for compatibility
- Load your modules with full compatibility

---

## Troubleshooting

### Plugin Not Loading

Run diagnostics:

```bash
pulse doctor
```

This checks for common issues:

- Zsh version compatibility
- Git availability
- Directory permissions
- Plugin specification errors

### Slow Startup

Benchmark your configuration:

```bash
pulse benchmark
```

This shows:

- Total startup time
- Time per plugin
- Pulse overhead
- Recommendations

### Plugin Conflicts

If two plugins conflict (e.g., both define the same alias):

1. Check which plugin provides which feature:

   ```bash
   pulse info plugin-name
   ```

2. Disable one:

   ```zsh
   pulse_disabled_plugins=(conflicting-plugin)
   ```

3. Or load one later to override the other:

   ```zsh
   pulse_plugin_stage[my-preferred-plugin]="late"
   ```

---

## Performance Tips

### 1. Use Lazy Loading

Heavy plugins like nvm, fzf, or rbenv can be loaded on demand:

```zsh
# Pulse detects these automatically and defers loading
plugins=(
  junegunn/fzf  # Loaded only when 'fzf' command used
  # nvm, rbenv also auto-deferred
)
```

### 2. Profile Your Startup

Find the slowest plugins:

```bash
pulse benchmark
```

### 3. Keep It Minimal

Ask yourself: "Do I actually use this plugin?"

The fastest plugin is the one you don't load. 🚀

---

## Getting Help

### Check Plugin Info

```bash
pulse info plugin-name
```

Shows detailed information about a plugin.

### Validate Configuration

```bash
pulse validate
```

Checks your `.zshrc` for syntax errors and potential issues.

### Enable Debug Mode

```bash
export PULSE_DEBUG=1
exec zsh
```

See exactly what Pulse is doing.

### Report Issues

Found a bug or have a question?

1. Run diagnostics: `pulse doctor`
2. Check debug log: `~/.cache/pulse/debug.log`
3. Open an issue: <https://github.com/astrosteveo/pulse/issues>

---

## What's Next?

You now have a fast, intelligent Zsh configuration! Here are some next steps:

1. **Explore Popular Plugins**: Search GitHub for "zsh plugins" to find tools that fit your workflow

2. **Customize Your Setup**: Check out the [full documentation](../docs/) for advanced features

3. **Share Your Config**: Pulse configs are portable—share your `plugins` array with teammates

4. **Contribute**: Found a bug or have an idea? Contributions welcome!

---

## Quick Reference

```bash
# Plugin management
pulse update              # Update all plugins
pulse install             # Install missing plugins
pulse remove <plugin>     # Remove a plugin
pulse list                # List installed plugins

# Diagnostics
pulse doctor              # Check for issues
pulse benchmark           # Measure startup time
pulse validate            # Validate configuration

# Info
pulse info <plugin>       # Plugin details
pulse cache clear         # Clear cache

# Configuration (in .zshrc)
plugins=(owner/repo ...)           # Declare plugins
pulse_disabled_plugins=(name ...)  # Disable plugins
pulse_plugin_stage[name]="stage"   # Override load stage
export PULSE_DEBUG=1               # Enable debug mode
```

---

**Welcome to Pulse!** Enjoy your fast, intelligent Zsh experience. 🚀
