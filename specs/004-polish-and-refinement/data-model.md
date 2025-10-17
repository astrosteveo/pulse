# Data Model: Polish & Refinement

**Feature**: 004-polish-and-refinement
**Purpose**: Define data structures for version pinning, lock files, and update tracking

---

## Lock File Structure

**File Location**: `$PULSE_DIR/pulse.lock` (typically `~/.local/share/pulse/pulse.lock`)

**Format**: INI-style sections with key-value pairs

**Structure**:

```ini
# Pulse Lock File v1
# Generated: <ISO8601 timestamp>
# DO NOT EDIT MANUALLY - Managed by Pulse

[plugin-section-name]
url = <git-clone-url>
ref = <branch|tag|commit|latest>
commit = <resolved-commit-sha>
timestamp = <ISO8601-install-time>
stage = <early|path|fpath|completions|defer>
```

**Field Definitions**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `[section]` | string | YES | Plugin identifier (derived from URL) |
| `url` | string | YES | Git clone URL (https or ssh) |
| `ref` | string | YES | User-specified reference (@latest, @v1.0, @main, @abc123) |
| `commit` | string | YES | Resolved commit SHA (40-char hex) |
| `timestamp` | string | YES | ISO8601 UTC timestamp of installation |
| `stage` | string | YES | Plugin loading stage (early\|path\|fpath\|completions\|defer) |

**Constraints**:

