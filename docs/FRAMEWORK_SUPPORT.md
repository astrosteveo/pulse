# Framework Support in Pulse

Pulse has native support for popular Zsh plugin frameworks, allowing you to use plugins from Oh-My-Zsh and Prezto without any additional configuration.

## Oh-My-Zsh Support

### Overview

Oh-My-Zsh (OMZ) is one of the most popular Zsh frameworks, with hundreds of community-contributed plugins. Pulse can load any Oh-My-Zsh plugin directly.

### How It Works

When you specify an Oh-My-Zsh plugin path like `ohmyzsh/ohmyzsh/plugins/kubectl`, Pulse:

1. **Uses sparse checkout** to clone only the specific plugin directory plus the `lib/` directory (not the entire 15MB+ repository)
2. **Includes framework dependencies** - The `lib/` directory contains shared helper files that many plugins depend on (like `git.zsh`)
3. **Automatically clones** the oh-my-zsh repository to `$PULSE_DIR/plugins/ohmyzsh` (only once per framework)
4. **Adds additional plugins** to the existing sparse checkout when you specify more OMZ plugins
5. **Sets up environment variables** that OMZ plugins expect:
   - `$ZSH` - points to the oh-my-zsh installation directory
   - `$ZSH_CACHE_DIR` - directory for plugin-generated completions and cache
   - `$ZSH_CUSTOM` - directory for custom plugins (for compatibility)
6. **Loads the plugin** from the correct subdirectory
7. **Creates the cache structure** for completions

**Disk Space Savings**: Using sparse checkout, Pulse only downloads the files you need. A single plugin with the lib directory typically uses ~6.4MB instead of ~15MB for the full repository (57% savings).

### Usage

Simply add OMZ plugins to your `plugins` array using the full path:

```zsh
plugins=(
  ohmyzsh/ohmyzsh/plugins/git
  ohmyzsh/ohmyzsh/plugins/docker
  ohmyzsh/ohmyzsh/plugins/kubectl
  ohmyzsh/ohmyzsh/plugins/aws
)
```

### Example: kubectl plugin

The kubectl plugin from Oh-My-Zsh provides aliases and completions:

```zsh
# In your .zshrc
plugins=(
  ohmyzsh/ohmyzsh/plugins/kubectl
)

# After reloading your shell, you'll have:
# - k=kubectl
# - kgp='kubectl get pods'
# - kgs='kubectl get svc'
# - And many more...
```

### Popular Oh-My-Zsh Plugins

Here are some commonly used OMZ plugins that work great with Pulse:

```zsh
plugins=(
  # Development tools
  ohmyzsh/ohmyzsh/plugins/git
  ohmyzsh/ohmyzsh/plugins/github
  ohmyzsh/ohmyzsh/plugins/docker
  ohmyzsh/ohmyzsh/plugins/docker-compose
  
  # Cloud platforms
  ohmyzsh/ohmyzsh/plugins/aws
  ohmyzsh/ohmyzsh/plugins/gcloud
  ohmyzsh/ohmyzsh/plugins/kubectl
  
  # Languages & frameworks
  ohmyzsh/ohmyzsh/plugins/node
  ohmyzsh/ohmyzsh/plugins/npm
  ohmyzsh/ohmyzsh/plugins/python
  ohmyzsh/ohmyzsh/plugins/rust
  
  # Utilities
  ohmyzsh/ohmyzsh/plugins/extract  # Smart extraction for various archives
  ohmyzsh/ohmyzsh/plugins/sudo     # ESC ESC to add sudo
  ohmyzsh/ohmyzsh/plugins/web-search  # Search engines from terminal
)
```

### Performance

Pulse uses git sparse checkout to dramatically reduce disk usage and clone times:
- **First Oh-My-Zsh plugin**: ~6.4MB initial clone including lib/ directory (vs ~15MB for full repository, 57% savings)
- **First Prezto module**: ~2MB initial clone including helper module
- **Additional plugins/modules**: Only fetches the specific plugin files (~200KB-1MB per plugin)
- **Subsequent shells**: Use cached version, no additional downloads

