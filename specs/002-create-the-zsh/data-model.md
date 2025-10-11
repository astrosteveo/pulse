# Data Model: Core Zsh Framework Modules

**Feature**: 002-create-the-zsh
**Date**: 2025-10-11
**Purpose**: Define data structures and state for framework modules

## Overview

This feature primarily deals with shell configuration and state rather than persistent data storage. The "entities" here are Zsh configuration constructs (options, styles, bindings) and runtime state (loaded modules, cache files).

## Core Entities

### Framework Module

**Description**: A loadable Zsh script that configures one aspect of the shell environment

**Attributes**:

- `name`: String - Module identifier (e.g., "compinit", "keybinds")
- `file_path`: String - Absolute path to module file (e.g., "$PULSE_DIR/lib/compinit.zsh")
- `load_order`: Integer - Position in loading sequence (1-7)
- `status`: Enum - "not_loaded", "loading", "loaded", "failed", "disabled"
- `load_time`: Integer - Time to load in milliseconds
- `enabled`: Boolean - Whether module should be loaded

**Relationships**:

- Module can depend on other modules being loaded first (implicit via load_order)
- Module contributes to overall Shell Configuration

**State Transitions**:

```
not_loaded → loading → loaded (success)
not_loaded → loading → failed (error)
not_loaded → disabled (user configuration)
```

**Validation**:

- Name must match filename (compinit.zsh → compinit)
- File must exist and be readable
- Load order must be unique (1-7)
- Failed modules don't block others from loading

---

### Completion Style

**Description**: A zstyle configuration that controls completion behavior and appearance

**Attributes**:

- `pattern`: String - Match pattern (e.g., ':completion:*', ':completion:*:descriptions')
- `style_name`: String - Style identifier (e.g., 'menu', 'matcher-list', 'format')
- `value`: Mixed - Style value (can be string, array, or boolean depending on style)
- `precedence`: Integer - Order styles are applied (lower = higher precedence)

**Relationships**:

- Multiple styles can match same pattern
- Styles are evaluated in precedence order
- User styles override framework styles (set after loading)

**Examples**:

```zsh
# Pattern: ':completion:*', style: 'menu', value: 'select'
zstyle ':completion:*' menu select

# Pattern: ':completion:*', style: 'matcher-list', value: array
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Pattern: ':completion:*:descriptions', style: 'format', value: '%B%d%b'
zstyle ':completion:*:descriptions' format '%B%d%b'
```

**Validation**:

- Pattern must be valid zstyle pattern
- Style name must be recognized by completion system
- Value must match expected type for style

---

### Keybinding

**Description**: A mapping from key sequence to Zsh widget or command

**Attributes**:

- `key_sequence`: String - Key code or combination (e.g., '^R', '^[[A', '\e.')
- `widget`: String - Zsh widget name (e.g., 'history-incremental-search-backward')
- `keymap`: Enum - 'emacs', 'viins', 'vicmd', 'both'
- `priority`: Integer - Override priority (user bindings > plugin bindings > framework bindings)

**Relationships**:

- Multiple bindings can exist for same key in different keymaps
- Later bindings override earlier ones for same key in same keymap
- User bindings (set after Pulse) override framework bindings

**Examples**:

```zsh
# Key: Ctrl+R, Widget: history search, Keymap: both
bindkey '^R' history-incremental-search-backward

# Key: Up Arrow, Widget: history navigation, Keymap: both
bindkey '^[[A' up-line-or-history

# Key: Alt+., Widget: insert last arg, Keymap: emacs
bindkey '\e.' insert-last-word
```

**Validation**:

- Key sequence must be valid Zsh key code
- Widget must exist (built-in or loaded)
- Keymap must be valid Zsh keymap name

---

### Shell Option

**Description**: A Zsh configuration setting that affects shell behavior

**Attributes**:

- `name`: String - Option name in uppercase (e.g., 'EXTENDED_HISTORY', 'AUTO_CD')
- `value`: Boolean - Enabled (setopt) or disabled (unsetopt)
- `category`: Enum - 'history', 'directory', 'completion', 'globbing', 'correction', 'job_control'
- `set_by`: Enum - 'framework', 'plugin', 'user'

