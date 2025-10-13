# Data Model: Pulse Framework

**Feature**: Intelligent Declarative Zsh Framework (Pulse)
**Date**: 2025-10-10
**Phase**: 1 (Design)

## Overview

This document defines the data structures and relationships used in the Pulse framework. Since Pulse is a shell framework, "data model" refers to the internal state management, configuration structures, and plugin metadata rather than persistent database entities.

---

## Core Entities

### 1. Plugin

Represents a Zsh plugin managed by Pulse.

**Attributes**:

- `name` (string): Short name of the plugin (e.g., "zsh-autosuggestions")
- `source` (string): Original specification from user config (e.g., "zsh-users/zsh-autosuggestions")
- `url` (string): Full Git URL for cloning
- `path` (string): Local filesystem path to plugin directory
- `type` (enum): Classification of plugin
  - Values: `completion`, `syntax`, `theme`, `standard`, `deferred`
- `stage` (enum): When plugin should be loaded
  - Values: `early`, `compinit`, `normal`, `late`, `deferred`
- `enabled` (boolean): Whether plugin is active
- `load_time` (integer): Milliseconds taken to source plugin (for performance tracking)
- `status` (enum): Current state
  - Values: `installed`, `missing`, `error`, `loading`, `loaded`
- `error_message` (string, optional): If status is error, contains diagnostic message

**Relationships**:

- Plugins are independent; relationships are implicit through load stages
- Deferred plugins may have command triggers (see DeferredTrigger)

**Storage**:

- User config: Array in `.zshrc` (e.g., `plugins=(user/repo ...)`)
- Runtime: Associative arrays in Zsh
  - `pulse_plugins[name]=path`
  - `pulse_plugin_types[name]=type`
  - `pulse_plugin_stages[name]=stage`
  - `pulse_plugin_status[name]=status`

---

### 2. Configuration State

Represents the desired state of the shell as declared by the user.

**Attributes**:

- `plugins` (array): List of plugin specifications
- `disabled_plugins` (array, optional): Plugins to skip
- `plugin_stage_overrides` (associative array, optional): Manual stage assignments
  - Format: `pulse_plugin_stage[plugin-name]=stage`
- `pulse_dir` (string): Base directory for Pulse data (default: `$XDG_DATA_HOME/pulse`)
- `cache_dir` (string): Cache directory (default: `$XDG_CACHE_HOME/pulse`)
- `debug_mode` (boolean): Enable verbose logging (default: false)
- `parallel_updates` (boolean): Update plugins concurrently (default: true)
- `startup_time_budget` (integer, optional): Maximum allowed startup time in ms

**Storage**:

- Declared in user's `.zshrc`
- Loaded into environment variables and Zsh arrays

**Example**:

```zsh
# In .zshrc
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)

# Optional overrides
pulse_plugin_stage[my-custom-plugin]="late"
pulse_disabled_plugins=(unwanted-plugin)
export PULSE_DEBUG=1
```

---

### 3. Load Stage

Defines a phase in the shell initialization process.

**Attributes**:

- `name` (enum): Stage identifier
  - Values: `early`, `compinit`, `normal`, `late`, `deferred`
- `order` (integer): Execution sequence (1-5)
- `description` (string): Human-readable explanation
- `execution_time` (integer): Cumulative time spent in stage (for performance tracking)

**Behavior Rules**:

| Stage | Purpose | When Executed | Example Plugins |
|-------|---------|---------------|-----------------|
| `early` | Add to fpath before compinit | Before completion initialization | Completion plugins, path modifiers |
| `compinit` | Run Zsh completion system | After early, before normal | (System function, not a plugin) |
| `normal` | Standard plugin loading | After compinit | Most plugins, utilities, aliases |
| `late` | Override previous settings | After normal plugins | Syntax highlighting, themes |
| `deferred` | Lazy load on first use | On command invocation | Heavy plugins (nvm, fzf, rbenv) |

**Relationships**:

- Each Plugin is assigned to exactly one stage
- Stages execute in strict order (early → compinit → normal → late)
- Deferred stage is asynchronous (loads on-demand)

---

### 4. Deferred Trigger

Maps commands to deferred plugins that should load when those commands are first invoked.

**Attributes**:

- `command` (string): Command name that triggers loading
- `plugin_name` (string): Plugin to load when command is invoked
- `wrapper_function` (string): Temporary function definition that loads plugin

**Behavior**:

1. When plugin is marked as deferred, identify triggering commands
2. Create wrapper functions for those commands
3. On first invocation, wrapper loads plugin and removes itself
4. Original command executes normally

**Example**:

```zsh
# For deferred nvm plugin
pulse_deferred_triggers[nvm]="nvm-plugin"
pulse_deferred_triggers[npm]="nvm-plugin"
pulse_deferred_triggers[node]="nvm-plugin"

# Wrapper function (created automatically)
nvm() {
  unfunction nvm npm node  # Remove all wrappers
  pulse_load_plugin "nvm-plugin"  # Load actual plugin
  nvm "$@"  # Execute original command
}
```

---

### 5. Plugin Cache

