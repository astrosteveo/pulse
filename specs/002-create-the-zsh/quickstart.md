# Quickstart: Core Zsh Framework Modules

**Feature**: 002-create-the-zsh
**Date**: 2025-10-11
**Purpose**: Quick implementation guide for framework modules

## Implementation Checklist

### Phase 1: P1 Modules (Critical - MVP)

- [ ] **environment.zsh** (5ms target)
  - [ ] Detect and set EDITOR (nvim > vim > vi > nano)
  - [ ] Detect and set PAGER (less with flags > more)
  - [ ] Set history configuration (HISTFILE, HISTSIZE, SAVEHIST)
  - [ ] Set history options (EXTENDED_HISTORY, HIST_IGNORE_ALL_DUPS, SHARE_HISTORY)
  - [ ] Set globbing options (EXTENDED_GLOB, GLOB_DOTS)
  - [ ] Configure LS_COLORS (if dircolors available)
  - [ ] Test: Preserve existing EDITOR/PAGER
  - [ ] Test: Create HISTFILE directory if missing

- [ ] **compinit.zsh** (15ms with cache target)
  - [ ] Set cache file location ($PULSE_CACHE_DIR/zcompdump)
  - [ ] Check cache age (<24 hours = fresh)
  - [ ] Call compinit with -C flag if cache fresh
  - [ ] Call compinit without -C if cache stale
  - [ ] Create cache directory if missing
  - [ ] Test: Cache file created on first run
  - [ ] Test: Cache used on subsequent runs
  - [ ] Test: Stale cache regenerated

- [ ] **completions.zsh** (5ms target)
  - [ ] Set menu selection (zstyle ':completion:*' menu select)
  - [ ] Set case-insensitive matching
  - [ ] Set fuzzy/approximate completion
  - [ ] Set colors (use LS_COLORS)
  - [ ] Set grouping and descriptions
  - [ ] Set completion options (ALWAYS_TO_END, AUTO_MENU, COMPLETE_IN_WORD, LIST_PACKED)
  - [ ] Test: Completion menu appears
  - [ ] Test: Case-insensitive works
  - [ ] Test: Fuzzy matching works

- [ ] **keybinds.zsh** (5ms target)
  - [ ] Set emacs mode as default (bindkey -e)
  - [ ] Bind history search (Ctrl+R, Ctrl+S)
  - [ ] Bind history navigation (arrows, Ctrl+P/N)
  - [ ] Bind line editing (Ctrl+A/E/W/U/K)
  - [ ] Bind word navigation (Alt+arrows, Alt+B/F)
  - [ ] Bind argument insertion (Alt+.)
  - [ ] Test: Ctrl+R triggers history search
  - [ ] Test: Arrows navigate history
  - [ ] Test: Ctrl+A/E moves to line start/end
  - [ ] Test: Alt+. inserts last argument

### Phase 2: P2 Modules (Important)

- [ ] **directory.zsh** (5ms target)
  - [ ] Set AUTO_CD option
  - [ ] Set AUTO_PUSHD option
  - [ ] Set PUSHD_IGNORE_DUPS option
  - [ ] Set PUSHD_SILENT option
  - [ ] Define directory stack alias (d='dirs -v')
  - [ ] Define navigation aliases (.., ..., -='cd -')
  - [ ] Define ls aliases (ls, ll, la) with OS detection
  - [ ] Test: Typing directory name changes to it
  - [ ] Test: cd adds to directory stack
  - [ ] Test: No duplicates in stack
  - [ ] Test: ls aliases work on Linux and macOS

### Phase 3: P3 Modules (Nice to have)

- [ ] **prompt.zsh** (2ms target)
  - [ ] Check if PROMPT already set
  - [ ] Set simple default if not set ('%F{blue}%~%f %# ')
  - [ ] Test: Don't override existing prompt
  - [ ] Test: Default shows directory and user type
  - [ ] Test: Fast render time (<5ms)

- [ ] **utilities.zsh** (3ms target)
  - [ ] Define pulse_has_command function
  - [ ] Define pulse_source_if_exists function
  - [ ] Define pulse_os_type function
  - [ ] Define pulse_extract function
  - [ ] Test: pulse_has_command works correctly
  - [ ] Test: pulse_source_if_exists doesn't error on missing files
  - [ ] Test: pulse_os_type identifies OS correctly
  - [ ] Test: pulse_extract handles common archives

### Phase 4: Integration

