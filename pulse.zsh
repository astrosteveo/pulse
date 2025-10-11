#!/usr/bin/env zsh
# Pulse: The Heartbeat of Your Zsh
# An intelligent declarative Zsh plugin framework
# (c) 2025, Unlicense. Inspired by mattmc3/zsh_unplugged and zephyr.

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
