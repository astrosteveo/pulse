#!/usr/bin/env zsh
# Prompt Integration - Minimal default prompt system
# Part of US5: Prompt Integration

# Skip if prompt already set by user or plugin
if [[ -n "$PROMPT" ]] || [[ -n "$PS1" ]] || [[ "$PULSE_PROMPT_SET" == "1" ]]; then
    return 0
fi

# Minimal default prompt: directory + user indicator
# Format: /current/path %
# Colors: blue directory, default user indicator
# Root: # instead of %

if [[ -t 1 ]] && [[ "$TERM" != "dumb" ]]; then
    # Colors available - use blue for directory
    PROMPT='%F{blue}%~%f %# '
else
    # No colors - plain text
    PROMPT='%~ %# '
fi

# Mark prompt as set (for plugin coordination)
export PULSE_PROMPT_SET=1
