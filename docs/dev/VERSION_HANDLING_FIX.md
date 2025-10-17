# Installer Version Handling Fix

**Status**: ✅ FIXED
**Commit**: 7507411
**Branch**: 003-implement-an-install
**Date**: 2025-10-13

## Problem

When running the installer to update an existing Pulse installation, it would fail with:

```
✓ Target version: 0.1.0-beta
✓ Switching to version 0.1.0-beta...
✗ Failed to checkout version 0.1.0-beta
✗ Failed to install Pulse repository
```

### Root Cause

The issue had two components:

1. **Environment Variable Inheritance**
   - `pulse.zsh` line 7: `typeset -gx PULSE_VERSION="${PULSE_VERSION:-0.1.0-beta}"`
   - The `-gx` flags make the variable **global** and **exported**
   - When user sources `.zshrc`, `PULSE_VERSION=0.1.0-beta` is set in the environment
   - When installer runs, it inherits this environment variable

2. **Incorrect Update Logic**
   - Installer checked if `PULSE_VERSION` was set
   - If set, it tried to `git checkout $PULSE_VERSION` even for updates
   - But `0.1.0-beta` is not a git tag (actual tag is `v0.1.0`)
   - Result: checkout fails → installation fails

### Why This Happened

The original design assumed `PULSE_VERSION` would only be set explicitly by users wanting a specific version:

```bash
PULSE_VERSION=v1.0.0 ./pulse-install.sh
```

But it didn't account for the framework itself exporting the version, which meant **every** installer run after initial installation would have `PULSE_VERSION` set.

## Solution

### Changes Made

**1. Update Logic (`scripts/pulse-install.sh` lines 307-319)**

Before:

```bash
if [ -d "$target_dir/.git" ]; then
  if [ -n "$PULSE_VERSION" ]; then
    # Try to checkout $PULSE_VERSION (fails!)
    git -C "$target_dir" checkout --quiet "$PULSE_VERSION"
  else
    git -C "$target_dir" pull --quiet
  fi
fi
```

After:

```bash
if [ -d "$target_dir/.git" ]; then
  # Always pull latest for updates (ignore PULSE_VERSION)
  print_step "Updating existing Pulse installation..."
  git -C "$target_dir" fetch --quiet
  git -C "$target_dir" pull --quiet
fi
```

**2. Display Logic (`scripts/pulse-install.sh` lines 592-595)**

Before:

```bash
if [ -n "$PULSE_VERSION" ]; then
  print_step "Target version: $PULSE_VERSION"
fi
```

After:

```bash
# Only show version for fresh installs (not updates)
if [ -n "$PULSE_VERSION" ] && [ ! -d "$INSTALL_DIR/.git" ]; then
  print_step "Target version: $PULSE_VERSION"
fi
```

### Behavior After Fix

| Scenario | PULSE_VERSION Set? | Behavior |
|----------|-------------------|----------|
| Fresh install, no env var | ❌ No | Clone `main` branch |
| Fresh install with `PULSE_VERSION=v0.1.0` | ✅ Yes | Clone tag `v0.1.0` |
| Update existing install | ✅ Yes (inherited) | Pull latest (ignore env var) |
| Update with explicit `PULSE_VERSION=v2.0.0` | ✅ Yes | Still pull latest (updates always ignore) |

**Key Principle**: Version selection only applies to **fresh installs**. Updates always pull the latest from the current branch.

## Testing

### Test Results

- ✅ All 47 install tests passing
- ✅ Update with inherited `PULSE_VERSION`: Works
- ✅ Fresh install with `PULSE_VERSION=v0.1.0`: Works
- ✅ Fresh install without version: Works

### Manual Verification

```bash
# Test 1: Update with inherited env var
$ PULSE_VERSION=0.1.0-beta bash scripts/pulse-install.sh
✓ Updating existing Pulse installation...
✓ Installation completed successfully!

# Test 2: Fresh install with specific version
$ PULSE_INSTALL_DIR=/tmp/test PULSE_VERSION=v0.1.0 bash scripts/pulse-install.sh
✓ Target version: v0.1.0
✓ Cloning Pulse repository (version v0.1.0)...
✓ Installation completed successfully!

$ cd /tmp/test && git describe --tags
v0.1.0  # ✓ Correct version installed
```

## User Impact

### Before Fix

- ❌ Updates would fail if Pulse was already sourced
- ❌ Error: "Failed to checkout version 0.1.0-beta"
- ❌ Users had to `unset PULSE_VERSION` before updating

### After Fix

- ✅ Updates work regardless of environment variables
- ✅ Version targeting only applies to fresh installs
- ✅ No workarounds needed

## Related Issues

- Discovered while testing PR #8 installer
- Related to commit 1167f29 (plugin preservation fix)
- Part of installer robustness improvements

## Notes for Future Development

1. **Version Export**: Consider removing `-x` flag from `PULSE_VERSION` in `pulse.zsh` if not needed for child processes
2. **Update Flexibility**: If users need to switch versions on existing installs, add explicit `--version` flag that overrides the "updates always pull latest" logic
3. **Documentation**: Update install docs to clarify version selection behavior
