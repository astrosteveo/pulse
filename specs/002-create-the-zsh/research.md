# Research: Core Zsh Framework Modules

**Feature**: 002-create-the-zsh
**Date**: 2025-10-11
**Purpose**: Research best practices, patterns, and implementation approaches for Zsh framework modules

## Overview

This research document consolidates findings for implementing framework modules that handle completion system initialization, keybindings, shell options, environment variables, directory management, prompts, and utility functions.

## Research Areas

### 1. Zsh Completion System (compinit)

**Decision**: Use `compinit -d "$zcompdump_file"` with cache file management

**Rationale**:

- compinit is the standard Zsh completion system initializer
- `-d` flag specifies cache file location for better control
- Cache improves startup performance (avoids rescanning on every shell start)
- Should be called AFTER all completion plugins are loaded but BEFORE other completions are requested

**Best Practices**:

- Place cache file in `$PULSE_CACHE_DIR` (XDG_CACHE_HOME or ~/.cache/pulse)
- Regenerate cache when: compinit files change, plugins added/removed, or manual request
- Use `compinit -C` to skip security checks for faster startup (if cache is fresh)
- Check cache age and regenerate if older than 24 hours

**Implementation Notes**:

```zsh
# Recommended pattern from Zsh community
zcompdump="${PULSE_CACHE_DIR:-$HOME/.cache/pulse}/zcompdump"
autoload -Uz compinit

# Check if cache is fresh (less than 24 hours old)
if [[ -n "$zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$zcompdump"
else
  compinit -C -d "$zcompdump"
fi
```

**Alternatives Considered**:

- Manual completion loading: Too complex, defeats purpose of compinit
- Always regenerate cache: Too slow, defeats purpose of caching
- No caching: Startup time suffers significantly

**References**:

- Zsh manual: zshcompsys(1)
- Prezto completion module
- Oh-My-Zsh lib/completion.zsh

---

### 2. Completion Styles (zstyle)

**Decision**: Use zstyle to configure completion appearance and behavior with sensible defaults

**Rationale**:

- zstyle is Zsh's native completion customization system
- Provides granular control over completion behavior
- User can override any style by setting their own zstyle after Pulse loads
- Industry-standard patterns exist for common preferences

**Best Practices**:

- Use `zstyle ':completion:*' ...` for global completion styles
- Enable menu selection for better UX
- Case-insensitive matching with smart case
- Group completions by type with descriptions
- Use colors to distinguish completion types

**Implementation Notes**:

```zsh
# Recommended styles from Prezto/Zephyr/Oh-My-Zsh
zstyle ':completion:*' menu select                    # Enable menu selection
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case-insensitive
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}     # Colors
zstyle ':completion:*' group-name ''                  # Group by type
zstyle ':completion:*:descriptions' format '%B%d%b'   # Bold descriptions
zstyle ':completion:*' completer _complete _approximate # Fuzzy matching
```

**Alternatives Considered**:

- No styles (use Zsh defaults): Poor UX, no colors, no grouping
- Extensive customization: Too opinionated, violates simplicity principle
- Config file for styles: Violates zero-configuration principle

**References**:

- Zsh manual: zshcompsys(1), section "Completion System Configuration"
- Prezto modules/completion/init.zsh
- Zephyr plugins/compstyle

---

### 3. Keybindings System

**Decision**: Use bindkey with separate configurations for emacs and vi modes

**Rationale**:

- bindkey is Zsh's native keybinding system
- Must respect user's editing mode preference (most use emacs mode by default)
- Standard keybindings exist that users expect (Ctrl+R, Ctrl+A, Ctrl+E, etc.)
- Vi mode users expect different bindings but still need some universal ones

**Best Practices**:

- Check current keymap with `$KEYMAP` variable
- Bind to widgets (Zsh internal functions) rather than commands where possible
- Provide bindings that work in both insert and command modes (for vi)
- Don't override user bindings if already set
- Use `autoload -Uz` for Zsh Line Editor (ZLE) widgets

**Implementation Notes**:

```zsh
# Emacs mode (default)
bindkey -e  # Ensure emacs mode is set

# Universal bindings (work in both modes)
bindkey '^R' history-incremental-search-backward  # Ctrl+R: reverse search
bindkey '^[[A' up-line-or-history                 # Up arrow: history
bindkey '^[[B' down-line-or-history               # Down arrow: history

# Emacs-specific
bindkey '^A' beginning-of-line                    # Ctrl+A: line start
bindkey '^E' end-of-line                          # Ctrl+E: line end
bindkey '^W' backward-kill-word                   # Ctrl+W: delete word
bindkey '\e.' insert-last-word                    # Alt+.: last argument

# Vi mode additions (if in vi mode)
if [[ "$KEYMAP" == 'vi'* ]]; then
  bindkey -v
  # Add vi-specific bindings while preserving useful emacs ones
fi
```

**Alternatives Considered**:

- Only support emacs mode: Alienates vi users
- Only support vi mode: Most users expect emacs by default
- Extensive custom widgets: Too complex, violates simplicity

**References**:

- Zsh manual: zshzle(1)
- Prezto modules/editor/init.zsh
- Zephyr plugins/editor

---

### 4. Shell Options (setopt)

**Decision**: Set sensible shell options that improve UX without breaking compatibility

**Rationale**:

- Shell options control Zsh behavior (history, globbing, navigation, etc.)
- Many useful options are disabled by default for POSIX compatibility
- Zsh users expect extended functionality
- Options can be overridden by user's subsequent setopt calls

**Best Practices**:

- Group options by category (history, directory, completion, etc.)
- Document why each option is set
- Avoid options that change fundamental behavior unexpectedly
- Test options across Zsh versions (5.0-5.9+)

**Implementation Notes**:

```zsh
# History options
setopt EXTENDED_HISTORY          # Save timestamp and duration
setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicates
setopt HIST_IGNORE_SPACE         # Ignore commands starting with space
setopt HIST_REDUCE_BLANKS        # Remove extra blanks
setopt SHARE_HISTORY             # Share history across sessions

# Directory options
setopt AUTO_CD                   # cd by typing directory name
setopt AUTO_PUSHD                # cd pushes to directory stack
setopt PUSHD_IGNORE_DUPS         # Don't push duplicates
setopt PUSHD_SILENT              # Don't print stack after pushd/popd

# Globbing options
setopt EXTENDED_GLOB             # Enable extended glob patterns (#, ~, ^)
setopt GLOB_DOTS                 # Glob includes hidden files

# Completion options
setopt ALWAYS_TO_END             # Move cursor to end after completion
setopt AUTO_MENU                 # Show menu on repeated completion
setopt COMPLETE_IN_WORD          # Complete from cursor position
setopt LIST_PACKED               # Compact completion lists
```

**Alternatives Considered**:

- Minimal options only: Misses opportunity to improve UX
- Aggressive options (auto_correct, etc.): Too intrusive, frustrates users
- Config file for options: Violates zero-configuration principle

**References**:

- Zsh manual: zshoptions(1)
- Prezto modules/environment/init.zsh
- Zephyr plugins/history, plugins/directory

---

### 5. Environment Variables

**Decision**: Set sensible defaults for EDITOR, PAGER, LS_COLORS, etc., but never override user values

**Rationale**:

- Many tools rely on environment variables (EDITOR, PAGER)
- Users may not have these set, leading to poor defaults (ed, more)
- Color configuration improves readability
- Must preserve user's existing settings

**Best Practices**:

- Check if variable is already set before assigning
- Detect available programs in order of preference
- Use `(( ${+VAR} ))` to check if variable exists
- Follow XDG Base Directory specification where applicable

**Implementation Notes**:

```zsh
# Set EDITOR if not already set
if (( ! ${+EDITOR} )); then
  if (( ${+commands[nvim]} )); then
    export EDITOR='nvim'
  elif (( ${+commands[vim]} )); then
    export EDITOR='vim'
  elif (( ${+commands[vi]} )); then
    export EDITOR='vi'
  else
    export EDITOR='nano'  # Last resort
  fi
fi

# Set PAGER if not already set
if (( ! ${+PAGER} )); then
  if (( ${+commands[less]} )); then
    export PAGER='less'
    export LESS='-R -F -X'  # Raw colors, quit if one screen, no init
  else
    export PAGER='more'
  fi
fi

# History file location (XDG compliant)
export HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/history"
export HISTSIZE=10000
export SAVEHIST=10000

# Colors (if terminal supports it)
if [[ -t 1 && "$TERM" != "dumb" ]]; then
  # LS_COLORS (if dircolors available)
  if (( ${+commands[dircolors]} )); then
    eval "$(dircolors -b)"
  fi

  # Enable color in grep
  export GREP_COLOR='1;32'  # Green
  export GREP_OPTIONS='--color=auto'
fi
```