- Section names MUST be unique within file
- commit MUST be valid 40-character SHA-1 hash
- timestamp MUST be ISO8601 UTC format: `YYYY-MM-DDTHH:MM:SSZ`
- stage MUST be one of: early, path, fpath, completions, defer
- url MUST be valid git URL (https:// or git@)

**Example**:

```ini
# Pulse Lock File v1
# Generated: 2025-10-14T15:30:00Z
# DO NOT EDIT MANUALLY - Managed by Pulse

[zsh-syntax-highlighting]
url = https://github.com/zsh-users/zsh-syntax-highlighting.git
ref = latest
commit = 754cefe0181a7acd42fdcb357a67d0217291ac47
timestamp = 2025-10-14T15:29:45Z
stage = defer

[zsh-autosuggestions]
url = https://github.com/zsh-users/zsh-autosuggestions.git
ref = v0.7.0
commit = c3d4e576c9c86eac62884bd47c01f6faed043fc5
timestamp = 2025-10-14T15:29:50Z
stage = defer
```

---

## Plugin Metadata

**Storage**: Embedded in lock file (no separate metadata files)

**Lifecycle**:

1. User declares plugin in `.zshrc`: `plugins=(user/repo@latest)`
2. Framework parses spec: extracts user, repo, ref
3. Framework clones plugin: resolves ref to commit SHA
4. Framework writes lock entry: records url, ref, commit, timestamp, stage
5. On subsequent loads: verify commit matches lock file

**Update Flow**:

1. User runs: `pulse update` or `pulse update <plugin>`
2. CLI reads lock file: retrieves current commit SHA
3. CLI fetches remote: `git ls-remote` to get latest refs
4. CLI compares: checks if newer commit available
5. If outdated: runs `git pull` in plugin directory
6. CLI updates lock: writes new commit SHA and timestamp

---

## Update Check Cache

**File Location**: `$PULSE_DIR/.update-cache/<plugin-name>.cache`

**Format**: Simple key-value text file

**Structure**:

```
checked_at=<unix-timestamp>
remote_refs=<json-array-of-refs>
```

**Example**:

```
checked_at=1728918600
remote_refs={"refs/heads/main":"abc123","refs/tags/v1.0":"def456"}
```

**TTL**: 24 hours (86400 seconds)

**Behavior**:

- Cache miss (no file): perform git ls-remote, write cache
- Cache stale (>24h): refresh via git ls-remote, update cache
- Cache fresh (<24h): use cached data, skip network call
- Network failure: use stale cache, warn user

---

## Version Spec Format

**User Configuration Format**: `user/repo[@ref]`

**Components**:

| Component | Required | Pattern | Example |
|-----------|----------|---------|---------|
| user | YES | `[a-zA-Z0-9_-]+` | `zsh-users` |
| repo | YES | `[a-zA-Z0-9_.-]+` | `zsh-syntax-highlighting` |
| @ | NO | Literal `@` | `@` |
| ref | NO | `[^@\s]+` | `latest`, `v1.0`, `main`, `abc123` |

**Parsing Rules**:

1. Split on first `/` to get user and rest
2. Split rest on first `@` to get repo and ref
3. If no `@` present: ref = empty (use default branch)
4. If ref = "latest": treat as empty (use default branch)

**Valid Examples**:

- `zsh-users/zsh-syntax-highlighting` → user=zsh-users, repo=zsh-syntax-highlighting, ref=empty
- `zsh-users/zsh-syntax-highlighting@latest` → user=zsh-users, repo=zsh-syntax-highlighting, ref=latest (treated as empty)
- `zsh-users/zsh-syntax-highlighting@v1.0` → user=zsh-users, repo=zsh-syntax-highlighting, ref=v1.0
- `zsh-users/zsh-syntax-highlighting@754cefe` → user=zsh-users, repo=zsh-syntax-highlighting, ref=754cefe

**Invalid Examples**:

- `zsh-syntax-highlighting` (missing user)
- `zsh-users/` (missing repo)
- `zsh-users/repo@` (empty ref after @)
- `user/repo@main@v1.0` (multiple @ symbols)

---

## CLI Command Data Flow

### `pulse list`

**Input**: None (reads from filesystem)

**Process**:

1. Read `$PULSE_DIR/pulse.lock`
2. Parse all sections
3. For each plugin: extract name, ref, commit (first 7 chars)
4. Format as table: NAME | VERSION | COMMIT

**Output**: Table printed to stdout

### `pulse update [plugin]`

**Input**: Optional plugin name

**Process**:

1. Read `$PULSE_DIR/pulse.lock`
2. If plugin specified: filter to that plugin only
3. For each plugin:
   - Check update cache (use if fresh)
   - Fetch remote refs: `git ls-remote --heads --tags <url>`
   - Compare remote commit to lock file commit
   - If different: run `git -C <plugin-path> pull`
   - Update lock file with new commit SHA and timestamp
4. Write updated lock file

**Output**: Progress messages, summary of updated plugins

### `pulse doctor`

**Input**: None (inspects system state)

**Process**:

1. Check git availability: `command -v git`
2. Check network: `curl -Is https://github.com 2>/dev/null | head -n1`
3. Check plugin dir: test `-d "$PULSE_DIR/plugins"`
4. Check lock file: validate format and required fields
5. Check plugin repos: for each, verify `.git` directory exists
6. Check PATH: verify `~/.local/bin` in PATH
7. Generate report with PASS/FAIL for each check

**Output**: Diagnostic report with actionable fixes

---

## State Transitions

### Plugin Installation

```
State: NOT_INSTALLED
  ↓ (user adds to plugins array)
State: DECLARED
  ↓ (framework calls pulse_load_plugin)
State: CLONING
  ↓ (git clone completes)
State: INSTALLED
  ↓ (lock file entry written)
State: LOCKED
```

### Plugin Update

```
State: LOCKED (installed, in lock file)
  ↓ (user runs pulse update)
State: CHECKING (fetching remote refs)
  ↓ (compare commits)
Branch: UP_TO_DATE → State: LOCKED
Branch: OUTDATED → State: UPDATING
  ↓ (git pull)
State: UPDATED
  ↓ (lock file entry updated)
State: LOCKED (with new commit SHA)
```

### Lock File Generation

```
State: NO_LOCK
  ↓ (first plugin installs)
State: LOCK_CREATED (file with header)
  ↓ (each plugin installs)
State: LOCK_ENTRY_ADDED (per-plugin sections)
  ↓ (all plugins installed)
State: LOCK_COMPLETE
```

---

## Performance Characteristics

**Lock File Operations**:

- Read: O(n) where n = number of plugins, <10ms for 50 plugins
- Write: O(n) where n = number of plugins, <20ms for 50 plugins
- Parse: O(n) lines, simple awk/sed processing, <5ms for 50 plugins

**Update Check**:

- Cache hit: <1ms (file read only)
- Cache miss: ~500ms (git ls-remote network call)
- Parallel updates: Can check multiple plugins concurrently

**CLI Overhead**:

- Startup: <50ms (Zsh script initialization)
- Lock file read: <10ms
- Total for `pulse list`: <100ms (read + format + print)

---

## Data Validation

**Lock File Validation**:

- Version header present and recognized (currently v1)
- Each section has all required fields
- commit field is 40-character hex string
- timestamp field parses as valid ISO8601
- stage field is one of allowed values
- url field is valid git URL

**Version Spec Validation**:

- Contains exactly one `/` separator
- user and repo are non-empty
- If `@` present, ref is non-empty
- ref contains no whitespace

**Error Handling**:

- Invalid lock file: warn user, regenerate from current state
- Invalid version spec: error message with correct format example
- Missing fields: treat as fatal error, refuse to proceed
- Malformed data: log warning, skip entry, continue processing

---

## Backward Compatibility

**Existing Behavior (no lock file)**:

- Framework works normally
- Plugins install and load
- No version tracking

**New Behavior (with lock file)**:

- Lock file generated transparently
- Framework behavior unchanged
- Additional CLI commands available

**Migration Path**:

- First load after upgrade: generates lock file for all installed plugins
- Existing plugin directories inspected: extract commit SHA via `git rev-parse HEAD`
- Lock file populated with current state
- No user action required

**Rollback**:

- Delete lock file: framework continues working
- Remove CLI symlink: framework unaffected
- Downgrade Pulse: lock file ignored (unknown feature)
