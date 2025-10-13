# Pulse Command Interface Contract

**Feature**: Intelligent Declarative Zsh Framework (Pulse)
**Date**: 2025-10-10
**Type**: Command-Line Interface Specification

## Overview

This document defines the command-line interface for Pulse. Since Pulse is a Zsh framework rather than a REST API, "contracts" refer to command signatures, expected behavior, exit codes, and output formats.

---

## Core Loading Interface

### pulse.zsh (Main Entry Point)

**Purpose**: Initialize Pulse framework and load plugins

**Usage**:

```zsh
source ~/.local/share/pulse/pulse.zsh
```

**Preconditions**:

- User has defined `plugins` array in `.zshrc`
- Zsh version 5.0 or later

**Behavior**:

1. Load core modules (lib/compinit.zsh, lib/keybinds.zsh, etc.)
2. Parse `plugins` array from user config
3. Detect plugin types and assign load stages
4. Execute load stages in order
5. Set up deferred loading for marked plugins

**Exit Codes**:

- N/A (sourced, doesn't exit)

**Output**:

- Silent on success (no output unless `PULSE_DEBUG=1`)
- Errors written to stderr with clear messages

**Performance Contract**:

- MUST complete in <50ms without plugins
- MUST complete in <500ms with 15 plugins (excluding deferred)

**Example**:

```zsh
# In ~/.zshrc
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)
source ~/.local/share/pulse/pulse.zsh
```

---

## Plugin Management Commands

### pulse update

**Purpose**: Update all installed plugins to latest versions

**Usage**:

```zsh
pulse update [plugin-name ...]
```

**Arguments**:

- `plugin-name` (optional): Specific plugin(s) to update. If omitted, updates all.

**Options**:

- `--parallel` : Update plugins concurrently (default: true)
- `--sequential` : Update plugins one at a time
- `--dry-run` : Show what would be updated without making changes

**Behavior**:

1. For each plugin:
   - Check for local modifications
   - Stash if necessary
   - Git pull latest changes
   - Pop stash if applicable
   - Report success/failure
2. If `--parallel`, use background jobs (max 5 concurrent)

**Exit Codes**:

- `0` : All updates successful
- `1` : One or more updates failed (non-fatal)
- `2` : Invalid arguments or configuration error

**Output**:

```
Updating plugins...
✓ zsh-users/zsh-autosuggestions (up to date)
↻ zsh-users/zsh-syntax-highlighting (updated: v0.7.1 → v0.8.0)
✗ broken/plugin (failed: repository not found)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Updated: 1  Up-to-date: 1  Failed: 1
```

**Error Handling**:

- Continue on failure (update remaining plugins)
- Detailed error messages for failures
- Suggest troubleshooting steps

---

### pulse install

**Purpose**: Install missing plugins without restarting shell

**Usage**:

```zsh
pulse install [plugin-name ...]
```

**Arguments**:

- `plugin-name` (optional): Specific plugin(s) to install. If omitted, installs all missing.

**Behavior**:

1. Parse plugin specifications
2. Clone missing repositories
3. Detect types and assign stages
4. Load newly installed plugins

**Exit Codes**:

- `0` : All plugins installed successfully
- `1` : One or more installations failed
- `2` : Invalid plugin specification

**Output**:

```
Installing plugins...
↓ zsh-users/zsh-autosuggestions (cloning...)
✓ zsh-users/zsh-autosuggestions (installed and loaded)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Installed: 1  Failed: 0
```

---

### pulse remove

**Purpose**: Remove installed plugins and clean up directories

**Usage**:

```zsh
pulse remove <plugin-name> [...]
```

**Arguments**:

- `plugin-name` (required): Plugin(s) to remove

**Options**:

- `--keep-config` : Remove files but keep in plugins array
- `--force` : Skip confirmation prompt

**Behavior**:

1. Confirm deletion (unless `--force`)
2. Unload plugin from current session
3. Delete plugin directory
4. Update cache

**Exit Codes**:

- `0` : Successfully removed
- `1` : Removal failed (permissions, not found, etc.)
- `2` : User cancelled at confirmation

**Output**:

```
Remove plugin 'zsh-users/zsh-autosuggestions'? [y/N]: y
✓ Unloaded zsh-autosuggestions
✓ Deleted ~/.local/share/pulse/plugins/zsh-autosuggestions
✓ Updated cache
```

---

### pulse list

**Purpose**: Show installed plugins and their status

**Usage**:

```zsh
pulse list [--format=<format>]
```

**Options**:

- `--format=table` : Table format (default)
- `--format=json` : JSON output for scripting
- `--format=simple` : Plain list (one per line)

**Exit Codes**:

- `0` : Always (informational command)

**Output (table format)**:

```
Plugin                            Status   Stage    Load Time
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
zsh-users/zsh-autosuggestions     loaded   normal   42ms
zsh-users/zsh-syntax-highlighting loaded   late     67ms
junegunn/fzf                      deferred deferred —
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 3 plugins  Loaded: 2  Deferred: 1
```

**Output (JSON format)**:

```json
{
  "plugins": [
    {
      "name": "zsh-autosuggestions",
      "source": "zsh-users/zsh-autosuggestions",
      "status": "loaded",
      "stage": "normal",
      "load_time_ms": 42,
      "path": "/home/user/.local/share/pulse/plugins/zsh-autosuggestions"
    },
    {
      "name": "zsh-syntax-highlighting",
      "source": "zsh-users/zsh-syntax-highlighting",
      "status": "loaded",
      "stage": "late",
      "load_time_ms": 67,
      "path": "/home/user/.local/share/pulse/plugins/zsh-syntax-highlighting"
    }
  ],
  "stats": {
    "total": 2,
    "loaded": 2,
    "deferred": 0,
    "errors": 0
  }
}
```

---

### pulse info

**Purpose**: Show detailed information about a specific plugin

**Usage**:

```zsh
pulse info <plugin-name>
```

**Arguments**:

- `plugin-name` (required): Plugin to inspect

**Exit Codes**:

- `0` : Plugin found, info displayed
- `1` : Plugin not found

**Output**:

```
Plugin: zsh-users/zsh-autosuggestions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status:      loaded
Type:        standard
Stage:       normal
Load Time:   42ms
Path:        ~/.local/share/pulse/plugins/zsh-autosuggestions
URL:         https://github.com/zsh-users/zsh-autosuggestions.git
Version:     v0.7.0 (git: a411ef3)
Last Update: 2025-09-15 14:32:11

Description:
  Fish-like fast/unobtrusive autosuggestions for zsh.

Files:
  zsh-autosuggestions.zsh
  zsh-autosuggestions.plugin.zsh
  src/ (18 files)
```

---

## Diagnostic Commands

### pulse doctor

**Purpose**: Diagnose common problems and verify configuration

**Usage**:

```zsh
pulse doctor
```

**Behavior**:

1. Check Zsh version compatibility
2. Verify directory permissions
3. Test Git availability
4. Validate plugin specifications
5. Check for common misconfigurations
6. Report potential issues

**Exit Codes**:

- `0` : No issues found
- `1` : Issues detected (non-fatal)
- `2` : Critical issues (Pulse may not work)

**Output**:

```
Pulse Diagnostics
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Zsh version: 5.9 (compatible)
✓ Git available: 2.40.0
✓ Pulse directory: ~/.local/share/pulse (writable)
✓ Cache directory: ~/.cache/pulse (writable)
✓ Plugin specifications: 5 valid
⚠ Warning: Plugin 'old/abandoned' hasn't been updated in 3 years
⚠ Warning: Syntax highlighting not loaded last (may not work)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status: OK (2 warnings)

Recommendations:
  • Move 'zsh-syntax-highlighting' to end of plugins array
  • Consider removing 'old/abandoned' (unmaintained)
```

---

### pulse benchmark

**Purpose**: Measure shell startup performance

**Usage**:

```zsh
pulse benchmark [--iterations=<n>]
```

**Options**:

- `--iterations=<n>` : Number of test runs (default: 10)

**Behavior**:

1. Launch new Zsh shells multiple times
2. Measure startup time for each iteration
3. Calculate statistics (min, max, avg, median)
4. Compare with/without Pulse overhead
5. Break down time by load stage

**Exit Codes**:

- `0` : Always (informational)

**Output**:

```
Pulse Startup Benchmark (10 iterations)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Baseline (no plugins):     245ms ± 12ms
With Pulse (15 plugins):   487ms ± 23ms
Pulse overhead:            42ms

Breakdown by stage:
  Early:     18ms (0 plugins)
  Compinit:  89ms
  Normal:    285ms (14 plugins, avg 20ms each)
  Late:      53ms (1 plugin)

Performance: ✓ Within target (<500ms)
```

---

## Cache Management Commands

### pulse cache clear

**Purpose**: Clear cached plugin metadata

**Usage**:

```zsh
pulse cache clear [--all]
```

**Options**:

- `--all` : Clear cache and debug logs

**Behavior**:

1. Delete cache files
2. Optionally delete debug logs
3. Next shell start will rebuild cache

**Exit Codes**:

- `0` : Cache cleared successfully

**Output**:

```
✓ Cleared plugin metadata cache
✓ Cleared debug logs
Next shell startup will rebuild cache.
```

---

## Configuration Validation

### pulse validate

**Purpose**: Check configuration syntax without loading plugins

**Usage**:

```zsh
pulse validate [config-file]
```

**Arguments**:

- `config-file` (optional): Path to .zshrc to validate (default: `~/.zshrc`)

**Behavior**:

1. Parse configuration file
2. Validate plugin specifications
3. Check for syntax errors
4. Warn about potential issues
5. Don't load plugins

**Exit Codes**:

- `0` : Configuration valid
- `1` : Warnings (config will work but may have issues)
- `2` : Errors (config will fail)

**Output**:

```
Validating ~/.zshrc
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Syntax: valid Zsh
✓ Plugins array: defined (5 plugins)
✓ Plugin specifications: all valid
⚠ Line 42: 'pulse_plugin_stage[foo]' set but plugin 'foo' not in plugins array
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status: Valid (1 warning)
```

---

## Environment Variables

### PULSE_DEBUG

**Type**: Boolean (0 or 1)
**Default**: 0
**Purpose**: Enable verbose debug logging

**Usage**:

```zsh
export PULSE_DEBUG=1
source ~/.local/share/pulse/pulse.zsh
```

**Effect**:

- Detailed log messages to stderr
- Write debug log to `~/.cache/pulse/debug.log`
- Show timing for each operation
- Display plugin detection logic

---

### PULSE_DIR

**Type**: Path
**Default**: `$XDG_DATA_HOME/pulse` or `~/.local/share/pulse`
**Purpose**: Override Pulse data directory

**Usage**:

```zsh
export PULSE_DIR=~/.config/pulse
```

---

### PULSE_CACHE_DIR

**Type**: Path
**Default**: `$XDG_CACHE_HOME/pulse` or `~/.cache/pulse`
**Purpose**: Override cache directory

---

### PULSE_NO_COMPINIT

**Type**: Boolean (0 or 1)
**Default**: 0
**Purpose**: Skip automatic compinit (user will call manually)

**Usage**:

```zsh
export PULSE_NO_COMPINIT=1
```

**Use Case**: User wants full control over compinit timing

---

## Global Arrays and Associative Arrays

### plugins

**Type**: Indexed array
**Scope**: User configuration
**Purpose**: Declare plugins to load

**Example**:

```zsh
plugins=(
  zsh-users/zsh-autosuggestions
  https://gitlab.com/user/plugin.git
  /path/to/local/plugin
)
```

---

### pulse_disabled_plugins

**Type**: Indexed array
**Scope**: User configuration
**Purpose**: Temporarily disable plugins without removing from config

**Example**:

```zsh
pulse_disabled_plugins=(broken-plugin experimental-plugin)
```

---

### pulse_plugin_stage

**Type**: Associative array
**Scope**: User configuration (optional overrides)
**Purpose**: Manually set load stage for specific plugins

**Example**:

```zsh
pulse_plugin_stage[my-plugin]="late"
```

---

## Function Contracts

These are internal functions, documented for advanced users and contributors.

### pulse_load_plugin

**Signature**: `pulse_load_plugin <plugin-name>`
**Purpose**: Load a single plugin immediately
**Returns**: 0 on success, 1 on failure

### pulse_detect_plugin_type

**Signature**: `pulse_detect_plugin_type <plugin-path>`
**Purpose**: Analyze plugin and return type
**Returns**: Echoes type string (completion, syntax, standard, etc.)

### pulse_defer_plugin

**Signature**: `pulse_defer_plugin <plugin-name> <command> [command ...]`
**Purpose**: Set up lazy loading for a plugin triggered by commands
**Returns**: 0 always (sets up wrappers)

---

## Error Message Format

All error messages follow this format:

```
[Pulse <LEVEL>] <Summary>
<Details>
<Action>
<Debug hint>
```

**Example**:

```
[Pulse ERROR] Failed to clone plugin 'user/nonexistent'
Git returned: repository not found (404)
Action: Check plugin name or URL
Debug: Run 'pulse doctor' for more diagnostics
```

**Levels**: ERROR, WARN, INFO, DEBUG

---

## Contract Guarantees

1. **Backward Compatibility**: Commands won't break between minor versions
2. **Exit Codes**: Always consistent with documented values
3. **Output Format**: JSON format stable, table format may improve aesthetically
4. **Performance**: Commands meet performance targets (e.g., <500ms startup)
5. **No Surprises**: Silent on success, informative on failure
6. **Graceful Degradation**: One broken plugin doesn't break all plugins

---

## Summary

Pulse provides a rich CLI for plugin management while maintaining simplicity in the common case (just source pulse.zsh). Advanced commands are available but optional. All commands follow Unix conventions: silent on success, informative on failure, consistent exit codes, and machine-readable output options.