- [ ] **Update pulse.zsh**
  - [ ] Add module loading loop after plugin loading
  - [ ] Support pulse_disabled_modules array
  - [ ] Add debug timing if PULSE_DEBUG set
  - [ ] Handle module errors gracefully
  - [ ] Test: All modules load in order
  - [ ] Test: Disabled modules are skipped
  - [ ] Test: One module failure doesn't break others
  - [ ] Test: Debug mode shows timing

- [ ] **Update pulse.zshrc.template**
  - [ ] Add comments explaining framework features
  - [ ] Show how to disable modules
  - [ ] Show how to override defaults
  - [ ] Add examples of user overrides

### Phase 5: Testing

- [ ] **Unit Tests** (one file per module)
  - [ ] tests/unit/environment.bats
  - [ ] tests/unit/compinit.bats
  - [ ] tests/unit/completions.bats
  - [ ] tests/unit/keybinds.bats
  - [ ] tests/unit/directory.bats
  - [ ] tests/unit/prompt.bats
  - [ ] tests/unit/utilities.bats

- [ ] **Integration Tests**
  - [ ] tests/integration/framework_loading.bats
  - [ ] tests/integration/user_overrides.bats
  - [ ] tests/integration/module_disabling.bats

- [ ] **Compatibility Tests**
  - [ ] tests/integration/zsh_versions.bats (5.0, 5.8, 5.9)
  - [ ] tests/integration/cross_platform.bats (Linux, macOS)

- [ ] **Performance Tests**
  - [ ] tests/integration/performance.bats (timing each module)

### Phase 6: Documentation

- [ ] Update README.md with framework features
- [ ] Document all shell options set
- [ ] Document all keybindings
- [ ] Document all environment variables
- [ ] Document how to override defaults
- [ ] Document how to disable modules

---

## Development Workflow

### 1. Set up development environment

```bash
# Clone repo if not already done
cd ~/workspace/pulse

# Ensure on feature branch
git checkout 002-create-the-zsh

# Set up test environment
tests/bats-core/bin/bats --version
```

### 2. Implement one module at a time (TDD)

```bash
# Example: Implementing environment.zsh

# Step 1: Write failing tests
vim tests/unit/environment.bats
# Write tests for EDITOR detection, PAGER detection, history setup

# Step 2: Run tests (they should fail)
tests/bats-core/bin/bats tests/unit/environment.bats

# Step 3: Implement module
vim lib/environment.zsh
# Implement feature to make tests pass

# Step 4: Run tests again (they should pass)
tests/bats-core/bin/bats tests/unit/environment.bats

# Step 5: Check performance
zsh -c 'start=$(($(date +%s%N)/1000000)); source lib/environment.zsh; end=$(($(date +%s%N)/1000000)); echo "Load time: $((end - start))ms"'

# Step 6: Commit
git add tests/unit/environment.bats lib/environment.zsh
git commit -m "feat: implement environment.zsh module"
```

### 3. Test integration after each module

```bash
# After implementing a module, test with existing modules
# Create a test .zshrc:
cat > /tmp/test-pulse-zshrc <<'EOF'
export PULSE_DIR="$HOME/workspace/pulse"
export PULSE_DEBUG=1
source "$PULSE_DIR/pulse.zsh"
EOF

# Start test shell
ZDOTDIR=/tmp zsh -c 'source /tmp/test-pulse-zshrc; echo "Shell ready"; exec zsh'

# Verify:
# - Module loads without errors
# - Timing is acceptable
# - Features work as expected
# - No conflicts with previous modules
```

### 4. Update pulse.zsh loader

```bash
# After implementing modules, update the loader in pulse.zsh
vim pulse.zsh

# Add module loading code (see contracts/modules.md)
# Test the loader:
tests/bats-core/bin/bats tests/integration/framework_loading.bats
```

### 5. Run full test suite

```bash
# Run all tests
tests/bats-core/bin/bats tests/unit/*.bats tests/integration/*.bats

# Check test coverage (all user stories covered)
# Check performance (total < 50ms with cache)
# Check compatibility (works on different Zsh versions)
```

### 6. Update documentation

```bash
# Update README.md
vim README.md
# Add section about framework features
# Document what each module does
# Show examples of user overrides

# Update template
vim pulse.zshrc.template
# Add comments about framework
# Show disable/override examples
```

---

## Quick Reference

### File Structure

