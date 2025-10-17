#!/usr/bin/env bats
# Tests for pulse doctor PATH checking

load ../test_helper

setup() {
  # Create temporary test directory
  TEST_TMPDIR="$(mktemp -d)"
  export HOME="${TEST_TMPDIR}"
  export PULSE_DIR="${TEST_TMPDIR}/.local/share/pulse"
  export PULSE_CACHE_DIR="${TEST_TMPDIR}/.cache/pulse"
  export PULSE_LOCK_FILE="${PULSE_DIR}/plugins.lock"
  mkdir -p "${PULSE_DIR}/plugins"
  mkdir -p "${PULSE_CACHE_DIR}"
  
  # Copy necessary files for doctor command
  cp -r "${PULSE_ROOT}/lib" "${PULSE_DIR}/"
  cp -r "${PULSE_ROOT}/bin" "${PULSE_DIR}/"
  cp "${PULSE_ROOT}/pulse.zsh" "${PULSE_DIR}/"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

@test "doctor.zsh contains modern PATH management suggestion" {
  # Simply verify the doctor command file has the updated guidance
  local doctor_file="${PULSE_ROOT}/lib/cli/commands/doctor.zsh"
  
  # Should mention modern Zsh approach
  grep -q "typeset -TUx PATH path" "$doctor_file" || {
    echo "Expected doctor.zsh to suggest modern PATH management"
    return 1
  }
  
  # Should mention path array usage
  grep -q "path=.*\$HOME/.local/bin" "$doctor_file" || {
    echo "Expected doctor.zsh to show path array usage"
    return 1
  }
  
  # Should still mention traditional method as alternative
  grep -q "export PATH=" "$doctor_file" || {
    echo "Expected doctor.zsh to show traditional method as alternative"
    return 1
  }
}
