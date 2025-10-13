#!/usr/bin/env zsh
# Pulse: Utility Functions
# Provides cross-platform helper functions for common tasks

# =============================================================================
# Command Detection
# =============================================================================

# Check if a command exists in the system
# Usage: pulse_has_command <command>
# Returns: 0 if command exists, 1 otherwise
pulse_has_command() {
  [[ -n "$1" ]] && command -v "$1" &>/dev/null
}

# =============================================================================
# Conditional File Sourcing
# =============================================================================

# Source a file only if it exists
# Usage: pulse_source_if_exists <file_path>
# Returns: 0 always (silent failure for missing files)
pulse_source_if_exists() {
  [[ -n "$1" && -f "$1" ]] && source "$1"
  return 0
}

# =============================================================================
# Operating System Detection
# =============================================================================

# Detect the operating system type
# Usage: pulse_os_type
# Returns: String - "linux", "macos", "freebsd", "openbsd", "netbsd", or "other"
pulse_os_type() {
  local os_name="$(uname -s)"

  case "${os_name:l}" in
    linux*)
      echo "linux"
      ;;
    darwin*)
      echo "macos"
      ;;
    freebsd*)
      echo "freebsd"
      ;;
    openbsd*)
      echo "openbsd"
      ;;
    netbsd*)
      echo "netbsd"
      ;;
    *)
      echo "other"
      ;;
  esac
}

# =============================================================================
# Archive Extraction
# =============================================================================

# Auto-detect and extract various archive formats
# Usage: pulse_extract <archive_file> [target_directory]
# Supported: .tar.gz, .tgz, .tar.bz2, .tbz2, .tar.xz, .txz, .tar, .zip, .7z, .gz, .bz2, .xz
pulse_extract() {
  local archive="$1"
  local target="${2:-.}"

  # Validate archive exists
  if [[ ! -f "$archive" ]]; then
    echo "pulse_extract: file not found: $archive" >&2
    return 1
  fi

  # Create target directory if it doesn't exist
  [[ ! -d "$target" ]] && mkdir -p "$target"

  # Detect format and extract
  case "${archive:l}" in
    *.tar.gz|*.tgz)
      tar -xzf "$archive" -C "$target"
      ;;
    *.tar.bz2|*.tbz2|*.tbz)
      tar -xjf "$archive" -C "$target"
      ;;
    *.tar.xz|*.txz)
      tar -xJf "$archive" -C "$target"
      ;;
    *.tar)
      tar -xf "$archive" -C "$target"
      ;;
    *.zip)
      if pulse_has_command unzip; then
        unzip -q "$archive" -d "$target"
      else
        echo "pulse_extract: unzip not found (required for .zip files)" >&2
        return 1
      fi
      ;;
    *.7z)
      if pulse_has_command 7z; then
        7z x "$archive" -o"$target" >/dev/null
      elif pulse_has_command 7za; then
        7za x "$archive" -o"$target" >/dev/null
      else
        echo "pulse_extract: 7z not found (required for .7z files)" >&2
        return 1
      fi
      ;;
    *.gz)
      if pulse_has_command gunzip; then
        gunzip -c "$archive" > "$target/$(basename "${archive%.gz}")"
      else
        echo "pulse_extract: gunzip not found" >&2
        return 1
      fi
      ;;
    *.bz2)
      if pulse_has_command bunzip2; then
        bunzip2 -c "$archive" > "$target/$(basename "${archive%.bz2}")"
      else
        echo "pulse_extract: bunzip2 not found" >&2
        return 1
      fi
      ;;
    *.xz)
      if pulse_has_command unxz; then
        unxz -c "$archive" > "$target/$(basename "${archive%.xz}")"
      else
        echo "pulse_extract: unxz not found" >&2
        return 1
      fi
      ;;
    *)
      echo "pulse_extract: unsupported archive format: $archive" >&2
      return 1
      ;;
  esac
}

# =============================================================================
# Module Loaded
# =============================================================================

# Export flag indicating utilities module is loaded
export PULSE_UTILITIES_LOADED=1
