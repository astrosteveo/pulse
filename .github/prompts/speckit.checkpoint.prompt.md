---
description: Create a Git checkpoint with a Conventional Commit after the current Spec Kit step; initialize repo/branch if needed and tag the step.
---

## User Input

Optional one-line summary or override defaults.

```text
$ARGUMENTS
```

## Goal

Create a minimal, consistent Git checkpoint to preserve progress at key workflow milestones. This command automates Git operations following Conventional Commit conventions and Spec-Driven Development (SDD) workflow tagging.

**Key Benefits:**

- Automated commit message formatting
- Workflow step tracking via tags
- Safe branch management
- Idempotent execution (re-running is safe)

## Execution Flow

### 1. Parse User Input

Extract and validate the optional summary from `$ARGUMENTS`:

- If provided: Use as custom commit summary
- If empty: Infer summary based on workflow context (see Step 4)
- Validation: Strip leading/trailing whitespace, ensure single line

### 2. Initialize Git Repository (If Needed)

Check if the current directory is a Git repository:

```bash
git rev-parse --git-dir 2>/dev/null
```

**If NOT a Git repository:**

1. **Initialize**: Run `git init`
2. **Configure**: Set up initial branch (main)
3. **Report**: "Initialized Git repository"

**If already a Git repository:**

1. **Verify**: Check repository integrity
2. **Proceed**: Continue to step 3

**Error Handling:**

- If `git` command not found: ERROR "Git is not installed. Install from: <https://git-scm.com/>"
- If init fails: ERROR "Failed to initialize Git repository: {reason}"

### 3. Ensure Feature Branch

Determine and checkout the appropriate feature branch:

#### Current Branch Detection

```bash
current_branch=$(git rev-parse --abbrev-ref HEAD)
```

#### Branch Decision Logic

```text
IF current branch is main/master:
  → Create new feature branch: feat/{feature-slug}

ELSE IF current branch matches feat/* pattern:
  → Use current branch (already on feature branch)

ELSE:
  → Ask user: "You're on branch '{current}'. Continue here or switch to feat/{feature-slug}?"
```

#### Feature Slug Derivation

Derive the feature slug from available context (priority order):

1. **From spec.md**: Extract feature name from first heading or YAML front matter
2. **From current directory**: Use `features/{name}/` directory name
3. **From Git branch**: Extract from existing `feat/{slug}` branch name
4. **Fallback**: Use generic slug like `feat/feature-{timestamp}`

**Slug Formatting Rules:**

- Lowercase
- Replace spaces with hyphens
- Remove special characters (keep only alphanumeric and hyphens)
- Max 50 characters
- Example: "User Authentication System" → `user-authentication-system`

#### Create/Checkout Branch

```bash
git checkout -b feat/{feature-slug}  # Create if doesn't exist
git checkout feat/{feature-slug}     # Checkout if exists
```

**Error Handling:**

- If branch creation fails: ERROR "Failed to create feature branch: {reason}"
- If checkout fails: ERROR "Failed to checkout branch: {reason}"

### 4. Infer Commit Metadata

Determine the commit type, scope, and summary based on workflow context:

#### Commit Type Inference

Analyze recent files changed and workflow state:

```text
IF implementing tasks (tasks.md exists with completed items):
  → type: feat

ELSE IF updating spec/plan/tasks templates:
  → type: docs

ELSE IF making constitution changes:
  → type: docs

ELSE IF analyzing artifacts:
  → type: chore

ELSE IF fixing bugs:
  → type: fix

ELSE:
  → type: chore (default)
```

**Type Definitions (Conventional Commits):**

- `feat`: New feature or functionality
- `fix`: Bug fix
- `docs`: Documentation changes
- `chore`: Maintenance, refactoring, or non-feature changes
- `test`: Test additions or modifications
- `refactor`: Code refactoring without behavior changes

#### Scope Inference

Determine the scope based on changed files:

```bash
git diff --staged --name-only
```

```text
IF changes in features/{name}/:
  → scope: {feature-name}

ELSE IF changes in .specify/memory/constitution.md:
  → scope: constitution

ELSE IF changes match spec.md:
  → scope: spec

ELSE IF changes match plan.md:
  → scope: plan

ELSE IF changes match tasks.md:
  → scope: tasks

ELSE:
  → scope: (no scope - omit from commit message)
```

