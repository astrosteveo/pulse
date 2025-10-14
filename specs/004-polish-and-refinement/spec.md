# Feature Specification: Polish & Refinement

**Feature ID**: 004-polish-and-refinement
**Feature Branch**: `004-polish-and-refinement`
**Status**: Draft
**Created**: 2025-10-14

## User Input

**Input**: "we can do a polish spec where we can hit all the polish things like that"

**Context**: After implementing the core framework (001), modules (002), and installer (003), we need to add polish and refinement features including:
- Better version management (`@latest` keyword, version constraints)
- Plugin management CLI commands (`pulse list`, `pulse update`)
- Version locking with lock files
- Update notifications for pinned versions
- Better documentation of existing features

---

## Key Clarifications

### Version Management
- Q: Should `@latest` be a special keyword or just alias to omitting `@`? → A: Add `@latest` as explicit keyword that resolves to default branch, maintaining backward compatibility with omitting `@`
- Q: Support semver constraints like `@^1.0.0` or `@>=2.0.0`? → A: Phase 2 feature - start with explicit versions/tags/branches/commits first
- Q: How to handle version resolution conflicts? → A: First declaration wins, warn on conflicts in debug mode

### Plugin Management CLI
- Q: Create a `pulse` CLI command or add to framework? → A: Create optional `bin/pulse` CLI that works independently of framework loading
- Q: What commands are essential? → A: `list` (show installed), `update` (update plugins), `doctor` (diagnose issues)
- Q: Should CLI be installed by default? → A: Yes, symlinked to `~/.local/bin/pulse` during installation

### Lock Files
- Q: Format for lock file? → A: YAML-style `plugins.lock` with plugin name, URL, ref/commit, timestamp
- Q: Auto-generate or manual? → A: Auto-generate on install/update, similar to package-lock.json
- Q: Lock file location? → A: `$PULSE_DIR/plugins.lock` (default: `~/.local/share/pulse/plugins.lock`)

### Update Notifications
- Q: How to check for updates without slowing shell startup? → A: Background check on `pulse update` command, not on shell load
- Q: Notify about updates to pinned versions? → A: Yes, show when running `pulse list --outdated`

---

## User Stories

### US1: Explicit Version Keywords

**Story**: As a user, I want to explicitly specify `@latest` in my plugin declarations so my intent is clear and documented.

**Value**: Makes configuration self-documenting and distinguishes intentional "latest" from forgotten version pins.

**Independent Test**: Add plugin with `user/repo@latest`, verify it clones default branch and updates show available versions.

**Acceptance Criteria**:
1. **Given** plugin spec with `@latest`, **When** framework loads, **Then** plugin clones from default branch
2. **Given** plugin spec with `@latest`, **When** running `pulse update`, **Then** plugin updates to latest default branch
3. **Given** plugin spec without `@`, **When** framework loads, **Then** behavior is identical to `@latest` (backward compatible)

### US2: Plugin Management CLI

**Story**: As a user, I want CLI commands to manage my plugins so I can list, update, and diagnose without editing config files.

**Value**: Provides convenience commands for common operations, improves discoverability of installed plugins.

**Independent Test**: Install Pulse, run `pulse list` to see plugins, `pulse update` to update them, `pulse doctor` to diagnose.

**Acceptance Criteria**:
1. **Given** plugins installed, **When** running `pulse list`, **Then** see name, version/ref, source URL, load stage
2. **Given** outdated plugins, **When** running `pulse update`, **Then** all plugins update to latest (respecting pins)
3. **Given** configuration issues, **When** running `pulse doctor`, **Then** see diagnostic info and fixes
4. **Given** specific plugin, **When** running `pulse update <plugin>`, **Then** only that plugin updates

### US3: Version Lock File

**Story**: As a user, I want a lock file to record exact versions installed so my environment is reproducible.

**Value**: Ensures consistent environments across machines, documents what's actually installed vs. what's declared.

**Independent Test**: Install plugins, verify `plugins.lock` created with exact commits/refs, restore from lock file works.

**Acceptance Criteria**:
1. **Given** plugins installed, **When** installation completes, **Then** `plugins.lock` created with exact versions
2. **Given** `plugins.lock` exists, **When** installing on new machine, **Then** exact versions from lock file are installed
3. **Given** lock file and config differ, **When** framework loads, **Then** warn about mismatch in debug mode
4. **Given** `pulse update` runs, **When** updates complete, **Then** lock file automatically updates

### US4: Update Notifications

**Story**: As a user, I want to know when updates are available for my pinned plugins so I can stay current.

**Value**: Keeps users informed about new releases without manual checking, encourages keeping dependencies updated.

**Independent Test**: Pin plugin to old version, run `pulse list --outdated`, see available updates.

**Acceptance Criteria**:
1. **Given** pinned plugins, **When** running `pulse list --outdated`, **Then** see plugins with available updates
2. **Given** plugins on latest, **When** running `pulse list --outdated`, **Then** no outdated plugins shown
3. **Given** plugin with semantic version tags, **When** checking updates, **Then** show latest stable version
4. **Given** update available, **When** output displayed, **Then** show current version, latest version, release notes link

### US5: Enhanced Documentation

**Story**: As a user, I want comprehensive documentation of version pinning and CLI commands so I can use advanced features.

**Value**: Improves discoverability, reduces support burden, empowers users to leverage full feature set.

