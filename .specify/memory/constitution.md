<!--
SYNC IMPACT REPORT
==================
Version Change: 1.1.0 → 1.2.0
Modified Principles:
  - Quality Over Features → Enhanced: Explicit zstyle requirement over environment variables
  - Test-Driven Reliability → Strengthened: Enforcement language hardened, penalties clarified
Added Sections: Zsh Best Practices (new subsection under Quality Over Features)
Removed Sections: None
Templates Requiring Updates:
  ✅ .specify/templates/plan-template.md (constitution check language strengthened)
  ✅ .specify/templates/spec-template.md (requirements validation updated)
  ✅ .specify/templates/tasks-template.md (TDD enforcement in task workflow)
  ✅ .github/copilot-instructions.md (core principles version + TDD emphasis updated)
Follow-up TODOs: None
-->

# Pulse Constitution

## Core Principles

### I. Radical Simplicity

Every feature must serve 90% of users—edge cases are explicitly excluded. No simpler alternative can exist to achieve the same goal. Features require documented justification proving they are essential, not convenient. Deletion is considered before addition: complexity is a liability, and every line of code must justify its existence.

**Validation Checklist**:

- [ ] Feature serves 90% of users (not edge case functionality)
- [ ] No simpler alternative exists to achieve the same goal
- [ ] Feature justification documented (why it's essential)
- [ ] Deletion considered before addition

### II. Quality Over Features

Code style MUST follow Zsh conventions and idioms. Error handling strategy is defined before implementation begins. Documentation is mandatory: inline comments for complex logic, user-facing documentation for all features. Performance impact is assessed and measured—no feature ships without understanding its cost.

**Zsh Best Practices (MANDATORY)**:

- **Configuration**: Use `zstyle` over environment variables for framework configuration where applicable
- **Builtins**: Prefer Zsh builtins (`setopt`, `autoload`, `bindkey`, `zle`) over external commands
- **Arrays**: Use Zsh array syntax and features (zero-indexing optional, associative arrays, parameter expansion)
- **Globbing**: Leverage extended glob patterns (`setopt extendedglob`) for file matching
- **Performance**: Avoid subshells (`$(...)`) when builtins suffice; minimize forks
- **Naming**: Prefix all functions with `pulse_` to prevent namespace collisions
- **Completion**: Use `compinit`, `compdef`, and `zstyle` for completion configuration
- **Portability**: Require Zsh ≥5.0, document Zsh-specific features used

**Validation Checklist**:

- [ ] Code style follows Zsh conventions and idioms (zstyle, builtins, arrays)
- [ ] Zsh-specific features documented (version requirements, feature usage)
- [ ] Error handling strategy defined
- [ ] Documentation approach specified
- [ ] Performance impact assessed

### III. Test-Driven Reliability (ABSOLUTE REQUIREMENT)

Test-Driven Development is **MANDATORY and NON-NEGOTIABLE**. This is not optional, not recommended, not suggested—it is **REQUIRED**. Tests MUST be written first, user scenarios MUST be validated before implementation, and the Red-Green-Refactor cycle MUST be strictly enforced. Integration tests MUST cover plugin loading workflows, cross-platform compatibility (Linux, macOS, BSD), and interaction with the Zsh ecosystem. Coverage targets are 100% for core functionality, 90% for utilities.

**TDD Workflow (STRICTLY ENFORCED)**:

1. **RED**: Write failing tests that define desired behavior
2. **Verify RED**: Run tests, confirm they fail (no false positives)
3. **GREEN**: Write minimal code to make tests pass
4. **Verify GREEN**: Run tests, confirm they pass
5. **REFACTOR**: Improve code while maintaining passing tests
6. **Verify REFACTOR**: Run tests, confirm they still pass

**Validation Checklist**:

- [ ] Test strategy defined (unit, integration, real-world scenarios)
- [ ] Test environment requirements documented (bats-core, fixtures, test helpers)
- [ ] Coverage targets specified (100% core, 90% utilities)
- [ ] Tests WRITTEN FIRST—implementation BLOCKED until tests exist and fail
- [ ] Red-Green-Refactor cycle documented in implementation plan
- [ ] Cross-platform test coverage specified (Linux, macOS, BSD variants)

**Enforcement (ZERO TOLERANCE)**:

- **BLOCK**: No implementation task begins until tests are written and failing
- **REJECT**: Pull requests without tests are rejected without review—no exceptions
- **REVERT**: Code merged without tests will be reverted immediately
- **MANDATE**: Every feature branch MUST include test results before merge consideration
- **VALIDATE**: CI pipeline MUST enforce test coverage thresholds (fails below target)
- **DOCUMENT**: Test failure means specification is wrong—update spec first, then tests, then implementation

### IV. Consistent User Experience

Default behavior is documented and sensible—users encounter no surprises. Breaking changes require a major version bump with documented migration path. User feedback mechanisms are defined: clear error messages, optional debug mode, and graceful degradation when errors occur. Backward compatibility is maintained unless explicitly justified.

**Validation Checklist**:

- [ ] Default behavior documented and sensible
- [ ] No breaking changes OR major version bump justified
- [ ] User feedback approach specified (error messages, logging, debug mode)
- [ ] Backward compatibility addressed

### V. Zero Configuration

Features work immediately without configuration—smart defaults handle common cases. Configuration is only introduced when unavoidable, and such cases require explicit justification. Auto-detection strategies discover user environment and preferences. Configuration options are minimized: each option adds complexity that must be justified.

**Validation Checklist**:

- [ ] Works without configuration OR configuration unavoidable (justify)
- [ ] Smart defaults defined
- [ ] Auto-detection strategy specified
- [ ] Configuration options minimized
- [ ] Configuration examples declare `plugins` before sourcing `pulse.zsh`

## Performance Standards

- **Framework overhead**: MUST be less than 50ms total (all modules combined)
- **Per-module overhead**: MUST be less than 30ms for any single framework module
- **Completion menu response**: MUST appear within 100ms after Tab press
- **Shell startup**: Target total startup time is less than 500ms with 15 typical plugins
- **Measurement**: All performance claims MUST be verified with benchmarks on reference hardware (documented in test artifacts)

## Development Workflow

### Constitution Gate

Every feature MUST pass the constitution check before Phase 0 (research) begins. The check is re-validated after Phase 1 (design). Features failing the check are rejected or redesigned until compliant.

### Test-First Workflow

1. **Test Writing**: Unit and integration tests written based on specification
2. **Validation**: Tests reviewed and approved (confirm they test the right behavior)
3. **Red Phase**: Tests run and fail (expected—no implementation yet)
4. **Implementation**: Code written to make tests pass
5. **Green Phase**: Tests run and pass
6. **Refactor Phase**: Code improved while maintaining passing tests

### Error Handling

- Graceful degradation is required: one module or plugin failure MUST NOT break the entire shell
- Clear error messages MUST include actionable guidance for users
- Debug mode (PULSE_DEBUG environment variable) MUST be supported for troubleshooting
- All error paths MUST be tested

### Code Review

- Every change MUST be reviewed for constitution compliance
- Complexity MUST be justified against the Radical Simplicity principle
- Performance impact MUST be measured if code touches the loading pipeline
- Test coverage MUST meet targets (100% core, 90% utilities)

### Configuration Order Compliance

- Documentation MUST show `plugins` (or empty array) defined before `source pulse.zsh`
- Templates and quickstarts MUST include automated or manual checks to prevent regressions
- Tests covering documentation-driven workflows MUST fail if initialization order is incorrect
- Critical fixes that touch configuration MUST backfill regression tests before merge

## Governance

This constitution supersedes all other development practices. When in doubt, principles take precedence over convenience.

### Amendments

Amendments require:

1. **Documentation**: Proposed change with rationale
2. **Impact Assessment**: Review of affected code, tests, and documentation
3. **Version Bump**: Semantic versioning applied (MAJOR for principle changes, MINOR for additions, PATCH for clarifications)
4. **Migration Plan**: If changes affect existing code, migration strategy documented

### Enforcement

- All pull requests MUST pass constitution validation
- Features adding complexity MUST justify necessity
- Agent guidance file (`.github/copilot-instructions.md`) reflects current constitution state

**Version**: 1.2.0 | **Ratified**: 2025-10-11 | **Last Amended**: 2025-10-13
