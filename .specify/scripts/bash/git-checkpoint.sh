#!/usr/bin/env bash
set -euo pipefail

# Minimal Git checkpoint helper for Spec Kit.
# Creates repo if missing, ensures feature branch, commits staged changes with Conventional Commits, and tags the step.

# Defaults
TYPE="chore"
SCOPE="spec"
STEP="${SPECKIT_STEP:-}"
SUMMARY=""
BRANCH=""
TAG="true"
ALL_STAGE="false"
DRY_RUN="false"
FILES=()

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g; s/-+/-/g'
}

usage() {
  cat <<EOF
Usage: $0 --step <name> [--summary "<text>"] [--type <type>] [--scope <scope>] [--branch <name>] [--tag|--no-tag] [--all] [--files <f1> <f2> ...] [--dry-run]
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) TYPE="${2:-}"; shift 2 ;;
    --scope) SCOPE="${2:-}"; shift 2 ;;
    --step) STEP="${2:-}"; shift 2 ;;
    --summary) SUMMARY="${2:-}"; shift 2 ;;
    --branch) BRANCH="${2:-}"; shift 2 ;;
    --tag) TAG="true"; shift ;;
    --no-tag) TAG="false"; shift ;;
    --all) ALL_STAGE="true"; shift ;;
    --files) shift; while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do FILES+=("$1"); shift; done ;;
    --dry-run) DRY_RUN="true"; shift ;;
    -h|--help) usage ;;
    *) FILES+=("$1"); shift ;;
  esac
done

infer_step() {
  if [[ -n "$STEP" ]]; then return; fi
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    last_paths="$(git status --porcelain | awk '{print $2}' | paste -sd' ' -)"
  else
    last_paths="$(ls -1 2>/dev/null || true)"
  fi
  case "$last_paths" in
    *constitution*|*memory/constitution.md*) STEP="constitution" ;;
    *spec*|*specs/*|*spec.md*) STEP="specify" ;;
    *clarif*) STEP="clarify" ;;
    *plan*|*plans/*|*plan.md*) STEP="plan" ;;
    *task*|*tasks/*|*tasks.md*) STEP="tasks" ;;
    *analy*) STEP="analyze" ;;
    *) STEP="implement" ;;
  esac
}
infer_step

case "$STEP" in
  implement) TYPE="${TYPE:-feat}" ;;
  *) TYPE="chore" ;;
esac
[[ -z "$SUMMARY" ]] && SUMMARY="Checkpoint: ${STEP}"

ensure_repo() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then return; fi
  echo "Initializing new Git repository..."
  git init -q
  if ! git rev-parse HEAD >/dev/null 2>&1; then git checkout -q -b main; fi
  if [[ ! -f .gitignore ]]; then
    cat > .gitignore <<'GITIGNORE'
# Spec Kit defaults
.speckit/
.memory/
.genreleases/
.env
.venv/
venv/
__pycache__/
dist/
build/
node_modules/
.DS_Store
.vscode/
.idea/
GITIGNORE
    git add .gitignore
    git commit -qm "chore(repo): add default .gitignore"
  fi
}

ensure_branch() {
  local current; current="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
  if [[ -n "${BRANCH}" ]]; then
    if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then [[ "$current" != "$BRANCH" ]] && git checkout -q "$BRANCH"; else git checkout -q -b "$BRANCH"; fi
    return
  fi
  if [[ "$current" == "main" || "$current" == "master" || -z "$current" ]]; then
    repo_base="$(basename "$(pwd)")"
    base_slug="$(slugify "${SPECKIT_FEATURE:-$repo_base}")"
    step_slug="$(slugify "$STEP")"
    BRANCH="feat/${base_slug}-${step_slug}"
    if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then git checkout -q "$BRANCH"; else git checkout -q -b "$BRANCH"; fi
  fi
}

stage_changes() {
  if [[ "${ALL_STAGE}" == "true" ]]; then git add -A; return; fi
  if [[ ${#FILES[@]} -gt 0 ]]; then git add -- "${FILES[@]}"; return; fi
  local paths=(memory specs plans tasks contracts docs src app lib test tests templates scripts .github .claude .cursor .windsurf .gemini .qwen .amazonq .roo .kilocode .augment .opencode .codex)
  local to_add=()
  for p in "${paths[@]}"; do [[ -e "$p" ]] && to_add+=("$p"); done
  [[ ${#to_add[@]} -gt 0 ]] && git add -- "${to_add[@]}" || true
}

create_commit() {
  if git diff --cached --quiet; then echo "Nothing to commit."; exit 0; fi
  local scope_part=""; [[ -n "$SCOPE" ]] && scope_part="(${SCOPE})"
  local header="${TYPE}${scope_part}: ${SUMMARY}"
  local staged_files; staged_files="$(git diff --cached --name-only | sed 's/^/ - /')"
  local body="Step: ${STEP}
Branch: $(git rev-parse --abbrev-ref HEAD)
Files:
${staged_files}"
  if [[ "${DRY_RUN}" == "true" ]]; then echo "[DRY RUN] $header"; echo; echo "$body"; exit 0; fi
  git commit -m "$header" -m "$body"
  if [[ "${TAG}" == "true" && -n "${STEP}" ]]; then
    ts="$(date +%Y%m%d-%H%M%S)"; tag_name="sdd/${STEP}/${ts}"
    git tag -a "$tag_name" -m "Checkpoint for ${STEP} at ${ts}" || true
    echo "Tagged: $tag_name"
  fi
  echo "Committed: $(git rev-parse --short HEAD) on $(git rev-parse --abbrev-ref HEAD)"
}

ensure_repo
ensure_branch
stage_changes
create_commit
