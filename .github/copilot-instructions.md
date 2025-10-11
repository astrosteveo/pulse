# Copilot Instructions for Pulse

This repo is a minimal Zsh plugin orchestrator. Keep edits small, POSIX-safe where possible, and prefer idiomatic Zsh. The goal is speed, reliability, and zero bloat.

## Architecture
- Entry point: `pulse.zsh` loads modules from `lib/` in this fixed order:
  1) `compinit.zsh` – completion system bootstrap
  2) `keybinds.zsh` – keymap and widgets
  3) `completions.zsh` – user/extra completion wiring
  4) `plugin-engine.zsh` – plugin discovery and load order
- Module discovery is path-based: `modpath=${0:A:h}/lib/$mod.zsh`; keep relative paths robust to sourcing.
- Philosophy: minimal, functional, fast. Avoid complex frameworks; prefer simple sourced scripts.

## Implementation patterns
- Files currently have placeholders. When adding logic, follow these patterns:
  - Guard repeat init with idempotent checks, e.g., `typeset -gA __pulse || typeset -gA __pulse` and flags like `__pulse[compinit]=1`.
  - Use `emulate -L zsh` and `setopt` locally in functions; avoid global side effects.
  - Protect lookups with `[[ -n $var ]]` and `[[ -r $file ]]` before sourcing.
  - Prefer arrays/mapfiles for lists (e.g., `typeset -ga pulse_plugins`).

## Expected module responsibilities
- `lib/compinit.zsh`
  - Fast, safe compinit with caching. Typical flow: set `fpath`, ensure cache dir (e.g., `${XDG_CACHE_HOME:-$HOME/.cache}/pulse`), run `autoload -Uz compinit` and `compinit -d $cachefile`.
  - Handle insecure directories: on compaudit failures, attempt to fix or fall back to `compinit -u` with a log note.
- `lib/keybinds.zsh`
  - Set `bindkey -e` or `-v` based on env/var (e.g., `PULSE_KEYMAP=${PULSE_KEYMAP:-emacs}`).
  - Define minimal widgets with `zle -N` and bind with `bindkey`.
- `lib/completions.zsh`
  - Load extra comps from well-known dirs if present: `${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions` etc., append to `fpath` safely.
  - Enable useful styles with `zstyle ':completion:*'` defaults; keep conservative.
- `lib/plugin-engine.zsh`
  - Provide `pulse_use <repo> [subpath]` that clones or fetches and sources scripts. Cache into `${XDG_DATA_HOME:-$HOME/.local/share}/pulse/plugins`.
  - Ensure deterministic load order and idempotence. Avoid re-sourcing the same plugin twice.

## Conventions
- Config via env vars (document defaults in code): `PULSE_CACHE_DIR`, `PULSE_DATA_DIR`, `PULSE_KEYMAP`, `PULSE_DEBUG`.
- Logging helpers: add `pulse_log level msg` with levels `debug|info|warn|error`; gate on `PULSE_DEBUG`.
- Do not introduce external runtime deps; Git and Zsh builtins are acceptable.

## Developer workflow
- Syntax check:
  - `zsh -n pulse.zsh lib/*.zsh`
- Lint (optional if shellcheck is installed):
  - `shellcheck -s sh -x pulse.zsh lib/*.zsh` (note: shellcheck has limited zsh awareness).
- Manual test: source from an interactive shell:
  - `source ./pulse.zsh` and verify completions/keybinds/plugins load as expected.

## Examples
- Safe compinit cache path:
  - Cache file: `${PULSE_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/pulse}/zcompdump`.
- Idempotent module guard:
  - `(( ${+__pulse[compinit]} )) || { __pulse[compinit]=1; emulate -L zsh; ... }`

## File map
- `pulse.zsh`: orchestrator that sources modules in order.
- `lib/*.zsh`: one concern per file; keep them small and idempotent.
- `README.md`: philosophy and project overview.

Keep changes minimal, focused, and fast. Update these instructions as patterns solidify.
