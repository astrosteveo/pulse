# Oh-My-Zsh and Framework Plugin Support

Pulse now supports loading plugins from popular Zsh frameworks like Oh-My-Zsh and Prezto with convenient shorthand syntax and path annotations.

## Quick Examples

### Oh-My-Zsh Plugins

```zsh
# Short syntax - just add to your plugins array
plugins=(
  omz:plugins/git          # Oh-My-Zsh git plugin
  omz:plugins/kubectl      # Oh-My-Zsh kubectl plugin
  omz:lib/git              # Oh-My-Zsh git library
  omz:themes/robbyrussell  # Oh-My-Zsh theme
)
```

### Prezto Modules

```zsh
plugins=(
  prezto:modules/git       # Prezto git module
  prezto:modules/prompt    # Prezto prompt module
)
```

### Path Annotations

```zsh
plugins=(
  # Load specific subdirectory from any repo
  ohmyzsh/ohmyzsh path:plugins/docker
  ohmyzsh/ohmyzsh path:plugins/helm
  
  # Multiple plugins from same repo
  ohmyzsh/ohmyzsh path:plugins/ansible
  ohmyzsh/ohmyzsh path:lib/vcs_info
)
```

### Kind Annotations

```zsh
plugins=(
  # Control loading stage
  user/repo kind:defer       # Load after compinit (for syntax highlighters)
  user/repo kind:path        # Load in normal stage
  user/repo kind:fpath       # Load early (for completions)
)
```

### Combined Annotations

```zsh
plugins=(
  # Combine multiple annotations
  ohmyzsh/ohmyzsh path:plugins/vi-mode kind:defer
  user/framework path:modules/editor kind:fpath
)
```

## How It Works

### Shorthand Syntax

The `omz:` and `prezto:` prefixes are shortcuts that:
1. Clone the framework repository once to `~/.local/share/pulse/plugins/ohmyzsh` (or `prezto`)
2. Load the specific subpath you requested
3. Share the same repo for all plugins from that framework

For example:
- `omz:plugins/git` → loads from `~/.local/share/pulse/plugins/ohmyzsh/plugins/git`
- `omz:plugins/kubectl` → loads from `~/.local/share/pulse/plugins/ohmyzsh/plugins/kubectl`

Both use the same cloned ohmyzsh repository.

### Path Annotations

The `path:` annotation lets you load a specific subdirectory from any repository:

```zsh
plugins=(
  user/repo path:subdirectory
)
```

This:
1. Clones `user/repo` to `~/.local/share/pulse/plugins/repo`
2. Loads the plugin from `~/.local/share/pulse/plugins/repo/subdirectory`
3. Creates a unique plugin name: `repo_subdirectory`

### Kind Annotations

The `kind:` annotation controls when and how a plugin is loaded:

- `kind:path` - Normal loading stage (default for most plugins)
- `kind:fpath` - Early loading stage (before compinit, for completions)
- `kind:defer` - Late loading stage (after compinit, for syntax highlighters)

## Full Configuration Example

Here's a complete `.zshrc` example using the new syntax:

```zsh
# Load Pulse framework
source ~/.local/share/pulse/pulse.zsh

# Define plugins with convenient syntax
plugins=(
  # Oh-My-Zsh plugins
  omz:plugins/git
  omz:plugins/docker
  omz:plugins/kubectl
  omz:plugins/helm
  omz:plugins/ansible
  
  # Oh-My-Zsh libraries
  omz:lib/git
  omz:lib/theme-and-appearance
  
  # Prezto modules
  prezto:modules/editor
  prezto:modules/history
  
  # Regular plugins with annotations
  zsh-users/zsh-completions kind:fpath
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting kind:defer
  
  # Framework plugins with path annotations
  sorin-ionescu/prezto path:modules/git
  
  # Custom framework loading
  your-org/your-framework path:modules/custom kind:path
)

# That's it! Pulse handles everything automatically
```

## Comparison with Other Plugin Managers

### Antidote Style

Pulse syntax is inspired by antidote's annotation style:

```zsh
# Antidote
ohmyzsh/ohmyzsh path:plugins/git
romkatv/zsh-bench kind:path
zsh-users/zsh-autosuggestions kind:defer

# Pulse (same syntax works!)
plugins=(
  ohmyzsh/ohmyzsh path:plugins/git
  romkatv/zsh-bench kind:path
  zsh-users/zsh-autosuggestions kind:defer
)
```

### Zinit Style

Pulse's shorthand is more concise than Zinit's `OMZP::` syntax:

```zsh
# Zinit
zinit snippet OMZP::git
zinit snippet OMZL::git.zsh

# Pulse (cleaner)
plugins=(
  omz:plugins/git
  omz:lib/git
)
```

## Benefits

1. **Less Repetition**: Use `omz:` instead of writing `ohmyzsh/ohmyzsh path:plugins/` every time
2. **Single Clone**: All Oh-My-Zsh plugins share one cloned repository
3. **Fast Loading**: Pulse's optimized loading pipeline ensures fast startup
4. **Clean Config**: Your `.zshrc` stays readable and maintainable
5. **Portable**: Same syntax works across different machines

## Migration from Oh-My-Zsh

If you're migrating from Oh-My-Zsh, simply convert your plugins:

```zsh
# Old Oh-My-Zsh style
plugins=(git docker kubectl)

# New Pulse style
plugins=(
  omz:plugins/git
  omz:plugins/docker
  omz:plugins/kubectl
)
```

That's it! No other changes needed.

## Troubleshooting

### Plugin Not Found

If you see "Plugin 'name' not found", make sure:
1. The plugin exists in the Oh-My-Zsh or Prezto repository
2. You're using the correct path (e.g., `omz:plugins/git` not `omz:plugin/git`)
3. Git is installed and accessible

### Slow Loading

If loading is slow:
1. Use `kind:defer` for syntax highlighters (they should load last)
2. Use `kind:fpath` for completion-only plugins (they should load early)
3. Check `PULSE_DEBUG=1` to see what's taking time

### Conflicts

If two plugins conflict:
1. Load them in different stages with `kind:` annotations
2. Check if they both try to define the same functions
3. Use `pulse_disabled_plugins` to temporarily disable one

## Related Documentation

- [CLI Reference](CLI_REFERENCE.md) - `pulse list`, `pulse update` commands
- [Performance Guide](PERFORMANCE.md) - Optimization tips
- [Plugin Development](plugin-development.md) - Creating your own plugins
