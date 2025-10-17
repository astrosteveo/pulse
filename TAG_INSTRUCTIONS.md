# Tag Creation Instructions for v0.3.0 Release

## Summary

The version bump to 0.3.0 has been completed. An annotated git tag `v0.3.0` has been created locally on the version bump commit.

## Tag Details

- **Tag name**: v0.3.0
- **Tag message**: Release version 0.3.0
- **Commit**: 38ac89cff6d4e86ffa372ca0fbaab0a512285c81
- **Commit message**: Version bump to 0.3.0

## Files Updated

The following files were updated from version 0.2.0 to 0.3.0:

1. `pulse.zsh` - Main framework version
2. `bin/pulse` - CLI version
3. `README.md` - Version badge and roadmap
4. `docs/CLI_REFERENCE.md` - Example version output
5. `docs/USER_FEEDBACK.md` - Documentation version and example

## Next Steps

After this PR is merged to main, the tag needs to be pushed to create the release:

```bash
# Option 1: Push the tag from this branch (before merge)
git push origin v0.3.0

# Option 2: After merging to main, recreate and push the tag
git checkout main
git pull
git tag -a v0.3.0 -m "Release version 0.3.0"
git push origin v0.3.0
```

## Creating the GitHub Release

Once the tag is pushed, create a GitHub release:

1. Go to https://github.com/astrosteveo/pulse/releases/new
2. Select tag: v0.3.0
3. Title: "Pulse v0.3.0"
4. Use the following as release notes template:

```markdown
# Pulse v0.3.0

This is the first official release of Pulse!

## What's New

- Core framework with 7 modules
- 5-stage plugin pipeline with auto-detection
- One-command installer
- CLI commands: `pulse list`, `pulse update`, `pulse doctor`
- Plugin version management (`@latest`, `@tag`, `@branch`)
- Lock file for reproducibility
- Oh-My-Zsh support with `omz:` shorthand

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh | bash
```

See the [README](https://github.com/astrosteveo/pulse#readme) for full documentation.
```

5. Publish the release

## Verification

After pushing the tag, verify it appears in the repository:

```bash
git ls-remote --tags origin
```

Should show:
```
<commit-sha>    refs/tags/v0.3.0
```