**Alternatives Considered**:

- Always override: Breaks user customization, violates principle IV
- Never set: Poor UX for users without configuration
- Complex detection logic: Too much code for simple feature

**References**:

- XDG Base Directory Specification
- GNU Coreutils documentation
- Prezto modules/environment/init.zsh

---

### 6. Directory Navigation

**Decision**: Enable auto_cd, auto_pushd, and provide convenience aliases

**Rationale**:

- auto_cd reduces typing (just type directory name)
- auto_pushd makes directory stack useful automatically
- Aliases for common operations improve efficiency
- These are power-user features that don't break normal usage

**Best Practices**:

- Combine auto_cd with auto_pushd for best experience
- Prevent duplicate entries in directory stack
- Provide aliases that don't conflict with common commands
- Make directory stack accessible but unobtrusive

**Implementation Notes**:

```zsh
# Enable directory options (covered in shell options above)
# setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

# Directory aliases
alias d='dirs -v'          # Show directory stack
alias -- -='cd -'          # Go to previous directory
alias ..='cd ..'           # Parent directory
alias ...='cd ../..'       # Two levels up
alias ....='cd ../../..'   # Three levels up

# ls aliases (with colors and human-readable sizes)
alias ls='ls --color=auto -h'  # Linux
alias ll='ls -lA'              # Long format, all files
alias la='ls -A'               # All files

# Cross-platform ls (macOS uses different flags)
if [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -G -h'
fi
```

**Alternatives Considered**:

- No aliases: Misses opportunity for common convenience
- Extensive aliases: Risks conflicts, violates simplicity
- Override cd with custom function: Too complex, fragile

**References**:

- Zsh manual: zshoptions(1), section "Changing Directories"
- Prezto modules/directory/init.zsh
- Zephyr plugins/directory

---

### 7. Prompt System

**Decision**: Provide minimal default prompt, allow easy override by prompt plugins

**Rationale**:

- Users have strong prompt preferences
- Complex prompts slow down startup
- Prompt plugins (Starship, Powerlevel10k) should just work
- Default should be functional but minimal

**Best Practices**:

- Use basic PROMPT variable for default
- Don't use prompt theme system (complex, unnecessary)
- Check if user/plugin already set prompt before setting default
- Keep default prompt fast (<5ms render time)

**Implementation Notes**:

```zsh
# Only set default prompt if not already set
if [[ -z "$PROMPT" ]]; then
  # Simple, informative prompt: directory + prompt symbol
  PROMPT='%F{blue}%~%f %# '
  # %F{blue} = blue foreground
  # %~ = current directory (with ~ substitution)
  # %f = reset foreground
  # %# = # for root, % for normal user
fi

# Prompt plugins typically set PROMPT directly or use precmd hooks
# No special handling needed - they override this default
```

**Alternatives Considered**:

- Complex default prompt: Slows startup, opinionated
- Use prompt theme system: Too complex for our needs
- No default prompt: Poor UX if user has no prompt plugin

**References**:

- Zsh manual: zshmisc(1), section "Prompt Expansion"
- Prezto modules/prompt/init.zsh
- Zephyr plugins/prompt

---

### 8. Utility Functions

**Decision**: Provide small set of cross-platform utility functions for common tasks

**Rationale**:

- OS differences (Linux vs macOS vs BSD) create friction
- Common operations (command existence check, file sourcing) lack built-in functions
- Small utility library improves script robustness
- Must be minimal to avoid bloat

**Best Practices**:

- Prefix all functions with `pulse_` to avoid conflicts
- Test on Linux, macOS, and BSD
- Keep functions small and focused
- Document expected behavior and return codes

**Implementation Notes**:

```zsh
# Check if command exists (cross-platform)
pulse_has_command() {
  (( ${+commands[$1]} ))
}

# Source file if it exists (no error if missing)
pulse_source_if_exists() {
  [[ -f "$1" ]] && source "$1"
}

# Detect OS type
pulse_os_type() {
  case "$OSTYPE" in
    linux*)   echo "linux" ;;
    darwin*)  echo "macos" ;;
    freebsd*) echo "bsd" ;;
    *)        echo "unknown" ;;
  esac
}

# Extract archives (multiple formats)
pulse_extract() {
  local file="$1"
  case "$file" in
    *.tar.gz|*.tgz)  tar -xzf "$file" ;;
    *.tar.bz2|*.tbz) tar -xjf "$file" ;;
    *.tar.xz|*.txz)  tar -xJf "$file" ;;
    *.zip)           unzip "$file" ;;
    *.7z)            7z x "$file" ;;
    *.rar)           unrar x "$file" ;;
    *)               echo "Unknown archive format: $file" >&2; return 1 ;;
  esac
}
```

**Alternatives Considered**:

- No utility functions: Misses opportunity to smooth OS differences
- Extensive library: Bloat, violates simplicity principle
- Separate utility plugin: Unnecessary separation, harder to maintain

**References**:

- Prezto modules/utility/init.zsh
- Zephyr plugins/utility
- Oh-My-Zsh lib/functions.zsh

---

### 9. Module Loading Order

**Decision**: Load modules in specific order: environment → compinit → completions → keybinds → directory → prompt → utilities

**Rationale**:

- Environment must be set first (affects all other modules)
- compinit must run after completion plugins but before completions are requested
- Keybindings and directory features should be available early
- Prompt and utilities are least critical, load last

**Best Practices**:

- Each module is independent (can be tested separately)
- Modules should not have circular dependencies
- Allow users to disable individual modules
- Document load order in pulse.zsh

**Implementation Notes**:

```zsh
# In pulse.zsh (after plugin loading)

# Array of modules to load
local -a pulse_modules
pulse_modules=(
  environment  # Set EDITOR, PAGER, colors, history location
  compinit     # Initialize completion system
  completions  # Configure completion styles
  keybinds     # Set up keybindings
  directory    # Directory navigation and aliases
  prompt       # Default prompt (if not set)
  utilities    # Utility functions
)

# Load each module
for module in $pulse_modules; do
  # Skip if module is disabled
  if [[ -n "${pulse_disabled_modules[(r)$module]}" ]]; then
    [[ -n "$PULSE_DEBUG" ]] && echo "Pulse: Skipping module $module (disabled)"
    continue
  fi

  local module_file="${PULSE_DIR}/lib/${module}.zsh"
  if [[ -f "$module_file" ]]; then
    source "$module_file" || {
      echo "Pulse: Error loading module $module" >&2
      # Continue loading other modules (graceful degradation)
    }
  fi
done
```

**Alternatives Considered**:

- Alphabetical loading: Wrong order, breaks functionality
- Single monolithic module: Hard to test, maintain, and customize
- Lazy loading all modules: Adds complexity, not worth the minimal startup time

**References**:

- Zephyr's module loading system
- Prezto's module initialization
- Unix philosophy: small, composable pieces

---

## Implementation Strategy

### Phase 1: P1 Modules (Critical)

1. **environment.zsh**: Set up environment variables and basic shell options
2. **compinit.zsh**: Initialize completion system with caching
3. **completions.zsh**: Configure completion styles
4. **keybinds.zsh**: Set up keybindings

### Phase 2: P2 Modules (Important)

5. **directory.zsh**: Enable directory navigation features and aliases

### Phase 3: P3 Modules (Nice to have)

6. **prompt.zsh**: Minimal default prompt
7. **utilities.zsh**: Utility functions

### Testing Strategy

- Unit tests for each module (can load independently)
- Integration tests for full startup (all modules together)
- Compatibility tests across Zsh versions (5.0, 5.1, 5.8, 5.9)
- Cross-platform tests (Linux, macOS, BSD)
- Performance tests (each module <30ms, total <50ms)

### Migration Path

This feature extends the existing plugin engine (feature 001) without modifying it:

1. Plugin engine handles plugin loading
2. After plugins loaded, framework modules initialize
3. Framework modules configure the shell environment
4. User's .zshrc customizations come after Pulse (can override anything)

## Conclusion

All research complete. No outstanding questions or NEEDS CLARIFICATION items. Ready to proceed to Phase 1 (design and contracts).
