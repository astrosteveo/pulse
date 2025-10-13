# Research Findings: Pulse Zero-Config Install Script

**Date**: 2025-10-12
**Branch**: `003-implement-an-install`

## Decision 1: Distribution Mechanism

- **Decision**: Provide a POSIX-compliant installer script hosted in the repository (`scripts/pulse-install.sh`) and distribute via a single `curl -fsSL https://... | sh` command.
- **Rationale**: A POSIX shell script runs on macOS and Linux without additional dependencies and keeps the zero-configuration promise. Streaming via `curl` avoids requiring Git pre-install just to download the installer while still allowing the script to validate Git before use.
- **Alternatives Considered**:
  - Homebrew/Apt packages — rejected due to higher maintenance overhead per platform and delayed availability.
  - Python installer — rejected because it violates the “no extra runtime” expectation and complicates environments without Python 3.

## Decision 2: Repository Retrieval Strategy

- **Decision**: Use `git clone --depth=1` for the initial installation and `git pull --ff-only` on re-runs when the install directory already exists.
- **Rationale**: Git is already a prerequisite for plugin management, enables incremental updates, and minimizes download size with shallow clones.
- **Alternatives Considered**:
  - Downloading release tarballs — rejected because it complicates updates and requires manual cleanup.
  - Syncing via rsync from a CDN — rejected due to infrastructure cost and lack of version control integration.

## Decision 3: `.zshrc` Modification Strategy

- **Decision**: Parse and update `.zshrc` using idempotent markers: insert a Pulse block that declares `plugins` before sourcing `pulse.zsh`, backing up the original file before modifications.
- **Rationale**: Markers make repeated runs safe, prevent duplicate blocks, and keep user customizations intact. Backups provide an easy rollback path.
- **Alternatives Considered**:
  - Appending blindly to the end of `.zshrc` — rejected because it can violate the configuration ordering and clutter user config.
  - Creating a separate `pulse.zshrc` file — rejected because it forces users to manage include order manually.

## Decision 4: Verification & Telemetry

- **Decision**: After installation, launch a non-interactive Zsh subshell (`zsh -ic 'pulse_version_check'`) to confirm modules load and log results in the installer output.
- **Rationale**: Automated verification ensures the zero-configuration promise is kept and surfaces actionable errors immediately.
- **Alternatives Considered**:
  - Relying on user to start a new shell — rejected because failures would surface too late and erode trust.
  - Running a full interactive shell — rejected since it would hijack the terminal session and complicate scripting.

## Prerequisite Checklist

- Zsh ≥ 5.0 (validate via `zsh --version`).
- Git ≥ 2.20 (validate via `git --version`).
- `curl` available; fallback to `wget` if missing.
- Write access to `~/.local/share/pulse` (create directory with `mkdir -p`).

## Risks & Mitigations

- **Network failures**: Detect non-zero exit codes from `curl`/`git` commands and retry once before aborting with guidance.
- **Corporate-managed systems**: Provide environment variable overrides for install path (`PULSE_INSTALL_DIR`) and skip fail-fast with clear messaging when permission checks fail.
- **Shell variance**: Ensure script uses POSIX `sh` features only; gate Zsh-specific commands behind validation checks.
