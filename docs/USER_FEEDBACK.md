# User Feedback System

**Version**: 0.2.0+  
**Status**: Active

## Overview

Pulse provides real-time, visually appealing feedback during plugin operations to keep users informed about what's happening behind the scenes. This sets Pulse apart from other zsh plugin managers by offering a polished, professional user experience.

## Features

### Visual Status Indicators

The feedback system uses clear, universally recognized symbols:

- ✓ **Success** - Green checkmark for successful operations
- ✗ **Error** - Red X for failed operations
- ℹ **Info** - Blue info icon for informational messages
- ⚠ **Warning** - Yellow info icon for warnings

### Animated Spinner

During long-running operations (like plugin installation), an animated spinner provides visual feedback that work is in progress:

```
⠋ Installing zsh-users/zsh-autosuggestions...
```

The spinner cycles through multiple frames, creating a smooth animation that reassures users the operation hasn't frozen.

### Automatic Degradation

The feedback system automatically adapts to the terminal environment:

- **Full TTY**: Shows animated spinner with colors and symbols
- **Non-TTY** (CI/scripts): Shows simple text messages without animation
- **Limited color support**: Falls back to plain symbols without colors

## Usage

### Automatic Feedback During Plugin Installation

When Pulse auto-installs missing plugins on shell startup, it automatically shows progress:

```zsh
# In your .zshrc
plugins=(
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)
source ~/.local/share/pulse/pulse.zsh
```

**Output:**
```
⠋ Installing zsh-syntax-highlighting...
✓ Installed zsh-syntax-highlighting
⠋ Installing zsh-autosuggestions...
✓ Installed zsh-autosuggestions
```

### Manual Plugin Operations

The CLI commands also use the feedback system:

```bash
# Update plugins with visual feedback
$ pulse update
⠋ Updating zsh-syntax-highlighting...
✓ Updated zsh-syntax-highlighting (a1b2c3d → e4f5g6h)
⠋ Updating zsh-autosuggestions...
✓ Updated zsh-autosuggestions (i7j8k9l → m0n1o2p)

Update summary:
  Updated: 2
  Up-to-date: 0
```

## API for Plugin Developers

If you're building tools that extend Pulse, you can use the feedback API:

### Basic Status Messages

```zsh
# Source the UI feedback library
source "${PULSE_LIB_DIR}/cli/lib/ui-feedback.zsh"

# Show different types of messages
pulse_success "Operation completed successfully"
pulse_error "Something went wrong"
pulse_info "Processing information..."
pulse_warning "This might take a while"
```

### Spinner Operations

```zsh
# Start a spinner
pulse_start_spinner "Downloading files..."

# ... do some work ...

# Stop with success
pulse_stop_spinner success "Download completed"

# Or stop with error
pulse_stop_spinner error "Download failed"
```

### Available Functions

| Function | Purpose | Example |
|----------|---------|---------|
| `pulse_success <msg>` | Show success message | `pulse_success "Plugin installed"` |
| `pulse_error <msg>` | Show error message | `pulse_error "Network timeout"` |
| `pulse_info <msg>` | Show info message | `pulse_info "Checking updates..."` |
| `pulse_warning <msg>` | Show warning message | `pulse_warning "Old version detected"` |
| `pulse_start_spinner <msg>` | Start animated spinner | `pulse_start_spinner "Installing..."` |
| `pulse_stop_spinner <status> <msg>` | Stop spinner with result | `pulse_stop_spinner success "Done"` |

### Color and Symbol Variables

You can also use the predefined color and symbol variables:

```zsh
# Colors (empty if terminal doesn't support colors)
PULSE_COLOR_GREEN
PULSE_COLOR_RED
PULSE_COLOR_YELLOW
PULSE_COLOR_BLUE
PULSE_COLOR_RESET

# Symbols (fallbacks for limited terminals)
PULSE_CHECK_MARK    # ✓
PULSE_CROSS_MARK    # ✗
PULSE_INFO_MARK     # ℹ
PULSE_SPINNER_MARK  # ⠋
```

## Configuration

### Disabling Feedback

To disable user feedback (useful in scripts), set `PULSE_QUIET` mode:

```zsh
export PULSE_QUIET=1
source ~/.local/share/pulse/pulse.zsh
```

This suppresses non-essential output while keeping error messages.

### Custom Symbols

You can override the default symbols:

```zsh
export PULSE_CHECK_MARK="[OK]"
export PULSE_CROSS_MARK="[FAIL]"
export PULSE_INFO_MARK="[INFO]"

source ~/.local/share/pulse/pulse.zsh
```

## Technical Details

### Performance Impact

The feedback system is designed to be lightweight:

- **Overhead**: < 1ms per operation
- **Background spinner**: Uses minimal CPU (sleep-based)
- **Memory**: < 1KB for all functions
- **No external dependencies**: Pure zsh implementation

### Thread Safety

The spinner uses a background job for animation. The system includes:

- Automatic cleanup on script exit
- Signal handlers for `EXIT`, `INT`, `TERM`
- PID tracking to prevent orphaned processes
- Lock file cleanup on failure

### TTY Detection

Feedback intelligently detects terminal capabilities:

```zsh
# Check if stdout is a TTY
[[ -t 1 ]] && use_animation=1

# Check color support
[[ -n "${terminfo[colors]}" ]] && [[ "${terminfo[colors]}" -ge 8 ]]
```

## Examples

### Complete Installation Example

```zsh
#!/usr/bin/env zsh
# Install Pulse and see the feedback in action

# Download and run installer
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh | bash

# The installer shows:
⠋ Downloading Pulse framework...
✓ Downloaded Pulse v0.2.0
⠋ Installing to ~/.local/share/pulse...
✓ Installed successfully
ℹ Add this to your .zshrc:
  source ~/.local/share/pulse/pulse.zsh
```

### Multiple Plugin Installation

```zsh
# Configure plugins in .zshrc
plugins=(
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-completions
  romkatv/powerlevel10k
)
source ~/.local/share/pulse/pulse.zsh

# On first run, you'll see:
⠋ Installing zsh-syntax-highlighting...
✓ Installed zsh-syntax-highlighting
⠋ Installing zsh-autosuggestions...
✓ Installed zsh-autosuggestions
⠋ Installing zsh-completions...
✓ Installed zsh-completions
⠋ Installing powerlevel10k...
✓ Installed powerlevel10k
```

## Troubleshooting

### Spinner Doesn't Animate

**Cause**: stdout is not a TTY (common in CI/automated environments)  
**Solution**: This is expected behavior. The system falls back to simple messages.

### Colors Don't Show

**Cause**: Terminal doesn't support colors or `$terminfo` not available  
**Solution**: Symbols still work. To force colors, set `PULSE_COLOR_GREEN` etc. manually.

### Background Job Warnings

**Cause**: Spinner wasn't properly cleaned up  
**Solution**: The cleanup handler should prevent this. If it persists, file an issue.

## See Also

- [CLI Reference](CLI_REFERENCE.md) - Complete CLI documentation
- [Performance](PERFORMANCE.md) - Performance benchmarks
- [Platform Compatibility](PLATFORM_COMPATIBILITY.md) - Platform-specific notes
