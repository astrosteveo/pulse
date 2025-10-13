#!/usr/bin/env zsh
# Mock environment script for isolated testing
# Sets up minimal test environment without affecting user's real shell

# Set test-specific directories
export PULSE_TEST_DIR="${PULSE_TEST_DIR:-${0:A:h}}"
export PULSE_DIR="${PULSE_TEST_DIR}/pulse_home"
export PULSE_CACHE_DIR="${PULSE_TEST_DIR}/pulse_cache"

# Set minimal PATH for predictable tests
export PATH="/usr/local/bin:/usr/bin:/bin"

# Clear any existing Pulse configuration
unset PULSE_DEBUG
unset pulse_disabled_modules
unset pulse_plugin_stage

# Reset environment variables that modules might set
unset EDITOR
unset PAGER
unset HISTFILE
unset LS_COLORS
unset GREP_COLOR

# Ensure clean history
export HISTSIZE=1000
export SAVEHIST=1000

# Disable any user customizations
unset ZDOTDIR
