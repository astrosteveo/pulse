# CLI Commands Interface

**Feature**: 004-polish-and-refinement
**Purpose**: Define public interfaces for CLI commands

---

## Command: `pulse`

**Synopsis**: Main entry point and help dispatcher

**Usage**:

```
pulse [command] [options]
pulse --version
pulse --help
```

**Arguments**:

- `[command]` - Subcommand to execute (list, update, doctor)
- `--version` - Print version and exit
- `--help` - Print help message and exit

**Exit Codes**:

- `0` - Success
- `1` - Invalid command or arguments
- `2` - Command execution failed

**Output**:

```
Pulse - Zsh Plugin Manager

Usage:
  pulse <command> [options]

Commands:
  list          Show installed plugins
  update        Update plugins to latest versions
  doctor        Diagnose installation issues

Options:
  --version     Print version information
  --help        Print this help message

Run 'pulse <command> --help' for command-specific help.
```

**Environment Variables**:

- `PULSE_DIR` - Installation directory (default: `~/.local/share/pulse`)
- `PULSE_DEBUG` - Enable debug output (any non-empty value)

---

## Command: `pulse list`

**Synopsis**: Display installed plugins with version information

**Usage**:

```
pulse list [--verbose] [--format=<format>]
```

**Options**:

- `--verbose` - Show additional details (URL, timestamp)
- `--format=<format>` - Output format: `table` (default), `json`, `simple`

**Exit Codes**:

- `0` - Success (plugins listed)
- `1` - Lock file not found or invalid
- `2` - No plugins installed

**Output (table format)**:

```
PLUGIN                      VERSION    COMMIT
zsh-syntax-highlighting     latest     754cefe
zsh-autosuggestions         v0.7.0     c3d4e57
zsh-completions             main       0.35.0
```

**Output (json format)**:

```json
{
  "plugins": [
    {
      "name": "zsh-syntax-highlighting",
      "url": "https://github.com/zsh-users/zsh-syntax-highlighting.git",
      "ref": "latest",
      "commit": "754cefe0181a7acd42fdcb357a67d0217291ac47",
      "timestamp": "2025-10-14T15:29:45Z",
      "stage": "defer"
    }
  ],
  "total": 1
}
```

**Output (simple format)**:

```
zsh-syntax-highlighting@latest
zsh-autosuggestions@v0.7.0
zsh-completions@main
```

**Contract**:

- MUST read from `$PULSE_DIR/pulse.lock`
- MUST validate lock file format before parsing
- MUST handle missing lock file gracefully (exit 2, message "No plugins installed")
- MUST truncate commit SHA to 7 characters for table display
- MUST sort plugins alphabetically by name

---

## Command: `pulse update`

**Synopsis**: Update plugins to latest versions

**Usage**:

```
pulse update [plugin-name] [--check-only] [--verbose]
```

**Arguments**:

- `[plugin-name]` - Update specific plugin (optional, default: all)

**Options**:

- `--check-only` - Check for updates without installing
- `--verbose` - Show detailed progress
- `--dry-run` - Show what would be updated without making changes

**Exit Codes**:

- `0` - Success (all updates completed)
- `1` - Lock file not found
- `2` - Network failure (cannot reach GitHub)
- `3` - Plugin not found in lock file
- `4` - Git operation failed

**Output (normal)**:

```
Checking for updates...
zsh-syntax-highlighting: Already up to date (754cefe)
zsh-autosuggestions: Updating v0.7.0 → v0.7.1
  → Pulling changes...
  → Updated to c5d2e8a
zsh-completions: Already up to date (0.35.0)

Summary: 1 updated, 2 up-to-date
```

**Output (check-only)**:

```
Checking for updates...
zsh-syntax-highlighting: Up to date (754cefe)
zsh-autosuggestions: Update available (v0.7.0 → v0.7.1)
zsh-completions: Up to date (0.35.0)

1 update available. Run 'pulse update' to install.
```

**Contract**:

