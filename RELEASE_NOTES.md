# Pulse Release Notes

---

## 🚀 v1.1.0 - Plugin Management & Auto-Installation (October 13, 2025)

### ✨ New Features

#### 🔄 Automatic Plugin Installation
- **Auto-clone missing plugins**: When you add a plugin to your `plugins` array, Pulse now automatically clones it from GitHub on next shell startup
- **No manual cloning needed**: Just declare your plugins and restart your shell
- **Version locking support**: Specify exact versions, tags, or branches (e.g., `user/repo@v1.0.0`)

#### 🛠️ Plugin Management CLI
New `pulse` command for managing plugins:
- `pulse install [plugin-spec ...]` - Install plugins from command line or .zshrc
- `pulse update [plugin-name ...]` - Update all or specific plugins
- `pulse list` - List installed plugins with version info
- `pulse remove <plugin-name ...>` - Remove plugins

#### 📦 Installation Script
- New `install.sh` script for one-command framework setup
- Automatic `.zshrc` configuration
- PATH setup for `pulse` command
- Backup of existing configuration

### 🔧 Improvements
- Enhanced plugin specification parsing with version support
- Better error messages for installation failures
- Support for branch/tag/version locking in plugin specs

### 📖 Documentation
- Updated README with installation instructions
- Added CLI command documentation
- Examples for version-locked plugins

---

## 🎉 v1.0.0-mvp - First Release (October 11, 2025)

**Status**: Minimum Viable Product (MVP)
**Branch**: 001-build-a-zsh

This is the initial MVP release of Pulse, a minimal and intelligent Zsh plugin orchestrator. The core functionality is complete, tested, and ready for real-world use.

---

## ✨ Features Included

### Core Plugin Loading (P1)

- ✅ **5-Stage Loading Pipeline**: Automatically loads plugins in the correct order
  - Early stage: Completion plugins (before compinit)
  - Compinit: Zsh completion system initialization
  - Normal stage: Standard plugins
  - Late stage: Syntax highlighting and themes
  - Deferred stage: Framework for lazy loading (implementation pending)

- ✅ **Intelligent Plugin Detection**: Automatically classifies plugins by analyzing their structure
  - Completion plugins: Detected by `_*` files or `completions/` directory
  - Syntax plugins: Detected by name patterns like `*-syntax-highlighting`
  - Theme plugins: Detected by `.zsh-theme` files
  - Standard plugins: Everything else

- ✅ **Flexible Plugin Sources**: Support for multiple plugin formats
  - GitHub shorthand: `zsh-users/zsh-autosuggestions`
  - Full Git URLs: `https://github.com/user/repo.git`
  - Local paths: `/absolute/path` or `./relative/path`

- ✅ **Error Handling**: Graceful degradation when plugins fail
  - Missing plugins generate warnings but don't break the shell
  - Syntax errors in plugins are trapped and reported
  - Clear error messages for troubleshooting

### Declarative Configuration (P1)

- ✅ **Simple Plugin Declaration**: Just list your plugins in an array

  ```zsh
  plugins=(
    zsh-users/zsh-autosuggestions
    zsh-users/zsh-syntax-highlighting
  )
  ```

- ✅ **Plugin Disabling**: Temporarily disable plugins without removing them

  ```zsh
  pulse_disabled_plugins=(unwanted-plugin)
  ```

- ✅ **Stage Overrides**: Manually control when specific plugins load

  ```zsh
  typeset -gA pulse_plugin_stage
  pulse_plugin_stage[my-plugin]="late"
  ```

- ✅ **Custom Directories**: Configure where Pulse stores data

  ```zsh
  export PULSE_DIR="${HOME}/.pulse"
  export PULSE_CACHE_DIR="${HOME}/.pulse/cache"
  ```

- ✅ **Debug Mode**: Verbose logging for troubleshooting

  ```zsh
  export PULSE_DEBUG=1
  ```

### Template Configuration (P2)

- ✅ **Ready-to-Use Template**: `pulse.zshrc.template` with examples and documentation
  - Popular plugin examples (commented out)
  - Multiple configuration scenarios (minimal, developer, power user)
  - Inline documentation and troubleshooting tips
  - Easy copy-and-customize workflow

---

## 📊 Test Coverage

**18/18 tests passing (100%)**

- **Integration Tests**: 12 tests
  - Plugin loading pipeline (5 tests)
  - Configuration parsing (7 tests)

- **Unit Tests**: 6 tests
  - Plugin type detection (6 tests)

All tests use Test-Driven Development (TDD) methodology—written before implementation.

---

## 📖 Documentation

