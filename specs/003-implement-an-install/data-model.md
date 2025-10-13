# Data Model: Pulse Zero-Config Install Script

**Feature**: 003-implement-an-install
**Date**: 2025-10-12
**Purpose**: Describe ephemeral state managed by the installer script to guarantee a safe, idempotent setup experience.

## Overview

The installer manipulates the local file system and Zsh configuration rather than persisting data in a database. The "entities" below represent runtime structures tracked within the script and written to disk (backups, logs) so the installer can reason about state across runs.

## Core Entities

### InstallationSession

**Description**: Represents a single execution of the installer, from prerequisite checks through verification.

**Attributes**:

- `session_id`: UUID-like string (timestamp + random suffix) used for log grouping
- `start_time`: Timestamp when installer started
- `end_time`: Timestamp when installer completed (success or failure)
- `status`: Enum — `pending`, `installing`, `verifying`, `completed`, `failed`
- `install_dir`: Absolute path selected for Pulse installation
- `zshrc_path`: Absolute path to primary Zsh configuration file being modified
- `backup_path`: Absolute path to backup created before modifications (if any)
- `actions`: Ordered array of action records (each containing action name, result, message)

**Relationships**:

- One `InstallationSession` aggregates multiple `PrerequisiteCheck` entries and one `ConfigurationPatch`.
- Each session produces zero or one `VerificationResult` depending on how far it progresses.

**State Transitions**:

```text
pending → installing → verifying → completed
pending → installing → failed (if install action fails)
pending → failed (if prerequisites not met)
```

**Validation**:

- `install_dir` must resolve to a writable path.
- `zshrc_path` must exist or be creatable before entering `installing` state.
- `status` transitions must follow the sequence above; no skipping from `pending` directly to `completed`.

---

### PrerequisiteCheck

**Description**: Captures the outcome of validating a single requirement (tool, version, permission).

**Attributes**:

- `name`: String — e.g., `zsh_version`, `git_installed`, `write_perms_install_dir`
- `required_version`: String or semantic range (when applicable)
- `detected_version`: String (empty when tool missing)
- `passed`: Boolean flag
- `remediation`: Human-readable guidance shown when `passed` is false
- `severity`: Enum — `fatal` (abort installer) or `warning` (continue with caution)

**Relationships**:

- Multiple `PrerequisiteCheck` records belong to a single `InstallationSession`.
- Failed fatal checks prevent creation of a `ConfigurationPatch`.

**Validation**:

- Fatal checks must stop execution before file writes begin.
- Remediation text should include actionable next steps (e.g., `brew install git`).

---

### ConfigurationPatch

**Description**: Represents the structured modification applied to the user’s `.zshrc` (or equivalent) to enable Pulse.

**Attributes**:

- `existing_plugins`: Array of plugin identifiers detected before modification
- `pulse_block_present`: Boolean — whether a Pulse-managed block already exists
- `insert_position`: Enum — `before_source`, `after_plugins`, `append_end`
- `backup_created`: Boolean
- `result`: Enum — `applied`, `skipped`, `failed`
- `messages`: Array of strings summarizing what changed

**Rules**:

- Ensure `plugins` declaration appears before `source pulse.zsh` in the resulting file.
- Preserve user-managed sections outside the Pulse block.
- Idempotent: running again keeps a single Pulse block with updated content.

**Relationships**:

- One `ConfigurationPatch` is associated with an `InstallationSession`.
- Depends on `PrerequisiteCheck` results succeeding.

---

### VerificationResult

**Description**: Outcome of the post-install validation step executed in a subshell.

**Attributes**:

- `command`: String — command executed for verification (e.g., `zsh -ic 'pulse --version'`)
- `exit_code`: Integer result of the verification command
- `output`: Captured stdout/stderr used for diagnostics
- `passed`: Boolean derived from `exit_code == 0`
- `follow_up`: Recommended action if verification fails (e.g., rerun with `PULSE_DEBUG=1`)

**Relationships**:

- Each `InstallationSession` can have at most one `VerificationResult`.
- Verification runs only after `ConfigurationPatch.result == applied`.

**Validation**:

- When `passed` is false, `follow_up` must contain specific guidance (link to troubleshooting doc).
- Store truncated output (e.g., last 200 lines) to keep logs readable.

---

### InstallerTelemetry (Optional)

**Description**: Aggregate counters produced at runtime to support analytics or future telemetry features (initially stored locally).

**Attributes**:

- `total_runs`: Integer — number of installer executions detected
- `successful_runs`: Integer
- `failed_prereq_runs`: Integer
- `average_duration_sec`: Float — moving average of completion time

**Usage**:

- Helps surface improvements in documentation and test coverage.
- Remains local (no network calls) to preserve privacy.

## Derived Files

- `~/.zshrc.pulse-backup-<timestamp>` — backups created when modifying the user’s existing configuration.
- `~/.cache/pulse/install.log` — optional log file storing serialized `InstallationSession` summaries for troubleshooting.

## Open Questions

- Do we want to support custom shell RC locations beyond `.zshrc` (e.g., `.zprofile`)? Default assumption: focus on `.zshrc` but detect common frameworks (Oh My Zsh) and adjust insert position accordingly.
