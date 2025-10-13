#!/usr/bin/env zsh
# Pulse: completions setup
# Configures completion styles for better user experience

# === Menu Selection ===
# Enable interactive menu for completions
zstyle ':completion:*' menu select

# Show helpful prompt when selecting from menu
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

# === Matching and Suggestions ===
# Configure matchers for flexible completion matching
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# The matchers above provide:
# 1. Case-insensitive matching (m:{a-zA-Z}={A-Za-z})
# 2. Partial word matching on separators (r:|[._-]=* r:|=*)
# 3. Left-to-right and right-to-left matching (l:|=* r:|=*)

# === Visual Presentation ===
# Use colors from LS_COLORS for completion listings
if [[ -n "$LS_COLORS" ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

# Enable grouping of completions by type
zstyle ':completion:*' group-name ''

# Format for group descriptions
zstyle ':completion:*:descriptions' format '%B%d%b'

# Format for messages
zstyle ':completion:*:messages' format '%d'

# Format for warnings (no matches)
zstyle ':completion:*:warnings' format 'No matches for: %d'

# Format for corrections
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'

# === Completion Behavior ===
# Use cache for expensive completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${PULSE_CACHE_DIR:-${HOME}/.cache/pulse}/zcompcache"

# Complete options and their arguments together
zstyle ':completion:*' complete-options true

# Show detailed information in completions
zstyle ':completion:*' verbose true

# Squeeze slashes in file paths (e.g., /usr//bin -> /usr/bin)
zstyle ':completion:*' squeeze-slashes true

# === Process and Job Completion ===
# Show detailed process list
zstyle ':completion:*:processes' command 'ps -au $USER'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;32'

# === Note ===
# Shell options for completion behavior (ALWAYS_TO_END, AUTO_MENU, etc.)
# are already set in environment.zsh to avoid duplication