- MUST read from `$PULSE_DIR/pulse.lock`
- MUST validate network connectivity before checking
- MUST use update cache (24h TTL) to minimize network calls
- MUST handle git failures gracefully (rollback on error)
- MUST update lock file atomically (write to temp, then rename)
- MUST preserve lock file comments and formatting
- MUST respect `--check-only` flag (no modifications)

**Network Calls**:

- `git ls-remote --heads --tags <url>` - Fetch available refs (cached)
- `git -C <path> pull` - Update plugin repository

**Cache Behavior**:

- Fresh cache (<24h): use cached data, no network call
- Stale cache (>24h): refresh via git ls-remote
- No cache: perform git ls-remote, create cache

---

## Command: `pulse doctor`

**Synopsis**: Diagnose Pulse installation and plugin health

**Usage**:

```
pulse doctor [--verbose] [--fix]
```

**Options**:

- `--verbose` - Show detailed diagnostic information
- `--fix` - Attempt to automatically fix detected issues (interactive)

**Exit Codes**:

- `0` - All checks passed
- `1` - One or more checks failed
- `2` - Critical failure (cannot run diagnostics)

**Output**:

```
Running Pulse diagnostics...

[✓] Git availability                 git version 2.39.0
[✓] Network connectivity             github.com reachable
[✓] Plugin directory                 /home/user/.local/share/pulse/plugins
[✓] Lock file validity               3 plugins registered
[✓] Plugin repository integrity      3/3 repositories valid
[✓] CLI installation                 /home/user/.local/bin/pulse
[✓] PATH configuration               ~/.local/bin in PATH
[✗] Configuration syntax             Error in .zshrc line 42: invalid plugin spec

Diagnostics: 7/8 checks passed

Issues detected:
  1. Configuration syntax error
     Fix: Review .zshrc and correct plugin spec format
     Expected: user/repo[@ref]
     Found: invalid-spec

Run 'pulse doctor --fix' to attempt automatic repairs.
```

**Checks Performed**:

| Check | Pass Criteria | Fix Available |
|-------|---------------|---------------|
| Git availability | `git` command exists and version ≥2.0 | No (install git) |
| Network connectivity | Can reach github.com (HTTPS or SSH) | No (check firewall) |
| Plugin directory | `$PULSE_DIR/plugins` exists and writable | Yes (create directory) |
| Lock file validity | Lock file exists, parses correctly | Yes (regenerate from state) |
| Plugin repository integrity | Each plugin has `.git` dir, valid repo | Yes (re-clone corrupted) |
| CLI installation | `pulse` binary exists and executable | Yes (re-symlink) |
| PATH configuration | CLI location in PATH | No (show instructions) |
| Configuration syntax | `.zshrc` plugins array is valid | No (manual fix) |

**Contract**:

- MUST run all checks even if early failures occur (complete report)
- MUST provide actionable fix instructions for each failure
- MUST NOT modify system without `--fix` flag and user confirmation
- MUST clearly indicate which issues are auto-fixable
- MUST exit with non-zero if any check fails
- MUST validate each check independently (no dependencies)

---

## Lock File Interface

**File Location**: `$PULSE_DIR/pulse.lock`

**Read Operations**:

```zsh
# Function: read_lock_file
# Returns: Array of plugin sections
# Usage: plugins=($(read_lock_file))

read_lock_file() {
  local lock_file="${PULSE_DIR}/pulse.lock"
  [[ -f "$lock_file" ]] || return 1

  # Parse sections (plugin names)
  awk '/^\[.*\]$/ { gsub(/[\[\]]/, ""); print }' "$lock_file"
}

# Function: get_plugin_field
# Args: plugin_name field_name
# Returns: Field value from lock file
# Usage: commit=$(get_plugin_field "zsh-syntax-highlighting" "commit")

get_plugin_field() {
  local plugin_name="$1"
  local field_name="$2"
  local lock_file="${PULSE_DIR}/pulse.lock"

  awk -v plugin="$plugin_name" -v field="$field_name" '
    /^\[.*\]$/ { current = $0; gsub(/[\[\]]/, "", current) }
    current == plugin && $0 ~ "^" field " *= *" {
      sub("^" field " *= *", "")
      print
      exit
    }
  ' "$lock_file"
}
```

**Write Operations**:

