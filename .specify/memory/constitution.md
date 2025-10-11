<!--
SYNC IMPACT REPORT - Constitution v1.0.0
═════════════════════════════════════════════════════════════════════════════

VERSION CHANGE: NEW → 1.0.0
BUMP RATIONALE: Initial constitution establishing core principles for Pulse

ADDED PRINCIPLES:
  • I. Radical Simplicity - Every line of code is a liability
  • II. Quality Over Features - High standards before new functionality
  • III. Test-Driven Reliability - All code must be tested (NON-NEGOTIABLE)
  • IV. Consistent User Experience - Predictable, intuitive behavior
  • V. Zero Configuration - Works out of the box

ADDED SECTIONS:
  • Code Standards - Establishes shell scripting quality requirements
  • Development Workflow - Defines contribution and review process

TEMPLATES REQUIRING UPDATES:
  ✅ plan-template.md - Updated with Pulse-specific constitution checks
  ✅ spec-template.md - No changes needed (technology-agnostic)
  ✅ tasks-template.md - Updated with Pulse testing requirements
  ⚠️  checklist-template.md - Review recommended for Pulse workflow
  ⚠️  agent-file-template.md - Review recommended for Pulse context

FOLLOW-UP TODOS:
  • Validate all lib/*.zsh files against Code Standards section
  • Create testing framework for Zsh shell code
  • Document contribution guidelines in CONTRIBUTING.md
  • Establish performance benchmarks for shell startup time

═════════════════════════════════════════════════════════════════════════════
-->

# Pulse Constitution

## Core Principles

### I. Radical Simplicity

Every line of code is a liability. Pulse fights complexity at every level:

- **Minimal by default**: Include only essential functionality
- **No bloat**: Remove features that don't serve 90% of users
- **Question every addition**: New features must justify their existence
- **Prefer deletion**: Removing code is better than adding code
- **YAGNI strictly enforced**: You Aren't Gonna Need It—build only what users need now

**Rationale**: Complexity is the enemy of reliability, maintainability, and
performance. A smaller codebase is easier to understand, test, and debug.

### II. Quality Over Features

High code quality is non-negotiable. Standards come before capabilities:

- **Readable code**: Clear variable names, logical structure, helpful comments
- **Consistent style**: Follow established Zsh conventions and formatting
- **Proper error handling**: Fail gracefully with informative messages
- **Documentation required**: Every function must explain its purpose and usage
- **Performance matters**: Profile before merging; no performance regressions

**Rationale**: Users depend on Pulse as foundational infrastructure. Quality
issues cascade across their entire shell environment.

### III. Test-Driven Reliability (NON-NEGOTIABLE)

All code changes require tests. No exceptions:

- **Tests first**: Write tests that fail, then make them pass
- **Coverage mandatory**: Every function must have test coverage
- **Integration tests**: Critical workflows must be tested end-to-end
- **Real-world scenarios**: Test with actual Zsh environments
- **Continuous validation**: Tests run on every commit

**Rationale**: Shell code is notoriously fragile across different environments,
Zsh versions, and terminal configurations. Comprehensive testing is the only
way to ensure reliability.

### IV. Consistent User Experience

Pulse must be predictable and intuitive:

- **Intelligent defaults**: Work correctly without configuration
- **Consistent behavior**: Similar operations use similar patterns
- **Clear feedback**: Users understand what's happening and why
- **No surprises**: Behavior changes require major version bumps
- **Backward compatibility**: Breaking changes only when absolutely necessary

**Rationale**: Users integrate Pulse into their daily workflow. Unpredictable
behavior or breaking changes disrupt productivity and erode trust.

### V. Zero Configuration

Pulse works out of the box:

- **Functional immediately**: No setup steps required
- **Smart detection**: Automatically discover and configure environment
- **Sensible defaults**: Pre-configured for common use cases
- **Optional customization**: Advanced users can tune, but don't have to
- **Self-healing**: Recover gracefully from configuration issues

**Rationale**: Configuration is complexity. Every configuration option is a
decision users must make and a potential point of failure.

## Code Standards

### Shell Scripting Requirements

- **POSIX compatibility**: Use Zsh features only when necessary
- **Shellcheck compliance**: All scripts pass shellcheck with no warnings
- **Quoting discipline**: Always quote variables unless splitting intended
- **Error propagation**: Use `set -e` equivalent or explicit error checks
- **Subshell awareness**: Understand and document variable scope

### File Organization

- **Module structure**: Each lib/*.zsh file has single, clear purpose
- **Load order matters**: Document dependencies and load sequence
- **Namespacing**: Prefix functions to avoid conflicts (pulse_*)
- **Lazy loading**: Defer expensive operations until needed

## Development Workflow

### Contribution Process

1. **Discuss first**: Open issue before significant changes
2. **Branch per feature**: Use descriptive branch names
3. **Tests included**: Every PR includes relevant tests
4. **Documentation updated**: Code and README stay in sync
5. **Review required**: All changes reviewed before merge

### Quality Gates

- All tests pass
- Shellcheck shows no warnings
- No performance regression measured
- Documentation complete
- Constitution compliance verified

### Review Checklist

- Does this add unnecessary complexity?
- Could this be simpler?
- Are tests comprehensive?
- Is error handling robust?
- Does this maintain backward compatibility?

## Governance

This constitution supersedes all other development practices and guidelines.

**Amendment Process**:

1. Propose change via issue with detailed rationale
2. Community discussion period (minimum 7 days)
3. Approval requires consensus from maintainers
4. Version bump follows semantic versioning
5. Update all dependent templates and documentation

**Compliance**:

- All pull requests must be reviewed for constitutional compliance
- Any complexity must be explicitly justified in code or PR description
- Violations block merge until resolved or exception granted
- Regular audits ensure ongoing alignment with principles

**Versioning Policy**:

- **MAJOR**: Breaking changes to principles or governance
- **MINOR**: New principle added or significant expansion
- **PATCH**: Clarifications, typos, non-semantic refinements

**Version**: 1.0.0 | **Ratified**: 2025-10-10 | **Last Amended**: 2025-10-10
