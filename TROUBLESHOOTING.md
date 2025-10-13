# Pulse Troubleshooting Guide

> **Quick Start**: For common issues, see [README.md#troubleshooting](README.md#troubleshooting). This guide covers advanced debugging, profiling, and issue resolution.

---

## Table of Contents

1. [Debugging Workflow](#debugging-workflow)
2. [Using PULSE_DEBUG](#using-pulse_debug)
3. [Performance Profiling](#performance-profiling)
4. [Isolating Module Issues](#isolating-module-issues)
5. [Common Issues (Extended)](#common-issues-extended)
6. [Reporting Bugs](#reporting-bugs)
7. [Advanced Diagnostics](#advanced-diagnostics)

---

## Debugging Workflow

Follow this systematic approach when troubleshooting Pulse:

### Step 1: Enable Debug Mode

```bash
export PULSE_DEBUG=1
exec zsh
```

This reveals:

- Module load times and order
- Plugin detection and loading stages
- File paths being sourced
- Any errors or warnings

### Step 2: Identify the Problem Area

**Is it a module issue?**

- Look for errors in module loading (environment, compinit, completions, keybinds, directory, prompt, utilities)
- Check module load times (should all be <5ms)

**Is it a plugin issue?**

- Check if plugin loaded successfully
- Verify plugin stage assignment (early/defer/path/fpath/completions)
- Look for plugin-specific errors

**Is it a configuration issue?**

- Verify `.zshrc` configuration (variable names, syntax)
- Check for conflicts with other frameworks or configurations

### Step 3: Isolate the Issue

Use the techniques in [Isolating Module Issues](#isolating-module-issues) to narrow down the problem.

### Step 4: Apply Fix or Report Bug

- If it's a configuration issue, adjust your `.zshrc`
- If it's a known issue, see [Common Issues](#common-issues-extended)
- If it's a bug, see [Reporting Bugs](#reporting-bugs)

---

## Using PULSE_DEBUG

The `PULSE_DEBUG` environment variable provides detailed diagnostics:

### Basic Usage

```bash
# Enable debug mode for next shell
export PULSE_DEBUG=1
exec zsh

# Or for a single session
PULSE_DEBUG=1 zsh
```

### What PULSE_DEBUG Shows

**Module Loading:**

```
[pulse] Loading module: environment (0ms)
[pulse] Loading module: compinit (0ms)
[pulse] Loading module: completions (0ms)
...
```

**Plugin Detection:**

```
[pulse] Plugin: zsh-users/zsh-syntax-highlighting
[pulse]   Type: defer (matched pattern: *syntax-highlighting*)
[pulse]   Stage: defer
[pulse]   Path: /home/user/.local/share/pulse/plugins/zsh-syntax-highlighting
```

**Plugin Loading:**

```
[pulse] Sourcing plugin (early): /path/to/plugin/plugin.zsh (42ms)
[pulse] Sourcing plugin (defer): /path/to/plugin/plugin.zsh (89ms)
```

**Errors:**

```
[pulse] ERROR: Plugin not found: user/repo
[pulse] WARNING: Module 'fake-module' not found
```

### Advanced Debug Techniques

**Debug Only Specific Modules:**

Temporarily disable modules to isolate issues:

```zsh
# In .zshrc before sourcing pulse.zsh
pulse_disabled_modules=(prompt utilities)  # Test without these
source /path/to/pulse.zsh
```

**Debug Plugin Loading:**

Test individual plugins:

```zsh
# Minimal .zshrc
plugins=(
  # zsh-users/zsh-autosuggestions  # Comment out others
  zsh-users/zsh-syntax-highlighting  # Test one at a time
)
source /path/to/pulse.zsh
```

---

## Performance Profiling

Pulse includes performance targets (<50ms framework, <500ms with 15 plugins). Here's how to profile your setup:

### Quick Performance Check

```bash
# Measure total startup time
time zsh -i -c 'exit'
```

**Expected results:**

- Framework only: <50ms
- With 5 plugins: <200ms
- With 15 plugins: <500ms

If you're seeing significantly higher times, investigate further.

### Detailed Module Profiling

**Method 1: PULSE_DEBUG with Timing**

```bash
export PULSE_DEBUG=1
exec zsh 2>&1 | grep "Loading module"
```

Output shows per-module times:

```
[pulse] Loading module: environment (0ms)
[pulse] Loading module: compinit (0ms)
[pulse] Loading module: completions (0ms)
...
```

**Method 2: Manual Timing with EPOCHREALTIME**

Add to `.zshrc` before sourcing Pulse:

```zsh
# Start timing
typeset -g _pulse_profile_start=$EPOCHREALTIME

# Source Pulse
source /path/to/pulse.zsh

# Calculate and display total time
typeset -g _pulse_profile_end=$EPOCHREALTIME
typeset -F3 _pulse_profile_total=$(( _pulse_profile_end - _pulse_profile_start ))
echo "Pulse loaded in ${_pulse_profile_total}s"
```

### Plugin Profiling

**Identify Slow Plugins:**

```bash
export PULSE_DEBUG=1
exec zsh 2>&1 | grep "Sourcing plugin" | sort -t'(' -k2 -n
```

This sorts plugins by load time (fastest first). Look for outliers >100ms.

**Solutions for Slow Plugins:**

1. **Move to defer stage** (load after prompt):

   ```zsh
   # In .zshrc
   pulse_plugin_stage[user/slow-plugin]=defer
   ```

2. **Remove unused plugins**: Comment out plugins you don't actively use

3. **Use lazy-loading alternatives**: Some plugins have lightweight alternatives

### Completion System Profiling

**Check completion cache age:**

```bash
stat "${PULSE_CACHE_DIR:-${HOME}/.cache/pulse}/zcompdump"
```

Cache should be <24 hours old for optimal performance. If older, it will auto-rebuild on next startup (~100ms one-time cost).

**Force cache rebuild:**

```bash
rm -f "${PULSE_CACHE_DIR:-${HOME}/.cache/pulse}/zcompdump"
exec zsh
```

### Profiling Results Interpretation

| Component | Target | Action if Exceeded |
|-----------|--------|-------------------|
| Framework modules | <50ms total | Check PULSE_DEBUG for slow modules |
| Individual module | <5ms | Report as performance bug |
| Plugin (typical) | <100ms | Acceptable for full-featured plugins |
| Plugin (heavy) | <200ms | Consider deferring or lazy-loading |
| Completion init (cached) | <1ms | Normal |
| Completion init (rebuild) | <100ms | Normal, happens <1/day |
| Total startup | <500ms (15 plugins) | Profile individual plugins |

---

## Isolating Module Issues

Pulse consists of 7 modules. Here's how to isolate which module is causing issues:

### Step 1: Test with All Modules Disabled

```zsh
# In .zshrc
pulse_disabled_modules=(environment compinit completions keybinds directory prompt utilities)
source /path/to/pulse.zsh
```

If the issue disappears, it's a module problem. If it persists, it's likely plugin-related or external.

### Step 2: Binary Search Approach

Enable modules one at a time to find the culprit:

```zsh
# Test 1: Enable first half
pulse_disabled_modules=(keybinds directory prompt utilities)
source /path/to/pulse.zsh
# If issue appears, problem is in: environment, compinit, or completions
# If no issue, problem is in: keybinds, directory, prompt, or utilities

# Test 2: Narrow down further
pulse_disabled_modules=(compinit completions keybinds directory prompt utilities)
source /path/to/pulse.zsh
# Continue until you isolate the specific module
```

### Step 3: Module-Specific Checks

**Environment Module:**

```bash
# Check for shell option conflicts
setopt | grep -i "hist\|glob\|cd"
```

**Completion Module:**

```bash
# Check completion system status
echo $fpath
compinit -D  # Dump completion info
```

**Keybinds Module:**

```bash
# List all keybindings
bindkey -L
# Check for conflicts
bindkey | grep "^R"  # Check Ctrl+R
```

**Directory Module:**

```bash
# Check directory stack
dirs -v
# Check AUTO_CD
setopt | grep auto_cd
```

**Prompt Module:**

```bash
# Check prompt settings
echo $PROMPT
echo $PULSE_PROMPT_SET
```

**Utilities Module:**

```bash
# Check loaded functions
whence -v pulse_cmd_exists pulse_os pulse_extract
```

### Step 4: Document and Report

Once isolated, see [Reporting Bugs](#reporting-bugs) for how to report the issue with relevant context.

---

## Common Issues (Extended)

For quick common issues, see [README.md#troubleshooting](README.md#troubleshooting). This section covers less common or more complex issues.

### Terminal Color Problems

**Problem**: Colors don't work or display incorrectly.

**Diagnosis:**

```bash
# Check TERM variable
echo $TERM  # Should be xterm-256color or similar

# Check color support
tput colors  # Should output 256 or higher

# Test colors
for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done
```

**Solutions:**

1. **Set TERM correctly** (before sourcing Pulse):

   ```zsh
   export TERM=xterm-256color
   ```

2. **Terminal doesn't support 256 colors**: Use a modern terminal (iTerm2, kitty, Alacritty, GNOME Terminal, etc.)

3. **SSH color issues**:

   ```bash
   # On remote server
   echo $TERM  # Should match local
   # If not, add to ~/.zshrc on server:
   export TERM=xterm-256color
   ```

4. **Disable colors** (if terminal is truly limited):

   ```zsh
   # In .zshrc before Pulse
   pulse_disabled_modules=(prompt)  # Use plain prompt
   ```

### Completion Menu Not Appearing

**Problem**: Tab shows completions as a list, not an interactive menu.

**Diagnosis:**

```bash
# Check completion menu status
zstyle -L ':completion:*:*:*:*:*'
```

**Solutions:**

1. **Menu explicitly disabled**:

   ```zsh
   # After sourcing Pulse, ensure menu is enabled
   zstyle ':completion:*' menu select
   ```

2. **Terminal size too small**: Menu requires enough terminal space. Resize terminal and try again.

3. **Completion module disabled**:

   ```zsh
   # Check if completions disabled
   echo $pulse_disabled_modules
   # If includes 'completions', remove it
   ```

### Function Already Defined Errors

**Problem**: `function definition file not found` or `function already defined` errors.

**Diagnosis:**

```bash
# List all functions
whence -v <function-name>
# Check autoload status
functions +T
```

**Solutions:**

1. **Conflicting plugin or framework**: Load Pulse first or last:

   ```zsh
   # Load Pulse FIRST
   source /path/to/pulse.zsh
   # Then other frameworks
   source /path/to/other-framework.zsh
   ```

2. **Function name collision**: Pulse prefixes all functions with `pulse_` to avoid collisions. If another plugin uses same names, it's a plugin issue.

3. **Stale function cache**: Clear completion cache:

   ```bash
   rm -f "${PULSE_CACHE_DIR:-${HOME}/.cache/pulse}/zcompdump"
   exec zsh
   ```

### Plugin Not Loading (Advanced)

Beyond README troubleshooting, check:

**Check Plugin Structure:**

```bash
# List plugin directory
ls -la "${PULSE_PLUGIN_DIR:-${HOME}/.local/share/pulse/plugins}/user-repo"

# Common patterns Pulse looks for:
# - user-repo.plugin.zsh
# - *.plugin.zsh
# - init.zsh
# - user-repo.zsh
# - *.zsh (as last resort)
```

**Check Plugin Type Detection:**

```bash
export PULSE_DEBUG=1
exec zsh 2>&1 | grep "Plugin: user/repo" -A 3
```

Output shows detected type and stage. If detection is wrong, override:

```zsh
# In .zshrc
pulse_plugin_stage[user/repo]=defer  # Force to defer stage
```

**Check for Circular Dependencies:**

Some plugins expect to be loaded in specific order. Try reordering in `plugins` array.

### Performance Regression

**Problem**: Shell startup was fast, now it's slow.

**Diagnosis:**

1. **Profile to find slow component**:

   ```bash
   export PULSE_DEBUG=1
   time zsh -i -c 'exit'
   ```

2. **Check recent changes**:

   ```bash
   # What plugins added recently?
   ls -lt "${PULSE_PLUGIN_DIR:-${HOME}/.local/share/pulse/plugins}"
   ```

3. **Check completion cache age**:

   ```bash
   stat "${PULSE_CACHE_DIR:-${HOME}/.cache/pulse}/zcompdump"
   ```

**Solutions:**

1. **Identify slow plugin**: See [Plugin Profiling](#plugin-profiling)

2. **Stale cache**: Rebuild if >7 days old (though should auto-rebuild at 24h)

3. **Too many plugins**: Consider removing unused plugins or deferring heavy ones

4. **Disk I/O issues**: Check if plugin directory is on slow storage (NFS, network drive, etc.)

---

## Reporting Bugs

When reporting issues, include the following information to help maintainers diagnose quickly:

### Essential Information

1. **System information**:

   ```bash
   echo "OS: $(uname -s) $(uname -r)"
   echo "Zsh: $ZSH_VERSION"
   echo "Pulse: $(git -C /path/to/pulse rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
   ```

2. **Debug output**:

   ```bash
   export PULSE_DEBUG=1
   zsh -i -c 'exit' 2>&1 | tee pulse-debug.log
   # Attach pulse-debug.log to bug report
   ```

3. **Relevant configuration**:

   ```zsh
   # Sanitize and include from .zshrc:
   # - plugins array
   # - pulse_* variables
   # - Any Pulse-related configuration
   ```

4. **Expected vs. actual behavior**:
   - What you expected to happen
   - What actually happened
   - Steps to reproduce

### Bug Report Template

```markdown
### Bug Description
[Clear description of the issue]

### Steps to Reproduce
1. [First step]
2. [Second step]
3. [Third step]

### Expected Behavior
[What should happen]

### Actual Behavior
[What actually happens]

### System Information
- **OS**: [e.g., Linux 5.15, macOS 13.2]
- **Zsh Version**: [output of `echo $ZSH_VERSION`]
- **Pulse Version**: [output of `git -C /path/to/pulse rev-parse --short HEAD`]
- **Terminal**: [e.g., iTerm2, GNOME Terminal, kitty]

### Configuration
```zsh
# Relevant .zshrc contents
plugins=(
  user/plugin1
  user/plugin2
)
# Any pulse_* variables
```

### Debug Output

```
[Attach output of `PULSE_DEBUG=1 zsh -i -c 'exit' 2>&1`]
```

### Additional Context

[Any other relevant information, screenshots, etc.]

```

### Where to Report

- **GitHub Issues**: [Primary bug tracker - create issue in repository]
- **Discussion Forum**: [For questions/support before filing bug]

### Before Reporting

1. **Search existing issues**: Your issue may already be reported or fixed
2. **Try latest version**: Update Pulse to latest commit
3. **Minimal reproduction**: Test with minimal `.zshrc` to isolate issue
4. **Check common issues**: Review [README Troubleshooting](README.md#troubleshooting) and this guide

---

## Advanced Diagnostics

### Shell State Inspection

**Check loaded modules:**
```bash
echo $pulse_disabled_modules
echo $PULSE_PLUGIN_DIR
echo $PULSE_CACHE_DIR
```

**Check environment:**

```bash
# Should see Pulse-related settings
setopt
zstyle -L
```

**Check completion system:**

```bash
# Completion functions available
echo $fpath
# Completion widgets
zle -L
```

### File System Checks

**Verify plugin directory structure:**

```bash
tree -L 2 "${PULSE_PLUGIN_DIR:-${HOME}/.local/share/pulse/plugins}"
```

**Check permissions:**

```bash
ls -la "${PULSE_PLUGIN_DIR:-${HOME}/.local/share/pulse/plugins}"
ls -la "${PULSE_CACHE_DIR:-${HOME}/.cache/pulse}"
```

**Check disk space:**

```bash
df -h "${PULSE_PLUGIN_DIR:-${HOME}/.local/share/pulse}"
```

### Network Diagnostics (Plugin Installation)

**Test Git connectivity:**

```bash
git ls-remote https://github.com/zsh-users/zsh-syntax-highlighting.git
```

**Check proxy settings:**

```bash
echo $http_proxy
echo $https_proxy
git config --global --get http.proxy
```

### Comparing with Clean Environment

**Test in isolated environment:**

```bash
# Create temporary home
export HOME=$(mktemp -d)

# Minimal .zshrc
cat > $HOME/.zshrc << 'EOF'
plugins=(
  zsh-users/zsh-syntax-highlighting
)
source /path/to/pulse.zsh
EOF

# Test
zsh -i
```

If issue doesn't reproduce in clean environment, it's likely a configuration conflict in your actual `.zshrc`.

### Zsh Internals

**Check for hooks:**

```bash
# List all hooks
typeset -p precmd_functions preexec_functions chpwd_functions
```

**Check for traps:**

```bash
trap
```

**Check for aliases:**

```bash
alias
```

These can interfere with Pulse if improperly configured.

---

## Getting Help

1. **Review documentation**:
   - [README.md](README.md) - Quick start and common issues
   - [PERFORMANCE.md](docs/PERFORMANCE.md) - Performance benchmarks
   - [PLATFORM_COMPATIBILITY.md](docs/PLATFORM_COMPATIBILITY.md) - Platform support

2. **Enable debug mode**: Most issues become clear with `PULSE_DEBUG=1`

3. **Search existing issues**: Check GitHub issues for similar problems

4. **Ask in discussions**: For support questions before filing bugs

5. **Report bugs**: Use the template above with complete information

---

**Note**: This guide covers advanced troubleshooting. For common issues and quick fixes, see [README.md#troubleshooting](README.md#troubleshooting).

**Last Updated**: 2025-01-12 (Pulse v1.0.0-beta)
