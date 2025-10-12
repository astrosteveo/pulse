#!/usr/bin/env bash
# Fixture cleanup script
# Removes generated test artifacts and resets fixtures to clean state

set -euo pipefail

FIXTURE_DIR="${1:-$(dirname "$0")}"

echo "Cleaning test fixtures in: ${FIXTURE_DIR}"

# Clean cache directory (preserve structure)
if [[ -d "${FIXTURE_DIR}/pulse_cache" ]]; then
  echo "  Cleaning pulse_cache..."
  find "${FIXTURE_DIR}/pulse_cache" -type f ! -name '.gitkeep' -delete
  # Restore mock zcompdump for tests
  touch "${FIXTURE_DIR}/pulse_cache/zcompdump"
fi

# Clean pulse_home (preserve structure)
if [[ -d "${FIXTURE_DIR}/pulse_home" ]]; then
  echo "  Cleaning pulse_home..."
  find "${FIXTURE_DIR}/pulse_home" -type f ! -name '.gitkeep' -delete
fi

# Remove any temporary test files
find "${FIXTURE_DIR}" -name '*.tmp' -delete 2>/dev/null || true
find "${FIXTURE_DIR}" -name '*.test' -delete 2>/dev/null || true

echo "✓ Fixtures cleaned"