**Relationships**:

- Options are global to shell session
- Later setopt/unsetopt overrides earlier ones
- User options (set after Pulse) override framework options

**Examples**:

```zsh
# History options
setopt EXTENDED_HISTORY          # name='EXTENDED_HISTORY', value=true, category='history'
setopt HIST_IGNORE_ALL_DUPS      # name='HIST_IGNORE_ALL_DUPS', value=true, category='history'

# Directory options
setopt AUTO_CD                   # name='AUTO_CD', value=true, category='directory'
setopt AUTO_PUSHD                # name='AUTO_PUSHD', value=true, category='directory'

# Glob options
setopt EXTENDED_GLOB             # name='EXTENDED_GLOB', value=true, category='globbing'
```

**Validation**:

- Name must be valid Zsh option
- Option must be available in current Zsh version
- Some options are mutually exclusive

---

### Environment Variable

**Description**: A system-wide variable that affects external program behavior

**Attributes**:

- `name`: String - Variable name (e.g., 'EDITOR', 'PAGER', 'LS_COLORS')
- `value`: String - Variable value
- `set_by`: Enum - 'system', 'framework', 'user'
- `priority`: Integer - Override priority (user > framework > system)
- `exported`: Boolean - Whether variable is exported to child processes

**Relationships**:

- Variables are inherited by child processes (if exported)
- User variables (set before Pulse or after) override framework variables
- Framework only sets if not already set

**Examples**:

```zsh
# EDITOR (if not set)
export EDITOR='vim'              # name='EDITOR', value='vim', set_by='framework', exported=true

# PAGER (if not set)
export PAGER='less'              # name='PAGER', value='less', set_by='framework', exported=true

# History configuration
export HISTFILE="$HOME/.local/share/zsh/history"  # name='HISTFILE', value='...', exported=true
export HISTSIZE=10000
export SAVEHIST=10000
```

**Validation**:

- Name must be valid variable name (alphanumeric + underscore)
- Value should be appropriate for variable type
- Check if already set before setting (preserve user values)

---

### Cache File

**Description**: A file that stores computed data to improve startup performance

**Attributes**:

- `file_path`: String - Absolute path to cache file
- `type`: Enum - 'zcompdump' (completion definitions), 'future cache types'
- `last_modified`: Timestamp - When file was last updated
- `size_bytes`: Integer - File size
- `valid`: Boolean - Whether cache is still valid

**Relationships**:

- Cache files are stored in $PULSE_CACHE_DIR
- compinit module creates/uses zcompdump
- Cache validity is checked on startup

**Examples**:

```zsh
# Completion cache
# file_path="$HOME/.cache/pulse/zcompdump"
# type='zcompdump'
# last_modified=1697040000 (timestamp)
# size_bytes=124567
# valid=true (if <24 hours old)
```

**Validation**:

- File path must be writable
- File must be valid Zsh zcompdump format
- Regenerate if older than threshold (24 hours)

---

### Directory Stack Entry

**Description**: An entry in Zsh's directory stack (used for navigation)

**Attributes**:

- `path`: String - Absolute directory path
- `position`: Integer - Position in stack (0 = current, 1-N = history)
- `symbolic`: Boolean - Whether path contains symbolic links

**Relationships**:

- Stack is a LIFO (last in, first out) structure
- auto_pushd adds entries automatically on cd
- Duplicates are prevented by PUSHD_IGNORE_DUPS

**Examples**:

```zsh
# Stack: ['/home/user/project', '/home/user', '/']
# Entry 0: path='/home/user/project', position=0, symbolic=false
# Entry 1: path='/home/user', position=1, symbolic=false
# Entry 2: path='/', position=2, symbolic=false
```

**Validation**:

- Path must be valid directory
- Stack size limited by system (typically 20-30 entries)

---

## State Diagram

### Module Loading Lifecycle

