---
description: Orchestrate the full Spec-Driven Development workflow, recommending the next command and a Git checkpoint after each step.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Goal

**Guided Mode** orchestrates the complete Spec-Driven Development (SDD) workflow from initial project setup through implementation. This command acts as your workflow navigator, analyzing the current state of your project artifacts and recommending the next appropriate step with ready-to-use prompts.

The standard SDD workflow is:

1. **constitution** → Define project principles and quality gates
2. **specify** → Create feature specification (what/why)
3. **clarify** → Resolve ambiguities in the specification
4. **plan** → Design technical implementation
5. **tasks** → Break down work into executable tasks
6. **analyze** → Validate consistency across artifacts
7. **implement** → Execute the implementation

After each step, the guide recommends checkpointing your progress with `/speckit.checkpoint`.

## Execution Flow

### 1. Initialize Context

Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` once from repo root and parse JSON output for absolute paths:

- FEATURE_DIR (current feature directory)
- FEATURE_SPEC (spec.md path if exists)
- IMPL_PLAN (plan.md path if exists)
- TASKS (tasks.md path if exists)
- CONSTITUTION (.specify/memory/constitution.md)

**Error handling:**

- If JSON parsing fails: Report error and suggest running the script manually to debug
- If repo root cannot be determined: ERROR "Not in a Spec Kit project - run 'specify init' first"
- For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### 2. Assess Current State

Analyze the presence and quality of each artifact to determine workflow position:

#### Constitution Check

- **Path**: `.specify/memory/constitution.md`
- **Assessment**:
  - ✓ EXISTS & COMPLETE: Constitution has been ratified with all principles defined
  - ⚠ EXISTS & INCOMPLETE: Constitution exists but has placeholder tokens `[LIKE_THIS]`
  - ✗ MISSING: Constitution file does not exist

#### Feature Specification Check

- **Path**: FEATURE_SPEC (`features/{feature-name}/spec.md`)
- **Assessment**:
  - ✓ EXISTS & COMPLETE: Has functional requirements, user stories, acceptance criteria, no [NEEDS CLARIFICATION] markers
  - ⚠ EXISTS & NEEDS CLARIFICATION: Contains [NEEDS CLARIFICATION] markers or missing critical sections
  - ⚠ EXISTS & INCOMPLETE: Missing mandatory sections (requirements, user stories, or acceptance criteria)
  - ✗ MISSING: No feature spec file found

#### Implementation Plan Check

- **Path**: IMPL_PLAN (`features/{feature-name}/plan.md`)
- **Assessment**:
  - ✓ EXISTS & COMPLETE: Has tech stack, architecture, data model, Phase 1 artifacts complete
  - ⚠ EXISTS & INCOMPLETE: Template only or missing critical sections (tech stack, structure)
  - ✗ MISSING: No plan file found

#### Task List Check

- **Path**: TASKS (`features/{feature-name}/tasks.md`)
- **Assessment**:
  - ✓ EXISTS & COMPLETE: Has numbered tasks (T001, T002...), dependencies, and phase grouping
  - ⚠ EXISTS & INCOMPLETE: Template only or tasks lack clear file paths/dependencies
  - ✗ MISSING: No tasks file found

#### Implementation Status Check

- If TASKS exists and is complete:
  - Count total tasks vs completed tasks (marked with [X] or [x])
  - Calculate progress percentage
  - Identify current phase based on uncompleted tasks

### 3. Determine Next Step

Based on the state assessment, determine the recommended next command using this decision logic:

```text
IF constitution is MISSING or INCOMPLETE:
  → NEXT: /speckit.constitution

ELSE IF spec is MISSING:
  → NEXT: /speckit.specify

ELSE IF spec has [NEEDS CLARIFICATION] markers:
  → NEXT: /speckit.clarify

ELSE IF spec is INCOMPLETE:
  → NEXT: /speckit.specify (to complete the spec)

ELSE IF plan is MISSING:
  → NEXT: /speckit.plan

ELSE IF plan is INCOMPLETE:
  → NEXT: /speckit.plan (to complete the plan)

ELSE IF tasks is MISSING:
  → NEXT: /speckit.tasks

ELSE IF tasks is INCOMPLETE:
  → NEXT: /speckit.tasks (to complete tasks)

ELSE IF analyze has not been run (no analysis report in feature dir):
  → NEXT: /speckit.analyze

ELSE IF implementation is INCOMPLETE (tasks with [ ] remaining):
  → NEXT: /speckit.implement

ELSE:
  → COMPLETE: Feature is implemented; suggest final checkpoint and next feature