```
pulse/
├── lib/
│   ├── plugin-engine.zsh      # Existing from feature 001
│   ├── environment.zsh         # NEW: Environment setup
│   ├── compinit.zsh            # NEW: Completion init
│   ├── completions.zsh         # NEW: Completion styles
│   ├── keybinds.zsh            # NEW: Keybindings
│   ├── directory.zsh           # NEW: Directory navigation
│   ├── prompt.zsh              # NEW: Default prompt
│   └── utilities.zsh           # NEW: Utility functions
├── tests/
│   ├── unit/
│   │   ├── environment.bats    # NEW: Environment tests
│   │   ├── compinit.bats       # NEW: Compinit tests
│   │   ├── completions.bats    # NEW: Completions tests
│   │   ├── keybinds.bats       # NEW: Keybinds tests
│   │   ├── directory.bats      # NEW: Directory tests
│   │   ├── prompt.bats         # NEW: Prompt tests
│   │   └── utilities.bats      # NEW: Utilities tests
│   └── integration/
│       ├── framework_loading.bats       # NEW: Module loading
│       ├── user_overrides.bats          # NEW: Override behavior
│       └── module_disabling.bats        # NEW: Disable modules
├── pulse.zsh                   # MODIFIED: Add module loading
└── pulse.zshrc.template        # MODIFIED: Add framework docs
```

### Module Loading Order

```
1. environment.zsh   (set variables, history, globbing)
2. compinit.zsh      (initialize completion system)
3. completions.zsh   (configure completion styles)
4. keybinds.zsh      (set up keybindings)
5. directory.zsh     (directory navigation, aliases)
6. prompt.zsh        (default prompt if needed)
7. utilities.zsh     (helper functions)
```

### Performance Targets

```
environment.zsh:    <  5ms
compinit.zsh:       < 15ms (with cache)
completions.zsh:    <  5ms
keybinds.zsh:       <  5ms
directory.zsh:      <  5ms
prompt.zsh:         <  2ms
utilities.zsh:      <  3ms
----------------------------
TOTAL:              < 40ms (with cache)
```

### Common Commands

```bash
# Run specific module tests
tests/bats-core/bin/bats tests/unit/environment.bats

# Run all unit tests
tests/bats-core/bin/bats tests/unit/*.bats

# Run all integration tests
tests/bats-core/bin/bats tests/integration/*.bats

# Run all tests
tests/bats-core/bin/bats tests/**/*.bats

# Test shell startup with debug
PULSE_DEBUG=1 zsh -ic exit

# Measure startup time
time zsh -ic exit

# Test specific module in isolation
zsh -c 'source lib/environment.zsh && env | grep -E "(EDITOR|PAGER|HIST)"'
```

### User Override Examples

```zsh
# Disable modules
pulse_disabled_modules=(prompt utilities)

# Override shell options
setopt NO_AUTO_CD                    # After sourcing Pulse

# Override keybindings
bindkey '^R' my-custom-search        # After sourcing Pulse

# Override environment variables
export EDITOR='emacs'                # Before or after Pulse

# Override completion styles
zstyle ':completion:*' menu no       # After sourcing Pulse

# Custom prompt
PROMPT='%~ $ '                       # After sourcing Pulse
```

---

## Troubleshooting

### Module doesn't load

```bash
# Enable debug mode
export PULSE_DEBUG=1
zsh -ic exit

# Check for errors
# Look for "Pulse: Error loading <module>" messages
```

### Performance is slow

```bash
# Time each module
PULSE_DEBUG=1 zsh -ic exit
# Look at individual module times
# Check compinit cache age (might be regenerating)

# Force cache refresh
rm ~/.cache/pulse/zcompdump
zsh -ic exit
```

### Feature not working

```bash
# Check if module is loaded
zsh -c 'echo $fpath | tr " " "\n" | grep pulse'

# Check if option is set
zsh -c 'setopt | grep AUTO_CD'

# Check if binding is set
zsh -c 'bindkey | grep "\\^R"'

# Check if variable is set
zsh -c 'echo $EDITOR'
```

### Tests fail on specific platform

```bash
# Run tests on target platform
# Check OS-specific logic (macOS vs Linux)
# Check Zsh version differences

# Test on specific Zsh version
zsh-5.8 -c 'source pulse.zsh'
```

---

## Next Steps

After implementing this feature:

1. Merge to main branch
2. Update version number (1.0.0 → 1.1.0 MINOR bump)
3. Tag release
4. Update RELEASE_NOTES.md
5. Announce new framework features

Future enhancements (post-MVP):

- Additional utility functions (as needed)
- Optional modules (can be selectively loaded)
- Performance optimizations (if needed)
- Additional keybinding sets (vi mode improvements)
- More completion styles (advanced customization)

---

## Conclusion

This quickstart provides a roadmap for implementing the core framework modules. Follow TDD approach, implement in priority order (P1 → P2 → P3), test thoroughly, and maintain performance targets.

For detailed contracts and behavior, see [contracts/modules.md](contracts/modules.md).
For research and best practices, see [research.md](research.md).
