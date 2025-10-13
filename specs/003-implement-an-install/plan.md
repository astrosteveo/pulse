# Implementation Plan: Pulse Zero-Config Install Script

**Branch**: `003-implement-an-install` | **Date**: 2025-10-12 | **Spec**: [specs/003-implement-an-install/spec.md](spec.md)
**Input**: Feature specification from `/specs/003-implement-an-install/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Deliver a one-command installer that bootstraps Pulse on macOS and Linux without manual configuration. The script will be POSIX-compliant, validate prerequisites, manage the Pulse checkout, update `.zshrc` while preserving custom sections, and verify that `plugins` precede `source pulse.zsh` to honor the zero-configuration principle.

## Technical Context

**Language/Version**: POSIX shell (sh) with Zsh-specific verification (Zsh ≥ 5.0)
**Primary Dependencies**: Git (for clone/update), curl (fallback wget), coreutils (cp, mv, chmod), bats-core for automated tests
**Storage**: N/A (installs into file system under `~/.local/share/pulse`)
**Testing**: bats-core integration tests executed via `tests/install/*.bats`
**Target Platform**: macOS (Intel/ARM) and Linux distributions with Zsh available (including WSL)
**Project Type**: Shell utility (installer script plus documentation)
**Performance Goals**: Installation completes within 120 seconds on reference hardware, verification step <10 seconds
**Constraints**: Must not require root privileges; preserve existing `.zshrc`; handle offline failure gracefully with actionable messaging
**Scale/Scope**: Single installer script with supporting docs/tests; impacts `scripts/`, `docs/`, and `tests/install/`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Initial Check (Pre-Phase 0)**:

- [x] **Radical Simplicity** – One-command installer covers majority use cases; script favors safe defaults and minimizes prompts.
- [x] **Quality Over Features** – Plan includes prerequisite validation, structured logging, and updated docs describing installer behavior.
- [x] **Test-Driven Reliability** – bats-core tests will be authored before implementation to exercise fresh install, re-run, and failure scenarios.
- [x] **Consistent User Experience** – Script outputs consistent messaging, preserves user customizations, and documents rollback instructions.
- [x] **Zero Configuration** – Installer enforces plugin-before-source ordering and verifies zero-touch startup, with fallback guidance if automated edits fail.

**Post-Phase 1 Re-validation (Design Complete)**:

- [x] **Radical Simplicity** – Contracts define single-purpose behaviors (prerequisite check, configuration patch, verification); quickstart validates 90% use case coverage.
- [x] **Quality Over Features** – Configuration patching contract includes comprehensive error handling, atomic updates, and rollback procedures; installer behavior contract documents all exit codes and error messages.
- [x] **Test-Driven Reliability** – Quickstart provides test scenarios for fresh install, idempotency, prerequisite failure, and verification; contracts specify validation rules that will drive test implementation.
- [x] **Consistent User Experience** – Output contracts ensure consistent formatting, helpful error messages with remediation steps, and clear next-step guidance; configuration patching preserves user customizations.
- [x] **Zero Configuration** – Configuration order validation enforced in patching contract (SG4); quickstart test validates plugins-before-source in Test 2; documentation requirements mandate inline guidance.

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
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
scripts/
└── pulse-install.sh          # New installer entry point (invoked via curl|sh)

docs/
└── install/
  ├── QUICKSTART.md        # User-facing install instructions (mirrors script flow)
  └── TROUBLESHOOTING.md   # Common failure remediation steps

tests/
└── install/
  ├── fresh_install.bats   # Ensures clean environment bootstrap works
  ├── rerun_idempotent.bats# Validates safe re-run behavior
  └── failure_modes.bats   # Covers missing prerequisites and permission errors

.github/
└── workflows/
  └── install.yml          # CI job running install tests inside container (optional)
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

**Structure Decision**: Extend existing repository with a `scripts/pulse-install.sh` utility, companion install documentation, and dedicated bats test suite under `tests/install/`. CI workflow addition is optional but planned to guarantee installer reliability across environments.

## Complexity Tracking

Fill ONLY if Constitution Check has violations that must be justified

No constitution violations identified; table not required at this stage.
