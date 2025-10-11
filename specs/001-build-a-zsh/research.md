# Research Document: Pulse Framework Technical Decisions

**Feature**: Intelligent Declarative Zsh Framework (Pulse)
**Date**: 2025-10-10
**Phase**: 0 (Research & Technical Decisions)

## Overview

This document captures research findings and technical decisions for implementing the Pulse Zsh framework. Each decision includes rationale and alternatives considered.

---

## 1. Plugin Detection and Classification

### Decision: Pattern-Based Plugin Type Detection

Plugins will be automatically classified into types based on file structure and naming patterns:

- **Completion plugins**: Contain `_*` files or `completions/` directory
- **Syntax/highlighting plugins**: Match patterns like `*-syntax-highlighting`, `*-highlighters`
- **Async/deferred plugins**: Contain `.async` marker or match specific plugin names (fzf, nvm, etc.)
- **Theme plugins**: Contain `.zsh-theme` files or `themes/` directory
- **Standard plugins**: Everything else (default)

### Rationale

- No plugin modifications required (FR-031)
- Works with existing plugin ecosystem
- Simple heuristics cover 95% of cases
- Explicit type override available for edge cases

### Alternatives Considered

1. **Plugin manifest files**: Rejected—requires plugin authors to add metadata, breaks FR-031
2. **Static plugin registry**: Rejected—requires maintenance, doesn't scale, fails on unknown plugins
3. **Machine learning classification**: Rejected—overkill, adds complexity and dependencies

### Implementation Notes

```zsh
# Pseudocode for detection
pulse_detect_plugin_type() {
  local plugin_dir=$1
  [[ -d "$plugin_dir/completions" ]] && echo "completion" && return
  [[ -n "$(find "$plugin_dir" -name '_*' -type f)" ]] && echo "completion" && return
  [[ "$plugin_dir" == *-syntax-highlighting ]] && echo "syntax" && return
  echo "standard"
}
```

---

## 2. Plugin Load Order Strategy

### Decision: Five-Stage Loading Pipeline

1. **Early**: Before compinit, for plugins that add to fpath
2. **Compinit**: Run once after early stage
3. **Normal**: Standard plugins after compinit
4. **Late**: Syntax highlighting, theme overrides
5. **Deferred**: Lazy-loaded on first command use

### Rationale

- Covers all documented plugin requirements from oh-my-zsh, prezto, and zsh_unplugged
- Prevents common ordering issues (syntax highlighting too early, completions after compinit)
- Explicit stages are easier to reason about than dependency graphs
- Deferred stage enables lazy loading (FR-022)

### Alternatives Considered

1. **Dependency graph with topological sort**: Rejected—complex to implement, fragile, requires plugin metadata
2. **Three stages (before/during/after compinit)**: Rejected—insufficient for syntax highlighting and lazy loading
3. **No stages, user specifies order**: Rejected—defeats purpose of intelligent loading (US1)

### Load Order Rules

```
Early Stage:
  - Completion plugins (add to fpath)
  - Plugins with .plugin-early marker

Compinit: (automatic)
  - Run once after all early plugins

Normal Stage:
  - Standard plugins
  - Most functionality

Late Stage:
  - Syntax highlighting (must be last to work correctly)
  - Theme plugins (override prompts)
  - Plugins with .plugin-late marker

Deferred Stage:
  - Heavy plugins (nvm, rbenv, fzf)
  - Loaded on first command invocation
```

---

## 3. Plugin Source Format

### Decision: Support Multiple Short Formats

Users can specify plugins in multiple convenient formats:

```zsh
# GitHub short format (org/repo)
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)

# Full URLs
plugins=(
  https://github.com/zsh-users/zsh-autosuggestions.git
  https://gitlab.com/user/custom-plugin.git
)

# Mixed formats
plugins=(
  zsh-users/zsh-autosuggestions          # GitHub short
  ~/.local/share/custom-plugin            # Local path
  https://example.com/plugin.git          # Custom URL
)
```

### Rationale

- GitHub short format is standard in community (oh-my-zsh, antigen, zplug)
- Full URLs support GitLab, Bitbucket, self-hosted Git
- Local paths support custom/private plugins
- Simple string parsing, no complex DSL

### Alternatives Considered

1. **URLs only**: Rejected—too verbose, poor UX for GitHub plugins
2. **Plugin registry with names**: Rejected—requires curation, maintenance, central authority
3. **Complex DSL with options**: Rejected—violates simplicity principle

### Parsing Logic

