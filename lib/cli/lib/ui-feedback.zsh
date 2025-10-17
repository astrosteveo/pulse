#!/usr/bin/env zsh
# UI Feedback Library for Pulse
# Provides visual feedback during plugin operations (installation, updates, etc.)

# Status symbols (with fallbacks for limited terminals)
typeset -g PULSE_CHECK_MARK="${PULSE_CHECK_MARK:-✓}"
typeset -g PULSE_CROSS_MARK="${PULSE_CROSS_MARK:-✗}"
typeset -g PULSE_INFO_MARK="${PULSE_INFO_MARK:-ℹ}"
typeset -g PULSE_SPINNER_MARK="${PULSE_SPINNER_MARK:-⠋}"

# Colors (only if terminal supports them)
typeset -g PULSE_COLOR_GREEN=""
typeset -g PULSE_COLOR_RED=""
typeset -g PULSE_COLOR_YELLOW=""
typeset -g PULSE_COLOR_BLUE=""
typeset -g PULSE_COLOR_RESET=""

# Initialize colors if terminal supports them
if [[ -t 1 ]] && [[ -n "${terminfo[colors]}" ]] && [[ "${terminfo[colors]}" -ge 8 ]]; then
  PULSE_COLOR_GREEN=$'\e[32m'
  PULSE_COLOR_RED=$'\e[31m'
  PULSE_COLOR_YELLOW=$'\e[33m'
  PULSE_COLOR_BLUE=$'\e[34m'
  PULSE_COLOR_RESET=$'\e[0m'
fi

# Spinner frames for animation
typeset -g PULSE_SPINNER_FRAMES
PULSE_SPINNER_FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

# Current spinner state
typeset -g PULSE_SPINNER_PID=""
typeset -g PULSE_SPINNER_FRAME=0
typeset -g PULSE_SPINNER_MESSAGE=""

# Start a spinner animation with a message
# Usage: pulse_start_spinner "Installing plugin..."
pulse_start_spinner() {
  local message="${1:-Working...}"
  PULSE_SPINNER_MESSAGE="$message"
  PULSE_SPINNER_FRAME=0
  
  # Only show spinner if stdout is a terminal
  if [[ ! -t 1 ]]; then
    echo "$message"
    return 0
  fi
  
  # Save cursor position and hide cursor
  printf '\e[?25l'
  
  # Start spinner in background
  {
    while true; do
      local frame="${PULSE_SPINNER_FRAMES[$(( PULSE_SPINNER_FRAME % ${#PULSE_SPINNER_FRAMES[@]} + 1 ))]}"
      printf '\r%s%s%s %s' "$PULSE_COLOR_BLUE" "$frame" "$PULSE_COLOR_RESET" "$PULSE_SPINNER_MESSAGE"
      PULSE_SPINNER_FRAME=$((PULSE_SPINNER_FRAME + 1))
      sleep 0.1
    done
  } &
  PULSE_SPINNER_PID=$!
}

# Stop the spinner and show a result
# Usage: pulse_stop_spinner [success|error|info] "Message"
pulse_stop_spinner() {
  local result_status="${1:-success}"
  local message="${2:-}"
  
  # Kill spinner background job if running
  if [[ -n "$PULSE_SPINNER_PID" ]] && kill -0 "$PULSE_SPINNER_PID" 2>/dev/null; then
    kill "$PULSE_SPINNER_PID" 2>/dev/null
    wait "$PULSE_SPINNER_PID" 2>/dev/null
  fi
  PULSE_SPINNER_PID=""
  
  # Only manipulate cursor if stdout is a terminal
  if [[ -t 1 ]]; then
    # Clear line and restore cursor
    printf '\r\e[K'
    printf '\e[?25h'
  fi
  
  # Show result with appropriate symbol and color
  case "$result_status" in
    success)
      printf '%s%s%s %s\n' "$PULSE_COLOR_GREEN" "$PULSE_CHECK_MARK" "$PULSE_COLOR_RESET" "${message:-$PULSE_SPINNER_MESSAGE}"
      ;;
    error)
      printf '%s%s%s %s\n' "$PULSE_COLOR_RED" "$PULSE_CROSS_MARK" "$PULSE_COLOR_RESET" "${message:-$PULSE_SPINNER_MESSAGE}"
      ;;
    info)
      printf '%s%s%s %s\n' "$PULSE_COLOR_YELLOW" "$PULSE_INFO_MARK" "$PULSE_COLOR_RESET" "${message:-$PULSE_SPINNER_MESSAGE}"
      ;;
    *)
      printf '%s\n' "${message:-$PULSE_SPINNER_MESSAGE}"
      ;;
  esac
}

# Show a success message
# Usage: pulse_success "Plugin installed successfully"
pulse_success() {
  local message="$1"
  printf '%s%s%s %s\n' "$PULSE_COLOR_GREEN" "$PULSE_CHECK_MARK" "$PULSE_COLOR_RESET" "$message"
}

# Show an error message
# Usage: pulse_error "Failed to install plugin"
pulse_error() {
  local message="$1"
  printf '%s%s%s %s\n' "$PULSE_COLOR_RED" "$PULSE_CROSS_MARK" "$PULSE_COLOR_RESET" "$message" >&2
}

# Show an info message
# Usage: pulse_info "Checking for updates..."
pulse_info() {
  local message="$1"
  printf '%s%s%s %s\n' "$PULSE_COLOR_BLUE" "$PULSE_INFO_MARK" "$PULSE_COLOR_RESET" "$message"
}

# Show a warning message
# Usage: pulse_warning "Plugin already exists"
pulse_warning() {
  local message="$1"
  printf '%s%s%s %s\n' "$PULSE_COLOR_YELLOW" "$PULSE_INFO_MARK" "$PULSE_COLOR_RESET" "$message"
}

# Cleanup function to ensure spinner is stopped
pulse_cleanup_spinner() {
  if [[ -n "$PULSE_SPINNER_PID" ]] && kill -0 "$PULSE_SPINNER_PID" 2>/dev/null; then
    kill "$PULSE_SPINNER_PID" 2>/dev/null
    wait "$PULSE_SPINNER_PID" 2>/dev/null
    PULSE_SPINNER_PID=""
    # Restore cursor
    [[ -t 1 ]] && printf '\e[?25h'
  fi
}

# Register cleanup on script exit
trap pulse_cleanup_spinner EXIT INT TERM