The sparse checkout includes necessary framework dependencies (Oh-My-Zsh `lib/`, Prezto `helper` module) so plugins work correctly while still saving significant disk space.

Individual plugins load quickly since Pulse uses the intelligent 5-stage loading pipeline.

---

## Prezto Support

### Overview

Prezto is a configuration framework for Zsh that provides useful modules. Pulse can load any Prezto module directly.

### How It Works

When you specify a Prezto module path like `sorin-ionescu/prezto/modules/git`, Pulse:

1. **Uses sparse checkout** to clone only the specific module directory plus the `helper` module (not the entire repository)
2. **Includes framework dependencies** - The `helper` module is a common dependency for many Prezto modules loaded via `pmodload`
3. **Automatically clones** the prezto repository to `$PULSE_DIR/plugins/prezto` (only once per framework)
4. **Adds additional modules** to the existing sparse checkout when you specify more Prezto modules
5. **Sets up environment variables**:
   - `$ZPREZTODIR` - points to the prezto installation directory
6. **Provides the `pmodload` function** for module dependency loading
7. **Loads the module** using its `init.zsh` file

**Disk Space Savings**: Just like with Oh-My-Zsh, Pulse uses sparse checkout to only download the modules you need. Prezto sparse checkouts are typically ~2MB per module.

### Usage

Add Prezto modules to your `plugins` array using the full path:

```zsh
plugins=(
  sorin-ionescu/prezto/modules/environment
  sorin-ionescu/prezto/modules/git
  sorin-ionescu/prezto/modules/terminal
)
```

### Example: git module

The git module from Prezto provides aliases and functions:

```zsh
# In your .zshrc
plugins=(
  sorin-ionescu/prezto/modules/git
)

# After reloading your shell, you'll have:
# - g=git
# - gst='git status'
# - And many more...
```

### Popular Prezto Modules

Here are some commonly used Prezto modules:

```zsh
plugins=(
  # Core modules
  sorin-ionescu/prezto/modules/environment
  sorin-ionescu/prezto/modules/terminal
  sorin-ionescu/prezto/modules/editor
  sorin-ionescu/prezto/modules/history
  sorin-ionescu/prezto/modules/directory
  
  # Utility modules
  sorin-ionescu/prezto/modules/git
  sorin-ionescu/prezto/modules/utility
  sorin-ionescu/prezto/modules/completion
  
  # Enhancement modules
  sorin-ionescu/prezto/modules/autosuggestions
  sorin-ionescu/prezto/modules/syntax-highlighting
)
```

---

## Mixing Frameworks

You can mix Oh-My-Zsh plugins, Prezto modules, and regular Zsh plugins:

```zsh
plugins=(
  # Oh-My-Zsh plugins
  ohmyzsh/ohmyzsh/plugins/docker
  ohmyzsh/ohmyzsh/plugins/kubectl
  
  # Prezto modules
  sorin-ionescu/prezto/modules/git
  
  # Community plugins
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)
```

Pulse handles the load order and environment setup automatically!

---

## Migration Guide

### From Oh-My-Zsh

If you're migrating from Oh-My-Zsh:

1. **Identify your plugins** - Look at the `plugins=()` array in your `.zshrc`

2. **Convert to Pulse format** - Add the full path:
   ```zsh
   # Before (in Oh-My-Zsh)
   plugins=(git docker kubectl)
   
   # After (in Pulse)
   plugins=(
     ohmyzsh/ohmyzsh/plugins/git
     ohmyzsh/ohmyzsh/plugins/docker
     ohmyzsh/ohmyzsh/plugins/kubectl
   )
   ```