- ✅ **README.md**: Comprehensive user documentation with examples
- ✅ **quickstart.md**: Quick start guide for new users
- ✅ **pulse.zshrc.template**: Self-documenting template configuration
- ✅ **TEST_RESULTS.md**: Detailed test results and coverage analysis
- ✅ **specs/**: Complete technical specification and design documents

---

## ⚡ Performance

Target performance achieved:

- Framework overhead: **< 50ms** ✓
- Per-plugin load: **~50-100ms** ✓
- Total startup (15 plugins): **< 500ms** ✓

**Note**: Measurements in test environment. Real-world performance depends on plugin complexity and first-time Git clone operations.

---

## 🔧 System Requirements

- **Zsh**: Version 5.0 or higher
- **Git**: For cloning plugins from GitHub
- **OS**: Linux, macOS, BSD, or other Unix-like systems

---

## 📦 What's NOT Included (Yet)

The following features are planned for future releases (P3 priority):

### Plugin Lifecycle Management

- `pulse install <plugin>` - Install a new plugin
- `pulse update [plugin]` - Update one or all plugins
- `pulse remove <plugin>` - Remove a plugin
- `pulse list` - List installed plugins with status
- `pulse info <plugin>` - Show detailed plugin information

### Performance Optimization

- Plugin metadata caching for faster startup
- Lazy loading for heavy plugins (defer stage implementation)
- `pulse benchmark` - Measure startup performance

### Diagnostics & Polish

- `pulse doctor` - Check configuration health
- `pulse validate` - Validate plugin compatibility
- Enhanced debug logging with timestamps
- Comprehensive error reporting

---

## 🐛 Known Limitations (v1.0.0)

1. ~~**No Automatic Plugin Installation**~~ - **FIXED in v1.1.0**
2. **No Caching**: Plugin detection happens on every shell startup. Future versions will cache metadata for faster startup.
3. **No Lazy Loading**: The deferred stage framework exists but isn't fully implemented. All plugins load at startup.
4. ~~**No CLI Commands**~~ - **FIXED in v1.1.0**
5. **Limited Plugin Formats**: Only supports Git repositories and local paths. No support for plugin managers' custom formats.

---

## 🚀 Installation

```bash
# Clone Pulse to ~/.local/share/pulse
git clone https://github.com/astrosteveo/pulse.git ~/.local/share/pulse

# Copy the template configuration
cp ~/.local/share/pulse/pulse.zshrc.template ~/.zshrc

# Edit and customize
$EDITOR ~/.zshrc

# Restart your shell
exec zsh
```

---

## 💡 Usage Examples

### Minimal Setup

```zsh
source ~/.local/share/pulse/pulse.zsh

plugins=(
  zsh-users/zsh-autosuggestions
)
```

### Standard Setup

```zsh
source ~/.local/share/pulse/pulse.zsh

plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-completions
)
```

---

## 🙏 Credits

Pulse is inspired by:

- [mattmc3/zsh_unplugged](https://github.com/mattmc3/zsh_unplugged) - Minimal plugin loading approach
- [mattmc3/zephyr](https://github.com/mattmc3/zephyr) - Modular framework patterns

Both projects are licensed under the Unlicense. Pulse continues in that spirit: public domain, with gratitude and attribution.

---

## 📝 Development Philosophy

Pulse follows five core principles:

1. **Radical Simplicity** - Every feature must justify its existence
2. **Quality Over Features** - Reliability trumps feature count
3. **Test-Driven Reliability** - Tests written before implementation (non-negotiable)
4. **Consistent User Experience** - No surprises, sensible defaults
5. **Zero Configuration** - Works out of the box, configure only when needed

---

## 🔮 Roadmap

### v1.1.0 ✅ RELEASED

- ✅ Plugin lifecycle CLI commands
- ✅ Automatic plugin installation
- ✅ Plugin update management
- ✅ Version locking support
- ✅ Installation script

### v1.2.0 (Future)

- Plugin metadata caching
- Performance benchmarking
- Startup time optimization

### v1.3.0 (Future)

- Lazy loading implementation
- Diagnostic tools (doctor, validate)
- Enhanced error reporting

---

## 🐞 Reporting Issues

This is an MVP release. If you encounter issues:

1. Enable debug mode: `PULSE_DEBUG=1 exec zsh`
2. Check the output for errors
3. Review [TEST_RESULTS.md](TEST_RESULTS.md) for known test scenarios
4. Open an issue with debug output and configuration

---

## 📄 License

Unlicense (Public Domain)

This is free and unencumbered software released into the public domain. See [LICENSE](LICENSE) for details.
