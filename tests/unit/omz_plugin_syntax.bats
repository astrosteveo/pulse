#!/usr/bin/env bats
# Unit tests for Oh-My-Zsh plugin syntax and annotations
# Tests omz:, prezto: shorthands and path: annotations

load ../test_helper

setup() {
  # Create temporary test directory
  TEST_TMPDIR="$(mktemp -d)"
  export PULSE_DIR="${TEST_TMPDIR}/.local/share/pulse"
  export PULSE_CACHE_DIR="${TEST_TMPDIR}/.cache/pulse"
  mkdir -p "${PULSE_DIR}/plugins"
  mkdir -p "${PULSE_CACHE_DIR}"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

# Test: Parse omz:plugins/git shorthand
@test "parses omz:plugins/git shorthand correctly" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  
  result=($(_pulse_parse_plugin_spec "omz:plugins/git"))
  
  # Should return: url name ref subpath kind
  # Arrays are 0-indexed in bash/bats
  [[ "${result[0]}" == "https://github.com/ohmyzsh/ohmyzsh.git" ]]
  [[ "${result[1]}" == "ohmyzsh" ]]
  [[ "${result[2]}" == "-" ]]
  [[ "${result[3]}" == "plugins/git" ]]
  [[ "${result[4]}" == "path" ]]
}

# Test: Parse omz:lib/git shorthand
@test "parses omz:lib/git shorthand correctly" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  
  result=($(_pulse_parse_plugin_spec "omz:lib/git"))
  
  [[ "${result[0]}" == "https://github.com/ohmyzsh/ohmyzsh.git" ]]
  [[ "${result[1]}" == "ohmyzsh" ]]
  [[ "${result[3]}" == "lib/git" ]]
  [[ "${result[4]}" == "path" ]]
}

# Test: Parse prezto:modules/git shorthand
@test "parses prezto:modules/git shorthand correctly" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  
  result=($(_pulse_parse_plugin_spec "prezto:modules/git"))
  
  [[ "${result[0]}" == "https://github.com/sorin-ionescu/prezto.git" ]]
  [[ "${result[1]}" == "prezto" ]]
  [[ "${result[3]}" == "modules/git" ]]
  [[ "${result[4]}" == "path" ]]
}

# Test: Parse path: annotation
@test "parses path: annotation correctly" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  
  result=($(_pulse_parse_plugin_spec "ohmyzsh/ohmyzsh path:plugins/kubectl"))
  
  [[ "${result[0]}" == "https://github.com/ohmyzsh/ohmyzsh.git" ]]
  [[ "${result[1]}" == "ohmyzsh_plugins_kubectl" ]]
  [[ "${result[3]}" == "plugins/kubectl" ]]
}

# Test: Parse kind: annotation
@test "parses kind: annotation correctly" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  
  result=($(_pulse_parse_plugin_spec "user/repo kind:defer"))
  
  [[ "${result[0]}" == "https://github.com/user/repo.git" ]]
  [[ "${result[4]}" == "defer" ]]
}

# Test: Parse combined annotations
@test "parses combined path: and kind: annotations" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  
  result=($(_pulse_parse_plugin_spec "user/repo path:subdir kind:fpath"))
  
  [[ "${result[0]}" == "https://github.com/user/repo.git" ]]
  [[ "${result[3]}" == "subdir" ]]
  [[ "${result[4]}" == "fpath" ]]
}

# Test: Resolve omz: path correctly
@test "resolves omz:plugins/git path correctly" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  
  result=$(_pulse_resolve_plugin_source "omz:plugins/git")
  
  [[ "$result" == "${PULSE_DIR}/plugins/ohmyzsh/plugins/git" ]]
}

# Test: Resolve prezto: path correctly
@test "resolves prezto:modules/git path correctly" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  
  result=$(_pulse_resolve_plugin_source "prezto:modules/git")
  
  [[ "$result" == "${PULSE_DIR}/plugins/prezto/modules/git" ]]
}

# Test: Resolve path: annotation correctly
@test "resolves path: annotation correctly" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  
  result=$(_pulse_resolve_plugin_source "ohmyzsh/ohmyzsh path:plugins/kubectl")
  
  [[ "$result" == "${PULSE_DIR}/plugins/ohmyzsh/plugins/kubectl" ]]
}

# Test: Plugin name generation for subpaths
@test "generates unique plugin names for subpaths" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  
  result1=($(_pulse_parse_plugin_spec "ohmyzsh/ohmyzsh path:plugins/git"))
  result2=($(_pulse_parse_plugin_spec "ohmyzsh/ohmyzsh path:plugins/kubectl"))
  
  # Names should be different
  [[ "${result1[1]}" != "${result2[1]}" ]]
  
  # Names should include subpath
  [[ "${result1[1]}" == "ohmyzsh_plugins_git" ]]
  [[ "${result2[1]}" == "ohmyzsh_plugins_kubectl" ]]
}

# Test: omz: shorthand all use same repo name
@test "omz: shorthand plugins use same base name" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  
  result1=($(_pulse_parse_plugin_spec "omz:plugins/git"))
  result2=($(_pulse_parse_plugin_spec "omz:lib/git"))
  
  # Both should use "ohmyzsh" as the name since they're from same repo
  [[ "${result1[1]}" == "ohmyzsh" ]]
  [[ "${result2[1]}" == "ohmyzsh" ]]
}

# Test: Empty values use "-" placeholder
@test "empty values use - placeholder" {
  source "${PULSE_ROOT}/lib/plugin-engine.zsh"
  
  result=($(_pulse_parse_plugin_spec "user/repo"))
  
  # ref should be "-" (no version specified)
  [[ "${result[2]}" == "-" ]]
  
  # subpath should be "-" (no path annotation)
  [[ "${result[3]}" == "-" ]]
}
