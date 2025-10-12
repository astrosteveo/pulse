#!/usr/bin/env zsh
# directory.zsh - Directory navigation and management features
# Provides sensible defaults for directory operations and helpful aliases

# === Directory Navigation Options ===

# AUTO_CD: Type directory name to change to it (no cd needed)
setopt AUTO_CD

# AUTO_PUSHD: Make cd push old directory onto directory stack
setopt AUTO_PUSHD

# PUSHD_IGNORE_DUPS: Don't push duplicate directories onto stack
setopt PUSHD_IGNORE_DUPS

# PUSHD_SILENT: Don't print directory stack after pushd/popd
setopt PUSHD_SILENT

# PUSHD_TO_HOME: pushd without arguments goes to $HOME (disabled for standard cd behavior)
setopt NO_PUSHD_TO_HOME

# === Directory Stack Aliases ===

# Show directory stack with numbers
alias d='dirs -v'

# === Navigation Aliases ===

# Quick parent directory navigation
alias ..='cd ..'        # Go up one level
alias ...='cd ../..'    # Go up two levels
alias -- -='cd -'       # Go to previous directory (OLDPWD)

# === ls Aliases ===

# Detect OS and set appropriate ls aliases
if [[ "$OSTYPE" == darwin* ]]; then
  # macOS: use -G for color
  alias ls='ls -G'
  alias ll='ls -lhG'      # Long format, human-readable sizes
  alias la='ls -lAhG'     # Long format, show hidden, human-readable
elif [[ "$OSTYPE" == linux* ]]; then
  # Linux: use --color=auto
  alias ls='ls --color=auto'
  alias ll='ls -lh --color=auto'        # Long format, human-readable sizes
  alias la='ls -lAh --color=auto'       # Long format, show hidden, human-readable
else
  # Generic Unix: basic ls
  alias ll='ls -lh'
  alias la='ls -lAh'
fi

# Additional helpful ls aliases
alias l='ls -CF'          # Compact format with indicators
alias lsd='ls -ld *(-/DN)'  # List only directories (including hidden)
alias lsa='ls -ld .*'     # List only hidden items

# === Directory Creation ===

# Create intermediate directories as needed
alias md='mkdir -p'

# === Safer Operations ===

# Prompt before overwriting or removing multiple files
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
