# Quickstart: Polish & Refinement

**Feature**: 004-polish-and-refinement
**Audience**: Users and developers
**Purpose**: Quick examples of new version management and CLI features

---

## 5-Minute User Guide

### Using @latest for Auto-Updates

**Old way** (still works):

```zsh
# .zshrc
plugins=(
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)
```

**New way** (explicit auto-update):

```zsh
# .zshrc
plugins=(
  zsh-users/zsh-syntax-highlighting@latest
  zsh-users/zsh-autosuggestions@latest
)
```

**Result**: Both work identically! `@latest` is self-documenting but optional.

### Checking Installed Plugins

```bash
$ pulse list
PLUGIN                      VERSION    COMMIT
zsh-syntax-highlighting     latest     754cefe
zsh-autosuggestions         v0.7.0     c3d4e57
zsh-completions             main       0.35.0
```

### Updating Plugins

**Update all plugins**:

```bash
$ pulse update
Checking for updates...
zsh-syntax-highlighting: Already up to date (754cefe)
zsh-autosuggestions: Updating v0.7.0 → v0.7.1
  → Pulling changes...
  → Updated to c5d2e8a
zsh-completions: Already up to date (0.35.0)

Summary: 1 updated, 2 up-to-date
```

**Update specific plugin**:

```bash
$ pulse update zsh-autosuggestions
Checking for updates...
zsh-autosuggestions: Updating v0.7.0 → v0.7.1
  → Pulling changes...
  → Updated to c5d2e8a

Summary: 1 updated
```

**Check without updating**:

```bash
$ pulse update --check-only
Checking for updates...
zsh-syntax-highlighting: Up to date (754cefe)
zsh-autosuggestions: Update available (v0.7.0 → v0.7.1)
zsh-completions: Up to date (0.35.0)

1 update available. Run 'pulse update' to install.
```

### Diagnosing Issues

```bash
$ pulse doctor
Running Pulse diagnostics...

[✓] Git availability                 git version 2.39.0
[✓] Network connectivity             github.com reachable
[✓] Plugin directory                 /home/user/.local/share/pulse/plugins
[✓] Lock file validity               3 plugins registered
[✓] Plugin repository integrity      3/3 repositories valid
[✓] CLI installation                 /home/user/.local/bin/pulse
[✓] PATH configuration               ~/.local/bin in PATH
[✓] Configuration syntax             plugins array valid

Diagnostics: 8/8 checks passed
All systems operational!
```

---

## Lock File Workflow

### Automatic Generation

Lock file is **automatically created** on first plugin install:

```bash
# Start fresh shell after configuring plugins
$ zsh

# Pulse installs plugins and creates lock file
[Pulse] Installing zsh-syntax-highlighting...
[Pulse] Installing zsh-autosuggestions...
[Pulse] Generated lock file: ~/.local/share/pulse/pulse.lock
```

### Lock File Contents

View the lock file:

```bash
cat ~/.local/share/pulse/pulse.lock
```

```ini
# Pulse Lock File v1
# Generated: 2025-10-14T15:30:00Z
# DO NOT EDIT MANUALLY - Managed by Pulse

[zsh-syntax-highlighting]
url = https://github.com/zsh-users/zsh-syntax-highlighting.git
ref = latest
commit = 754cefe0181a7acd42fdcb357a67d0217291ac47
timestamp = 2025-10-14T15:29:45Z
stage = defer

[zsh-autosuggestions]
url = https://github.com/zsh-users/zsh-autosuggestions.git
ref = v0.7.0
commit = c3d4e576c9c86eac62884bd47c01f6faed043fc5
timestamp = 2025-10-14T15:29:50Z
stage = defer
```

### Version Pinning Examples

