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

- Q: Should "latest" be explicitly specified or implied when version is omitted? → A: Support both - allow explicit "latest" keyword while maintaining backward compatibility with omitted versions
- Q: Support complex version rules like "1.x compatible" or "greater than 2.0"? → A: Not in this feature - start with explicit version pinning only
- Q: How to handle when user specifies different versions for same plugin? → A: Use first declaration, display warning about conflict

### Command-Line Interface

- Q: Should commands be integrated into the shell framework or separate? → A: Provide separate command-line tool that works independently
- Q: Which management commands are most valuable? → A: Focus on listing plugins, updating them, and diagnosing configuration problems
- Q: Should commands be available immediately after installation? → A: Yes, make accessible without additional configuration steps

### Version Recording

- Q: What format should version records use? → A: Use human-readable structured format with plugin details and versions
- Q: Should records be created automatically or manually? → A: Generate automatically during install and update operations
- Q: Where should version records be stored? → A: Store in framework's data directory alongside plugins

### Update Discovery

- Q: When should system check for plugin updates? → A: Only when user explicitly requests update information, not during shell startup
- Q: Should users be notified about updates for pinned versions? → A: Yes, show available updates even when specific version is pinned

---

## Clarifications

### Session 2025-10-14

- Q: How should Pulse handle concurrent plugin updates (e.g., two shell sessions running `pulse update` simultaneously)? → A: Use file-based advisory locking (flock/lockfile) - first process locks, second waits or exits with message
- Q: How should Pulse handle a corrupted or invalid lock file? → A: Regenerate automatically with warning - scan installed plugins, recreate lock file, warn user
- Q: What security measures should Pulse enforce for plugin sources? → A: Warn only for SSH URLs - suggest HTTPS, warn if SSH without known_hosts configured
- Q: How should `pulse update` handle plugin directories with uncommitted local changes? → A: Warn and skip with --force option - skip that plugin, continue others, allow override flag
- Q: What exit code convention should CLI commands follow for scripting/automation? → A: Standard POSIX exit codes - 0 success, 1 general error, 2 usage error, 126-127 command issues

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

- **FR-001**: Support explicit "latest" keyword in plugin declarations that always fetches newest version (backward compatible with omitted version)
- **FR-002**: Allow users to specify exact plugin versions using release tags, branch names, or specific snapshots
- **FR-003**: Alert users when their configuration contains conflicting version requirements for the same plugin
- **FR-004**: Provide clear documentation with examples showing how to pin plugins to specific versions

### Command-Line Interface

- **FR-005**: Provide command to list all installed plugins with their current versions and sources
- **FR-006**: Provide command to show which installed plugins have newer versions available
- **FR-007**: Provide command to update all plugins or selectively update specific plugins by name
- **FR-008**: When updating, skip plugins with uncommitted local changes and display warning, unless --force flag provided
- **FR-009**: Provide diagnostic command that checks for common configuration issues and suggests fixes
- **FR-010**: Make commands accessible from user's shell after installation without additional setup
- **FR-011**: Provide built-in help documentation for all commands

### Version Recording

- **FR-012**: Automatically record exact versions of all installed plugins for future reference
- **FR-013**: Update version records whenever plugins are installed or updated
- **FR-014**: Use recorded versions when installing on a new machine to ensure identical setup
- **FR-015**: Notify users when their installed versions differ from recorded versions
- **FR-016**: Store version records in structured format with plugin identity, version, and installation timestamp
- **FR-017**: Automatically regenerate corrupted or invalid lock files by scanning installed plugins, displaying warning to user

### Update Discovery

- **FR-018**: Check for plugin updates on demand without automatic background operations
- **FR-019**: Display update information including current version, available version, and link to release information
- **FR-020**: Cache update information to avoid repeated network requests within same session
- **FR-021**: Handle network unavailability gracefully without blocking other operations

---

## Non-Functional Requirements

### Performance

- **NFR-001**: Commands complete within 2 seconds for typical usage (10-20 plugins)
- **NFR-002**: Update discovery minimizes network requests and bandwidth usage
- **NFR-003**: Version record processing adds negligible overhead to shell startup (under 10ms)

### Usability

- **NFR-004**: Command output is easy to read with clear visual hierarchy
- **NFR-005**: Error messages explain what went wrong and how to fix it
- **NFR-006**: Commands follow standard POSIX exit code conventions (0=success, 1=general error, 2=usage error, 126-127=command issues)

### Reliability

- **NFR-007**: Commands never leave plugin installations in broken or inconsistent state
- **NFR-008**: Version record updates are atomic and never partially complete
- **NFR-009**: Failed update operations can be reversed to restore previous working state
- **NFR-010**: Concurrent update operations are serialized using file-based advisory locking to prevent race conditions

### Security

- **NFR-014**: Warn users when using SSH URLs without known_hosts configured to prevent MITM attacks
- **NFR-015**: Suggest HTTPS URLs as preferred transport for plugin sources

### Compatibility

- **NFR-011**: Commands work across different shell environments
- **NFR-012**: Version record format remains compatible across framework versions
- **NFR-013**: Existing user configurations continue working without modification

---

## Technical Constraints

- **TC-001**: Must maintain full backward compatibility with existing plugin configurations
- **TC-002**: Command-line tools are optional enhancements (framework operates independently)
- **TC-003**: Version records are informational only (framework functions without them)
- **TC-004**: Solution uses only tools already required by base framework
- **TC-005**: Storage locations respect user-configurable paths

---

## Success Metrics

- **SM-001**: 100% of users can specify exact plugin versions without editing multiple files or running manual commands
- **SM-002**: Plugin management tasks (viewing, updating, diagnosing) complete in under 5 seconds for typical configurations (10-20 plugins)
- **SM-003**: Users can replicate their shell environment on a new machine with 100% accuracy (same plugin versions, same behavior)
- **SM-004**: Users discover available plugin updates within 10 seconds without visiting external websites
- **SM-005**: 90% of users successfully use version pinning features without consulting documentation beyond README examples
- **SM-006**: Zero existing user configurations break after upgrade (100% backward compatibility maintained)

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
