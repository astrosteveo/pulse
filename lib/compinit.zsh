#!/usr/bin/env zsh
# Pulse: compinit setup
# Handles intelligent completion system initialization with caching

# Set cache directory (use default if not set)
if [[ -z "$PULSE_CACHE_DIR" ]]; then
  if [[ -n "$XDG_CACHE_HOME" ]]; then
    PULSE_CACHE_DIR="${XDG_CACHE_HOME}/pulse"
  else
    PULSE_CACHE_DIR="${HOME}/.cache/pulse"
  fi
fi

# Set completion dump file location
PULSE_ZCOMPDUMP="${PULSE_CACHE_DIR}/zcompdump"

# Create cache directory if it doesn't exist
if [[ ! -d "$PULSE_CACHE_DIR" ]]; then
  mkdir -p "$PULSE_CACHE_DIR" 2>/dev/null || {
    # Fallback if cache creation fails
    [[ -n "${PULSE_DEBUG}" ]] && echo "Pulse: WARNING - Could not create cache directory, using temp" >&2
    PULSE_CACHE_DIR="$(mktemp -d 2>/dev/null || echo /tmp/pulse-$$)"
    PULSE_ZCOMPDUMP="${PULSE_CACHE_DIR}/zcompdump"
  }
fi

# Check if cache is fresh (less than 24 hours old)
_pulse_cache_fresh=false
if [[ -f "$PULSE_ZCOMPDUMP" ]]; then
  # Get cache age in hours
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS stat command
    cache_age=$(( ($(date +%s) - $(stat -f %m "$PULSE_ZCOMPDUMP")) / 3600 ))
  else
    # Linux stat command
    cache_age=$(( ($(date +%s) - $(stat -c %Y "$PULSE_ZCOMPDUMP" 2>/dev/null || echo 0)) / 3600 ))
  fi

  if [[ $cache_age -lt 24 ]]; then
    _pulse_cache_fresh=true
  fi
fi

# Load compinit function
autoload -Uz compinit

# Initialize completion system
if [[ "$_pulse_cache_fresh" == "true" ]]; then
  # Use -C flag to skip security check for fresh cache (faster)
  [[ -n "${PULSE_DEBUG}" ]] && echo "Pulse: Using cached completions (<24h old)" >&2
  compinit -C -d "$PULSE_ZCOMPDUMP"
else
  # Full initialization for stale or missing cache
  [[ -n "${PULSE_DEBUG}" ]] && echo "Pulse: Rebuilding completion cache" >&2
  compinit -d "$PULSE_ZCOMPDUMP"
fi

# Clean up temporary variable
unset _pulse_cache_fresh
