#!/usr/bin/env zsh
# Pulse: The Heartbeat of Your Zsh
# An intelligent declarative Zsh plugin framework
# (c) 2025, Unlicense. Inspired by mattmc3/zsh_unplugged and zephyr.

# Framework version (update alongside releases)
typeset -gx PULSE_VERSION="${PULSE_VERSION:-0.3.0}"

# Get the directory where pulse.zsh is located
PULSE_SCRIPT_DIR="${0:A:h}"

# Load the plugin engine
source "${PULSE_SCRIPT_DIR}/lib/plugin-engine.zsh"

# Initialize the plugin engine
_pulse_init_engine

# Discover and register all plugins from the plugins array
_pulse_discover_plugins

# Execute the 5-stage loading pipeline
_pulse_load_stages

# Framework module loading
# Modules provide core shell features: completions, keybindings, shell options, etc.
# Load order is critical: environment → compinit → completions → keybinds → directory → prompt → utilities

# Module load order (DO NOT CHANGE without updating dependencies)
typeset -ga _pulse_framework_modules
_pulse_framework_modules=(
  environment  # Set environment variables and shell options
  compinit     # Initialize completion system
  completions  # Configure completion styles
  keybinds     # Set up keybindings
  directory    # Directory navigation and management
  prompt       # Basic prompt setup
  utilities    # Utility functions
)

# Track loaded modules for debugging
typeset -ga pulse_loaded_modules
pulse_loaded_modules=()

# Track load order for testing
typeset -ga pulse_load_order
pulse_load_order=()

# Load framework modules
for _pulse_module in ${_pulse_framework_modules[@]}; do
  # Skip if module is disabled
  if (( ${pulse_disabled_modules[(Ie)${_pulse_module}]} )); then
    [[ -n "${PULSE_DEBUG}" ]] && echo "Pulse: Skipping disabled module: ${_pulse_module}" >&2
    continue
  fi

  # Module file path
  _pulse_module_file="${PULSE_SCRIPT_DIR}/lib/${_pulse_module}.zsh"

  # Check if module exists
  if [[ ! -f "${_pulse_module_file}" ]]; then
    [[ -n "${PULSE_DEBUG}" ]] && echo "Pulse: Module not found: ${_pulse_module}" >&2
    continue
  fi

  # Load module with timing if debug enabled
  if [[ -n "${PULSE_DEBUG}" ]]; then
    _pulse_start=$EPOCHREALTIME
    if source "${_pulse_module_file}" 2>&1; then
      _pulse_end=$EPOCHREALTIME
      _pulse_elapsed=$(( (_pulse_end - _pulse_start) * 1000 ))
      printf "Pulse: Loaded %s (%.2fms)\n" "${_pulse_module}" "${_pulse_elapsed}" >&2
      pulse_loaded_modules+=("${_pulse_module}")
      pulse_load_order+=("${_pulse_module}")
    else
      echo "Pulse: ERROR loading module ${_pulse_module} (continuing)" >&2
    fi
  else
    # Load without timing
    if source "${_pulse_module_file}" 2>&1; then
      pulse_loaded_modules+=("${_pulse_module}")
      pulse_load_order+=("${_pulse_module}")
    else
      # Graceful degradation: log error but continue
      echo "Pulse: ERROR loading module ${_pulse_module} (continuing)" >&2
    fi
  fi
done

# Cleanup temporary variables
unset _pulse_module _pulse_module_file _pulse_start _pulse_end _pulse_elapsed
