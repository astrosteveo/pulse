# pulse Development Guidelines

> **Custom instructions for GitHub Copilot coding agent**
> 
> This file provides context to help GitHub Copilot understand the pulse project's architecture, conventions, and development workflow. These instructions apply to all Copilot features including coding agent, chat, and code review.

Auto-generated from all feature plans. Last updated: 2025-10-16

## Quick Reference

**Essential Commands**:
```bash
# Setup
git submodule update --init tests/bats-core

# Test
tests/bats-core/bin/bats tests/integration/*.bats

# Debug
export PULSE_DEBUG=1 && zsh -c 'source pulse.zsh'
```

**Key Principles**: TDD mandatory, <50ms performance target, Zsh ≥5.0, prefix functions with `pulse_`

**See**: [Build and Test](#build-and-test) | [Development Workflow](#development-workflow) | [Constitution](#constitution)

---

## Constitution

All development MUST adhere to the project constitution at `.specify/memory/constitution.md`.

**Core Principles** (v1.2.0):

1. **Radical Simplicity** - Features serve 90% of users; edge cases excluded; every line justified
2. **Quality Over Features** - Zsh conventions MANDATORY (zstyle over env vars, builtins preferred, Zsh ≥5.0), error handling, documentation, performance measurement
3. **Test-Driven Reliability** (ABSOLUTE REQUIREMENT - NOT OPTIONAL) - Tests written FIRST and MUST FAIL before implementation, 100% core coverage, Red-Green-Refactor STRICTLY enforced, zero tolerance policy
4. **Consistent User Experience** - Sensible defaults, no surprises, graceful degradation
5. **Zero Configuration** - Works immediately, smart auto-detection, minimal configuration, documentation always declares `plugins` before sourcing `pulse.zsh`

**Performance Targets**:
- Framework overhead: <50ms total
- Per-module overhead: <30ms
- Completion menu: <100ms response
- Shell startup: <500ms with 15 plugins

## Active Technologies

### Core Runtime
- **Zsh**: Version 5.0+ (tested on 5.9) - primary shell environment
- **Zsh Builtins**: compinit, bindkey, setopt, zstyle, autoload, zle
- **POSIX Utilities**: ls, less, grep, find, stat

### Dependencies
- **Git**: For plugin management (clone, update)
- **curl/wget**: For installer script download
- **coreutils**: Standard file operations (cp, mv, chmod)
- **sha256sum/shasum**: Checksum verification for installer

### Development & Testing
- **Test Framework**: bats-core v1.12.0 (included as submodule)
- **POSIX shell (sh)**: For installer script portability
- **Test Fixtures**: Mock plugins in `tests/fixtures/`

### Data Storage
- **Cache**: zcompdump in $PULSE_CACHE_DIR (~/.cache/pulse)
- **History**: HISTFILE for shell history management
- **Plugin Directory**: `$PULSE_DIR` (default: ~/.local/share/pulse)
- **Lock File**: `$PULSE_DIR/plugins.lock` for version tracking
- **Installation Marker**: `.pulse-installed` in PULSE_DIR

## Framework Modules

Pulse consists of 7 core modules, loaded in order:

1. **environment** (lib/environment.zsh) - Shell options, history, globbing, colors
2. **compinit** (lib/compinit.zsh) - Completion system initialization with caching
3. **completions** (lib/completions.zsh) - Completion menu, fuzzy matching, styles
4. **keybinds** (lib/keybinds.zsh) - Emacs mode, Ctrl+R/S, Alt+B/F navigation
5. **directory** (lib/directory.zsh) - AUTO_CD, directory stack, navigation aliases
6. **prompt** (lib/prompt.zsh) - Minimal default prompt, plugin-friendly
7. **utilities** (lib/utilities.zsh) - Helper functions (pulse_cmd_exists, pulse_os, pulse_extract)

**Module Loading Order**: Modules load sequentially. Each can be disabled via `pulse_disabled_modules` array.

**Performance Characteristics** (validated):
- All modules: <5ms each (sub-millisecond in practice)
- Total framework: ~29ms (target <50ms) ✅
- With 15 plugins: <500ms target ✅

## Plugin Engine

5-stage loading pipeline (lib/plugin-engine.zsh):

1. **early** - Pre-completion setup (PATH/FPATH modifications)
2. **path** - $path modifications
3. **fpath** - $fpath modifications
4. **completions** - Completion definitions
5. **defer** - Post-completion plugins (syntax highlighting, suggestions)

**Plugin Type Detection**: Pattern-based automatic stage assignment
**GitHub Shorthand**: user/repo format supported
**Declarative Config**: `plugins` array in .zshrc

## Project Structure
```
pulse.zsh              # Main entry point
lib/                   # Framework modules
  environment.zsh      # Shell options, history, colors
  compinit.zsh         # Completion initialization
  completions.zsh      # Completion configuration
  keybinds.zsh         # Keybinding setup
  directory.zsh        # Directory navigation
  prompt.zsh           # Prompt setup
  utilities.zsh        # Helper functions
  plugin-engine.zsh    # Plugin loading system
bin/                   # CLI commands
  pulse                # Plugin management CLI
tests/                 # Test suite (273 tests, 100% passing)
  integration/         # Integration tests
  unit/                # Unit tests
  fixtures/            # Test fixtures
  test_helper.bash     # Test utilities
docs/                  # Documentation
  CLI_REFERENCE.md     # Complete CLI documentation
  PERFORMANCE.md       # Performance benchmarks
  PLATFORM_COMPATIBILITY.md  # Cross-platform guide
specs/                 # Feature specifications
  001-build-a-zsh/     # Plugin engine spec
  002-create-the-zsh/  # Framework modules spec
  003-implement-an-install/  # Installer spec
  004-polish-and-refinement/  # Version management & CLI spec
```

## Commands

### CLI Commands (bin/pulse)
- pulse list - Display installed plugins with versions
- pulse update [plugin] [--force] [--check-only] - Update plugins
- pulse doctor - Run system diagnostics
- pulse --help - Show help
- pulse --version - Show version

### Framework Functions (all prefixed with pulse_)
- pulse_load_modules() - Load framework modules
- pulse_clone_plugin() - Clone plugin from GitHub
- pulse_load_plugin() - Load plugin based on type
- pulse_cmd_exists() - Check if command exists
- pulse_os() - Detect operating system
- pulse_extract() - Extract archives

### Lock File Functions (lib/cli/lib/lock-file.zsh)
- pulse_init_lock_file() - Initialize plugins.lock
- pulse_write_lock_entry() - Write/update plugin entry
- pulse_read_lock_entry() - Read plugin entry
- pulse_validate_lock_file() - Validate lock file format

## Code Style
- **Zsh conventions (MANDATORY)**: Use Zsh-specific features (arrays, parameter expansion, builtins), prefer `zstyle` over environment variables for configuration, require Zsh ≥5.0
- **Naming**: All functions prefixed with `pulse_` to avoid collisions
- **Error handling**: Graceful degradation, no breaking failures
- **Performance**: Minimize subshells, prefer builtins over external commands (no `$(...)` when builtins suffice)
- **Documentation**: Comments explain complex logic, usage examples in docs, document Zsh version requirements
- **Testing (ABSOLUTE REQUIREMENT)**: TDD MANDATORY—tests written FIRST and MUST FAIL before implementation, Red-Green-Refactor cycle STRICTLY enforced, 100% core functionality coverage target, pull requests without tests REJECTED without review

## Recent Changes

### v0.2.0 (2025-10)
- **Version Management**: Added plugin version pinning with `@latest`, `@tag`, `@branch` syntax
- **CLI Commands**: Implemented `pulse list`, `pulse update`, `pulse doctor`
- **Lock File**: Plugin version tracking in `plugins.lock`
- **Installer**: One-command install script with checksums and validation
- **Cross-platform**: Enhanced POSIX shell portability for CLI tools

## Build and Test

### Prerequisites
- Zsh ≥5.0 installed
- Git (for submodule management)
- bats-core (included as submodule in `tests/bats-core`)

### Setup Test Environment
```bash
# Initialize bats-core submodule
git submodule update --init tests/bats-core

# Verify bats is working
tests/bats-core/bin/bats --version  # Should output: Bats 1.12.0
```

### Running Tests
```bash
# Run all integration tests
tests/bats-core/bin/bats tests/integration/*.bats

# Run specific test file
tests/bats-core/bin/bats tests/integration/module_loading.bats

# Run specific test suite
tests/bats-core/bin/bats tests/install/*.bats  # Installer tests
```

### Test Organization
- `tests/integration/` - Integration tests for framework features
- `tests/install/` - Installer script tests
- `tests/fixtures/` - Test fixtures and mock data
- `tests/test_helper.bash` - Shared test utilities

### Debug Mode
Enable verbose logging during development:
```bash
export PULSE_DEBUG=1
exec zsh
```

## Development Workflow

### Making Changes

1. **Identify the component**:
   - Framework modules: `lib/*.zsh`
   - Plugin engine: `lib/plugin-engine.zsh`
   - CLI commands: `bin/pulse`, `lib/cli/`
   - Installer: `scripts/pulse-install.sh`

2. **Follow TDD workflow** (MANDATORY):
   - Write tests first (must fail initially)
   - Implement minimal code to pass tests
   - Refactor while keeping tests green

3. **Test your changes**:
   ```bash
   # Run relevant test suite
   tests/bats-core/bin/bats tests/integration/module_loading.bats
   
   # Test in live shell
   export PULSE_DEBUG=1
   zsh -c 'source pulse.zsh'
   ```

4. **Verify performance** (if touching loading pipeline):
   ```bash
   # Check module load times
   export PULSE_DEBUG=1
   zsh -c 'source pulse.zsh' 2>&1 | grep "loaded in"
   ```

### Common Development Tasks

**Adding a new framework module**:
1. Create `lib/new-module.zsh`
2. Add to module list in `pulse.zsh`
3. Write tests in `tests/integration/`
4. Update documentation in `docs/`

**Modifying plugin engine**:
1. Edit `lib/plugin-engine.zsh`
2. Test with multiple plugin types
3. Verify 5-stage pipeline order
4. Check performance impact

**Adding CLI command**:
1. Edit `bin/pulse` or add to `lib/cli/`
2. Write tests in `tests/integration/cli_commands.bats`
3. Update `docs/CLI_REFERENCE.md`

**Fixing bugs**:
1. Write failing test that reproduces bug
2. Fix the issue
3. Verify test passes
4. Check for regressions

### File Locations

**Where to find things**:
- Main entry point: `pulse.zsh`
- Framework modules: `lib/environment.zsh`, `lib/compinit.zsh`, etc.
- Plugin loading: `lib/plugin-engine.zsh`
- CLI tool: `bin/pulse`
- Lock file logic: `lib/cli/lib/lock-file.zsh`
- Installation: `scripts/pulse-install.sh`
- Documentation: `docs/`, `README.md`
- Tests: `tests/integration/`, `tests/install/`

**Where to add things**:
- New completion logic → `lib/completions.zsh`
- New keybindings → `lib/keybinds.zsh`
- Directory navigation → `lib/directory.zsh`
- Helper functions → `lib/utilities.zsh`
- Plugin detection → `lib/plugin-engine.zsh`

## Debugging and Troubleshooting

### Using PULSE_DEBUG
```bash
export PULSE_DEBUG=1
exec zsh
```

Shows:
- Module load times
- Plugin detection results
- Stage assignments
- File paths being sourced

### Common Issues

**Tests failing**: Check if bats-core submodule is initialized
**Module not loading**: Verify module order in `pulse.zsh`
**Plugin not detected**: Check pattern matching in `pulse_detect_plugin_type()`
**Performance regression**: Use PULSE_DEBUG to identify slow modules

### Performance Validation
```bash
# Measure total framework load time
time zsh -c 'source pulse.zsh; exit'

# Should be <50ms for framework only
```

## CI/CD

The repository uses GitHub Actions for CI:
- `.github/workflows/install.yml` - Runs installer tests

Tests run automatically on:
- Pushes to `main` or `**-implement-an-install` branches that modify:
  - `scripts/pulse-install.sh`
  - `tests/install/**`
  - `.github/workflows/install.yml`
- Pull requests that modify the same paths listed above

## Code Review Guidelines

When performing code reviews, follow these guidelines:

### Providing Feedback
- **Always include code suggestions**: When suggesting changes, provide a concrete code suggestion block that can be directly applied
- **Use diff format**: Structure suggestions as diffs showing before/after
- **Be specific**: Point to exact line numbers and provide actionable feedback
- **Offer alternatives**: When possible, suggest multiple approaches with pros/cons

### Code Suggestion Format
For changes that can be automated, use GitHub's suggestion format:
````markdown
```suggestion
// Your suggested code here
```
````

This allows reviewers to apply suggestions with a single click.

### Review Checklist
When reviewing code changes:
- [ ] Code follows project style guide and conventions
- [ ] Functions are prefixed with `pulse_` where appropriate
- [ ] Changes include appropriate tests (TDD principle)
- [ ] No code duplication (extract helper functions)
- [ ] Performance considerations addressed
- [ ] Documentation updated if needed
- [ ] Error handling is present
- [ ] Zsh compatibility maintained (≥5.0)

## Additional Resources

- [CLI Reference](docs/CLI_REFERENCE.md) - Complete CLI documentation
- [Performance Guide](docs/PERFORMANCE.md) - Performance benchmarks
- [Platform Compatibility](docs/PLATFORM_COMPATIBILITY.md) - Cross-platform guide
- [Troubleshooting](TROUBLESHOOTING.md) - Advanced debugging guide
- [Constitution](.specify/memory/constitution.md) - Development principles

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
