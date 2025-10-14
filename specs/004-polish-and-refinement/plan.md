# Implementation Plan: Polish & Refinement

**Branch**: `004-polish-and-refinement` | **Date**: 2025-10-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-polish-and-refinement/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature adds polish and refinement to the Pulse framework through five key enhancements: (1) explicit `@latest` keyword support for plugin version specifications, (2) command-line interface tools for plugin management (`pulse list`, `pulse update`, `pulse doctor`), (3) automatic version lock file generation for reproducible environments, (4) on-demand update checking to discover outdated plugins, and (5) comprehensive documentation of version management features. The implementation extends the existing plugin engine with `@latest` parsing, creates an optional standalone CLI binary, implements lock file generation/reading, and adds git-based update checking—all while maintaining 100% backward compatibility with existing configurations.

## Technical Context

**Language/Version**: Zsh ≥5.0 (primary), POSIX shell for CLI portability
**Primary Dependencies**: Git (for plugin operations), existing plugin-engine.zsh infrastructure
**Storage**: File-based (lock file in `$PULSE_DIR`, typically `~/.local/share/pulse/plugins.lock`)
**Testing**: bats-core v1.12.0 (existing test infrastructure)
**Target Platform**: Linux, macOS, BSD variants (cross-platform Zsh environments)
**Project Type**: Single project (extends existing Pulse framework)
**Performance Goals**: CLI operations <2 seconds, lock file parsing <10ms, update checks <5 seconds
**Constraints**: Zero external dependencies beyond git, 100% backward compatibility, CLI must be optional
**Scale/Scope**: Support 10-50 plugins per user, lock file <100KB, CLI handles typical configurations efficiently

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Radical Simplicity** – Core features (version pinning, CLI list/update/doctor) serve 90% of users; CLI is optional (doesn't add complexity to framework); lock file is informational (framework works without it); semver constraints explicitly excluded as Phase 2
- [x] **Quality Over Features** – Zsh builtins used for parsing and file operations; CLI uses standard Zsh conventions; error handling defined (graceful degradation, offline support); documentation includes README updates and CLI help; performance measured (CLI <2s, lock parsing <10ms); Zsh ≥5.0 documented
- [x] **Test-Driven Reliability (ABSOLUTE REQUIREMENT)** – Tests MUST be written first for: `@latest` parsing, CLI commands (list/update/doctor), lock file generation/reading, update checking; Red-Green-Refactor cycle documented in tasks.md; coverage targets: 100% for version parsing and lock file operations, 90% for CLI commands; test environments: bats-core with fixtures for multiple plugin scenarios
- [x] **Consistent User Experience** – Backward compatible (`@latest` optional, omitting `@` still works); CLI is opt-in enhancement; lock file warnings only in debug mode; error messages include remediation steps; zero breaking changes to existing configs
- [x] **Zero Configuration** – `@latest` works immediately without configuration; CLI available after installation without setup; lock file generated automatically; existing configurations continue working without modification

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── plugin-engine.zsh       # EXTEND: Add @latest parsing logic
└── utilities.zsh           # EXTEND: Add lock file read/write functions

bin/
└── pulse                   # NEW: CLI entry point

lib/cli/                    # NEW: CLI implementation
├── commands/
│   ├── list.zsh           # NEW: pulse list command
│   ├── update.zsh         # NEW: pulse update command
│   └── doctor.zsh         # NEW: pulse doctor command
└── lib/
    ├── lock-file.zsh      # NEW: Lock file operations
    └── update-check.zsh   # NEW: Update checking logic

tests/
├── integration/
│   ├── cli_commands.bats         # NEW: CLI integration tests
│   ├── version_pinning.bats      # NEW: @latest and version pinning tests
│   └── lock_file_workflow.bats   # NEW: Lock file generation/restore tests
└── unit/
    ├── version_parsing.bats      # NEW: @latest parsing unit tests
    └── lock_file_format.bats     # NEW: Lock file read/write unit tests

docs/
├── README.md                      # UPDATE: Add version pinning examples
└── CLI_REFERENCE.md              # NEW: Command-line interface documentation

scripts/
└── pulse-install.sh              # UPDATE: Install bin/pulse to PATH
```

**Structure Decision**: Single project extension - this feature builds on existing Pulse infrastructure. Core changes extend `lib/plugin-engine.zsh` for `@latest` support and `lib/utilities.zsh` for lock file operations. New CLI tooling is isolated in `bin/pulse` and `lib/cli/` to keep it optional. Tests follow existing structure (bats-core in `tests/integration` and `tests/unit`). Lock file stored at runtime in `$PULSE_DIR/plugins.lock` (typically `~/.local/share/pulse/plugins.lock`).

## Complexity Tracking

No constitution violations - all checks passed. This feature:

- Serves 90%+ of users (version pinning, plugin management, reproducibility)
- Maintains radical simplicity (CLI is optional, lock file is informational)
- Zero configuration required (everything works automatically)
- 100% backward compatible (no breaking changes)
