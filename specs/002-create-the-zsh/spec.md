# Feature Specification: Core Zsh Framework Modules

**Feature Branch**: `002-create-the-zsh`
**Created**: 2025-10-11
**Status**: Draft
**Input**: User description: "Create the zsh framework itself (for the compinit, completions, keybinds, etc.) This is the framework I was mentioning from <https://github.com/mattmc3/zephyr>. That's the second half of our solution - and in our case, our implementation of the framework, should work hand in hand with the plugin engine's feature set."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Intelligent Completion System (Priority: P1)

A user wants tab completions to work immediately without manual configuration. The system should initialize the Zsh completion system at the optimal time, configure sensible completion styles, and integrate with plugin-provided completions automatically.

**Why this priority**: Completions are fundamental to shell usability. Without this, users lose one of Zsh's most powerful features. This is the highest-impact framework component.

**Independent Test**: Install Pulse with 3 completion-providing plugins (e.g., zsh-completions, docker-compose, kubectl). Start a new shell. Type a command and press Tab. Completions work correctly without any user configuration. Test completion behavior (case-insensitive, menu selection, descriptions).

**Acceptance Scenarios**:

1. **Given** a fresh shell with Pulse loaded, **When** user presses Tab after a command, **Then** completion menu appears with appropriate suggestions
2. **Given** completion plugins are loaded, **When** user requests completions for plugin-provided commands, **Then** custom completions are available and functional
3. **Given** multiple completion sources exist, **When** user invokes completion, **Then** all sources are merged and presented cohesively
4. **Given** user makes a typo in a command, **When** requesting completion, **Then** system suggests close matches (fuzzy/approximate matching)
5. **Given** completions are displayed, **When** navigating through options, **Then** descriptions and categories are shown clearly

---

### User Story 2 - Enhanced Keybindings (Priority: P1)

A user wants productive keyboard shortcuts that make shell interaction faster. The system should provide sensible keybindings for common operations (history search, directory navigation, line editing) while respecting user preferences for vi or emacs mode.

**Why this priority**: Keybindings directly impact productivity. Poor defaults frustrate users and slow down workflows. This is core to the user experience.

**Independent Test**: Start a shell with Pulse. Test key operations: Ctrl+R for reverse history search, arrow keys for history navigation, Ctrl+A/E for line start/end, Alt+. for last argument insertion. All work as expected without configuration.

**Acceptance Scenarios**:

1. **Given** a new shell session, **When** user presses history navigation keys (Up/Down or Ctrl+P/N), **Then** previous commands are accessible
2. **Given** user is editing a command, **When** using line editing shortcuts (Ctrl+A, Ctrl+E, Ctrl+W, Alt+Backspace), **Then** cursor moves and text is modified correctly
3. **Given** user needs a previous argument, **When** pressing Alt+. (or equivalent), **Then** last argument from previous command is inserted
4. **Given** user wants reverse history search, **When** pressing Ctrl+R, **Then** interactive search activates with incremental matching
5. **Given** user has vi mode preference, **When** vi mode is enabled, **Then** keybindings respect vi conventions while maintaining essential features
6. **Given** user has emacs mode preference (default), **When** using emacs shortcuts, **Then** keybindings follow emacs conventions

---

### User Story 3 - Shell Options and Environment (Priority: P2)

A user wants sensible shell behavior without configuration. The system should set reasonable defaults for shell options (history behavior, globbing, correction) and environment variables (colors, pager, editor) that improve the experience without being intrusive.

**Why this priority**: Good defaults reduce friction and make the shell pleasant to use. Less critical than completions and keybindings, but important for overall experience.

**Independent Test**: Start a shell with Pulse. Verify behavior: history is saved and deduplicated, glob patterns work intuitively, colored output appears in supporting commands, common environment variables (EDITOR, PAGER) have sensible values.

**Acceptance Scenarios**:

1. **Given** a new shell session, **When** user executes commands, **Then** history is saved across sessions and duplicates are removed
2. **Given** user uses glob patterns, **When** patterns include extended syntax, **Then** Zsh extended globbing works (e.g., `**/*.txt` for recursive)
3. **Given** user runs commands with color support, **When** output is to a terminal, **Then** colors are enabled and readable
4. **Given** user needs to edit a file, **When** EDITOR is used by a command, **Then** a sensible editor is invoked (vim, nano, or detected from system)
5. **Given** user views paginated output, **When** PAGER is used, **Then** a sensible pager is invoked (less with appropriate options)
6. **Given** user types a command with a minor typo, **When** shell correction is enabled, **Then** system suggests correction but doesn't auto-execute

---

### User Story 4 - Directory Management (Priority: P2)

A user wants easy directory navigation and management. The system should provide useful directory stack features, sensible cd behavior (auto_cd, auto_pushd), and helpful aliases for common directory operations.

**Why this priority**: Directory navigation is frequent but not as critical as completions/keybindings. Good defaults here improve efficiency for power users.

**Independent Test**: Start a shell with Pulse. Type a directory name without cd and verify auto_cd works. Use pushd/popd commands and verify directory stack is maintained. Test directory stack navigation.

**Acceptance Scenarios**:

1. **Given** user types just a directory path, **When** pressing Enter, **Then** shell changes to that directory (auto_cd)
2. **Given** user navigates between directories, **When** using cd, **Then** previous directories are saved to dirstack (auto_pushd)
3. **Given** user has visited multiple directories, **When** using directory stack commands (dirs, popd), **Then** navigation history is accessible
4. **Given** user needs parent directory, **When** using `..` or `...` syntax, **Then** navigation works for one or multiple levels up
5. **Given** user lists files, **When** using ls-related aliases, **Then** helpful defaults are applied (colors, human-readable sizes)

---

### User Story 5 - Prompt Integration (Priority: P3)

A user wants a functional prompt that shows relevant information. The system should provide a basic, fast prompt that works everywhere, while allowing easy integration with advanced prompt systems (Starship, Powerlevel10k).

**Why this priority**: Users often have strong prompt preferences and will customize this. A simple default is sufficient for MVP. Advanced users will bring their own solutions.

**Independent Test**: Start a shell with Pulse (no prompt plugin). Verify a basic prompt appears showing current directory. Install a prompt plugin (e.g., Starship). Verify it integrates without conflicts.

**Acceptance Scenarios**:

1. **Given** a fresh shell with no prompt plugin, **When** user starts the shell, **Then** a simple, informative prompt appears (showing directory and prompt symbol)
2. **Given** user installs a prompt plugin, **When** shell starts, **Then** custom prompt loads and displays correctly
3. **Given** user's prompt shows git information, **When** in a git repository, **Then** prompt reflects git status accurately
4. **Given** prompt needs to be fast, **When** displaying the prompt, **Then** render time is under 50ms (no blocking operations)

---

### User Story 6 - Utility Functions (Priority: P3)

A user wants helpful utility functions for common tasks. The system should provide cross-platform utilities (file operations, archive handling, URL encoding) that abstract away OS differences and provide consistent behavior.

**Why this priority**: Nice to have but not essential. Most users can accomplish these tasks with standard commands. This is convenience for power users.

**Independent Test**: Start a shell with Pulse. Use utility functions for common tasks: check if a command exists, source files conditionally, handle different archive types. Verify functions work on Linux and macOS.

**Acceptance Scenarios**:

1. **Given** user needs to check if a command exists, **When** using a utility function, **Then** accurate result is returned regardless of OS
2. **Given** user needs to extract an archive, **When** using a utility function with various formats (tar.gz, zip, 7z), **Then** correct extraction method is used automatically
3. **Given** user needs to source a file conditionally, **When** file exists, **Then** it's sourced; when it doesn't, **Then** no error occurs
4. **Given** user needs platform-specific behavior, **When** using OS detection utilities, **Then** correct OS is identified (Linux, macOS, BSD, etc.)

