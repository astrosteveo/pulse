# Pulse: The Heartbeat of Your Zsh
# (c) 2025, Unlicense. Inspired by mattmc3/zsh_unplugged and zephyr.

# Load core modules
for mod in compinit keybinds completions plugin-engine; do
  modpath=${0:A:h}/lib/$mod.zsh
  [[ -f $modpath ]] && source $modpath
done

# Main entry point for Pulse
# (future logic will go here)