#### Workflow Step Detection

Identify which SDD workflow step was just completed:

```text
IF constitution.md was modified:
  → step: constitution

ELSE IF spec.md was modified but plan.md doesn't exist:
  → step: specify

ELSE IF spec.md was modified and had [NEEDS CLARIFICATION] markers:
  → step: clarify

ELSE IF plan.md was modified:
  → step: plan

ELSE IF tasks.md was modified:
  → step: tasks

ELSE IF analysis report exists in feature dir:
  → step: analyze

ELSE IF tasks show completion markers [X]:
  → step: implement

ELSE:
  → step: checkpoint (generic)
```

#### Summary Generation

Generate commit summary if not provided by user:

**Format**: `{step description} - {brief-context}`

**Examples:**

- constitution: "project principles established"
- specify: "{feature-name} specified"
- clarify: "ambiguities resolved in spec"
- plan: "architecture and tech stack defined"
- tasks: "work breakdown complete"
- analyze: "artifacts validated for consistency"
- implement: "completed {phase-name} implementation"
- checkpoint: "progress saved"

### 5. Stage Relevant Changes

Intelligently stage files related to the current workflow step:

#### Staging Strategy

```bash
git add -A  # Stage all changes by default
```

**Selective Staging (if needed):**

```text
IF only SDD artifacts changed (spec.md, plan.md, tasks.md):
  → Stage only features/ directory

ELSE IF implementation files changed:
  → Stage all (implementation + tests + docs)

ELSE IF constitution changed:
  → Stage .specify/memory/constitution.md

ELSE:
  → Stage all changes
```

**Verification:**

```bash
git diff --staged --stat  # Show what will be committed
```

**Empty Staging Check:**

```bash
if [ -z "$(git diff --staged)" ]; then
  echo "No changes to commit"
  exit 0
fi
```

If no staged changes, exit gracefully without creating a commit.

### 6. Create Conventional Commit

Format and create the commit following Conventional Commit specification:

#### Commit Message Format

```text
{type}({scope}): {summary}

{optional body}

{optional footers}
```

**Rules:**

- Type: Required, lowercase
- Scope: Optional, lowercase, parentheses
- Summary: Required, imperative mood, no period, max 50 chars
- Body: Optional, wrap at 72 chars
- Footers: Optional (e.g., "Closes #123", "BREAKING CHANGE:")

#### Example Messages

```text
feat(user-auth): implement password reset flow

docs(constitution): update to v1.1.0 - add security principles

chore(spec): clarify user permissions requirements

fix(api): resolve token expiration edge case

test(auth): add unit tests for login validation
```

#### Execute Commit

```bash
git commit -m "{formatted-message}"
```

**Error Handling:**

- If commit fails: ERROR "Failed to create commit: {reason}"
- If no staged changes: INFO "No changes to commit" (exit gracefully)

### 7. Create SDD Step Tag

Tag the commit to mark the workflow step milestone:

#### Tag Format

```text
sdd/{step}/{timestamp}
```

**Components:**

- Prefix: `sdd/` (Spec-Driven Development)
- Step: Workflow step name (constitution, specify, clarify, plan, tasks, analyze, implement)
- Timestamp: ISO 8601 format `YYYYMMDD-HHMMSS` or Unix timestamp

**Examples:**

- `sdd/specify/20250111-143022`
- `sdd/plan/20250111-150815`
- `sdd/implement/20250111-163445`

#### Create Lightweight Tag

```bash
git tag "sdd/{step}/{timestamp}"
```

**Tag Description (annotated tag alternative):**

```bash
git tag -a "sdd/{step}/{timestamp}" -m "SDD Checkpoint: {step} - {summary}"
```

**Error Handling:**

- If tag already exists: Skip tag creation (idempotent)
- If tag creation fails: WARN "Failed to create tag, but commit succeeded"

### 8. Report Completion

Output a summary of the checkpoint operation:

**Success Report Format:**

