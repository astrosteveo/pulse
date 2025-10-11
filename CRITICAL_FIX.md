# Critical Fix Applied: Plugin Declaration Order

## Issue Discovered

The original documentation had plugins being defined **AFTER** sourcing `pulse.zsh`, which is incorrect. Pulse needs the `plugins` array to exist **BEFORE** it's sourced so it can discover and load them during initialization.

## Incorrect Pattern ❌

```zsh
# WRONG - Don't do this!
source ~/.local/share/pulse/pulse.zsh

plugins=(
  zsh-users/zsh-autosuggestions
)
```

Result: `[Pulse] No plugins array defined`

## Correct Pattern ✅

```zsh
# CORRECT - Define plugins first!
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)

source ~/.local/share/pulse/pulse.zsh
```

Result: Plugins are discovered, classified, and loaded correctly!

## Files Fixed

1. ✅ `pulse.zshrc.template` - Reordered sections, added clear warnings
2. ✅ `README.md` - Fixed all example configurations
3. ✅ `QUICKSTART_MVP.md` - Fixed all example configurations

## Correct Configuration Template

```zsh
# ~/.zshrc

# ============================================================================
# 1. PLUGIN CONFIGURATION (must come first!)
# ============================================================================

plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)

# ============================================================================
# 2. ADVANCED CONFIGURATION (optional, before sourcing Pulse)
# ============================================================================

# Optional: Disable specific plugins
# pulse_disabled_plugins=(unwanted-plugin)

# Optional: Override plugin stages
# typeset -gA pulse_plugin_stage
# pulse_plugin_stage[my-plugin]="late"

# Optional: Enable debug mode
# export PULSE_DEBUG=1

# ============================================================================
# 3. LOAD PULSE (after configuration!)
# ============================================================================

source ~/.local/share/pulse/pulse.zsh

# ============================================================================
# 4. YOUR CUSTOM CONFIGURATION (after Pulse)
# ============================================================================

# Your aliases, functions, etc. go here
```

## Why This Order Matters

Pulse's initialization flow:

1. **User sources pulse.zsh** → triggers `_pulse_init_engine()`
2. **Engine calls `_pulse_discover_plugins()`** → looks for `plugins` array
3. **If `plugins` exists** → processes each plugin
4. **If `plugins` doesn't exist** → prints "No plugins array defined" and continues

The `plugins` array must exist in step 2, which means it must be defined before step 1!

## Testing the Fix

Try this:

```bash
# Create a test plugin
mkdir -p ~/.local/share/pulse/plugins/test-plugin
echo "echo 'Test plugin loaded!'" > ~/.local/share/pulse/plugins/test-plugin/test-plugin.plugin.zsh

# Test with correct order
zsh -c "
export PULSE_DEBUG=1
plugins=(test-plugin)
source ~/.local/share/pulse/pulse.zsh
"
```

Expected output:

```
[Pulse] Engine initialized (PULSE_DIR=...)
[Pulse] Registered: test-plugin (type=standard, stage=normal)
[Pulse] Stage 1: Early
[Pulse] Stage 2: Compinit
[Pulse] Stage 3: Normal
[Pulse] Loaded: test-plugin
Test plugin loaded!
[Pulse] Stage 4: Late
[Pulse] Stage 5: Deferred (on-demand)
```

## Status

✅ **All documentation corrected**
✅ **Template file fixed**
✅ **Order clearly documented**
✅ **Ready for user testing**

The MVP is now correctly documented and ready to ship!