**Independent Test**: Read README, find version pinning examples, CLI command reference, lock file explanation.

**Acceptance Criteria**:
1. **Given** README, **When** reading plugin section, **Then** see version pinning syntax and examples
2. **Given** CLI installed, **When** running `pulse help`, **Then** see all available commands with descriptions
3. **Given** CLI command, **When** running `pulse <command> --help`, **Then** see detailed usage and examples
4. **Given** docs/, **When** browsing, **Then** find version management guide and CLI reference

---

## Functional Requirements

### Version Management
- **FR-001**: Support `@latest` keyword as explicit alias for default branch (backward compatible with omitting `@`)
- **FR-002**: Parse and validate version specifications: tags, branches, commits, `@latest`
- **FR-003**: Warn in debug mode when multiple plugins declare conflicting versions
- **FR-004**: Document version pinning syntax in README with examples

### CLI Commands
- **FR-005**: Provide `pulse list` command showing installed plugins with name, version, source, stage
- **FR-006**: Provide `pulse list --outdated` showing plugins with available updates
- **FR-007**: Provide `pulse update [plugin]` to update all or specific plugin(s)
- **FR-008**: Provide `pulse doctor` to diagnose configuration and environment issues
- **FR-009**: Install CLI to `~/.local/bin/pulse` during framework installation
- **FR-010**: Support `pulse help` and `pulse <command> --help` for documentation

### Lock File
- **FR-011**: Generate `plugins.lock` file recording exact installed versions (commit hashes)
- **FR-012**: Auto-update lock file after install/update operations
- **FR-013**: Read lock file on install to ensure reproducible environments
- **FR-014**: Warn when lock file and config diverge (debug mode)
- **FR-015**: Lock file format: YAML-style with plugin name, URL, ref, commit hash, timestamp

### Update Checking
- **FR-016**: Check for updates when running `pulse list --outdated`
- **FR-017**: Show available updates with current version, latest version, changelog link
- **FR-018**: Cache update check results (24h TTL) to avoid repeated network calls
- **FR-019**: Skip update checks when offline (graceful degradation)

---

## Non-Functional Requirements

### Performance
- **NFR-001**: CLI commands execute in <2 seconds for typical operations
- **NFR-002**: Update checks use shallow git operations (fetch --depth 1)
- **NFR-003**: Lock file parsing adds <10ms to framework load time

### Usability
- **NFR-004**: CLI output is human-readable with colors and formatting
- **NFR-005**: Error messages include actionable remediation steps
- **NFR-006**: CLI follows UNIX conventions (exit codes, --flags, stdin/stdout)

### Reliability
- **NFR-007**: CLI commands never corrupt plugin installations
- **NFR-008**: Lock file generation is atomic (write to temp, rename)
- **NFR-009**: Update operations can be rolled back on failure

### Compatibility
- **NFR-010**: CLI works with Zsh 5.0+ and Bash 4.0+ (for non-Zsh users managing Pulse)
- **NFR-011**: Lock file format is forward/backward compatible
- **NFR-012**: Existing configurations without `@latest` continue working

---

## Technical Constraints

- **TC-001**: Must not break existing plugin specifications (backward compatibility)
- **TC-002**: CLI must be optional (framework works without it)
- **TC-003**: Lock file is informational (framework works without it)
- **TC-004**: No external dependencies beyond git, curl/wget
- **TC-005**: Lock file location respects `$PULSE_DIR` override

---

## Success Metrics

- **SM-001**: Users can pin plugins to specific versions using `@` syntax (documented and tested)
- **SM-002**: CLI commands execute successfully in automated tests (100% coverage)
- **SM-003**: Lock file enables reproducible installs across machines
- **SM-004**: Update checking identifies outdated plugins accurately
- **SM-005**: Documentation covers all version management and CLI features
- **SM-006**: Zero breaking changes to existing configurations

---

## Out of Scope (Future Enhancements)

- Semantic version constraints (`@^1.0.0`, `@>=2.0.0`) - Complex resolution logic
- Plugin search/discovery (`pulse search <keyword>`) - Requires external plugin registry
- Automatic security vulnerability scanning - Requires vulnerability database
- Plugin dependency resolution - Complex graph resolution
- GUI/TUI interface for plugin management - Scope creep
- Plugin marketplace/ratings - Infrastructure overhead

---

## Dependencies

- **Feature 001** (Plugin Engine): Version pinning parsing already exists, needs `@latest` support
- **Feature 003** (Installer): CLI installation needs integration with installer script
- Git operations infrastructure already exists in plugin-engine.zsh

---

## Risk Assessment

### High Risks
- **Breaking existing configs**: Mitigate with comprehensive backward compatibility tests
- **CLI complexity creep**: Mitigate with strict scope (list, update, doctor only)

### Medium Risks
- **Lock file format evolution**: Mitigate with versioned format and migration path
- **Update check network failures**: Mitigate with caching and graceful degradation

### Low Risks
- **Performance impact**: Lock file parsing is simple YAML-style, <10ms overhead
- **User adoption**: CLI is optional, doesn't affect existing users

---

## Next Steps

1. Review and approve specification
2. Create plan.md with architecture and technology choices
3. Create tasks.md with test-first implementation steps
4. Implement in order: `@latest` support, CLI commands, lock file, update checking, docs
