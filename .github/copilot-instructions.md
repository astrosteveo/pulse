# pulse Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-16

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
- **Zsh**: Version 5.0+ (tested on 5.9)
- **Zsh Builtins**: compinit, bindkey, setopt, zstyle, autoload, zle
- **POSIX Utilities**: ls, less, grep, find, stat
- **Git**: For plugin management (clone, update)
- **Test Framework**: bats-core v1.12.0
- **Caching**: zcompdump in $PULSE_CACHE_DIR (~/.cache/pulse)
- **History**: HISTFILE for shell history management
- POSIX shell (sh) with Zsh-specific verification (Zsh ≥ 5.0) + Git (for clone/update), curl (fallback wget), coreutils (cp, mv, chmod), bats-core for automated tests (003-implement-an-install)
- N/A (installs into file system under `~/.local/share/pulse`) (003-implement-an-install)
- POSIX shell (sh) with Zsh-specific verification (requires Zsh ≥5.0 on target system) + Git (for repository cloning), curl or wget (for script download), coreutils (cp, mv, chmod), sha256sum or shasum (for checksum verification) (003-implement-an-install)
- File system operations only - writes to `~/.local/share/pulse`, `~/.zshrc`, marker file `.pulse-installed` (003-implement-an-install)
- Zsh ≥5.0 (primary), POSIX shell for CLI portability + Git (for plugin operations), existing plugin-engine.zsh infrastructure (004-polish-and-refinement)
- File-based (lock file in `$PULSE_DIR`, typically `~/.local/share/pulse/plugins.lock`) (004-polish-and-refinement)

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
- 004-polish-and-refinement: Added Zsh ≥5.0 (primary), POSIX shell for CLI portability + Git (for plugin operations), existing plugin-engine.zsh infrastructure
- 004-polish-and-refinement: Added Zsh ≥5.0 (primary), POSIX shell for CLI portability + Git (for plugin operations), existing plugin-engine.zsh infrastructure
- 003-implement-an-install: Added POSIX shell (sh) with Zsh-specific verification (requires Zsh ≥5.0 on target system) + Git (for repository cloning), curl or wget (for script download), coreutils (cp, mv, chmod), sha256sum or shasum (for checksum verification)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