3. **Remove Oh-My-Zsh** - You can now remove the Oh-My-Zsh installation and sourcing:
   ```zsh
   # Remove these lines:
   # export ZSH="$HOME/.oh-my-zsh"
   # source $ZSH/oh-my-zsh.sh
   ```

4. **Keep using your favorite plugins** - All OMZ plugins work as expected!

### From Prezto

If you're migrating from Prezto:

1. **Identify your modules** - Look at the `pmodule` configuration:
   ```zsh
   zstyle ':prezto:load' pmodule \
     'environment' \
     'terminal' \
     'git'
   ```

2. **Convert to Pulse format**:
   ```zsh
   plugins=(
     sorin-ionescu/prezto/modules/environment
     sorin-ionescu/prezto/modules/terminal
     sorin-ionescu/prezto/modules/git
   )
   ```

3. **Remove Prezto bootstrap** - Remove the Prezto sourcing:
   ```zsh
   # Remove these lines:
   # source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
   ```

---

## How It's Implemented

For developers interested in how Pulse achieves framework compatibility:

### Detection

Pulse detects framework plugins by path pattern:
- Oh-My-Zsh: `ohmyzsh/ohmyzsh/plugins/*`
- Prezto: `sorin-ionescu/prezto/modules/*`

### Environment Setup

Before loading a framework plugin, Pulse calls `_pulse_setup_framework_env()` which:

1. Extracts the framework root directory from the plugin path
2. Exports the appropriate environment variables
3. Creates required directory structures (e.g., cache directories)
4. Adds completion directories to `$fpath`
5. Defines compatibility functions (e.g., `pmodload` for Prezto)

### Plugin Loading

Framework plugins are loaded like any other plugin, but with the framework environment pre-configured. This ensures that all references to framework variables work correctly.

### Repository Cloning

When you specify a framework plugin path, Pulse:
1. Parses the specification to identify it as a framework plugin
2. Clones the entire framework repository (not just the single plugin)
3. Points the plugin path to the specific plugin/module within the framework
4. Shares the framework installation across all plugins from that framework

---

## Troubleshooting

### Plugin not loading

If a framework plugin isn't loading:

1. **Check the path** - Ensure you're using the correct path format:
   - Oh-My-Zsh: `ohmyzsh/ohmyzsh/plugins/PLUGIN_NAME`
   - Prezto: `sorin-ionescu/prezto/modules/MODULE_NAME`

2. **Enable debug mode**:
   ```zsh
   export PULSE_DEBUG=1
   exec zsh
   ```
   This will show you what Pulse is doing.

3. **Check if the plugin exists** - Not all plugins are available in every version. Check the framework's repository.

### Environment variables not set

If a plugin complains about missing environment variables:

1. **Verify the plugin path** - The path must match the framework pattern exactly
2. **Check plugin order** - Some plugins may depend on others being loaded first
3. **Report an issue** - If you believe it's a Pulse bug, please open an issue

### Completions not working

If completions aren't working for a framework plugin:

1. **Check compinit** - Ensure Pulse's compinit runs (it should by default)
2. **Rebuild completions**:
   ```zsh
   rm -f $PULSE_CACHE_DIR/zcompdump
   exec zsh
   ```
3. **Check fpath** - Run `echo $fpath` and ensure the framework's completion directory is included

---

## Performance Considerations

### First Run

On the first run, Pulse will clone the framework repository, which can take a few seconds:
- Oh-My-Zsh: ~10-20 seconds (repository is ~50MB)
- Prezto: ~5-10 seconds (smaller repository)

This is a one-time operation. Subsequent shell starts use the cached framework.

### Subsequent Runs

After the initial clone:
- Framework detection: <1ms
- Environment setup: <5ms per framework
- Plugin loading: Same as regular plugins

### Optimization Tips

1. **Load only what you need** - Framework repos contain hundreds of plugins/modules. Only load the ones you actually use.

