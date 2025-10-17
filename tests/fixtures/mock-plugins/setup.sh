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
  if [[ ! -d "${plugin_dir}" ]]; then
    echo "Error: Plugin directory '${plugin_dir}' does not exist." >&2
    exit 1
  fi
  if [[ ! -w "${plugin_dir}" ]]; then
    echo "Error: Plugin directory '${plugin_dir}' is not writable." >&2
    exit 1
  fi
  find "${plugin_dir}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to clean plugin directory '${plugin_dir}'." >&2
    exit 1
  fi

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

init_ohmyzsh() {
  local dir="$1"
  mkdir -p "${dir}/lib" "${dir}/plugins/git" "${dir}/plugins/extra"

  cat > "${dir}/lib/git.zsh" <<'LIB'
# oh-my-zsh git library
export OHMYZSH_GIT_LIB=1
LIB

  cat > "${dir}/lib/unused.zsh" <<'LIB'
# unused library fixture
export OHMYZSH_UNUSED=1
LIB

  cat > "${dir}/plugins/git/git.plugin.zsh" <<'PLUG'
# oh-my-zsh git plugin fixture
source "$ZSH/lib/git.zsh"
PLUG

  cat > "${dir}/plugins/extra/extra.plugin.zsh" <<'PLUG'
# extra plugin not used in sparse checkout tests
export OHMYZSH_EXTRA=1
PLUG

  git -C "$dir" add lib/git.zsh lib/unused.zsh plugins/git/git.plugin.zsh plugins/extra/extra.plugin.zsh
  git -C "$dir" commit -q -m "Initial ohmyzsh fixture"
  git -C "$dir" branch -M main
}

init_prezto() {
  local dir="$1"
  mkdir -p "${dir}/modules/git" "${dir}/modules/git/functions" "${dir}/modules/environment" "${dir}/modules/prompt"

  cat > "${dir}/modules/environment/init.zsh" <<'ENV'
# prezto environment module fixture
export PREZTO_ENVIRONMENT=1
ENV

  cat > "${dir}/modules/environment/unused.zsh" <<'ENV'
# unused prezto environment helper
export PREZTO_ENVIRONMENT_UNUSED=1
ENV

  cat > "${dir}/modules/git/init.zsh" <<'MOD'
# prezto git module fixture
source "$ZPREZTODIR/modules/environment/init.zsh"
MOD

  cat > "${dir}/modules/git/functions/git-aliases.zsh" <<'MOD'
# prezto git aliases fixture
alias gtest='git status'
MOD

  cat > "${dir}/modules/prompt/init.zsh" <<'MOD'
# unused prompt module
export PREZTO_PROMPT_UNUSED=1
MOD

  git -C "$dir" add modules/git/init.zsh modules/git/functions/git-aliases.zsh modules/environment/init.zsh modules/environment/unused.zsh modules/prompt/init.zsh
  git -C "$dir" commit -q -m "Initial prezto fixture"
  git -C "$dir" branch -M main
}

main() {
  init_repo "plugin-a" init_plugin_a
  init_repo "plugin-b" init_plugin_b
  init_repo "plugin-c" init_plugin_c
  init_repo "ohmyzsh" init_ohmyzsh
  init_repo "prezto" init_prezto
  echo "Mock plugin fixtures initialized"
}

main "$@"
