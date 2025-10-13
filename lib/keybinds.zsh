#!/usr/bin/env zsh
# keybinds.zsh - Enhanced keybindings for productive shell interaction
# Provides sensible keybindings for history search, line editing, and navigation

# Set emacs mode as default (most common, cross-platform compatible)
bindkey -e

# History search with Ctrl+R (reverse) and Ctrl+S (forward)
# Note: Ctrl+S may be captured by terminal for flow control (XOFF)
# We disable flow control to allow Ctrl+S for forward search
stty -ixon 2>/dev/null  # Disable XON/XOFF flow control
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward

# History navigation with arrows and Ctrl+P/N
# Use substring search if available, otherwise use line-based search
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey "${terminfo[kcuu1]}" up-line-or-history      # Up arrow
bindkey "${terminfo[kcud1]}" down-line-or-history    # Down arrow

# Line editing - move to beginning/end of line
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# Line editing - deletion
bindkey '^W' backward-kill-word      # Delete word backward (Ctrl+W)
bindkey '^U' kill-whole-line         # Delete entire line (Ctrl+U)
bindkey '^K' kill-line               # Delete from cursor to end (Ctrl+K)

# Word navigation with Alt/Meta key
# Alt sends escape sequences: ESC followed by the character
bindkey '\eb' backward-word          # Alt+B - move back one word
bindkey '\ef' forward-word           # Alt+F - move forward one word
bindkey '\e[1;3D' backward-word      # Alt+Left arrow (some terminals)
bindkey '\e[1;3C' forward-word       # Alt+Right arrow (some terminals)

# Alt+Backspace to delete word backward (alternative to Ctrl+W)
bindkey '\e^?' backward-kill-word

# Insert last argument from previous command with Alt+.
bindkey '\e.' insert-last-word

# Home and End keys (terminal-specific)
bindkey "${terminfo[khome]}" beginning-of-line  # Home
bindkey "${terminfo[kend]}" end-of-line         # End

# Delete key
bindkey "${terminfo[kdch1]}" delete-char        # Delete

# Additional useful bindings
bindkey '^Y' yank                    # Ctrl+Y - paste (yank) killed text
bindkey '\eu' undo                   # Alt+U - undo last change
bindkey '^_' undo                    # Ctrl+_ - undo (alternative)

# Ctrl+X Ctrl+E to edit command line in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Allow user to override any bindings after this module loads
# User bindings in .zshrc will take precedence over these defaults
