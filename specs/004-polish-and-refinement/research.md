# Research: Polish & Refinement

**Feature**: 004-polish-and-refinement
**Date**: 2025-10-14
**Purpose**: Resolve technical unknowns and establish best practices for version management, CLI tools, and lock files

---

## R001: @latest Keyword Implementation

**Question**: How should `@latest` be parsed and distinguished from other version specifiers?

**Research**:

- Existing parser in `lib/plugin-engine.zsh` already handles `@tag`, `@branch`, `@commit`
- Current behavior when `@` is omitted: defaults to cloning without specific ref (gets default branch)
- `@latest` should be explicit alias that maps to same behavior as omitting `@`

**Decision**: Add special case in `_pulse_parse_plugin_spec()` function

- If `plugin_ref == "latest"`, treat as empty ref (clone default branch)
- Maintain backward compatibility: omitting `@` continues to work identically

**Rationale**:

- Minimal code change (single conditional)
- Self-documenting in user configurations
- No performance impact (string comparison)
- Backward compatible (existing configs unchanged)

**Alternatives Considered**:

- Use git's default branch detection: More complex, requires additional git operations
- Map `@latest` to `@main` or `@master`: Breaks when repos use different default branches

**Implementation Note**: Modify lines 115-130 of `lib/plugin-engine.zsh` where `plugin_ref` is extracted

---

## R002: CLI Binary Structure

**Question**: What's the best structure for a standalone Zsh CLI tool?

**Research**:

- Zsh scripts can use shebang `#!/usr/bin/env zsh` for portability
- Standard CLI pattern: main entry point dispatches to command modules
- Commands should be separate files for maintainability
- Shared logic belongs in lib/ subdirectory

**Decision**: Create `bin/pulse` entry point with command dispatcher

- Entry point: `bin/pulse` - argument parsing and command routing
- Commands: `lib/cli/commands/{list,update,doctor}.zsh` - individual implementations
- Shared lib: `lib/cli/lib/{lock-file,update-check}.zsh` - reusable functions

**Rationale**:

- Clean separation of concerns
- Easy to add new commands later
- Commands can be tested individually
- Follows UNIX tool conventions

**Alternatives Considered**:

- Single monolithic script: Harder to maintain and test
- Python/Ruby CLI: Adds external dependency (violates constitution)
- Integrate into framework: Couples CLI to framework loading (not optional)

**Implementation Note**: CLI must work even when Pulse framework isn't sourced in current shell

---

## R003: Lock File Format

**Question**: What format should the lock file use for version records?

**Research**:

- Common formats: JSON, YAML, TOML, custom
- Requirements: Human-readable, easy to parse with Zsh, forward-compatible
- Similar tools: npm uses JSON (package-lock.json), yarn uses YAML (yarn.lock), cargo uses TOML (Cargo.lock)

**Decision**: Use simple key-value format (similar to .ini files)

```
# Pulse Lock File v1
# Generated: 2025-10-14T10:30:00Z

[zsh-syntax-highlighting]
url = https://github.com/zsh-users/zsh-syntax-highlighting.git
ref = master
commit = abc123def456
timestamp = 2025-10-14T10:29:45Z

[zsh-autosuggestions]
url = https://github.com/zsh-users/zsh-autosuggestions.git
ref = latest
commit = def789ghi012
timestamp = 2025-10-14T10:29:50Z
```

**Rationale**:

- Extremely simple to parse with Zsh (awk/sed/read)
- Human-readable and diff-friendly
- No external dependencies (no jq, yq, etc.)
- Version header enables future format evolution
- Similar to git config format (familiar to users)

**Alternatives Considered**:

- JSON: Requires jq or complex Zsh parsing
- YAML: Requires yq or complex parsing
- TOML: Requires external parser
- Line-based (plugin:url:ref:commit): Less readable, harder to extend

**Implementation Note**: Use section-based parsing with `awk` for efficient reads

---

## R004: Update Checking Strategy

**Question**: How to efficiently check for plugin updates without slowing down operations?

**Research**:

- Git operations needed: `git ls-remote` to check remote refs/tags
- Caching strategy: Store last check timestamp and results
- Network failures: Must handle gracefully (offline mode)

**Decision**: On-demand checking with simple caching

- Run `git ls-remote --heads --tags <url>` to get available refs
- Cache results in `$PULSE_DIR/.update-cache/<plugin-name>` with 24h TTL
- Compare cached remote refs against installed commit hash
- Skip check if cache is fresh (<24h old) or network unavailable

**Rationale**:

- Lazy evaluation (only when user requests)
- Respects network conditions (graceful offline)
- Simple TTL-based cache (no complex invalidation)
- Fast for repeated checks (uses cache)

**Alternatives Considered**:

- Background daemon checking: Adds complexity, resource usage
- Check on every shell startup: Unacceptable performance impact
- No caching: Slow for repeated operations, network-dependent

**Implementation Note**: Cache format: `<plugin-name>.cache` containing JSON-like output from ls-remote with timestamp

---

## R005: CLI Installation Strategy

