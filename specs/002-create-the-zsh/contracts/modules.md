# Module Contracts: Core Zsh Framework Modules

**Feature**: 002-create-the-zsh
**Date**: 2025-10-11
**Purpose**: Define the interface and behavior contracts for each framework module

## Overview

These contracts define what each module must provide, what it depends on, and how it integrates with the rest of Pulse. Unlike traditional API contracts, these are shell module interfaces.

---

## environment.zsh

**Purpose**: Set up environment variables and XDG paths

**Load Order**: 1 (first)

**Dependencies**: None

**Exports**:

```zsh
# Environment Variables (set only if not already set)
EDITOR          # Text editor (nvim > vim > vi > nano)
PAGER           # Pager program (less > more)
LESS            # Less options (-R -F -X)
HISTFILE        # History file location (XDG_DATA_HOME/zsh/history)
HISTSIZE        # In-memory history size (10000)
SAVEHIST        # Saved history size (10000)
LS_COLORS       # Color configuration for ls (from dircolors if available)
GREP_COLOR      # Grep color (1;32 = green)
```

**Shell Options Set**:

```zsh
# History
EXTENDED_HISTORY          # Save timestamp and duration
HIST_IGNORE_ALL_DUPS      # Remove older duplicates
HIST_IGNORE_SPACE         # Ignore commands starting with space
HIST_REDUCE_BLANKS        # Remove extra blanks
SHARE_HISTORY             # Share history across sessions
INC_APPEND_HISTORY        # Append immediately, not on exit

# Globbing
EXTENDED_GLOB             # Enable extended glob patterns
GLOB_DOTS                 # Glob includes hidden files
```

**Functions Provided**: None

**Side Effects**:

- Creates `$HISTFILE` parent directory if it doesn't exist
- Never overrides existing environment variables

**Error Handling**:

- Graceful: If preferred EDITOR not found, tries next option
- If no editors found, leaves EDITOR unset (shell will use default)

**Testing Contract**:

- Must respect existing EDITOR/PAGER environment variables
- Must create HISTFILE directory if missing
- Must work on Linux, macOS, BSD
- Must work with Zsh 5.0+

---

## compinit.zsh

**Purpose**: Initialize Zsh completion system with caching

**Load Order**: 2

**Dependencies**: environment.zsh (for cache directory location)

**Exports**:

```zsh
# Variables
PULSE_ZCOMPDUMP  # Path to completion cache file
```

**Functions Provided**: None (uses built-in `compinit`)

**Side Effects**:

- Creates `$PULSE_CACHE_DIR` if it doesn't exist
- Generates or loads zcompdump file
- Calls `autoload -Uz compinit`
- Calls `compinit -d "$PULSE_ZCOMPDUMP"` (with or without -C flag)

**Caching Logic**:

```zsh
if cache is fresh (<24 hours old):
    compinit -C -d "$PULSE_ZCOMPDUMP"  # Skip security check
else:
    compinit -d "$PULSE_ZCOMPDUMP"     # Full initialization
fi
```

**Error Handling**:

- If cache directory creation fails, fall back to default compinit
- If compinit fails, log error but don't block shell startup

**Testing Contract**:

- Must create cache file on first run
- Must use cached version on subsequent runs (< 24 hours)
- Must regenerate stale cache (>24 hours)
- Must work with $PULSE_CACHE_DIR set or unset
- Performance: <15ms with cache, <100ms without

---

## completions.zsh

**Purpose**: Configure completion styles for better UX

**Load Order**: 3

**Dependencies**: compinit.zsh (compinit must be initialized first)

**Exports**: None

**Functions Provided**: None

**Zstyles Set**:

```zsh
# Menu and selection
zstyle ':completion:*' menu select
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

# Matching and case sensitivity
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Colors
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Grouping and descriptions
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'

# Completion behavior
zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX+$#SUFFIX)/3 )) numeric )'
```

**Shell Options Set**:

```zsh
ALWAYS_TO_END       # Move cursor to end after completion
AUTO_MENU           # Show menu on repeated completion
COMPLETE_IN_WORD    # Complete from cursor position
LIST_PACKED         # Compact completion lists
```

**Side Effects**: None (only configuration)