```zsh
# .zshrc - Mix and match version strategies

plugins=(
  # Auto-update (tracks default branch)
  zsh-users/zsh-syntax-highlighting@latest

  # Specific tag (stays on v0.7.0)
  zsh-users/zsh-autosuggestions@v0.7.0

  # Specific branch (tracks develop branch)
  zsh-users/zsh-completions@develop

  # Specific commit (never changes)
  zsh-users/zsh-history-substring-search@754cefe0181a7acd42fdcb357a67d0217291ac47

  # No version (tracks default branch, same as @latest)
  zdharma-continuum/fast-syntax-highlighting
)
```

---

## Developer Guide

### Testing @latest Parsing

```bash
# Unit test
$ bats tests/unit/version_parsing.bats

# Integration test
$ bats tests/integration/version_pinning.bats
```

### Implementing New CLI Command

1. Create command file:

```zsh
# lib/cli/commands/status.zsh

_pulse_cmd_status() {
  echo "Pulse Status Check"
  # Implementation here
}
```

2. Register in dispatcher:

```zsh
# bin/pulse (add to case statement)

case "$command" in
  list) source "${PULSE_LIB}/cli/commands/list.zsh"; _pulse_cmd_list "$@" ;;
  update) source "${PULSE_LIB}/cli/commands/update.zsh"; _pulse_cmd_update "$@" ;;
  doctor) source "${PULSE_LIB}/cli/commands/doctor.zsh"; _pulse_cmd_doctor "$@" ;;
  status) source "${PULSE_LIB}/cli/commands/status.zsh"; _pulse_cmd_status "$@" ;;  # NEW
  *) _pulse_show_help; exit 1 ;;
esac
```

3. Add tests:

```bash
# tests/integration/cli_commands.bats

@test "status command shows plugin status" {
  run pulse status
  assert_success
  assert_output --partial "Pulse Status Check"
}
```

### Lock File Operations

**Read plugin info**:

```zsh
source lib/cli/lib/lock-file.zsh

plugin_commit=$(get_plugin_field "zsh-syntax-highlighting" "commit")
echo "Current commit: $plugin_commit"
```

**Write new entry**:

```zsh
source lib/cli/lib/lock-file.zsh

write_lock_entry \
  "my-plugin" \
  "https://github.com/user/repo.git" \
  "latest" \
  "abc123def456789..." \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  "defer"
```

**Validate lock file**:

```zsh
source lib/cli/lib/lock-file.zsh

if validate_lock_file; then
  echo "Lock file is valid"
else
  echo "Lock file has errors"
fi
```

### Update Check Workflow

```zsh
# Check if plugin needs update
source lib/cli/lib/update-check.zsh

if needs_update "zsh-syntax-highlighting"; then
  echo "Update available!"
  new_commit=$(get_remote_commit "zsh-syntax-highlighting")
  echo "New commit: $new_commit"
fi
```

---

## Common Scenarios

### Scenario 1: Fresh Installation with Version Pinning

**Goal**: Install Pulse with specific plugin versions

```bash
# 1. Install Pulse
curl -fsSL https://raw.githubusercontent.com/pulse-zsh/pulse/main/scripts/pulse-install.sh | sh

# 2. Configure plugins with versions
cat >> ~/.zshrc << 'EOF'
# Pulse plugins
plugins=(
  zsh-users/zsh-syntax-highlighting@latest
  zsh-users/zsh-autosuggestions@v0.7.0
)

source ~/.local/share/pulse/pulse.zsh
EOF

# 3. Start new shell
zsh

# 4. Verify installation
pulse list
```

### Scenario 2: Migrating from Oh-My-Zsh

**Goal**: Replace OMZ with Pulse, keep same plugins

```bash
# 1. Remove OMZ plugins from .zshrc
# 2. Add Pulse with equivalent plugins

cat >> ~/.zshrc << 'EOF'
plugins=(
  zsh-users/zsh-syntax-highlighting@latest
  zsh-users/zsh-autosuggestions@latest
  zsh-users/zsh-completions@latest
)

source ~/.local/share/pulse/pulse.zsh
EOF

# 3. Start new shell (plugins install automatically)
zsh

# 4. Check status
pulse doctor
pulse list
```