**Question**: How should the CLI be installed and made available to users?

**Research**:

- Standard locations: `/usr/local/bin`, `~/.local/bin`, `~/bin`
- PATH requirements: `~/.local/bin` commonly in PATH on modern systems
- Symlink vs copy: Symlinks keep source of truth, copies are independent

**Decision**: Install symlink to `~/.local/bin/pulse` pointing to repository installation

- During install: Create `~/.local/bin` if needed, symlink `bin/pulse`
- Advantage: Updates automatically available (symlink points to repo)
- Fallback: If `~/.local/bin` not in PATH, show instructions to add it

**Rationale**:

- Follows XDG Base Directory specification
- Common pattern for user-installed tools
- Automatic updates (symlink follows repo)
- No sudo required (user-local installation)

**Alternatives Considered**:

- Copy to /usr/local/bin: Requires sudo, disconnects from updates
- Add to $PATH directly: Modifies shell config, less clean
- Function in .zshrc: Requires framework to be loaded

**Implementation Note**: Extend `scripts/pulse-install.sh` to create symlink during installation

---

## R006: Backward Compatibility Strategy

**Question**: How to ensure 100% backward compatibility with existing configurations?

**Research**:

- Existing behavior: Plugins declared as `user/repo` or `user/repo@ref`
- Risk areas: Parsing changes, new files, CLI availability

**Decision**: Multi-layered compatibility approach

1. **Parsing**: Keep existing logic untouched, add `@latest` as optional enhancement
2. **Lock file**: Generate automatically but never required (informational only)
3. **CLI**: Completely optional, framework works without it
4. **Tests**: Add regression tests for existing plugin specs (without @latest)

**Rationale**:

- Defensive approach minimizes risk
- Users opt-in to new features naturally
- No forced migrations or changes
- Existing workflows unaffected

**Alternatives Considered**:

- Require lock file: Breaks zero-config principle
- Deprecate old format: Violates backward compatibility
- Auto-migrate configs: Surprising behavior, risky

**Implementation Note**: Regression test suite must cover all existing plugin spec formats

---

## R007: Error Handling and Diagnostics

**Question**: What error conditions need handling and what diagnostics should `pulse doctor` provide?

**Research**:

- Common issues: Missing git, network failures, invalid plugin specs, version conflicts
- User expectations: Clear messages with actionable fixes

**Decision**: Three-tier error handling

1. **Graceful degradation**: Framework works even if CLI/lock file fails
2. **Clear errors**: Specific messages with remediation ("Install git: https://...")
3. **Doctor diagnostics**: Comprehensive health check

**pulse doctor** checks:

- [ ] Git availability and version
- [ ] Network connectivity (github.com reachable)
- [ ] Plugin directory permissions
- [ ] Lock file validity (if exists)
- [ ] Plugin integrity (cloned repos are valid git repos)
- [ ] Configuration syntax (plugins array well-formed)
- [ ] Version conflicts (same plugin declared multiple times)
- [ ] PATH includes CLI location

**Rationale**:

- Helps users self-diagnose issues
- Reduces support burden
- Follows "consistent user experience" principle

**Alternatives Considered**:

- Auto-fix issues: Risky, could make things worse
- Minimal error handling: Poor user experience
- Separate diagnostic tool: Extra complexity

**Implementation Note**: Each check should be independent and non-destructive

---

## R008: Testing Strategy

**Question**: What test coverage is needed to meet constitution requirements (100% core, 90% utilities)?

**Research**:

- Core functionality: Version parsing (@latest), lock file read/write
- Utilities: CLI commands, update checking
- Integration: End-to-end workflows

**Decision**: Comprehensive test plan
**Unit Tests** (100% coverage for core):

- `tests/unit/version_parsing.bats` - All @latest scenarios
- `tests/unit/lock_file_format.bats` - Read/write/parse operations

**Integration Tests** (90% coverage for utilities):

- `tests/integration/version_pinning.bats` - Install with @latest, verify cloning
- `tests/integration/cli_commands.bats` - list, update, doctor commands
- `tests/integration/lock_file_workflow.bats` - Generate, restore, update lock file

**Test Fixtures**:

- Mock plugin repositories with tagged releases
- Sample lock files (valid and invalid)
- Configuration files with various plugin specs

**Rationale**:

- Meets constitution TDD requirements
- Tests written first (Red-Green-Refactor)
- Covers all user stories acceptance criteria
- Platform-independent (uses mocks)

**Implementation Note**: Tests must be written and failing BEFORE any implementation code

---

## Summary

All research complete. Key decisions:

1. `@latest` = simple string comparison in existing parser
2. CLI = standalone tool with command dispatcher pattern
3. Lock file = simple ini-style format, easily parsed with Zsh
4. Updates = on-demand with 24h TTL cache
5. Installation = symlink to ~/.local/bin
6. Compatibility = additive changes only, no breaking modifications
7. Diagnostics = pulse doctor with comprehensive health checks
8. Testing = TDD with 100% core coverage, written first

Ready for Phase 1 (design artifacts).