```zsh
# Function: write_lock_entry
# Args: plugin_name url ref commit timestamp stage
# Returns: 0 on success, 1 on error
# Usage: write_lock_entry "zsh-syntax" "https://..." "latest" "abc123" "2025-..." "defer"

write_lock_entry() {
  local plugin_name="$1"
  local url="$2"
  local ref="$3"
  local commit="$4"
  local timestamp="$5"
  local stage="$6"

  local lock_file="${PULSE_DIR}/pulse.lock"
  local temp_file="${lock_file}.tmp"

  # Create header if new file
  if [[ ! -f "$lock_file" ]]; then
    {
      echo "# Pulse Lock File v1"
      echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
      echo "# DO NOT EDIT MANUALLY - Managed by Pulse"
      echo ""
    } > "$lock_file"
  fi

  # Append or update entry
  {
    echo "[$plugin_name]"
    echo "url = $url"
    echo "ref = $ref"
    echo "commit = $commit"
    echo "timestamp = $timestamp"
    echo "stage = $stage"
    echo ""
  } >> "$lock_file"
}
```

**Validation Operations**:

```zsh
# Function: validate_lock_file
# Returns: 0 if valid, 1 if invalid
# Prints: Error messages to stderr
# Usage: validate_lock_file || echo "Invalid lock file"

validate_lock_file() {
  local lock_file="${PULSE_DIR}/pulse.lock"
  [[ -f "$lock_file" ]] || { echo "Lock file not found" >&2; return 1; }

  # Check version header
  if ! head -n1 "$lock_file" | grep -q "^# Pulse Lock File v"; then
    echo "Invalid lock file: missing version header" >&2
    return 1
  fi

  # Check each section has required fields
  local sections=($(read_lock_file))
  for section in "${sections[@]}"; do
    for field in url ref commit timestamp stage; do
      local value=$(get_plugin_field "$section" "$field")
      if [[ -z "$value" ]]; then
        echo "Invalid lock file: [$section] missing field '$field'" >&2
        return 1
      fi
    done

    # Validate commit SHA format
    local commit=$(get_plugin_field "$section" "commit")
    if ! [[ "$commit" =~ ^[0-9a-f]{40}$ ]]; then
      echo "Invalid lock file: [$section] invalid commit SHA" >&2
      return 1
    fi
  done

  return 0
}
```

**Contract**:

- Lock file MUST be UTF-8 encoded
- Lock file MUST start with version header: `# Pulse Lock File v1`
- Each section MUST be enclosed in brackets: `[plugin-name]`
- Each field MUST use format: `key = value` (spaces around =)
- Commit SHA MUST be 40-character hexadecimal
- Timestamp MUST be ISO8601 UTC format
- Stage MUST be one of: early, path, fpath, completions, defer
- Empty lines between sections are OPTIONAL but RECOMMENDED
- Comments (lines starting with #) are PRESERVED during updates

---

## Error Handling Interface

**Error Output**:

- All errors MUST be printed to stderr
- Error messages MUST start with `Error:` prefix
- Exit codes MUST match documented values

**Standard Error Messages**:

```
Error: Lock file not found at <path>
  → Run a Pulse-enabled shell to generate the lock file
  → Or install plugins manually and re-source .zshrc

Error: Network connectivity issue
  → Cannot reach github.com
  → Check your internet connection and try again

Error: Plugin '<name>' not found
  → Available plugins: <list>
  → Check spelling and try again

Error: Git operation failed
  → Command: <git-command>
  → Exit code: <code>
  → Output: <output>

Error: Invalid lock file format
  → Expected: Pulse Lock File v1
  → Found: <actual-content>
  → Delete the lock file to regenerate

Error: Invalid plugin specification
  → Expected format: user/repo[@ref]
  → Your config: <actual-spec>
  → Examples: zsh-users/zsh-syntax-highlighting
               zsh-users/zsh-autosuggestions@v0.7.0
```

**Contract**:

- MUST provide actionable fix instructions
- MUST show actual vs expected values
- MUST include examples for format errors
- MUST NOT expose internal implementation details
- MUST be consistent across all commands
