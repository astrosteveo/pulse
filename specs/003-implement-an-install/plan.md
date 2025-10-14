# Implementation Plan: Pulse Zero-Config Install Script

**Branch**: `003-implement-an-install` | **Date**: 2025-10-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-implement-an-install/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a zero-configuration install script that enables users to install Pulse with a single command, automatically configures their `.zshrc` with correct plugin ordering, validates prerequisites, and provides idempotent upgrade/repair capabilities with automatic rollback on failure.

## Technical Context

**Language/Version**: POSIX shell (sh) with Zsh-specific verification (requires Zsh ≥5.0 on target system)
**Primary Dependencies**: Git (for repository cloning), curl or wget (for script download), coreutils (cp, mv, chmod), sha256sum or shasum (for checksum verification)
**Storage**: File system operations only - writes to `~/.local/share/pulse`, `~/.zshrc`, marker file `.pulse-installed`
**Testing**: bats-core (Bash Automated Testing System) for install script validation, fixture-based integration tests
**Target Platform**: macOS (Darwin), Linux (various distributions), BSD variants (future consideration)
**Project Type**: Single script installer with supporting infrastructure (checksums, documentation, tests)
**Performance Goals**: Complete installation within 2 minutes on typical home broadband, prerequisite checks <5 seconds
**Constraints**: Must work on minimal POSIX systems, no Python/Ruby/Node.js dependencies, network failures must trigger clean rollback
**Scale/Scope**: Single-user workstation installations, idempotent for upgrades, <500 LOC for maintainability

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Radical Simplicity** – Single-command install serves 90% of users (power users get `--verbose` and `PULSE_VERSION` for edge cases), no simpler alternative exists than a shell script for zero-dependency installation
- [x] **Quality Over Features** – POSIX shell best practices enforced, error handling strategy defined (rollback on failure), documentation includes inline comments and user-facing install guide, performance measured against 2-minute target
- [x] **Test-Driven Reliability (ABSOLUTE REQUIREMENT)** – bats-core tests MUST be written first covering: prerequisite detection, idempotent behavior, rollback scenarios, checksum verification, configuration order validation. 100% coverage of critical paths (install, upgrade, rollback). Red-Green-Refactor cycle documented in tasks.
- [x] **Consistent User Experience** – Sensible defaults (latest version, `~/.local/share/pulse`), clear error messages with remediation steps, `--verbose` flag for troubleshooting, automatic rollback prevents broken states, preserves user customizations
- [x] **Zero Configuration** – Works immediately after single command execution, auto-detects prerequisites, auto-fixes incorrect plugin ordering, no manual configuration required, documentation shows correct `plugins` before `pulse.zsh` ordering

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
scripts/
└── pulse-install.sh         # Main install script (POSIX shell)

docs/
└── install/
    ├── QUICKSTART.md         # Installation quick start guide
    └── TROUBLESHOOTING.md    # Common installation issues and solutions

tests/
└── install/
    ├── prerequisites.bats    # Prerequisite detection tests
    ├── foundation.bats       # Core install logic tests
    ├── configuration.bats    # .zshrc modification tests
    ├── orchestration.bats    # End-to-end install workflow tests
    ├── repository.bats       # Git operations and version selection tests
    ├── test_helper.bash      # Shared test utilities and fixtures
    └── fixtures/
        ├── zshrc-templates/  # Various .zshrc configurations for testing
        ├── mock_env.sh       # Mock environment setup
        └── pulse-mock/       # Mock Pulse installation for testing

README.md                     # Must include SHA256 checksum of pulse-install.sh
```

**Structure Decision**: Single project structure with install script in `scripts/`, comprehensive test coverage in `tests/install/`, and installation documentation in `docs/install/`. The install script is standalone and can be downloaded directly or executed via curl/wget piping. Checksum verification requires SHA256 hash published in README.md.

## Complexity Tracking

No constitution violations. All complexity is justified:

- POSIX shell script: Minimal dependency, maximum compatibility
- SHA256 verification: Security requirement, not complexity
- Rollback mechanism: Reliability requirement, not complexity
- Marker files: Simplest state tracking possible

## Post-Phase-1 Constitution Re-Check

✅ **All gates passed after design phase**

- ✅ **Radical Simplicity**: Design maintains single-script approach, marker files are simplest state tracking
- ✅ **Quality Over Features**: POSIX best practices documented in research.md, comprehensive error handling defined
- ✅ **Test-Driven Reliability**: Test structure defined (prerequisites.bats, foundation.bats, configuration.bats, orchestration.bats, repository.bats), fixtures planned, 100% critical path coverage target confirmed
- ✅ **Consistent User Experience**: Default behavior fully specified (latest version, standard paths), error messages defined with remediation steps, rollback ensures no broken states
- ✅ **Zero Configuration**: Single command install confirmed, auto-detection of all prerequisites, auto-fix of configuration order issues
