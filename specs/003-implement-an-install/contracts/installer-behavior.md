# Installer Behavior Contract

**Feature**: 003-implement-an-install  
**Date**: 2025-10-12  
**Purpose**: Define the formal behavioral contract for the Pulse installer script

## Overview

This contract specifies the expected behavior, inputs, outputs, and guarantees of the `pulse-install.sh` script. Implementation MUST conform to these contracts to ensure predictable, safe installation behavior.

## Script Invocation

### Entry Point

```bash
# Standard invocation (recommended)
curl -fsSL https://raw.githubusercontent.com/USER/pulse/main/scripts/pulse-install.sh | sh

# Alternative: download then execute
curl -fsSL https://raw.githubusercontent.com/USER/pulse/main/scripts/pulse-install.sh -o pulse-install.sh
chmod +x pulse-install.sh
./pulse-install.sh
```

### Environment Variables (Optional)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `PULSE_INSTALL_DIR` | String | `~/.local/share/pulse` | Target installation directory |
| `PULSE_ZSHRC` | String | `~/.zshrc` | Path to Zsh configuration file |
| `PULSE_SKIP_BACKUP` | Boolean | `false` | Skip creating backup of `.zshrc` (NOT RECOMMENDED) |
| `PULSE_DEBUG` | Boolean | `false` | Enable verbose diagnostic output |
| `PULSE_SKIP_VERIFY` | Boolean | `false` | Skip post-install verification step |

### Exit Codes

| Code | Meaning | When |
|------|---------|------|
| 0 | Success | Installation completed without errors |
| 1 | Prerequisites failed | Missing Zsh, Git, or permissions |
| 2 | Installation failed | Error during clone/copy operations |
| 3 | Configuration failed | Error modifying `.zshrc` |
| 4 | Verification failed | Post-install verification detected issues |
| 5 | User cancelled | User aborted interactive prompt |

## Behavioral Guarantees

### G1: Idempotency

**Contract**: Running the installer multiple times on the same system MUST produce the same end state without duplicating configuration or corrupting files.

**Implementation Requirements**:

- Detect existing Pulse installation before attempting clone
- Detect existing Pulse block in `.zshrc` before adding new entries
- Update existing installation in-place rather than creating duplicates
- Preserve user modifications within allowed customization zones

**Test Validation**:

```bash
# Run installer twice
./pulse-install.sh
./pulse-install.sh

# Verify: Only one Pulse block in .zshrc
grep -c "# BEGIN Pulse Configuration" ~/.zshrc  # Must equal 1
```

---

### G2: Prerequisite Validation

**Contract**: The installer MUST validate all prerequisites before making any file system changes.

**Prerequisites**:

1. **Zsh Version**: ≥ 5.0
   - Check: `zsh --version | grep -oE '[0-9]+\.[0-9]+' | head -1`
   - Failure: Exit code 1, message directs to Zsh installation docs

2. **Git Availability**: `git` command exists
   - Check: `command -v git >/dev/null 2>&1`
   - Failure: Exit code 1, message suggests `brew install git` or `apt-get install git`

3. **Write Permissions**: Target directory writable or creatable
   - Check: Test write to `$PULSE_INSTALL_DIR` parent or prompt for alternative
   - Failure: Exit code 1, message explains permission issue and workaround

**Implementation Requirements**:

- All checks complete before ANY file operations
- Failed checks output actionable remediation steps
- Exit immediately on fatal prerequisite failure (no partial state)

---

### G3: Configuration Order Enforcement

**Contract**: The installer MUST ensure `plugins` array declaration appears before `source pulse.zsh` in the resulting `.zshrc`.

**Implementation Requirements**:

1. **Detection Phase**: Scan existing `.zshrc` for:
   - Existing Pulse block markers
   - Plugin declarations
   - Source statements

2. **Insertion Phase**: When creating new block:
   - Insert `plugins=()` declaration FIRST
   - Insert `source $PULSE_INSTALL_DIR/pulse.zsh` AFTER plugins
   - Wrap in delimited markers: `# BEGIN Pulse Configuration` / `# END Pulse Configuration`

3. **Validation Phase**: After modification:
   - Parse modified `.zshrc` to confirm order
   - If order incorrect, revert changes and exit with code 3
   - Print warning if order cannot be automatically verified

**Test Validation**:

```bash
# Extract Pulse block
sed -n '/# BEGIN Pulse Configuration/,/# END Pulse Configuration/p' ~/.zshrc > /tmp/pulse-block.txt

# Verify plugins come before source
grep -n "plugins=" /tmp/pulse-block.txt | cut -d: -f1  # Line N
grep -n "source.*pulse.zsh" /tmp/pulse-block.txt | cut -d: -f1  # Line M
# Assert: N < M
```