```

### 4. Generate Contextual Recommendations

For the determined next step, provide:

#### A. Current State Summary

Present a clean status table showing the state of all artifacts:

| Artifact | Status | Details |
|----------|--------|---------|
| Constitution | ✓/⚠/✗ | Brief status description |
| Specification | ✓/⚠/✗ | Brief status description |
| Plan | ✓/⚠/✗ | Brief status description |
| Tasks | ✓/⚠/✗ | Brief status description |
| Implementation | ✓/⚠/✗/🔄 | Brief status description |

Status symbols:

- ✓ Complete
- ⚠ Incomplete/Needs Attention
- ✗ Missing
- 🔄 In Progress

#### B. Recommended Command

Provide the specific command to run next with a suggested prompt:

**Command**: `/speckit.{command-name}`

**Suggested Prompt**:

```text
/speckit.{command-name} {context-specific-suggestion}
```

**Why**: {1-2 sentence explanation of why this is the next step}

**What It Will Do**: {Brief description of expected outcomes}

#### C. Context-Specific Prompt Suggestions

Generate intelligent prompt suggestions based on the current state:

- **constitution**: "Create principles focused on {inferred-from-readme: testing, security, performance, code quality}"
- **specify**: "Feature: {user-provided-description or 'Describe your feature here'}"
- **clarify**: "Ready to resolve ambiguities" (no additional context needed)
- **plan**: "Tech stack: {inferred-from-existing-code or suggest: Node.js/Python/Go/etc.} with {framework-suggestion}"
- **tasks**: "Generate executable tasks" (uses existing spec/plan)
- **analyze**: "Perform consistency validation" (no additional context needed)
- **implement**: "Execute implementation plan" (no additional context needed)

**Inference Rules:**

- Check for package.json, requirements.txt, go.mod, pom.xml to infer language
- Check for framework imports in existing code
- Use constitution principles to suggest testing/quality focus
- Use README.md description to suggest feature contexts

#### D. Ready-to-Paste Checkpoint

Based on the last completed step, provide a ready-to-use checkpoint command:

```text
/speckit.checkpoint "{inferred-step}: {one-line-summary}"
```

**Checkpoint inference examples:**

- After constitution: "constitution: project principles established"
- After specify: "spec: {feature-name} specified"
- After clarify: "spec: ambiguities resolved"
- After plan: "plan: architecture defined"
- After tasks: "tasks: work breakdown complete"
- After analyze: "analysis: artifacts validated"
- After implement: "feat: {feature-name} implemented"

### 5. Interactive Confirmation

Ask the user to confirm before proceeding (non-blocking):

**Proceed?**

Reply with:

- **"yes"** or **"recommended"** to run the suggested command
- **"checkpoint first"** to create a Git checkpoint before proceeding
- **"skip"** to skip to a different step (you'll be asked which one)
- **"info"** to get more details about the recommended command
- **"status"** to see the full workflow status again
- **"no"** or **"stop"** to end guided mode

**Wait for user response** before taking action.

### 6. Handle User Response

Based on user's reply:

- **"yes"** or **"recommended"**: Acknowledge and provide the ready-to-paste command again
- **"info"**: Provide detailed explanation of the recommended command (read from that command's description)
- **"status"**: Re-display the full status table with more details
- **"no"** or **"stop"**: Acknowledge and end (suggest they can run `/speckit.guide` again anytime)

## Operating Principles

### Minimal Friction

- Provide ready-to-paste commands; never require the user to construct prompts from scratch
- Use intelligent defaults based on project context
- Make recommendations, don't block or require decisions for every choice
- If information is missing, suggest reasonable defaults in the prompt

### Context Awareness

- Infer language/framework from existing project files
- Reference constitution principles when suggesting next steps
- Track progress through the workflow without manual status tracking
- Detect partially completed steps and recommend completion or continuation

### Non-Prescriptive

- Always allow users to skip or go to a different step
- Acknowledge that workflows may not be perfectly linear
- Support iterative refinement (going back to clarify after planning is valid)
- Never force a particular technology or approach

### Progress Preservation

- Recommend checkpoints after completing each major step
- Suggest descriptive checkpoint messages based on work completed
- Encourage frequent, atomic Git commits during implementation
- Make it easy to pause and resume work at any point

## Error Handling

### Missing Prerequisites

If a required prerequisite is missing:

1. **Identify the gap**: "Cannot proceed with {command} because {prerequisite} is missing"
2. **Recommend fix**: "First, complete: /speckit.{prerequisite-command} {suggested-prompt}"
3. **Explain why**: "{1 sentence explaining the dependency}"

### Invalid State

If artifacts are in an inconsistent state:

1. **Report the issue**: "Detected inconsistency: {specific-problem}"
2. **Suggest resolution**: Consider options:
   - Re-run earlier command to fix
   - Run `/speckit.analyze` to identify all issues
   - Manual fix with specific guidance
3. **Do not proceed** until resolved

### Workflow Deviation

If user wants to skip ahead:

1. **Acknowledge request**: "You want to skip to {command}"
2. **Assess safety**: Check if prerequisites are met
3. **Warn if risky**: "Skipping {step} may cause {specific-problem}"
4. **Offer alternatives**:
   - "I can help you quickly complete {step} first (recommended)"
   - "Or proceed with {command} anyway (may need rework later)"
5. **Let user decide**

## Output Format

Always structure your response as:

1. **Current Workflow Status** (table)
2. **Recommended Next Step** (command + prompt + reasoning)
3. **Ready-to-Paste Checkpoint** (for last completed step)
4. **Proceed?** (interactive options)

Keep the output clean, scannable, and action-oriented.

## Notes

- Guided Mode is **stateless**: Each run assesses current state from scratch
- Running `/speckit.guide` multiple times is safe and encouraged
- The guide adapts to your actual workflow; deviations are acceptable
- Use `/speckit.guide {context}` to provide additional context for recommendations

## Next Step (Guided Mode)

This command IS the guide - run it anytime to get your next step:

```text
/speckit.guide
```

Or provide context to get more targeted recommendations:

```text
/speckit.guide "I want to implement authentication"
/speckit.guide "Skip planning, jump to implementation"
/speckit.guide "Review my progress so far"
```
