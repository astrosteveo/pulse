#!/usr/bin/env bash
# Initialize mock plugin git repositories used by integration tests

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_USER_EMAIL="test@example.com"
GIT_USER_NAME="Pulse Test"

init_repo() {
  local plugin_name="$1"
  local initializer="$2"
  local plugin_dir="${ROOT_DIR}/${plugin_name}"

  mkdir -p "${plugin_dir}"

  # Remove any previous git repository contents to ensure deterministic state
  find "${plugin_dir}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

  git -C "${plugin_dir}" init -q
  git -C "${plugin_dir}" config user.email "${GIT_USER_EMAIL}"
  git -C "${plugin_dir}" config user.name "${GIT_USER_NAME}"
  git -C "${plugin_dir}" config commit.gpgsign false >/dev/null

  "${initializer}" "${plugin_dir}"
}

init_plugin_a() {
  local dir="$1"
  cat > "${dir}/plugin-a.plugin.zsh" <<'PLUG'
# Plugin A fixture
export PULSE_PLUGIN_A_LOADED=1
export PULSE_PLUGIN_A_VERSION="1.0"
PLUG
  cat > "${dir}/README.md" <<'DOC'
# Plugin A

Fixture repository with semantic version tags.

## v1.0
DOC

  git -C "$dir" add plugin-a.plugin.zsh README.md
  git -C "$dir" commit -q -m "Initial release"
  git -C "$dir" branch -M main
  git -C "$dir" tag -f v1.0 >/dev/null

  cat > "${dir}/plugin-a.plugin.zsh" <<'PLUG'
# Plugin A fixture
export PULSE_PLUGIN_A_LOADED=1
export PULSE_PLUGIN_A_VERSION="1.1"
PLUG
  cat > "${dir}/README.md" <<'DOC'
# Plugin A

Fixture repository with semantic version tags.

## v1.1
DOC

  git -C "$dir" add plugin-a.plugin.zsh README.md
  git -C "$dir" commit -q -m "Add v1.1 release"
  git -C "$dir" tag -f v1.1 >/dev/null

  cat > "${dir}/plugin-a.plugin.zsh" <<'PLUG'
# Plugin A fixture
export PULSE_PLUGIN_A_LOADED=1
export PULSE_PLUGIN_A_VERSION="2.0"
PLUG
  cat > "${dir}/README.md" <<'DOC'
# Plugin A

Fixture repository with semantic version tags.

## v2.0
DOC

  git -C "$dir" add plugin-a.plugin.zsh README.md
  git -C "$dir" commit -q -m "Add v2.0 release"
  git -C "$dir" tag -f v2.0 >/dev/null
}

init_plugin_b() {
  local dir="$1"
  cat > "${dir}/plugin-b.plugin.zsh" <<'PLUG'
# Plugin B fixture
export PULSE_PLUGIN_B_BRANCH=${PULSE_PLUGIN_B_BRANCH:-main}
PLUG
  echo "# Plugin B" > "${dir}/README.md"

  git -C "$dir" add plugin-b.plugin.zsh README.md
  git -C "$dir" commit -q -m "Initial commit on default branch"
  git -C "$dir" branch -M main

  echo "# Main branch update" >> "${dir}/README.md"
  git -C "$dir" add README.md
  git -C "$dir" commit -q -m "Main branch update"

  git -C "$dir" checkout -q -b develop
  cat >> "${dir}/plugin-b.plugin.zsh" <<'DEV'
export PULSE_PLUGIN_B_FEATURE=1
DEV
  echo "# Develop branch features" >> "${dir}/README.md"
  git -C "$dir" add plugin-b.plugin.zsh README.md
  git -C "$dir" commit -q -m "Develop branch commit"
  git -C "$dir" checkout -q main
}

init_plugin_c() {
  local dir="$1"
  cat > "${dir}/plugin-c.plugin.zsh" <<'PLUG'
# Plugin C fixture
export PULSE_PLUGIN_C_STATE=0
PLUG
  cat > "${dir}/README.md" <<'DOC'
# Plugin C

Commit history fixture.

## 1
DOC

  git -C "$dir" add plugin-c.plugin.zsh README.md
  git -C "$dir" commit -q -m "Initial commit"
  git -C "$dir" branch -M main

  cat > "${dir}/plugin-c.plugin.zsh" <<'PLUG'
# Plugin C fixture
export PULSE_PLUGIN_C_STATE=1
PLUG
  cat > "${dir}/README.md" <<'DOC'
# Plugin C

Commit history fixture.

## 2
DOC

  git -C "$dir" add plugin-c.plugin.zsh README.md
  git -C "$dir" commit -q -m "Second commit"

  cat > "${dir}/plugin-c.plugin.zsh" <<'PLUG'
# Plugin C fixture
export PULSE_PLUGIN_C_STATE=2
PLUG
  cat > "${dir}/README.md" <<'DOC'
# Plugin C

Commit history fixture.

## 3
DOC

  git -C "$dir" add plugin-c.plugin.zsh README.md
  git -C "$dir" commit -q -m "Third commit"
}

main() {
  init_repo "plugin-a" init_plugin_a
  init_repo "plugin-b" init_plugin_b
  init_repo "plugin-c" init_plugin_c
  echo "Mock plugin fixtures initialized"
}

main "$@"