```markdown
## Checkpoint Complete

**Branch**: feat/{feature-slug}
**Commit**: {short-hash} - {commit-message}
**Tag**: sdd/{step}/{timestamp} (if created)
**Files Changed**: {file-count}
**Insertions**: +{lines-added}
**Deletions**: -{lines-removed}

### Summary

{commit-summary}

### Next Steps

{context-aware-suggestions}
```

**Example Output:**

```markdown
## Checkpoint Complete

**Branch**: feat/user-authentication
**Commit**: a3f5c2d - feat(user-auth): implement password reset flow
**Tag**: sdd/implement/20250111-163445
**Files Changed**: 8
**Insertions**: +245
**Deletions**: -12

### Summary

Implemented password reset flow including email verification and token generation.

### Next Steps

Continue implementation or checkpoint again after next phase:

```text
/speckit.implement
/speckit.checkpoint "Next phase completed"
```

```

## Operating Principles

### Idempotent Execution
- Re-running the same checkpoint command is safe
- Won't create duplicate commits if no changes
- Won't fail if branch/tag already exists
- Always checks current state before acting

### Minimal User Input
- Most metadata inferred from context
- User only needs to provide summary if desired
- Smart defaults for type, scope, and step
- No manual Git commands required

### Workflow Integration
- Tightly integrated with SDD workflow phases
- Tags enable workflow tracking and navigation
- Branch naming follows SDD conventions
- Commit messages are searchable and meaningful

### Safety First
- Never overwrites existing commits
- Never force-pushes
- Always verifies Git state before operations
- Provides clear error messages with remediation steps

## Advanced Usage

### Custom Commit Types

Override the inferred commit type:

```text
/speckit.checkpoint "fix: resolved authentication bug"
/speckit.checkpoint "docs: updated API documentation"
```

The command detects the type prefix and uses it.

### Checkpoint Without Summary

Create a checkpoint with just the inferred summary:

```text
/speckit.checkpoint
```

### Multiple Checkpoints Per Step

It's valid to checkpoint multiple times during a single workflow step:

```text
/speckit.checkpoint "completed user model"
/speckit.checkpoint "added validation logic"
/speckit.checkpoint "integrated with auth service"
```

Each gets a unique timestamp tag.

## Error Handling

### Git Not Found

**Error**: "Git is not installed"

**Resolution**:

1. Install Git: <https://git-scm.com/downloads>
2. Verify installation: `git --version`
3. Re-run checkpoint command

### No Changes to Commit

**Message**: "No staged changes found"

**Resolution**:

- This is not an error; nothing to checkpoint
- Make changes first, then run checkpoint
- Or use `/speckit.guide` to see what to do next

### Merge Conflicts

**Error**: "Cannot create commit due to merge conflicts"

**Resolution**:

1. Resolve conflicts manually in affected files
2. Stage resolved files: `git add {file}`
3. Re-run checkpoint command

### Branch Checkout Failed

**Error**: "Failed to checkout branch feat/{slug}"

**Resolution**:

1. Check if there are uncommitted changes: `git status`
2. Commit or stash changes first
3. Re-run checkpoint command

## Git Best Practices

### Commit Frequency

- Checkpoint after each major workflow step
- Checkpoint when switching contexts
- Checkpoint before risky changes
- Checkpoint at end of work session

### Commit Size

- Keep checkpoints focused on single workflow step
- Avoid mixing multiple unrelated changes
- If checkpoint includes too many files, consider splitting

### Commit Messages

- Let the command infer metadata when possible
- Provide custom summary when context isn't obvious
- Use imperative mood: "add feature" not "added feature"
- Keep summary under 50 characters

### Branch Management

- Stay on feature branches during development
- Don't commit directly to main/master
- Use `/speckit.checkpoint` instead of raw `git commit`
- Let the command handle branch creation

## Notes

- Checkpoints are local until explicitly pushed
- Tags are lightweight by default (can use annotated tags)
- Compatible with all Git workflows (GitHub Flow, Git Flow, etc.)
- Commit messages follow Conventional Commits v1.0.0 spec

## Next Step (Guided Mode)

After creating a checkpoint, continue with the workflow:

```text
/speckit.guide
```

Or proceed to the next step directly if you know where you are:

```text
/speckit.specify "Your feature description"
/speckit.clarify
/speckit.plan
/speckit.tasks
/speckit.analyze
/speckit.implement
```