Metadata cache to avoid repeated filesystem analysis.

**Attributes**:

- `plugin_name` (string): Plugin identifier
- `plugin_type` (enum): Detected type (completion, syntax, etc.)
- `plugin_stage` (enum): Determined load stage
- `cache_timestamp` (integer): Unix timestamp of last update
- `file_hash` (string): Hash of plugin directory for change detection

**Storage**:

- File: `$XDG_CACHE_HOME/pulse/plugin-cache.zsh`
- Format: Zsh associative array declarations

**Example**:

```zsh
# In cache file
typeset -gA pulse_cache_types
typeset -gA pulse_cache_stages
typeset -gA pulse_cache_timestamps

pulse_cache_types[zsh-autosuggestions]="standard"
pulse_cache_stages[zsh-autosuggestions]="normal"
pulse_cache_timestamps[zsh-autosuggestions]=1696896000
```

**Invalidation**:

- Cache invalidated if:
  - Plugin directory modified (compare hash)
  - Cache older than 7 days
  - User runs `pulse cache clear` command

---

### 6. Debug Log Entry

Records events for troubleshooting when debug mode is enabled.

**Attributes**:

- `timestamp` (string): ISO 8601 timestamp
- `level` (enum): Severity
  - Values: `DEBUG`, `INFO`, `WARN`, `ERROR`
- `component` (string): Which part of Pulse generated the log
  - Values: `loader`, `detection`, `git`, `cache`, `deferred`
- `message` (string): Log message
- `plugin_name` (string, optional): Associated plugin if applicable
- `duration_ms` (integer, optional): Operation duration if applicable

**Storage**:

- File: `$XDG_CACHE_HOME/pulse/debug.log` (when `PULSE_DEBUG=1`)
- Format: Plaintext, one entry per line

**Example**:

```
2025-10-10T14:23:45Z INFO  loader   Pulse initialization started
2025-10-10T14:23:45Z DEBUG detection Analyzing plugin: zsh-autosuggestions
2025-10-10T14:23:45Z DEBUG detection Detected type: standard, stage: normal
2025-10-10T14:23:45Z INFO  loader   Loading stage: early (0 plugins)
2025-10-10T14:23:45Z INFO  loader   Running compinit
2025-10-10T14:23:45Z INFO  loader   Loading stage: normal (5 plugins)
2025-10-10T14:23:46Z DEBUG loader   Loaded zsh-autosuggestions in 45ms
2025-10-10T14:23:46Z ERROR loader   Failed to load broken-plugin: syntax error on line 23
2025-10-10T14:23:46Z INFO  loader   Pulse initialization complete (723ms total)
```

---

## State Transitions

### Plugin Lifecycle

```
[User Config] → (parse) → [missing]
                            ↓
                         (clone)
                            ↓
                       [installed]
                            ↓
                      (load/defer)
                       ↙         ↘
                [deferred]    [loading]
                     ↓             ↓
               (on-demand)    (source)
                     ↓             ↓
                [loading] →  [loaded] or [error]
```

### Stage Execution Flow

```
Shell Start
    ↓
Parse Config (plugins array)
    ↓
Detect Plugin Types (cached or analyze)
    ↓
Assign Load Stages
    ↓
[Early Stage] → Load completion plugins, modify fpath
    ↓
[Compinit] → Run once if needed
    ↓
[Normal Stage] → Load standard plugins
    ↓
[Late Stage] → Load syntax highlighting, themes
    ↓
[Deferred Stage] → Set up command wrappers
    ↓
Shell Ready
```

---

## Validation Rules

### Plugin Specification

- MUST be non-empty string
- MUST match one of:
  - GitHub short format: `owner/repo`
  - Full URL: `https?://...`
  - Local path: `/absolute/path`
- MUST NOT contain shell metacharacters (`;`, `|`, `&`, etc.)

### Load Stage Override

- Stage name MUST be one of: `early`, `normal`, `late`, `deferred`
- Override only applies to user-specified plugins (not built-in modules)

### Plugin Directory

- MUST contain at least one `.zsh` file or `.plugin.zsh` file
- MUST be readable and executable
- MAY contain subdirectories: `completions/`, `functions/`, `themes/`

---

## Performance Considerations

### Memory Usage

- Associative arrays are memory-efficient for plugin metadata
- Cache file keeps memory footprint low (lazy load only needed data)
- Deferred plugins not loaded until needed → lower baseline memory

### Access Patterns

- Plugin lookup: O(1) via associative arrays
- Stage execution: O(n) where n = plugins in stage (sequential loading)
- Cache read: O(1) per plugin (hash table lookup)

### Scaling

- Tested with 50+ plugins
- Linear growth in startup time (each plugin ~50-100ms)
- Parallel Git operations for updates (concurrent, not sequential)

---

## Summary

The Pulse data model is intentionally simple, using native Zsh data structures (arrays, associative arrays, environment variables) to represent plugins, configuration, and state. This keeps the framework lightweight, fast, and easy to debug. The cache layer optimizes repeated operations, while the deferred loading mechanism ensures minimal startup impact for heavy plugins.
