# pulse Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-12

## Constitution

All development MUST adhere to the project constitution at `.specify/memory/constitution.md`.

**Core Principles** (v1.1.0):

1. **Radical Simplicity** - Features serve 90% of users; edge cases excluded; every line justified
2. **Quality Over Features** - Zsh conventions, error handling, documentation, performance measurement
3. **Test-Driven Reliability** (NON-NEGOTIABLE) - Tests written FIRST, 100% core coverage, TDD mandatory
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
tests/                 # Test suite (201 tests, 91% passing)
  integration/         # Integration tests (121 tests, 100% passing)
  unit/                # Unit tests (80 tests)
  fixtures/            # Test fixtures
  test_helper.bash     # Test utilities
docs/                  # Documentation
  PERFORMANCE.md       # Performance benchmarks
  PLATFORM_COMPATIBILITY.md  # Cross-platform guide
specs/                 # Feature specifications
  001-build-a-zsh/     # Plugin engine spec
  002-create-the-zsh/  # Framework modules spec
```

## Commands
# Framework functions (all prefixed with pulse_):
- pulse_load_modules() - Load framework modules
- pulse_clone_plugin() - Clone plugin from GitHub
- pulse_load_plugin() - Load plugin based on type
- pulse_cmd_exists() - Check if command exists
- pulse_os() - Detect operating system
- pulse_extract() - Extract archives

## Code Style
- **Zsh conventions**: Use Zsh-specific features (arrays, parameter expansion, builtins)
- **Naming**: All functions prefixed with `pulse_` to avoid collisions
- **Error handling**: Graceful degradation, no breaking failures
- **Performance**: Minimize subshells, prefer builtins over external commands
- **Documentation**: Comments explain complex logic, usage examples in docs
- **Testing**: TDD mandatory, 100% core functionality coverage target

## Recent Changes
- 002-create-the-zsh: Added Zsh (compatible with Zsh 5.0+) + Zsh builtins (compinit, bindkey, setopt, zstyle), POSIX utilities (ls, less)
- 002-create-the-zsh: Added Zsh (compatible with Zsh 5.0+) + Zsh builtins (compinit, bindkey, setopt, zstyle), POSIX utilities (ls, less)
- 002-create-the-zsh: Added Zsh (compatible with Zsh 5.0+) + Zsh builtins (compinit, bindkey, setopt, zstyle), POSIX utilities (ls, less)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