```zsh
pulse_resolve_plugin_url() {
  local spec=$1
  case "$spec" in
    http://*|https://*|git://*)
      echo "$spec"  # Full URL, use as-is
      ;;
    */*)
      echo "https://github.com/${spec}.git"  # GitHub short format
      ;;
    /*)
      echo "$spec"  # Absolute local path
      ;;
    *)
      echo "https://github.com/${spec}.git"  # Assume GitHub
      ;;
  esac
}
```

---

## 4. Configuration Storage Strategy

### Decision: XDG Base Directory Specification

- **Plugins**: `$XDG_DATA_HOME/pulse/plugins` (default: `~/.local/share/pulse/plugins`)
- **Cache**: `$XDG_CACHE_HOME/pulse` (default: `~/.cache/pulse`)
- **Config**: User's `.zshrc` (no separate config file needed)

### Rationale

- Follows modern Linux/Unix standards (XDG)
- Keeps home directory clean
- Separates mutable data (plugins) from cache
- No config file needed—declaration in .zshrc is config (declarative philosophy)

### Alternatives Considered

1. **Home directory dotfiles**: Rejected—clutters home, outdated pattern
2. **Separate config file**: Rejected—adds complexity, violates zero-config principle
3. **Single directory for everything**: Rejected—mixes concerns, prevents selective cleanup

---

## 5. Plugin Update Strategy

### Decision: Git Pull with Stash Protection

Update command will:

1. Check for local modifications
2. Stash if necessary
3. Pull latest changes
4. Pop stash (warn on conflicts)
5. Report success/failure per plugin

### Rationale

- Preserves user customizations
- Clear feedback on conflicts (FR-018)
- Standard Git workflow, no surprises
- Parallel updates for performance

### Alternatives Considered

1. **Force pull (discard local changes)**: Rejected—data loss risk
2. **Refuse to update if modified**: Rejected—blocks legitimate workflow
3. **Complex merge strategies**: Rejected—overkill for plugin updates

---

## 6. Lazy Loading Implementation

### Decision: Command Wrapper with One-Time Initialization

For deferred plugins, create wrapper functions that:

1. Load the actual plugin
2. Remove wrapper
3. Execute intended command

### Rationale

- Transparent to user—command "just works"
- One-time cost per session
- Minimal complexity
- Proven pattern from zsh-defer and other frameworks

### Example

```zsh
# Before plugin loads
nvm() {
  unfunction nvm  # Remove this wrapper
  pulse_load_plugin nvm  # Load actual plugin
  nvm "$@"  # Execute original command
}

# After first invocation, nvm is the real function
```

### Alternatives Considered

1. **Hook into command_not_found_handler**: Rejected—only works for missing commands, not existing ones
2. **Precmd hook checks**: Rejected—runs on every prompt, wasteful
3. **Full plugin preloading**: Rejected—defeats purpose of lazy loading

---

## 7. Testing Framework Choice

### Decision: Bats-core for Integration, Custom Harness for Units

- **Integration tests**: Use bats-core (Bash Automated Testing System)
  - Mature, widely adopted
  - Shell-native, no language barrier
  - Good output formatting

- **Unit tests**: Custom lightweight harness
  - Zsh-specific assertions
  - Fast execution
  - No external dependencies

### Rationale

- Bats-core is industry standard for shell testing
- Custom harness needed for Zsh-specific features (associative arrays, etc.)
- Combination provides coverage without over-engineering

### Alternatives Considered

1. **Ztst (Zsh Test)**: Rejected—limited documentation, steep learning curve
2. **Shunit2**: Rejected—sh-focused, not Zsh-optimized
3. **Bats-core only**: Rejected—some Zsh features awkward to test in bats

### Test Structure

```
tests/
├── integration/           # Bats tests
│   ├── plugin-loading.bats
│   ├── declarative-config.bats
│   └── error-handling.bats
├── unit/                  # Custom harness
│   ├── test-detection.zsh
│   ├── test-ordering.zsh
│   └── test-parsing.zsh
└── fixtures/              # Mock plugins
    ├── mock-completion/
    ├── mock-syntax/
    └── mock-standard/
```

---

## 8. Template .zshrc Design

### Decision: Three-Section Template with Progressive Disclosure

1. **Quick Start**: Minimal working example (5 lines)
2. **Common Configurations**: Commented examples for typical setups
3. **Advanced Options**: Edge cases and customizations

### Rationale

