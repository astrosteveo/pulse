# Quickstart: Pulse Zero-Config Installer

**Feature**: 003-implement-an-install
**Date**: 2025-10-12
**Audience**: Developers implementing the installer script

## Purpose

This quickstart demonstrates the complete installation workflow from the user's perspective and validates that the implementation satisfies all functional requirements and success criteria from the specification.

---

## User Journey: Fresh Installation

### Step 1: Run Installer Command

**User Action**:

```bash
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh | sh
```

**Expected Output**:

```text
=======================================================
  Pulse Zero-Config Framework Installer
=======================================================

[✓] Checking prerequisites...
    ✓ Zsh version: 5.9 (required: ≥5.0)
    ✓ Git: found at /usr/bin/git
    ✓ Install directory: ~/.local/share/pulse (writable)

[✓] Installing Pulse...
    ✓ Cloning repository from https://github.com/astrosteveo/pulse.git
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

**Validation**:

- ✓ Installation completes in <2 minutes (SC-001)
- ✓ No manual edits required (SC-003)

---

### Step 2: Verify Installation

**User Action**:

```bash
# Restart shell
exec zsh

# Check Pulse is loaded
echo $PULSE_VERSION
```

**Expected Output**:

```text
0.1.0
```

**Validation**:

- ✓ Pulse loads automatically without further configuration
- ✓ Environment variables set correctly

---

### Step 3: Inspect Configuration

**User Action**:

```bash
# View Pulse configuration block
sed -n '/# BEGIN Pulse Configuration/,/# END Pulse Configuration/p' ~/.zshrc
```

**Expected Output**:

```bash
# BEGIN Pulse Configuration
# Automatically added by Pulse installer on 2025-10-12
# Learn more: https://github.com/astrosteveo/pulse

# Declare plugins array (add your plugins here)
plugins=(
  # user/repo syntax for GitHub plugins
  # zsh-users/zsh-autosuggestions
  # zsh-users/zsh-syntax-highlighting
)

# Source Pulse framework
source "$HOME/.local/share/pulse/pulse.zsh"

# END Pulse Configuration
```

**Validation**:

- ✓ `plugins` array declared before `source` statement (SC-002, FR-004)
- ✓ Clear inline documentation
- ✓ Delimiter markers present for future updates

---

## User Journey: Re-run (Idempotent Install)

### Step 4: Run Installer Again

**User Action**:

```bash
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh | sh
```

**Expected Output**:

```text
=======================================================
  Pulse Zero-Config Framework Installer
=======================================================

[✓] Checking prerequisites...
    ✓ Zsh version: 5.9 (required: ≥5.0)
    ✓ Git: found at /usr/bin/git
    ✓ Install directory: ~/.local/share/pulse (writable)

[✓] Installing Pulse...
    ✓ Existing installation detected: ~/.local/share/pulse
    ✓ Updating repository from https://github.com/astrosteveo/pulse.git
    ✓ Update complete: ~/.local/share/pulse

[✓] Configuring Zsh...
    ✓ Existing Pulse configuration detected
    ✓ Configuration already correct (no changes needed)

[✓] Verifying installation...
    ✓ Pulse loads successfully in test shell

=======================================================
  Installation Up-to-Date! ✓
=======================================================

Next steps:
  1. Restart your shell: exec zsh

Configuration file: ~/.zshrc
Installation directory: ~/.local/share/pulse
```

**Validation**:

- ✓ Installer detects existing installation (User Story 2)
- ✓ No duplicate configuration blocks added
- ✓ User customizations preserved

---

### Step 5: Verify No Duplication

**User Action**:

```bash
# Count Pulse configuration blocks
grep -c "# BEGIN Pulse Configuration" ~/.zshrc
```

**Expected Output**:

```text
1
```

**Validation**:

- ✓ Idempotency guarantee (only one block)

---

## User Journey: Prerequisite Failure

### Step 6: Simulate Missing Git

**User Action**:

```bash
# Temporarily hide git (simulation)
PATH=/usr/local/bin:/usr/bin:/bin

# Run installer
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh | sh
```

**Expected Output**:

```text
=======================================================
  Pulse Zero-Config Framework Installer
=======================================================

[✗] Checking prerequisites...
    ✓ Zsh version: 5.9 (required: ≥5.0)
    ✗ Git: not found

=======================================================
  Installation Failed ❌
=======================================================

Error: Git is not installed on this system

To fix this issue:
  • macOS: brew install git
  • Ubuntu/Debian: sudo apt-get install git
  • Fedora/RHEL: sudo dnf install git

After installing Git, re-run this installer.

For more help, visit: https://github.com/astrosteveo/pulse/docs/install/TROUBLESHOOTING.md
```

**Validation**:

- ✓ Prerequisite validation runs before file changes (User Story 3, FR-002)
- ✓ Clear actionable guidance provided
- ✓ No partial installation state created

---

## User Journey: Custom Plugin Configuration

### Step 7: Add Plugins to Configuration

**User Action**:

```bash
# Edit .zshrc to add plugins
vim ~/.zshrc
```

**User Modification** (within Pulse block):

```bash
# BEGIN Pulse Configuration
# ...

plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
  romkatv/powerlevel10k
)

# ...
# END Pulse Configuration
```

**Expected Behavior**:

- Pulse loads and automatically clones/manages specified plugins
- No additional configuration required

**Validation**:

- ✓ Zero-configuration promise maintained (Principle V)
- ✓ User customizations work immediately

---

## Developer Testing Scenarios

### Test 1: Fresh Install on Clean System

```bash
# Setup: Clean test environment
docker run -it --rm ubuntu:22.04 bash

# Install Zsh and Git
apt-get update && apt-get install -y zsh git curl

# Run installer
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh | sh

# Verify
zsh -c 'source ~/.zshrc; echo "Pulse loaded: $PULSE_VERSION"'
```

**Success Criteria**: Exit code 0, Pulse version printed

---

### Test 2: Configuration Order Validation

```bash
# After installation
PLUGINS_LINE=$(grep -n "plugins=" ~/.zshrc | head -1 | cut -d: -f1)
SOURCE_LINE=$(grep -n "source.*pulse.zsh" ~/.zshrc | head -1 | cut -d: -f1)

# Assert: plugins before source
[ "$PLUGINS_LINE" -lt "$SOURCE_LINE" ] && echo "✓ Order correct" || echo "✗ Order incorrect"
```

**Success Criteria**: "✓ Order correct" output

---

### Test 3: Idempotency Check

```bash
# First install
./scripts/pulse-install.sh
CHECKSUM1=$(md5sum ~/.zshrc | cut -d' ' -f1)

# Second install
./scripts/pulse-install.sh
CHECKSUM2=$(md5sum ~/.zshrc | cut -d' ' -f1)

# Verify identical
[ "$CHECKSUM1" = "$CHECKSUM2" ] && echo "✓ Idempotent" || echo "✗ Not idempotent"
```

**Success Criteria**: "✓ Idempotent" output

---

### Test 4: Backup Creation

```bash
# Count existing backups
BEFORE=$(ls ~/.zshrc.pulse-backup-* 2>/dev/null | wc -l)

# Run installer
./scripts/pulse-install.sh

# Count new backups
AFTER=$(ls ~/.zshrc.pulse-backup-* 2>/dev/null | wc -l)

# Verify exactly one new backup
[ "$AFTER" -eq $((BEFORE + 1)) ] && echo "✓ Backup created" || echo "✗ Backup missing"
```

**Success Criteria**: "✓ Backup created" output

---

### Test 5: Verification Step

```bash
# Corrupt installation
echo "syntax error" >> ~/.local/share/pulse/pulse.zsh

# Run installer (should fail verification)
./scripts/pulse-install.sh
EXIT_CODE=$?

# Verify failure detected
[ "$EXIT_CODE" -eq 4 ] && echo "✓ Verification works" || echo "✗ Verification failed"
```

**Success Criteria**: Exit code 4, helpful error message

---

## Performance Benchmarks

### Benchmark 1: Total Installation Time

```bash
time (curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh | sh)
```

**Target**: <120 seconds on reference hardware

---

### Benchmark 2: Verification Step

```bash
time (zsh -c "source ~/.zshrc; echo PULSE_OK")
```

**Target**: <10 seconds

---

## Success Metrics Validation

| Metric | Target | Test Command | Pass Criteria |
|--------|--------|--------------|---------------|
| SC-001 | 90% complete in 2 min | `time ./install.sh` | <120s elapsed |
| SC-002 | 100% verify order | `grep plugins ~/.zshrc` before `grep source ~/.zshrc` | plugins line < source line |
| SC-003 | 95% no manual edits | `./install.sh && zsh -c 'echo $PULSE_VERSION'` | Version printed |
| SC-004 | 60% fewer tickets | Manual tracking post-release | Support ticket volume |

---

## Troubleshooting Reference

### Issue: "Configuration already exists"

**Symptom**: Installer warns about existing Pulse block but user wants fresh install

**Solution**:

```bash
# Remove existing block manually
sed -i '/# BEGIN Pulse Configuration/,/# END Pulse Configuration/d' ~/.zshrc

# Re-run installer
./scripts/pulse-install.sh
```

---

### Issue: "Verification failed"

**Symptom**: Installer completes but verification step fails

**Solution**:

```bash
# Restore from backup
cp ~/.zshrc.pulse-backup-TIMESTAMP ~/.zshrc

# Debug with verbose mode
PULSE_DEBUG=1 ./scripts/pulse-install.sh
```

---

### Issue: "Permission denied"

**Symptom**: Cannot write to default install directory

**Solution**:

```bash
# Specify custom install directory
PULSE_INSTALL_DIR=~/my-pulse ./scripts/pulse-install.sh
```

---

## Next Steps

After validating this quickstart:

1. Implement `scripts/pulse-install.sh` following the contracts
2. Write bats tests covering each scenario above
3. Create `docs/install/QUICKSTART.md` based on user journeys
4. Update main README.md with one-command install instruction
