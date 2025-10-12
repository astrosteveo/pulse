# pulse Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-11

## Constitution

All development MUST adhere to the project constitution at `.specify/memory/constitution.md`.

**Core Principles** (v1.0.0):

1. **Radical Simplicity** - Features serve 90% of users; edge cases excluded; every line justified
2. **Quality Over Features** - Zsh conventions, error handling, documentation, performance measurement
3. **Test-Driven Reliability** (NON-NEGOTIABLE) - Tests written FIRST, 100% core coverage, TDD mandatory
4. **Consistent User Experience** - Sensible defaults, no surprises, graceful degradation
5. **Zero Configuration** - Works immediately, smart auto-detection, minimal configuration

**Performance Targets**:
- Framework overhead: <50ms total
- Per-module overhead: <30ms
- Completion menu: <100ms response
- Shell startup: <500ms with 15 plugins

## Active Technologies
- Zsh (compatible with Zsh 5.0+) + Zsh builtins, POSIX utilities, Git (for plugin management) (001-build-a-zsh)
- Zsh (compatible with Zsh 5.0+) + Zsh builtins (compinit, bindkey, setopt, zstyle), POSIX utilities (ls, less) (002-create-the-zsh)
- Cache files (zcompdump in $PULSE_CACHE_DIR), HISTFILE for shell history (002-create-the-zsh)

## Project Structure
```
src/
tests/
```

## Commands
# Add commands for Zsh (compatible with Zsh 5.0+)

## Code Style
Zsh (compatible with Zsh 5.0+): Follow standard conventions

## Recent Changes
- 002-create-the-zsh: Added Zsh (compatible with Zsh 5.0+) + Zsh builtins (compinit, bindkey, setopt, zstyle), POSIX utilities (ls, less)
- 001-build-a-zsh: Added Zsh (compatible with Zsh 5.0+) + Zsh builtins, POSIX utilities, Git (for plugin management)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