**Error Handling**: N/A (zstyle calls don't fail)

**Testing Contract**:

- Completion menu must appear on Tab
- Case-insensitive matching must work
- Fuzzy/approximate matching must work (with typos)
- Colors must appear (if terminal supports)
- Groups and descriptions must be shown

---

## keybinds.zsh

**Purpose**: Set up productive keybindings

**Load Order**: 4

**Dependencies**: None (can work independently)

**Exports**: None

**Functions Provided**: None (uses built-in widgets)

**Keybindings Set**:

```zsh
# Ensure emacs mode by default
bindkey -e

# History navigation
bindkey '^R' history-incremental-search-backward   # Ctrl+R
bindkey '^S' history-incremental-search-forward    # Ctrl+S (if terminal allows)
bindkey '^[[A' up-line-or-history                  # Up arrow
bindkey '^[[B' down-line-or-history                # Down arrow
bindkey '^P' up-line-or-history                    # Ctrl+P
bindkey '^N' down-line-or-history                  # Ctrl+N

# Line editing
bindkey '^A' beginning-of-line                     # Ctrl+A
bindkey '^E' end-of-line                           # Ctrl+E
bindkey '^W' backward-kill-word                    # Ctrl+W
bindkey '^U' backward-kill-line                    # Ctrl+U
bindkey '^K' kill-line                             # Ctrl+K
bindkey '\e[3~' delete-char                        # Delete key

# Word navigation
bindkey '\e^[[C' forward-word                      # Alt+Right
bindkey '\e^[[D' backward-word                     # Alt+Left
bindkey '\eb' backward-word                        # Alt+B
bindkey '\ef' forward-word                         # Alt+F

# Argument insertion
bindkey '\e.' insert-last-word                     # Alt+.
bindkey '\e_' insert-last-word                     # Alt+_ (alternative)
```

**Vi Mode Support**:

- If user sets `bindkey -v` after sourcing Pulse, vi mode is respected
- Vi mode users still get Ctrl+R and arrow keys (universal bindings)

**Side Effects**: None

**Error Handling**: N/A (bindkey calls don't fail if widget exists)

**Testing Contract**:

- Ctrl+R must trigger history search
- Arrow keys must navigate history
- Ctrl+A/E must move to line beginning/end
- Alt+. must insert last argument
- User bindings (set after) must override framework bindings

---

## directory.zsh

**Purpose**: Enable easy directory navigation

**Load Order**: 5

**Dependencies**: None

**Exports**: None

**Functions Provided**: None

**Shell Options Set**:

```zsh
AUTO_CD                 # cd by typing directory name
AUTO_PUSHD              # cd pushes to directory stack
PUSHD_IGNORE_DUPS       # Don't push duplicates
PUSHD_SILENT            # Don't print stack after pushd/popd
```

**Aliases Defined**:

```zsh
# Directory stack
alias d='dirs -v'          # Show directory stack
alias -- -='cd -'          # Go to previous directory

# Parent directory shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# ls aliases (with colors and human-readable sizes)
# Linux
alias ls='ls --color=auto -h'
alias ll='ls -lA'
alias la='ls -A'

# macOS (different flags)
if [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -G -h'
fi
```

**Side Effects**: None

**Error Handling**: N/A (options and aliases don't fail)

**Testing Contract**:

- Typing directory name must cd to it
- cd must add to directory stack
- `d` alias must show directory stack
- `..` must go to parent directory
- ls aliases must work on Linux and macOS
- Directory stack must not contain duplicates

---

## prompt.zsh

**Purpose**: Provide minimal default prompt

**Load Order**: 6

**Dependencies**: None

**Exports**:

```zsh
PROMPT     # Default prompt string (if not already set)
```

**Functions Provided**: None

**Prompt String**:

```zsh
# Only set if PROMPT is not already set by user/plugin
if [[ -z "$PROMPT" ]]; then
  PROMPT='%F{blue}%~%f %# '
  # %F{blue} = blue foreground
  # %~ = current directory (with ~ substitution)
  # %f = reset foreground
  # %# = # for root, % for normal user
fi
```

**Side Effects**: None

**Error Handling**: N/A (prompt string is just a variable)

**Testing Contract**:

- Must NOT override existing PROMPT (from plugin or user)
- Default prompt must show current directory
- Default prompt must distinguish root vs normal user
- Prompt must not contain slow operations (no git status, etc.)
- Render time must be <5ms

---

## utilities.zsh

**Purpose**: Provide cross-platform utility functions

**Load Order**: 7 (last)

**Dependencies**: None

**Exports**: None

**Functions Provided**:

```zsh
# Check if command exists
pulse_has_command() {
  # Usage: pulse_has_command <command_name>
  # Returns: 0 if command exists, 1 otherwise
  (( ${+commands[$1]} ))
}

# Source file if it exists
pulse_source_if_exists() {
  # Usage: pulse_source_if_exists <file_path>
  # Returns: 0 if sourced, 1 if file doesn't exist
  [[ -f "$1" ]] && source "$1"
}

# Detect OS type
pulse_os_type() {
  # Usage: pulse_os_type
  # Returns: "linux", "macos", "bsd", or "unknown"
  case "$OSTYPE" in
    linux*)   echo "linux" ;;
    darwin*)  echo "macos" ;;
    freebsd*) echo "bsd" ;;
    *)        echo "unknown" ;;
  esac
}

# Extract archives
pulse_extract() {
  # Usage: pulse_extract <archive_file>
  # Returns: 0 on success, 1 on error
  local file="$1"
  case "$file" in
    *.tar.gz|*.tgz)  tar -xzf "$file" ;;
    *.tar.bz2|*.tbz) tar -xjf "$file" ;;
    *.tar.xz|*.txz)  tar -xJf "$file" ;;
    *.zip)           unzip "$file" ;;
    *.7z)            7z x "$file" ;;
    *.rar)           unrar x "$file" ;;
    *)
      echo "Unknown archive format: $file" >&2
      return 1
      ;;
  esac
}
```

**Side Effects**: None (pure functions)

**Error Handling**:

- Functions return appropriate exit codes
- Error messages go to stderr
- Failures don't block shell operation

**Testing Contract**:

- `pulse_has_command` must work for existing and non-existing commands
- `pulse_source_if_exists` must not error on missing files
- `pulse_os_type` must correctly identify Linux, macOS, BSD
- `pulse_extract` must handle common archive formats
- All functions must work on Linux, macOS, BSD

---

## Module Loading Interface

**Contract for pulse.zsh (main entry point)**:

```zsh
# After plugin loading, load framework modules
local -a pulse_modules
pulse_modules=(
  environment
  compinit
  completions
  keybinds
  directory
  prompt
  utilities
)

for module in $pulse_modules; do
  # Skip if disabled
  if [[ -n "${pulse_disabled_modules[(r)$module]}" ]]; then
    [[ -n "$PULSE_DEBUG" ]] && echo "Pulse: Skipping $module (disabled)"
    continue
  fi

  # Load module
  local module_file="${PULSE_DIR}/lib/${module}.zsh"
  if [[ -f "$module_file" ]]; then
    if [[ -n "$PULSE_DEBUG" ]]; then
      local start_time=$(($(date +%s%N)/1000000))
      source "$module_file" || {
        echo "Pulse: Error loading $module" >&2
      }
      local end_time=$(($(date +%s%N)/1000000))
      echo "Pulse: Loaded $module in $((end_time - start_time))ms"
    else
      source "$module_file" || {
        echo "Pulse: Error loading $module" >&2
      }
    fi
  else
    [[ -n "$PULSE_DEBUG" ]] && echo "Pulse: Module $module not found"
  fi
done
```

**User Configuration Interface**:

```zsh
# Users can disable modules before sourcing Pulse
pulse_disabled_modules=(
  prompt      # Use my own prompt
  utilities   # Don't need utility functions
)

# Users can override any setting after sourcing Pulse
source ~/.local/share/pulse/pulse.zsh

# Override examples
setopt NO_AUTO_CD                        # Disable auto_cd
bindkey '^R' my-custom-history-widget    # Custom history search
zstyle ':completion:*' menu no           # Disable menu completion
export EDITOR='emacs'                    # Use emacs
PROMPT='%~ $ '                           # Custom prompt
```

---

## Performance Contracts

**Per-Module Maximum Load Times**:

- environment.zsh: 5ms
- compinit.zsh: 15ms (with cache), 100ms (cache rebuild)
- completions.zsh: 5ms
- keybinds.zsh: 5ms
- directory.zsh: 5ms
- prompt.zsh: 2ms
- utilities.zsh: 3ms

**Total: <40ms** (with cache), <120ms (cache rebuild)

**Measurement Method**:

```zsh
start=$(($(date +%s%N)/1000000))
source lib/module.zsh
end=$(($(date +%s%N)/1000000))
echo "Load time: $((end - start))ms"
```

---

## Compatibility Contracts

**Zsh Version Support**: 5.0+

**Platform Support**: Linux, macOS, BSD

**Terminal Support**:

- Color terminals (xterm, screen, tmux, etc.)
- Non-color terminals (dumb terminal graceful degradation)

**Integration Support**:

- Works with plugin engine from feature 001
- Compatible with popular prompt frameworks (Starship, Powerlevel10k, pure)
- Compatible with popular completion plugins (zsh-completions, docker, kubectl)
- Compatible with popular Zsh plugins (zsh-autosuggestions, zsh-syntax-highlighting)

---

## Testing Contracts

**Each module must have**:

- Unit tests (test in isolation)
- Integration tests (test with other modules)
- Compatibility tests (test on Zsh 5.0, 5.8, 5.9)
- Cross-platform tests (test on Linux, macOS)
- Performance tests (verify load time targets)

**Test Coverage Requirements**:

- 100% of public functions tested
- All user stories have integration tests
- All edge cases covered
- All error paths tested

---

## Conclusion

These contracts define the interface and behavior expectations for each framework module. Modules must honor these contracts to ensure consistent behavior, proper integration, and maintainability.