---

### Edge Cases

- What happens when user's terminal doesn't support colors?
- How does system handle keybinding conflicts with terminal emulator shortcuts?
- What if user has existing keybindings or shell options set in their .zshrc?
- How does completion system handle plugins that don't follow standard completion patterns?
- What happens when user switches between vi and emacs mode mid-session?
- How does system handle incompatible Zsh versions (< 5.0)?
- What if user's EDITOR or PAGER environment variables are already set?
- How does directory stack behave with symbolic links?
- What happens when prompt rendering encounters an error?
- How does system handle very long directory paths in prompts?

## Requirements *(mandatory)*

### Functional Requirements

#### Completion System

- **FR-001**: System MUST initialize the Zsh completion system (compinit) automatically at the optimal time after completion plugins are loaded
- **FR-002**: System MUST configure completion styles for better user experience (menu selection, descriptions, case-insensitive matching, colors)
- **FR-003**: System MUST cache completion definitions to improve startup performance (zcompdump file)
- **FR-004**: System MUST support both system-wide completions and plugin-provided completions
- **FR-005**: System MUST handle completion style customization through standard Zsh zstyle interface
- **FR-006**: System MUST provide fuzzy/approximate matching for completion suggestions when exact matches fail
- **FR-007**: System MUST group completions by type and show descriptions where available

#### Keybindings

- **FR-008**: System MUST provide default keybindings that work in both emacs mode (default) and vi mode
- **FR-009**: System MUST bind history search functionality (incremental search with Ctrl+R, history navigation with arrows)
- **FR-010**: System MUST bind line editing commands (beginning/end of line, delete word, kill line)
- **FR-011**: System MUST bind argument manipulation (insert last argument with Alt+.)
- **FR-012**: System MUST allow user to override any default keybinding by defining their own bindings after Pulse loads
- **FR-013**: System MUST detect and respect user's preferred editing mode (vi vs emacs)
- **FR-014**: System MUST provide custom key bindings for Pulse-specific features (e.g., toggle options, prefix commands)

#### Shell Options

- **FR-015**: System MUST set history options (share history, remove duplicates, ignore duplicates, extended history format)
- **FR-016**: System MUST enable extended globbing for advanced pattern matching
- **FR-017**: System MUST set directory navigation options (auto_cd, auto_pushd, pushd_ignore_dups)
- **FR-018**: System MUST configure completion behavior options (menu selection, auto list, list packed)
- **FR-019**: System MUST enable color support in compatible terminals (ls colors, completion colors)
- **FR-020**: System MUST set sensible defaults for error handling and job control
- **FR-021**: System MUST allow users to override any shell option by setting it after Pulse loads

#### Environment Variables

- **FR-022**: System MUST set EDITOR to a sensible default if not already set (detect available editors)
- **FR-023**: System MUST set PAGER to less with appropriate flags if not already set
- **FR-024**: System MUST configure color-related environment variables (LS_COLORS, GREP_COLOR)
- **FR-025**: System MUST preserve user-set environment variables (never override existing values)
- **FR-026**: System MUST set HISTFILE location following XDG conventions or sensible defaults

#### Directory Management

- **FR-027**: System MUST enable auto_cd so typing a directory path changes to that directory
- **FR-028**: System MUST enable auto_pushd so cd commands automatically push to directory stack
- **FR-029**: System MUST provide directory stack management (maintain stack, prevent duplicates)
- **FR-030**: System MUST provide directory navigation aliases (parent directory shortcuts)
- **FR-031**: System MUST provide ls aliases with sensible defaults (colors, human-readable sizes)

#### Prompt System

- **FR-032**: System MUST provide a minimal default prompt if no prompt plugin is loaded
- **FR-033**: System MUST allow prompt plugins to override the default prompt
- **FR-034**: System MUST ensure prompt rendering doesn't block shell startup
- **FR-035**: System MUST support common prompt frameworks (Starship, Powerlevel10k, pure)