```
┌─────────────┐
│ not_loaded  │
└──────┬──────┘
       │
       ├──────→ disabled (user config)
       │
       ↓
┌─────────────┐
│   loading   │
└──────┬──────┘
       │
       ├──────→ loaded (success)
       │
       └──────→ failed (error)
                 ↓
           (continue with next module)
```

### Completion System Initialization

```
┌────────────────────┐
│  Check cache age   │
└─────────┬──────────┘
          │
    ┌─────┴─────┐
    │           │
    ↓           ↓
Fresh       Stale
(<24h)      (>24h)
    │           │
    │           ↓
    │     ┌────────────┐
    │     │ Regenerate │
    │     │   cache    │
    │     └─────┬──────┘
    │           │
    └──────┬────┘
           ↓
    ┌─────────────┐
    │   compinit  │
    │   with -C   │
    └─────────────┘
```

### Environment Variable Setting

```
┌──────────────────┐
│ Check if already │
│       set        │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
    ↓         ↓
  Set     Not set
    │         │
    │         ↓
    │  ┌─────────────┐
    │  │   Detect    │
    │  │  available  │
    │  │   program   │
    │  └──────┬──────┘
    │         │
    │         ↓
    │  ┌─────────────┐
    │  │ Set default │
    │  └─────────────┘
    │
    └────→ (preserve user value)
```

## Data Flow

### Shell Startup Sequence

```
1. User sources pulse.zsh
   ↓
2. Plugin engine loads plugins
   ↓
3. Framework modules load in order:
   - environment.zsh sets EDITOR, PAGER, colors
   - compinit.zsh initializes completion system
   - completions.zsh configures completion styles
   - keybinds.zsh sets up keybindings
   - directory.zsh enables navigation features
   - prompt.zsh sets default prompt (if needed)
   - utilities.zsh loads helper functions
   ↓
4. User's .zshrc continues (can override anything)
   ↓
5. Shell ready for use
```

### User Override Pattern

```
Framework sets:      zstyle ':completion:*' menu select
                     ↓
User can override:   zstyle ':completion:*' menu no
                     ↓
Result:              menu completion disabled (user preference wins)
```

## Module Dependencies

```
environment
    ↓
compinit (needs HISTFILE, cache locations from environment)
    ↓
completions (needs compinit to be initialized)
    ↓
keybinds (independent, but commonly loaded after completions)
    ↓
directory (independent, but loads after core features)
    ↓
prompt (independent, loads late to not conflict with plugins)
    ↓
utilities (independent, loads last)
```

## Performance Considerations

**Cache Strategy**:

- zcompdump cache: Regenerate if >24 hours old or on compinit changes
- No other caching in MVP (keep it simple)

**Load Time Targets**:

- environment.zsh: <5ms (simple variable setting)
- compinit.zsh: <15ms (with cache), <100ms (cache rebuild)
- completions.zsh: <5ms (zstyle calls are fast)
- keybinds.zsh: <5ms (bindkey calls are fast)
- directory.zsh: <5ms (setopt and aliases)
- prompt.zsh: <2ms (simple prompt string)
- utilities.zsh: <3ms (function definitions)
- **Total: <40ms** (with fresh cache), <120ms (cache rebuild)

## Testing Data

**Test Fixtures Needed**:

- Mock Zsh environments (different versions: 5.0, 5.8, 5.9)
- Mock terminal configurations (color support, no color support)
- Mock filesystems (test cache file operations)
- Mock environment (existing EDITOR/PAGER, missing EDITOR/PAGER)
- Mock plugins (completion plugins, prompt plugins)

**Test Scenarios**:

- First startup (no cache)
- Subsequent startup (with cache)
- Stale cache (>24 hours old)
- Missing cache directory (should create)
- Disabled modules (should skip)
- Failed module (should continue)
- User overrides (should respect)
- Vi mode vs emacs mode
- Linux vs macOS vs BSD differences

## Conclusion

This data model defines the configuration constructs and runtime state for the framework modules. The focus is on Zsh-native structures (options, styles, bindings, variables) rather than custom data formats, keeping implementation simple and aligned with Zsh conventions.
