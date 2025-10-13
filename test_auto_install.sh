#!/usr/bin/env bash
# Test script for auto-installation features
# This script should be run in a zsh environment

set -e

echo "==================================="
echo "Pulse Auto-Installation Test Suite"
echo "==================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_test() {
  echo -e "${YELLOW}TEST:${NC} $1"
}

print_pass() {
  echo -e "${GREEN}✓ PASS:${NC} $1"
}

print_fail() {
  echo -e "${RED}✗ FAIL:${NC} $1"
}

# Setup test environment
TEST_DIR="/tmp/pulse_test_$$"
export PULSE_DIR="${TEST_DIR}/pulse"
export PULSE_CACHE_DIR="${TEST_DIR}/cache"
export PULSE_DEBUG=1

echo "Setting up test environment..."
echo "  PULSE_DIR: ${PULSE_DIR}"
echo "  PULSE_CACHE_DIR: ${PULSE_CACHE_DIR}"
echo ""

mkdir -p "${TEST_DIR}"
cd "${TEST_DIR}"

# Copy pulse to test directory
cp -r "$(cd "$(dirname "$0")" && pwd)" "${TEST_DIR}/pulse_source"

echo "==================================="
echo "Test 1: Parse plugin specification"
echo "==================================="
print_test "Testing _pulse_parse_plugin_spec function"

zsh -c "
export PULSE_DIR='${PULSE_DIR}'
export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
source '${TEST_DIR}/pulse_source/lib/plugin-engine.zsh'

# Test 1: user/repo
parsed=(\$(_pulse_parse_plugin_spec 'zsh-users/zsh-autosuggestions'))
if [[ \"\${parsed[1]}\" == \"https://github.com/zsh-users/zsh-autosuggestions.git\" ]] && \
   [[ \"\${parsed[2]}\" == \"zsh-autosuggestions\" ]] && \
   [[ -z \"\${parsed[3]}\" ]]; then
  echo 'PASS: user/repo parsed correctly'
  exit 0
else
  echo \"FAIL: user/repo - got URL=\${parsed[1]} name=\${parsed[2]} ref=\${parsed[3]}\"
  exit 1
fi
" && print_pass "user/repo parsed correctly" || print_fail "user/repo parsing"

print_test "Testing version locking syntax"
zsh -c "
export PULSE_DIR='${PULSE_DIR}'
export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
source '${TEST_DIR}/pulse_source/lib/plugin-engine.zsh'

# Test 2: user/repo@tag
parsed=(\$(_pulse_parse_plugin_spec 'zsh-users/zsh-autosuggestions@v0.7.0'))
if [[ \"\${parsed[1]}\" == \"https://github.com/zsh-users/zsh-autosuggestions.git\" ]] && \
   [[ \"\${parsed[2]}\" == \"zsh-autosuggestions\" ]] && \
   [[ \"\${parsed[3]}\" == \"v0.7.0\" ]]; then
  echo 'PASS: user/repo@tag parsed correctly'
  exit 0
else
  echo \"FAIL: user/repo@tag - got URL=\${parsed[1]} name=\${parsed[2]} ref=\${parsed[3]}\"
  exit 1
fi
" && print_pass "user/repo@tag parsed correctly" || print_fail "user/repo@tag parsing"

echo ""
echo "==================================="
echo "Test 2: Plugin path resolution"
echo "==================================="
print_test "Testing _pulse_resolve_plugin_source function"

zsh -c "
export PULSE_DIR='${PULSE_DIR}'
export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
source '${TEST_DIR}/pulse_source/lib/plugin-engine.zsh'

path=\$(_pulse_resolve_plugin_source 'zsh-users/zsh-autosuggestions')
expected='${PULSE_DIR}/plugins/zsh-autosuggestions'
if [[ \"\$path\" == \"\$expected\" ]]; then
  echo 'PASS: Plugin path resolved correctly'
  exit 0
else
  echo \"FAIL: Expected \$expected, got \$path\"
  exit 1
fi
" && print_pass "Plugin path resolved correctly" || print_fail "Plugin path resolution"

print_test "Testing version spec stripping"
zsh -c "
export PULSE_DIR='${PULSE_DIR}'
export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
source '${TEST_DIR}/pulse_source/lib/plugin-engine.zsh'

path=\$(_pulse_resolve_plugin_source 'zsh-users/zsh-autosuggestions@v0.7.0')
expected='${PULSE_DIR}/plugins/zsh-autosuggestions'
if [[ \"\$path\" == \"\$expected\" ]]; then
  echo 'PASS: Version spec stripped correctly'
  exit 0
else
  echo \"FAIL: Expected \$expected, got \$path\"
  exit 1
fi
" && print_pass "Version spec stripped correctly" || print_fail "Version spec stripping"

echo ""
echo "==================================="
echo "Test 3: Auto-installation"
echo "==================================="
print_test "Testing automatic plugin cloning"

# This test actually clones a real plugin - skip if no network
if ping -c 1 github.com >/dev/null 2>&1; then
  zsh -c "
  export PULSE_DIR='${PULSE_DIR}'
  export PULSE_CACHE_DIR='${PULSE_CACHE_DIR}'
  export PULSE_DEBUG=1
  
  source '${TEST_DIR}/pulse_source/lib/plugin-engine.zsh'
  _pulse_init_engine
  
  # Define a plugin
  plugins=(zsh-users/zsh-autosuggestions)
  
  # Run discovery (should auto-install)
  _pulse_discover_plugins
  
  # Check if plugin was installed
  if [[ -d '${PULSE_DIR}/plugins/zsh-autosuggestions' ]]; then
    echo 'PASS: Plugin auto-installed'
    exit 0
  else
    echo 'FAIL: Plugin not installed'
    exit 1
  fi
  " && print_pass "Plugin auto-installed successfully" || print_fail "Plugin auto-installation"
else
  print_fail "Skipped (no network connection)"
fi

echo ""
echo "==================================="
echo "Test 4: Pulse CLI"
echo "==================================="
print_test "Testing pulse help command"

if zsh "${TEST_DIR}/pulse_source/bin/pulse" help >/dev/null 2>&1; then
  print_pass "pulse help command works"
else
  print_fail "pulse help command"
fi

print_test "Testing pulse list command"
if zsh "${TEST_DIR}/pulse_source/bin/pulse" list >/dev/null 2>&1; then
  print_pass "pulse list command works"
else
  print_fail "pulse list command"
fi

# Cleanup
echo ""
echo "Cleaning up test environment..."
rm -rf "${TEST_DIR}"

echo ""
echo "==================================="
echo "All tests completed!"
echo "==================================="