#### Utility Functions

- **FR-036**: System MUST provide command existence check function
- **FR-037**: System MUST provide cross-platform file operations (safe rm, recursive operations)
- **FR-038**: System MUST provide archive extraction utilities (auto-detect format, extract appropriately)
- **FR-039**: System MUST provide OS detection utilities (identify Linux, macOS, BSD, etc.)
- **FR-040**: System MUST provide conditional sourcing utilities (source if exists, no error if missing)

#### Integration and Compatibility

- **FR-041**: System MUST work with the existing plugin engine from feature 001
- **FR-042**: System MUST load framework modules in correct order (environment → compinit → completions → keybinds → directory → prompt → utilities)
- **FR-043**: System MUST allow users to selectively disable framework modules
- **FR-044**: System MUST work on Zsh 5.0+ across Linux, macOS, and BSD
- **FR-045**: System MUST not conflict with user's existing .zshrc customizations
- **FR-046**: System MUST handle gracefully when framework modules encounter errors (one module failure doesn't break others)

### Assumptions

- Users prefer sensible defaults over extensive configuration (aligns with Zero Configuration principle)
- Most users will use emacs mode (Zsh default) rather than vi mode
- Users have basic terminal emulators with standard ANSI color support
- Standard command-line tools are available (ls, less, etc.)
- Users follow XDG Base Directory conventions or accept HOME/.local/share and HOME/.cache locations
- Framework modules can be loaded independently (loose coupling)
- Most users want completion menu selection rather than just listing options
- Users appreciate fuzzy matching and approximate completion suggestions

### Key Entities

- **Framework Module**: An independent Zsh script file (lib/*.zsh) that configures a specific aspect of the shell environment (completions, keybindings, options, etc.), loaded by Pulse in a defined order
- **Completion Style**: A configuration setting that controls how completions are displayed and matched, set via zstyle and affecting the entire completion system
- **Keybinding**: A mapping from a key sequence to a Zsh widget or command, configured via bindkey and active in the current editing mode (emacs or vi)
- **Shell Option**: A Zsh configuration setting enabled via setopt that affects shell behavior (globbing, history, directory handling, etc.)
- **Environment Variable**: A system-wide variable (EDITOR, PAGER, LS_COLORS, etc.) that affects external program behavior and is set conditionally to avoid overriding user preferences
- **Directory Stack**: A Zsh maintained list of previously visited directories, accessible via pushd/popd/dirs commands, used for quick navigation
- **Utility Function**: A shell function that provides cross-platform functionality or convenience operations, namespaced with pulse_ prefix to avoid conflicts

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users start a new shell and tab completion works immediately without any configuration (100% success rate in test environments)
- **SC-002**: All standard keybindings (history search, line editing, navigation) work correctly on first shell start across Linux, macOS, and BSD
- **SC-003**: Framework module loading adds less than 30ms to shell startup time (measured individually per module)
- **SC-004**: Completion menu appears in under 100ms after pressing Tab for common commands (measured on reference hardware)
- **SC-005**: All framework modules pass on Zsh versions 5.0 through 5.9+ without errors or warnings
- **SC-006**: Users can override any framework default by setting options/bindings in their .zshrc after sourcing Pulse (100% of tested overrides work)
- **SC-007**: Framework modules can be loaded independently in test environments (one module can be tested without loading others)
- **SC-008**: Users report improved shell usability compared to default Zsh (measured through user surveys or GitHub feedback)
- **SC-009**: Completion suggestions include plugin-provided completions from at least 3 popular completion plugins
- **SC-010**: Framework works correctly with at least 3 popular prompt frameworks (Starship, Powerlevel10k, pure) without conflicts
- **SC-011**: All utility functions work identically on Linux and macOS (cross-platform compatibility verified)
- **SC-012**: Shell history is properly saved and restored across sessions with duplicates removed (verify after 100 commands)
