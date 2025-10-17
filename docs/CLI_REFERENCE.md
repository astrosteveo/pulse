# Pulse CLI Reference

Complete reference for Pulse command-line interface.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Commands](#commands)
  - [pulse list](#pulse-list)
  - [pulse update](#pulse-update)
  - [pulse doctor](#pulse-doctor)
- [Exit Codes](#exit-codes)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

---

## Overview

The Pulse CLI provides commands for managing plugins and system health:

```bash
pulse [command] [options]
```

**Available Commands:**

- `list` - Show installed plugins
- `update` - Update plugins to latest versions
- `doctor` - Run system diagnostics
- `help` - Show help information
- `--version` - Show version number

---

## Installation

The CLI is automatically installed with Pulse at `~/.local/share/pulse/bin/pulse`.

### Adding to PATH

To use `pulse` from anywhere, add to your PATH:

```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="${HOME}/.local/share/pulse/bin:${PATH}"
```

The installer adds this automatically. To verify:

```bash
which pulse
# Should output: /home/user/.local/share/pulse/bin/pulse (or similar)

pulse --version
# Should output: pulse version 0.3.0
```

---

## Commands

### pulse list

Display all installed plugins in a formatted table.

**Usage:**

```bash
pulse list
```

**Output Format:**

```
┌──────────────────────────┬─────────┬──────────┐
│ PLUGIN                   │ VERSION │ COMMIT   │
├──────────────────────────┼─────────┼──────────┤
│ zsh-autosuggestions      │ latest  │ a411ef3  │
│ zsh-syntax-highlighting  │ v0.8.0  │ 754cefe  │
│ powerlevel10k            │ main    │ 5ce6aef  │
└──────────────────────────┴─────────┴──────────┘

3 plugins installed
```

**Exit Codes:**

- `0` - Success (plugins listed)
- `2` - No lock file found (no plugins installed)

**Notes:**

- Local plugins (no URL) are shown without version information
- Short commit SHA (7 chars) displayed for clarity
- Empty ref shown as "latest" for readability

**Example:**

```bash
$ pulse list
# Shows all installed plugins with version info

$ pulse list --help
# Shows detailed help for list command
```

---

### pulse update

Update plugins to their latest versions.

**Usage:**

```bash
pulse update [plugin-name] [options]
```

**Options:**

- (none) - Update all plugins
- `plugin-name` - Update specific plugin only
- `--force` - Force update, discarding local changes
- `--check-only` - Check for updates without applying

**Behavior:**

- Skips local plugins (no URL)
- Skips plugins with uncommitted changes (unless `--force`)
- Updates lock file with new commit SHAs
- Shows summary: updated/up-to-date/skipped/errors

**Exit Codes:**

- `0` - Success (updates applied or no updates needed)
- `2` - No lock file found (no plugins to update)
- `1` - Update errors occurred (see output)

**Examples:**

```bash
# Update all plugins
$ pulse update
Updating plugins...
✓ zsh-autosuggestions updated (a411ef3 → b522ef4)
• zsh-syntax-highlighting already up to date
⊘ powerlevel10k skipped (local changes)

Summary: 1 updated, 1 up-to-date, 1 skipped, 0 errors

# Update specific plugin
$ pulse update zsh-autosuggestions
✓ zsh-autosuggestions updated (a411ef3 → b522ef4)

# Force update (discard local changes)
$ pulse update --force
Updating plugins (forcing)...
✓ zsh-autosuggestions updated (a411ef3 → b522ef4)
✓ powerlevel10k updated (5ce6aef → 7da8bef) [forced]

# Check for updates without applying
$ pulse update --check-only
Checking for updates...
↑ zsh-autosuggestions has update (a411ef3 → b522ef4)
• zsh-syntax-highlighting up to date

1 update available
```

**Security Warning:**
If a plugin uses SSH URL (`git@github.com:...`) and `github.com` is not in your `~/.ssh/known_hosts`, a warning is shown:

```
⚠ Security Warning: SSH URL without known_hosts entry
  Plugin: zsh-autosuggestions
  URL: git@github.com:zsh-users/zsh-autosuggestions.git

  Consider using HTTPS instead: https://github.com/zsh-users/zsh-autosuggestions.git
  Or add to known_hosts: ssh-keyscan github.com >> ~/.ssh/known_hosts
```

---

### pulse doctor

Run system health checks to diagnose common issues.

**Usage:**

```bash
pulse doctor
```

**Checks Performed:**

1. **Git Availability** (Critical)
   - Verifies Git is installed
   - Checks Git version
   - **Fix:** Install Git via package manager

2. **Network Connectivity** (Optional)
   - Tests connection to github.com
   - **Fix:** Check internet connection

3. **Plugin Directory** (Critical)
   - Verifies `$PULSE_DIR/plugins` exists
   - **Fix:** Directory auto-created if missing

4. **Lock File Validation** (Critical)
   - Checks lock file format
   - Validates all required fields
   - **Fix:** Regenerates corrupted lock file automatically

5. **Plugin Integrity** (Critical)
   - Verifies each plugin is a valid Git repository
   - **Fix:** Re-clone corrupted plugins manually

6. **CLI Installation** (Optional)
   - Checks if CLI is accessible
   - **Fix:** Add to PATH or use full path

7. **PATH Configuration** (Optional)
   - Verifies CLI in PATH
   - **Fix:** Add `~/.local/share/pulse/bin` to PATH

8. **Framework Installation** (Critical)
   - Checks `pulse.zsh` is accessible
   - Looks in standard locations
   - **Fix:** Verify installation path

**Output Format:**

```
Pulse System Diagnostics
========================

[✓] Git available (version 2.39.0)
[~] Network connectivity (github.com) - optional
[✓] Plugin directory exists
[✓] Lock file valid
[✓] All plugins intact (3 plugins)
[✓] CLI installation found
[~] PATH configuration - CLI not in PATH
[✓] Framework installation found

Result: All critical checks passed
Some optional features unavailable - see [~] items above
```

**Symbols:**

- `[✓]` - Check passed
- `[✗]` - Check failed (with suggested fix)
- `[~]` - Optional feature unavailable

**Exit Codes:**

- `0` - All critical checks passed
- `1` - One or more critical checks failed

**Examples:**

```bash
# Run full diagnostic
$ pulse doctor

# Run and save output
$ pulse doctor > diagnosis.txt

# Get help
$ pulse doctor --help
```

---

## Exit Codes

Pulse uses standard exit codes:

| Code | Meaning | Example |
|------|---------|---------|
| `0` | Success | Command completed successfully |
| `1` | Error | Update failed, doctor check failed |
| `2` | Usage Error | Invalid command, missing lock file |

**Usage in Scripts:**

```bash
# Check if updates available
if pulse update --check-only; then
    echo "Updates available"
    pulse update
fi

# Verify system health before deployment
pulse doctor || {
    echo "System checks failed!"
    exit 1
}
```

---

## Examples

### Daily Workflow

```bash
# Morning: Update plugins
pulse update

# Check versions
pulse list
```

### CI/CD Pipeline

```bash
#!/bin/bash
# Ensure Pulse is healthy before tests

set -e

# Verify installation
pulse doctor

# List current versions (for logs)
pulse list

# Update to latest (optional)
pulse update --check-only && pulse update
```

### Troubleshooting

```bash
# Check system health
pulse doctor

# If issues, get detailed info
pulse list

# Try updating
pulse update --force
```

### Version Lock Workflow

```bash
# 1. Install plugins (manual or via .zshrc)
source ~/.local/share/pulse/pulse.zsh

# 2. Check what's installed
pulse list

# 3. Commit plugins.lock for reproducibility
git add ~/.local/share/pulse/plugins.lock
git commit -m "Lock Pulse plugin versions"

# 4. On another machine, restore exact versions
# (Currently: plugins.lock is auto-updated on load)
# (Future: pulse restore command)
```

---

## Troubleshooting

### "pulse: command not found"

**Cause:** CLI not in PATH

**Fix:**

```bash
# Option 1: Add to PATH
export PATH="${HOME}/.local/share/pulse/bin:${PATH}"

# Option 2: Use full path
~/.local/share/pulse/bin/pulse list

# Option 3: Run doctor to verify
~/.local/share/pulse/bin/pulse doctor
```

### "No lock file found"

**Cause:** No plugins have been loaded yet

**Fix:**

```bash
# Load plugins first (in .zshrc)
plugins=(zsh-users/zsh-autosuggestions)
source ~/.local/share/pulse/pulse.zsh

# Then CLI will work
pulse list
```

### "Plugin has local changes"

**Cause:** Plugin directory has uncommitted Git changes

**Fix:**

```bash
# Option 1: Review and commit changes
cd ~/.local/share/pulse/plugins/plugin-name
git diff
git add -A && git commit -m "Local changes"

# Option 2: Force update (discards changes)
pulse update plugin-name --force

# Option 3: Skip this plugin
pulse update other-plugin
```

### "Network connectivity failed"

**Cause:** No internet or GitHub unreachable

**Fix:**

```bash
# Check connection
ping github.com

# Check GitHub status
curl -I https://github.com

# If offline, updates won't work
# But local plugins still function
```

### "Lock file format invalid"

**Cause:** Corrupted `plugins.lock`

**Fix:**

```bash
# Doctor auto-fixes this
pulse doctor

# Or manually regenerate
rm ~/.local/share/pulse/plugins.lock
source ~/.local/share/pulse/pulse.zsh  # Recreates lock file
```

---

## Advanced Usage

### Scripting with Pulse CLI

```bash
#!/usr/bin/env bash
# Example: Update notification script

# Check for updates silently
if pulse update --check-only > /dev/null 2>&1; then
    notify-send "Pulse" "Plugin updates available"
fi
```

### Custom Update Workflow

```bash
#!/usr/bin/env bash
# Update only specific plugin categories

# Update completion plugins
for plugin in $(pulse list | grep completion); do
    pulse update "$plugin"
done
```

### Health Check Automation

```bash
# Add to cron or systemd timer
0 9 * * * /home/user/.local/share/pulse/bin/pulse doctor && \
          /home/user/.local/share/pulse/bin/pulse update --check-only | \
          mail -s "Pulse Daily Report" user@example.com
```

---

## Best Practices

1. **Regular Updates**
   - Run `pulse update` weekly
   - Use `--check-only` to preview

2. **Version Lock in CI**
   - Commit `plugins.lock` to Git
   - Ensures reproducible builds

3. **Health Checks**
   - Run `pulse doctor` when issues arise
   - Add to deployment scripts

4. **Review Changes**
   - Check plugin changelogs before updating
   - Test updates in non-production first

5. **Backup Before Major Updates**

   ```bash
   cp ~/.local/share/pulse/plugins.lock ~/.local/share/pulse/plugins.lock.backup
   pulse update
   ```

---

## See Also

- [README](../README.md) - Main documentation
- [Installation Guide](install/QUICKSTART.md) - Setup instructions
- [Troubleshooting Guide](../TROUBLESHOOTING.md) - Common issues
- [Performance Guide](PERFORMANCE.md) - Optimization tips

---

<div align="center">

**[⬆ Back to Top](#pulse-cli-reference)**

Made with ❤️ by the Pulse community

</div>
