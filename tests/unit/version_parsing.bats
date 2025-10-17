#!/usr/bin/env bats
# Unit tests for version parsing in plugin engine
# Tests @latest keyword support (US1)

load ../test_helper

setup() {
  # Create temporary test directory
  TEST_TMPDIR="$(mktemp -d)"
  export PULSE_DIR="${TEST_TMPDIR}/.local/share/pulse"
  mkdir -p "${PULSE_DIR}/plugins"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

# Test: @latest should parse as empty ref (default branch)
@test "parses @latest as empty ref" {
  # Parse in a zsh subprocess and capture the output
  run zsh -c "
    source lib/plugin-engine.zsh
    _pulse_parse_plugin_spec 'zsh-users/zsh-syntax-highlighting@latest'
  "

  [ "$status" -eq 0 ]

  # Function returns: "plugin_url plugin_name plugin_ref plugin_subpath plugin_kind" (5 values)
  # When ref is empty (@latest), ref field should be "-" (placeholder for empty)
  [[ "$output" =~ "zsh-users/zsh-syntax-highlighting" ]]
  [[ "$output" =~ "zsh-syntax-highlighting" ]]
  # Count words - should be 5 (url, name, ref, subpath, kind) with "-" for empty fields
  local word_count=$(echo "$output" | wc -w)
  [[ "$word_count" -eq 5 ]]
  # Check that ref is "-" (empty/latest)
  [[ "$output" =~ " - " ]]
}

# Test: @latest should behave identically to omitted version
@test "@latest behaves identically to omitted version" {
  # Parse with @latest
  run zsh -c "source lib/plugin-engine.zsh; _pulse_parse_plugin_spec 'zsh-users/zsh-autosuggestions@latest'"
  [ "$status" -eq 0 ]
  local result1="$output"

  # Parse without version
  run zsh -c "source lib/plugin-engine.zsh; _pulse_parse_plugin_spec 'zsh-users/zsh-autosuggestions'"
  [ "$status" -eq 0 ]
  local result2="$output"

  # Both should produce identical output
  [[ "$result1" == "$result2" ]]
}

# Test: @latest with tag should still allow explicit version override
@test "explicit version tag overrides @latest pattern" {
  run zsh -c "source lib/plugin-engine.zsh; _pulse_parse_plugin_spec 'zsh-users/zsh-completions@v0.34.0'"
  [ "$status" -eq 0 ]

  # Should preserve the explicit version tag
  [[ "$output" =~ "zsh-completions" ]]
  [[ "$output" =~ "v0.34.0" ]]
  # Should have 5 words (url, name, ref, subpath, kind)
  local word_count=$(echo "$output" | wc -w)
  [[ "$word_count" -eq 5 ]]
}

# Test: @latest is case-sensitive
@test "@latest is case-sensitive (LATEST should not match)" {
  run zsh -c "source lib/plugin-engine.zsh; _pulse_parse_plugin_spec 'zsh-users/plugin@LATEST'"
  [ "$status" -eq 0 ]

  # Should NOT treat LATEST as special keyword - it should be preserved as a tag
  [[ "$output" =~ "plugin" ]]
  [[ "$output" =~ "LATEST" ]]
  # Should have 5 words (url, name, ref, subpath, kind) with LATEST as the ref
  local word_count=$(echo "$output" | wc -w)
  [[ "$word_count" -eq 5 ]]
}
