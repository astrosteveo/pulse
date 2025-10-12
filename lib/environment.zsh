#!/usr/bin/env zsh
# Pulse: environment setup
# Sets environment variables and shell options with sensible defaults

# === EDITOR Configuration ===
# Set EDITOR only if not already set
# Priority: nvim > vim > vi > nano > emacs
if [[ -z "$EDITOR" ]]; then
  if command -v nvim &>/dev/null; then
    export EDITOR=nvim
  elif command -v vim &>/dev/null; then
    export EDITOR=vim
  elif command -v vi &>/dev/null; then
    export EDITOR=vi
  elif command -v nano &>/dev/null; then
    export EDITOR=nano
  elif command -v emacs &>/dev/null; then
    export EDITOR=emacs
  fi
fi

# === PAGER Configuration ===
# Set PAGER only if not already set
# Priority: less > more
if [[ -z "$PAGER" ]]; then
  if command -v less &>/dev/null; then
    export PAGER=less
    # Set less options for better experience
    export LESS='-R -F -X'
  elif command -v more &>/dev/null; then
    export PAGER=more
  fi
fi

# === History Configuration ===
# Use XDG Base Directory if available, otherwise fallback to HOME
if [[ -n "$XDG_DATA_HOME" ]]; then
  HISTFILE="${XDG_DATA_HOME}/zsh/history"
else
  HISTFILE="${HOME}/.local/share/zsh/history"
fi

# Create history directory if it doesn't exist
[[ -d "$(dirname "$HISTFILE")" ]] || mkdir -p "$(dirname "$HISTFILE")"

# History settings
HISTSIZE=10000
SAVEHIST=10000

# History options
setopt EXTENDED_HISTORY          # Write timestamp to history file
setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicate entries from history
setopt HIST_IGNORE_SPACE         # Don't record commands starting with space
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks from history
setopt SHARE_HISTORY             # Share history between sessions
setopt INC_APPEND_HISTORY        # Write to history file immediately

# === Globbing Options ===
setopt EXTENDED_GLOB             # Enable extended globbing (#, ~, ^)
setopt GLOB_DOTS                 # Include dotfiles in globs

# === Directory Options ===
# These are set in directory.zsh, but we ensure they're not conflicting
# AUTO_CD, AUTO_PUSHD, PUSHD_IGNORE_DUPS will be set by directory module

# === Color Support ===
# Configure LS_COLORS if dircolors is available
if command -v dircolors &>/dev/null; then
  eval "$(dircolors -b)"
elif command -v gdircolors &>/dev/null; then
  # macOS with GNU coreutils
  eval "$(gdircolors -b)"
fi

# Set GREP_COLOR for highlighted grep output
export GREP_COLOR='1;32'

# === Shell Behavior Options ===
setopt NO_BEEP                   # Don't beep on errors
setopt NOTIFY                    # Report status of background jobs immediately
setopt NO_HUP                    # Don't send HUP signal to jobs on shell exit
setopt NO_CHECK_JOBS             # Don't warn about running jobs on exit

# === Completion Behavior ===
# Basic completion options (detailed configuration in completions.zsh)
setopt ALWAYS_TO_END             # Move cursor to end after completion
setopt AUTO_MENU                 # Show completion menu on successive tab
setopt COMPLETE_IN_WORD          # Complete from both ends of word
setopt LIST_PACKED               # Compact completion lists

# === Error Handling ===
# Don't exit on errors in scripts (for interactive shells)
setopt NO_ERR_EXIT
