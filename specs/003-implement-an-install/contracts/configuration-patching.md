# Configuration Patching Contract

**Feature**: 003-implement-an-install  
**Date**: 2025-10-12  
**Purpose**: Define the formal contract for modifying user `.zshrc` files during installation

## Overview

The installer must safely modify the user's `.zshrc` to bootstrap Pulse while preserving existing configuration. This contract specifies the exact transformation rules, detection logic, and safety guarantees.

## Detection Phase

### Scan for Existing Pulse Block

**Pattern**: Look for delimiter comments

```bash
# BEGIN Pulse Configuration
... (existing Pulse config)
# END Pulse Configuration
```

**Implementation**:

```bash
has_pulse_block() {
  grep -q "# BEGIN Pulse Configuration" "$PULSE_ZSHRC"
}
```

**Decision Tree**:

- Block found → **Update Mode** (preserve user edits within block)
- Block not found → **Insert Mode** (add new block)

---

### Detect Existing Plugin Declarations

**Patterns to detect**:

```bash
plugins=()                    # Empty array
plugins=(git docker)          # Populated array  
plugins+=(something)          # Append syntax
```

**Implementation**:

```bash
has_plugins_declaration() {
  grep -q "^[[:space:]]*plugins=" "$PULSE_ZSHRC"
}
```

**Purpose**: Avoid duplicating plugin array declaration if user already has one

---

### Detect Conflicting Frameworks

**Known frameworks**:

- Oh My Zsh: `source $ZSH/oh-my-zsh.sh`
- Prezto: `source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"`
- Antigen: `antigen apply`

**Action**:

- If detected → Print warning about potential conflicts
- Suggest manual integration guidance in docs
- Do NOT automatically modify framework configurations

---

## Insertion Phase

### Insert Mode (No Existing Pulse Block)

**Algorithm**:

1. **Determine insertion point**:
   - Prefer: After existing `plugins=()` declaration (if present)
   - Fallback: End of file

2. **Generate Pulse block**:

```bash
# Template for new installation
cat >> "$PULSE_ZSHRC" << 'EOF'

# BEGIN Pulse Configuration
# Automatically added by Pulse installer on $(date -I)
# Learn more: https://github.com/USER/pulse

# Declare plugins array (add your plugins here)
plugins=(
  # user/repo syntax for GitHub plugins
  # zsh-users/zsh-autosuggestions
   # zsh-users/zsh-syntax-highlighting
)

# Source Pulse framework
source "$HOME/.local/share/pulse/pulse.zsh"

# END Pulse Configuration
EOF
```

1. **Verify insertion**:
   - Read modified file
   - Confirm block markers present
   - Confirm configuration order correct

---

### Update Mode (Existing Pulse Block Found)

**Contract**: Preserve user modifications within the Pulse block while ensuring structural correctness.

**Algorithm**:

1. **Extract current block**:

```bash
sed -n '/# BEGIN Pulse Configuration/,/# END Pulse Configuration/p' "$PULSE_ZSHRC" > /tmp/pulse-block.txt
```

1. **Validate structure**:
   - Check: `plugins=` appears before `source.*pulse.zsh`
   - Check: Source path matches current installation directory

1. **Update if needed**:
   - If source path wrong → Update to current `$PULSE_INSTALL_DIR`
   - If order wrong → Rebuild block with corrected order
   - If structure valid → No changes (idempotent)

1. **Preserve user content**:
   - Keep user's plugin list intact
   - Keep user's custom comments/variables within block
   - Only modify structural elements (paths, order)

**Example Transformation**:

**Before** (wrong order):

```bash
# BEGIN Pulse Configuration
source "$HOME/.local/share/pulse/pulse.zsh"  # WRONG: source before plugins
plugins=(zsh-users/zsh-autosuggestions)
# END Pulse Configuration
```

**After** (corrected):

```bash
# BEGIN Pulse Configuration
plugins=(zsh-users/zsh-autosuggestions)      # FIXED: plugins first
source "$HOME/.local/share/pulse/pulse.zsh"
# END Pulse Configuration
```

---

## Safety Guarantees

### SG1: Atomic Updates

**Contract**: Configuration changes are atomic—either complete successfully or leave original file unchanged.

**Implementation**:

1. Copy original to temporary location
2. Modify temporary copy
3. Validate modified copy
4. If validation passes → `mv temp original`
5. If validation fails → Restore from temp, report error

```bash
cp "$PULSE_ZSHRC" "$PULSE_ZSHRC.tmp"
# ... apply modifications to .tmp file ...
if validate_zshrc "$PULSE_ZSHRC.tmp"; then
  mv "$PULSE_ZSHRC.tmp" "$PULSE_ZSHRC"
else
  rm "$PULSE_ZSHRC.tmp"
  error "Configuration validation failed"
fi
```

---

### SG2: Backup Before Modification

**Contract**: Original `.zshrc` is backed up before ANY modification attempts.

**Implementation**:

```bash
BACKUP_PATH="$HOME/.zshrc.pulse-backup-$(date +%Y%m%d-%H%M%S)"
cp -p "$PULSE_ZSHRC" "$BACKUP_PATH"
echo "Backup created: $BACKUP_PATH"
```

**Rollback Instructions** (printed on failure):

```text
To restore your original configuration:
  cp ~/.zshrc.pulse-backup-TIMESTAMP ~/.zshrc
  exec zsh
```

---

### SG3: Preserve User Sections

**Contract**: Content outside Pulse block markers MUST remain unchanged.

**Implementation Strategy**:

- Use sed/awk to extract lines before/after Pulse block
- Reconstruct file: `[before] + [new_pulse_block] + [after]`
- Never use global find/replace that could affect user code

**Test Validation**:

```bash
# User adds custom content
echo "export MY_VAR=123" >> ~/.zshrc

# Run installer
./pulse-install.sh

# Verify user content preserved
grep -q "export MY_VAR=123" ~/.zshrc  # Must still exist
```

---

### SG4: Configuration Order Validation

**Contract**: After modification, installer MUST verify `plugins` declaration precedes `source pulse.zsh`.

**Implementation**:

```bash
validate_config_order() {
  local config_file="$1"
  
  # Extract line numbers
  local plugins_line=$(grep -n "plugins=" "$config_file" | head -1 | cut -d: -f1)
  local source_line=$(grep -n "source.*pulse.zsh" "$config_file" | head -1 | cut -d: -f1)
  
  # Both must exist
  [ -z "$plugins_line" ] && return 1
  [ -z "$source_line" ] && return 1
  
  # plugins must come before source
  [ "$plugins_line" -lt "$source_line" ] && return 0
  
  return 1
}
```

**On Validation Failure**:

- Restore from backup
- Print error explaining the issue
- Exit with code 3

---

## Edge Cases

### EC1: No `.zshrc` File

**Scenario**: User has never created a `.zshrc` (defaults to system `/etc/zshrc`)

**Action**:

1. Create new `~/.zshrc` with Pulse block as only content
2. Print message: "Created new ~/.zshrc with Pulse configuration"
3. Remind user that per-user config now takes precedence

---

### EC2: `.zshrc` is Symlink

**Scenario**: `~/.zshrc` is a symlink to a dotfiles repo

**Action**:

1. Detect symlink: `[ -L "$PULSE_ZSHRC" ]`
2. Resolve real path: `REAL_PATH=$(readlink -f "$PULSE_ZSHRC")`
3. Print warning: "Detected symlink; modifying target: $REAL_PATH"
4. Ask user to confirm or specify alternative path
5. Modify real target (preserves symlink)

---

### EC3: Sourced Configuration Files

**Scenario**: User's `.zshrc` sources other files (e.g., `source ~/.zsh/plugins.zsh`)

**Action**:

1. Add Pulse block to main `~/.zshrc` (don't follow sourced files)
2. Print note: "If you manage plugins elsewhere, add Pulse block to that file manually"
3. Provide example in documentation

---

### EC4: Conflicting Plugin Managers

**Scenario**: User has Oh My Zsh or Prezto already configured

**Action**:

1. Detect OMZ/Prezto initialization
2. Print warning: "Detected [framework]; Pulse may conflict with its plugin system"
3. Suggest: "Consider migrating plugins to Pulse or using Pulse alongside [framework]"
4. Continue installation (don't block) but document integration patterns

---

## Validation Rules

### VR1: Syntax Checking

**Contract**: Modified `.zshrc` must be syntactically valid Zsh.

**Implementation**:

```bash
zsh -n "$PULSE_ZSHRC"  # Parse without executing
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  error "Configuration has syntax errors; restoring backup"
  restore_backup
  exit 3
fi
```

---

### VR2: Idempotency Testing

**Contract**: Running configuration patch twice produces identical output.

**Test**:

```bash
# First run
./pulse-install.sh
md5sum ~/.zshrc > /tmp/checksum1.txt

# Second run
./pulse-install.sh
md5sum ~/.zshrc > /tmp/checksum2.txt

# Verify identical
diff /tmp/checksum1.txt /tmp/checksum2.txt  # Must be empty
```

---

## Documentation Requirements

Every configuration modification MUST be accompanied by:

1. **Inline comments** explaining what Pulse block does
2. **Header timestamp** showing when installer ran
3. **Restoration instructions** in error messages
4. **Manual configuration guide** in docs/install/ for advanced users

**Example Header**:

```bash
# BEGIN Pulse Configuration
# Added by Pulse installer on 2025-10-12
# Installation directory: ~/.local/share/pulse
# To uninstall: Remove this block and restart shell
# Documentation: https://github.com/USER/pulse/docs/install/
```

---

## Success Criteria

Configuration patching is successful when:

- ✓ Backup created before modification
- ✓ Pulse block inserted with correct structure
- ✓ `plugins` declaration precedes `source pulse.zsh`
- ✓ User content outside block preserved exactly
- ✓ Modified file passes syntax validation
- ✓ Verification subshell loads without errors
- ✓ Re-running installer produces no additional changes