### Scenario 3: Updating After Long Time

**Goal**: Update all plugins after not updating for months

```bash
# 1. Check what's available
pulse update --check-only

# 2. Update everything
pulse update

# 3. Restart shell to load new versions
exec zsh
```

### Scenario 4: Fixing Broken Installation

**Goal**: Diagnose and fix issues

```bash
# 1. Run diagnostics
pulse doctor

# If issues found:
# 2. Attempt automatic fixes
pulse doctor --fix

# If still broken:
# 3. Regenerate lock file
rm ~/.local/share/pulse/pulse.lock
zsh  # Will regenerate from installed plugins

# 4. Verify
pulse doctor
```

### Scenario 5: CI/CD with Version Locking

**Goal**: Reproducible builds in CI environment

```bash
# .github/workflows/test.yml

- name: Install Pulse
  run: |
    curl -fsSL https://raw.githubusercontent.com/pulse-zsh/pulse/main/scripts/pulse-install.sh | sh

- name: Configure Pulse
  run: |
    cat >> ~/.zshrc << 'EOF'
    plugins=(
      zsh-users/zsh-syntax-highlighting@754cefe0181a7acd42fdcb357a67d0217291ac47
      zsh-users/zsh-autosuggestions@c3d4e576c9c86eac62884bd47c01f6faed043fc5
    )
    source ~/.local/share/pulse/pulse.zsh
    EOF

- name: Test
  shell: zsh {0}
  run: |
    pulse list
    # Your tests here
```

**Commit lock file** for reproducibility:

```bash
git add ~/.local/share/pulse/pulse.lock
git commit -m "Lock plugin versions for CI"
```

---

## Troubleshooting

### Lock File Not Found

**Symptom**: `pulse list` shows "Lock file not found"

**Solution**:

```bash
# Start a new shell to trigger plugin installation
zsh

# Or manually generate by re-sourcing
source ~/.local/share/pulse/pulse.zsh
```

### Update Check Fails

**Symptom**: `pulse update` shows "Network connectivity issue"

**Solutions**:

```bash
# Check internet connection
curl -Is https://github.com

# Check if SSH keys work (if using SSH URLs)
ssh -T git@github.com

# Use HTTPS URLs instead of SSH
# Edit .zshrc: use https:// instead of git@
```

### CLI Command Not Found

**Symptom**: `zsh: command not found: pulse`

**Solution**:

```bash
# Check if symlink exists
ls -l ~/.local/bin/pulse

# Verify PATH includes ~/.local/bin
echo $PATH | grep ".local/bin"

# If not in PATH, add to .zshrc:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Plugin Version Conflict

**Symptom**: Same plugin declared with different versions

**Solution**:

```bash
# Check configuration
grep "plugin-name" ~/.zshrc

# Keep only one declaration
# Edit .zshrc and remove duplicates

# Regenerate lock file
rm ~/.local/share/pulse/pulse.lock
zsh
```

---

## Best Practices

1. **Use @latest for actively maintained plugins** - Get bug fixes automatically
2. **Pin specific versions for stability** - Use tags for production environments
3. **Run `pulse update --check-only` regularly** - Stay informed about updates
4. **Commit lock file in dotfiles** - Reproducible configurations across machines
5. **Run `pulse doctor` after changes** - Catch issues early
6. **Test updates in development first** - Use `--check-only` before updating production
7. **Keep plugins minimal** - Only install what you actively use
8. **Review plugin updates** - Check changelogs before updating

---

## Next Steps

- Read full specification: `specs/004-polish-and-refinement/spec.md`
- Understand data model: `specs/004-polish-and-refinement/data-model.md`
- Review command contracts: `specs/004-polish-and-refinement/contracts/commands.md`
- Run tests: `bats tests/integration/version_pinning.bats`
- Contribute: Follow TDD workflow in constitution