---

### G4: Backup Creation

**Contract**: Before modifying `.zshrc`, the installer MUST create a timestamped backup unless explicitly skipped.

**Implementation Requirements**:

- Backup path: `~/.zshrc.pulse-backup-$(date +%Y%m%d-%H%M%S)`
- Backup created via `cp -p` to preserve permissions
- If backup fails, prompt user to continue or abort
- Backup path printed to stdout for user reference

**Test Validation**:

```bash
# Before install, count backups
BEFORE=$(ls ~/.zshrc.pulse-backup-* 2>/dev/null | wc -l)

# Run installer
./pulse-install.sh

# After install, verify new backup created
AFTER=$(ls ~/.zshrc.pulse-backup-* 2>/dev/null | wc -l)
[ $AFTER -eq $((BEFORE + 1)) ]  # Must be exactly one more backup
```

---

### G5: Verification Step

**Contract**: After installation, the installer MUST verify Pulse loads correctly in a subshell.

**Implementation Requirements**:

- Launch test subshell: `zsh -c "source ~/.zshrc; echo PULSE_OK"`
- Capture exit code and output
- If verification fails (non-zero exit or missing "PULSE_OK"):
  - Print diagnostic output
  - Suggest checking backup and running with `PULSE_DEBUG=1`
  - Exit with code 4
- If verification succeeds: Print success message with next steps

**Test Validation**:

```bash
# Simulate verification failure by corrupting pulse.zsh
echo "syntax error" >> ~/.local/share/pulse/pulse.zsh

# Re-run installer (should detect corruption)
./pulse-install.sh
EXIT_CODE=$?

# Verify: Exit code 4 and helpful error message printed
[ $EXIT_CODE -eq 4 ]
```

---

## Output Contract

### Standard Output Format

```text
=======================================================
  Pulse Zero-Config Framework Installer
=======================================================

[✓] Checking prerequisites...
    ✓ Zsh version: 5.9 (required: ≥5.0)
    ✓ Git: found at /usr/bin/git
    ✓ Install directory: ~/.local/share/pulse (writable)

[✓] Installing Pulse...
    ✓ Cloning repository from https://github.com/USER/pulse.git
    ✓ Installation complete: ~/.local/share/pulse

[✓] Configuring Zsh...
    ✓ Backup created: ~/.zshrc.pulse-backup-20251012-143022
    ✓ Added Pulse configuration block to ~/.zshrc
    ✓ Verified configuration order (plugins before source)

[✓] Verifying installation...
    ✓ Pulse loads successfully in test shell

=======================================================
  Installation Complete! 🎉
=======================================================

Next steps:
  1. Restart your shell: exec zsh
  2. Verify Pulse is loaded: echo $PULSE_VERSION
  3. Read the quickstart: cat ~/.local/share/pulse/README.md

Configuration file: ~/.zshrc
Installation directory: ~/.local/share/pulse
Backup location: ~/.zshrc.pulse-backup-20251012-143022
```

### Error Output Format

```text
=======================================================
  Pulse Installation Failed ❌
=======================================================

Error: Git is not installed on this system

To fix this issue:
  • macOS: brew install git
  • Ubuntu/Debian: sudo apt-get install git
  • Fedora/RHEL: sudo dnf install git

After installing Git, re-run this installer.

For more help, visit: https://github.com/USER/pulse/docs/install/TROUBLESHOOTING.md
```

---

## Security Considerations

### S1: Input Validation

- All user-provided paths (e.g., `PULSE_INSTALL_DIR`) MUST be validated to prevent path traversal
- Reject paths containing `..`, leading `/`, or other unsafe patterns
- Canonicalize paths using `realpath` or equivalent before use

### S2: Safe File Operations

- Use atomic operations where possible (write to temp, then move)
- Never use `eval` on user input or external data
- Quote all variable expansions to prevent word splitting

### S3: Privilege Escalation

- Script MUST NOT require or request root/sudo privileges
- If installation location requires elevated permissions, prompt user to change location
- Document alternative installation paths that don't require root

---

## Extensibility

### Future Considerations

- Plugin pre-configuration: Allow environment variables to specify initial plugins
- Remote configuration: Support fetching starter `.zshrc` templates
- Silent mode: Non-interactive installation for CI/automation scenarios
- Update mode: Dedicated path for in-place framework updates

**Constraint**: All extensions MUST maintain backward compatibility with basic one-command installation.