2. **Consider alternatives** - For some plugins, there are lighter community alternatives:
   ```zsh
   # Instead of:
   # ohmyzsh/ohmyzsh/plugins/git
   
   # Consider:
   peterhurford/git-it-on.zsh  # Lighter git utilities
   ```

3. **Use Pulse's lazy loading** - For heavy framework plugins, Pulse's deferred loading can help (future feature).

---

## Contributing

Found a framework plugin that doesn't work? Want to add support for another framework?

1. **Open an issue** - Describe the problem or feature request
2. **Submit a PR** - Framework support is implemented in `lib/plugin-engine.zsh`
3. **Add tests** - Framework support has comprehensive tests in `tests/integration/framework_*.bats`

---

## FAQ

### Q: Will using framework plugins make Pulse slower?

**A:** No. After the initial clone, framework plugins load at the same speed as regular plugins. The framework environment setup adds <5ms of overhead.

### Q: Can I mix Oh-My-Zsh and Prezto plugins?

**A:** Yes! Pulse handles each framework independently. You can load plugins from both.

### Q: Do I need to install Oh-My-Zsh or Prezto separately?

**A:** No. Pulse clones only what it needs and manages it automatically.

### Q: What about Oh-My-Zsh themes?

**A:** Pulse loads Oh-My-Zsh themes automatically if you specify a theme plugin. However, Pulse has its own prompt system that may conflict. We recommend using Pulse-compatible themes or sticking with the Pulse prompt.

### Q: Can I use Oh-My-Zsh's `omz` command?

**A:** The `omz` command is specific to Oh-My-Zsh's installation. Pulse provides its own `pulse` command for plugin management. However, all plugin functionality remains the same.

### Q: What if a framework plugin depends on other framework plugins?

**A:** Some framework plugins have dependencies on other plugins/modules. Add all required plugins to your `plugins` array. Pulse loads them in the correct order based on their types.

---

## Examples

### Complete Oh-My-Zsh Migration

```zsh
# Before: .zshrc with Oh-My-Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(
  git
  docker
  kubectl
  aws
  extract
)
source $ZSH/oh-my-zsh.sh

# After: .zshrc with Pulse
export PATH="$HOME/.local/share/pulse/bin:$PATH"
source ~/.local/share/pulse/pulse.zsh

plugins=(
  ohmyzsh/ohmyzsh/plugins/git
  ohmyzsh/ohmyzsh/plugins/docker
  ohmyzsh/ohmyzsh/plugins/kubectl
  ohmyzsh/ohmyzsh/plugins/aws
  ohmyzsh/ohmyzsh/plugins/extract
)
```

### Complete Prezto Migration

```zsh
# Before: .zpreztorc
zstyle ':prezto:load' pmodule \
  'environment' \
  'terminal' \
  'editor' \
  'history' \
  'directory' \
  'git'

# After: .zshrc with Pulse
export PATH="$HOME/.local/share/pulse/bin:$PATH"
source ~/.local/share/pulse/pulse.zsh

plugins=(
  sorin-ionescu/prezto/modules/environment
  sorin-ionescu/prezto/modules/terminal
  sorin-ionescu/prezto/modules/editor
  sorin-ionescu/prezto/modules/history
  sorin-ionescu/prezto/modules/directory
  sorin-ionescu/prezto/modules/git
)
```

### Mixed Setup

```zsh
# Best of all worlds
plugins=(
  # Framework plugins
  ohmyzsh/ohmyzsh/plugins/kubectl
  sorin-ionescu/prezto/modules/git
  
  # Modern community plugins
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
  
  # Your own plugins
  ~/my-custom-plugins/work-aliases
)
```

---

## Related Documentation

- [Pulse Quickstart Guide](../specs/001-build-a-zsh/quickstart.md)
- [Plugin Loading Documentation](../specs/001-build-a-zsh/plan.md)
- [Test Suite](../tests/integration/framework_support.bats)