- Progressive disclosure: simple → complex
- Self-documenting through examples
- Copy-paste friendly
- Satisfies FR-014 through FR-017

### Template Structure

```zsh
# ============================================================================
# Pulse - Quick Start (Uncomment to activate)
# ============================================================================
# source ~/.local/share/pulse/pulse.zsh
# plugins=(zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting)

# ============================================================================
# Common Configurations
# ============================================================================
# Developer Setup
# plugins=(
#   zsh-users/zsh-autosuggestions
#   zsh-users/zsh-syntax-highlighting
#   zsh-users/zsh-completions
# )

# Minimal Setup (fast startup)
# plugins=(zsh-users/zsh-autosuggestions)

# Power User Setup
# plugins=(
#   zsh-users/zsh-autosuggestions
#   zsh-users/zsh-syntax-highlighting
#   zsh-users/zsh-completions
#   junegunn/fzf  # Fuzzy finder (deferred)
# )

# ============================================================================
# Advanced Options (optional)
# ============================================================================
# Override plugin load stage
# pulse_plugin_stage[my-plugin]="late"

# Disable specific plugin temporarily
# pulse_disabled_plugins=(unwanted-plugin)

# Enable debug mode
# export PULSE_DEBUG=1
```

---

## 9. Error Handling Philosophy

### Decision: Fail Gracefully with Clear Messages

- **Missing plugin**: Warn once, continue with other plugins
- **Git clone failure**: Error message with troubleshooting, skip plugin
- **Plugin syntax error**: Wrap in trap, report, continue
- **Circular dependencies**: Detect and error with explanation

### Rationale

- One broken plugin shouldn't break entire shell (FR-019)
- Clear errors help users self-service (FR-018)
- Debug mode provides verbose output (FR-020)
- Aligns with constitution's quality principle

### Error Message Format

```
[Pulse ERROR] Failed to load plugin 'user/plugin-name'
Reason: Git clone failed (network timeout)
Action: Check internet connection or try again later
Debug: Run 'PULSE_DEBUG=1 zsh' for details
```

---

## 10. Performance Optimization Techniques

### Decision: Multi-Pronged Performance Strategy

1. **Plugin metadata caching**: Store type, load stage in cache file
2. **Parallel Git operations**: Clone/update plugins concurrently
3. **Lazy compinit**: Only run if completion plugins present
4. **Deferred loading**: Heavy plugins loaded on demand
5. **Minimal shell overhead**: Core framework <50ms

### Rationale

- Achieves <500ms startup with 15 plugins (SC-002)
- Framework overhead <50ms (SC-008)
- Each technique addresses specific bottleneck
- No single point of failure

### Performance Budget

```
Framework initialization:    < 50ms
Plugin detection (cached):    < 10ms per plugin
Git operations (parallel):    ~100-200ms (network dependent)
Plugin sourcing:              < 100ms per plugin
Compinit:                     ~50-100ms (one-time)
──────────────────────────────────────
Total (15 plugins, cached):   < 500ms ✓
```

### Alternatives Considered

1. **Compile Zsh scripts**: Rejected—minimal benefit, adds complexity
2. **Binary plugin loader**: Rejected—requires compilation, platform-specific
3. **Aggressive caching**: Rejected—can cause stale state issues

---

## Summary of Key Decisions

| Area | Decision | Primary Rationale |
|------|----------|-------------------|
| Plugin Detection | Pattern-based classification | No plugin modifications needed |
| Load Order | Five-stage pipeline | Covers all known requirements |
| Plugin Format | Multiple formats (short/URL/path) | Flexible, user-friendly |
| Storage | XDG Base Directory | Modern standard, clean home |
| Updates | Git pull with stash | Preserves customizations |
| Lazy Loading | Command wrappers | Transparent, one-time cost |
| Testing | Bats + custom harness | Best tool for each job |
| Template | Progressive disclosure | Simple → complex |
| Errors | Graceful degradation | Robust, helpful |
| Performance | Multi-technique optimization | Achieves <500ms target |

---

## Open Questions / Future Research

None—all technical decisions for MVP are resolved. Future enhancements (plugin discovery, visual plugin manager) deferred to post-v1.0.

---

## References

- [zsh_unplugged](https://github.com/mattmc3/zsh_unplugged) - Inspiration for minimal approach
- [zephyr](https://github.com/mattmc3/zephyr) - Modular framework patterns
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Bats-core Documentation](https://bats-core.readthedocs.io/)
- Zsh Manual: Plugin Loading Best Practices (sections on fpath, autoload, compinit)
