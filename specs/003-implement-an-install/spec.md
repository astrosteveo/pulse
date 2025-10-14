# Feature Specification: Pulse Zero-Config Install Script

**Feature Branch**: `003-implement-an-install`
**Created**: 2025-10-12
**Status**: Draft
**Input**: User description: "Implement an install script that allows users to easily install the framework and get up and running promising the zero configuration principle"

## Clarifications

### Session 2025-10-13

- Q: How should the installer verify script integrity to prevent supply chain attacks? → A: SHA256 checksum - Publish checksum in README, verify before execution
- Q: How should the installer reliably identify an existing installation for idempotent behavior? → A: Marker file + functional check - Check for `.pulse-installed` marker AND verify `pulse.zsh` exists and is valid
- Q: Should the installer attempt automatic rollback if installation fails partway through? → A: Automatic rollback with backup - Backup existing config, rollback on failure, keep backup for manual recovery
- Q: Should users be able to install a specific version of Pulse? → A: Latest by default, optional version via env var - `PULSE_VERSION=v1.2.0` for specific versions
- Q: Should the installer provide verbose logging output for troubleshooting? → A: Optional via flag - `--verbose` or `-v` flag enables detailed logging

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One Command Install (Priority: P1)

New shell users want a single command they can copy-paste to install Pulse with sensible defaults so they can start using the framework immediately after the script finishes.

**Why this priority**: Without an effortless install experience, new users abandon the framework before trying it, so delivering a working one-command bootstrap is critical for adoption.

**Independent Test**: Run the published install command on a clean macOS or Linux machine and verify that Pulse is installed, `.zshrc` is prepared, and the next shell session loads Pulse without manual edits.

**Acceptance Scenarios**:

1. **Given** a user without Pulse installed, **When** they run the documented install command, **Then** the script installs Pulse into the default location and prints a success confirmation.
2. **Given** the same user starts a new shell session, **When** Zsh loads their updated configuration, **Then** Pulse loads successfully with no additional configuration required.

---

### User Story 2 - Safe Re-run & Detection (Priority: P2)

Returning users need to re-run the installer to update or repair their setup without breaking existing Pulse configuration or overwriting customizations.

**Why this priority**: Idempotent installs reduce support load and ensure minimal friction when users upgrade or reinstall.

**Independent Test**: Execute the install command twice on the same machine and confirm that the second run detects the existing installation, preserves user choices, and still verifies configuration correctness.

**Acceptance Scenarios**:

1. **Given** Pulse is already installed in the default location, **When** the user re-runs the installer, **Then** the script detects the installation and provides upgrade/repair options without duplicating files.
2. **Given** the user has custom plugin entries, **When** the installer updates `.zshrc`, **Then** it preserves existing plugin and module settings while ensuring the `plugins` array still precedes `source pulse.zsh`.
3. **Given** a user wants a specific Pulse version, **When** they run the installer with `PULSE_VERSION=v1.2.0`, **Then** the installer fetches and installs that exact version instead of the latest.

---

### User Story 3 - Environment Validation (Priority: P3)

Power users want the installer to validate prerequisites (Zsh version, Git availability, writable directories) and guide them through any issues before attempting to install.

**Why this priority**: Early detection of missing prerequisites prevents partial installs and reinforces the zero-configuration promise by providing actionable remediation steps.

**Independent Test**: Run the installer on systems that lack prerequisites (e.g., missing Git) and observe that the script halts with clear instructions without making unsafe changes.

**Acceptance Scenarios**:

1. **Given** Git is missing from the system, **When** the installer runs, **Then** it stops before modifying files and instructs the user how to install Git.
2. **Given** the default install directory is not writable, **When** the installer runs, **Then** it prompts for an alternate directory or elevated permissions without failing silently.
3. **Given** the installation fails partway through due to network error, **When** the failure is detected, **Then** the installer automatically rolls back changes and restores backed-up configuration files while reporting the error with recovery guidance.
4. **Given** a user encounters installation issues, **When** they run the installer with `--verbose` flag, **Then** detailed diagnostic output shows each step, prerequisite check, and file operation to aid troubleshooting.

### Edge Cases

- User runs the installer from a shell that is not Zsh (e.g., Bash) but wants to configure Pulse for their Zsh profile.
- Installation directory already exists but contains partial or corrupt files from a previous failed attempt (no `.pulse-installed` marker or missing `pulse.zsh`).
- Network connectivity drops mid-install, leaving a partially downloaded repository.
- Downloaded install script fails SHA256 checksum verification (corrupted or tampered file).
- User has a custom `.zshrc` structure (e.g., sourcing multiple files) that requires precise insertion of the Pulse bootstrap sequence.
- Target system uses locked-down corporate permissions that disallow writes to the default installation path.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Provide a single documented command that fetches and runs the installer, completing setup on supported macOS and Linux environments within one user interaction.
- **FR-002**: Detect required prerequisites (Zsh 5.0+, Git, write permissions) before making changes and surface actionable remediation steps for any missing dependency.
- **FR-003**: Install Pulse into the default directory (`~/.local/share/pulse` or user-selected alternative) with correct permissions and idempotent behavior on repeated runs, detecting existing installations via `.pulse-installed` marker file combined with functional validation that `pulse.zsh` exists and is valid.
- **FR-004**: Update the user's Zsh configuration to declare the `plugins` array before sourcing `pulse.zsh`, maintaining existing customizations and ensuring the configuration order is preserved. **If an existing Pulse block has incorrect order (source before plugins), the installer SHALL auto-fix the order by regenerating the block while preserving the user's plugin entries.**
- **FR-005**: Produce human-readable status output and a final success summary that confirms the next steps (e.g., restarting the shell) without requiring further manual configuration.
- **FR-006**: Provide automatic verification at the end of the install that Pulse loads successfully (e.g., by launching a subshell or dry-run check) and report any detected issues with remediation guidance.
- **FR-007**: Publish installation documentation that mirrors the script workflow and reiterates the configuration order guarantee (`plugins` before `pulse.zsh`).
- **FR-008**: Verify install script integrity using SHA256 checksums published in README.md before execution, halting with clear error if checksum mismatch detected.
- **FR-009**: Implement automatic rollback on installation failure by backing up existing configuration files before modification and restoring them if any installation step fails, preserving backup files for manual recovery.
- **FR-010**: Install the latest stable version of Pulse by default, with support for installing specific versions via `PULSE_VERSION` environment variable (e.g., `PULSE_VERSION=v1.2.0 curl ... | sh`).
- **FR-011**: Support verbose logging mode via `--verbose` or `-v` flag that outputs detailed step-by-step progress, prerequisite checks, file operations, and decision points for troubleshooting installation issues.

### Assumptions

- Target users have basic terminal access and can copy-paste commands but may be unfamiliar with manual shell configuration edits.
- Pulse remains focused on macOS and Linux; Windows support (via WSL) is desirable but treated as future scope.
- Users expect to keep control over their `.zshrc`, so the installer must respect and preserve custom sections.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 90% of first-time users complete installation and launch a new Pulse-enabled shell session within 2 minutes of running the command.
- **SC-002**: 100% of successful installations verify that `.zshrc` declares the `plugins` array before sourcing `pulse.zsh` and surface a warning if they cannot.
- **SC-003**: 95% of installer runs complete without manual edits to configuration files beyond confirming defaults or selecting paths.
- **SC-004**: Installation-related support tickets decrease by 60% compared to the previous release cycle as measured over the first month of availability.
