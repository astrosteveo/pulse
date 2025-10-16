<div align="center">

# ⚡ Pulse

**The intelligent Zsh framework that just works**

[![Version](https://img.shields.io/badge/version-0.2.0-blue.svg)](https://github.com/astrosteveo/pulse/releases)
[![License](https://img.shields.io/badge/license-Unlicense-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-97%25-brightgreen.svg)](TEST_RESULTS.md)
[![Zsh](https://img.shields.io/badge/zsh-%3E%3D5.0-orange.svg)](https://www.zsh.org/)

*Your shell should be alive, responsive, and reliable—the heartbeat of your workflow.*

[Quick Start](#-quick-start) • [Features](#-features) • [Documentation](#-documentation) • [Performance](#-performance)

</div>

---

## 🎯 What is Pulse?

Pulse is a **zero-configuration Zsh framework** that combines intelligent plugin management with essential shell features—all in under 100ms.

### Why Pulse?

- **🚀 Zero Config** - Source one file, you're done
- **🧠 Intelligent** - Auto-detects plugin types, loads in optimal order
- **⚡ Fast** - <100ms total overhead, sub-millisecond module loads
- **🎁 Complete** - Plugins + completions + keybindings + navigation + prompt
- **🛡️ Reliable** - Graceful errors, 200+ tests, 91% coverage
- **🔧 Flexible** - Works standalone or with plugins, override anything

### The Problem Pulse Solves

```zsh
# Before Pulse: Manual plugin management hell
source plugin1.zsh    # Did I load this before compinit?
compinit              # When do I run this?
source plugin2.zsh    # Is this syntax highlighting? Load last!
# ... 20 more plugins in the "right" order

# With Pulse: Just declare what you want
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)
source ~/.local/share/pulse/pulse.zsh  # Done!
```

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎨 Framework Modules

- **Environment** - History, globbing, colors
- **Completions** - Fuzzy matching, menu select
- **Keybindings** - Emacs mode, Ctrl+R search
- **Directory Nav** - AUTO_CD, stack, aliases
- **Prompt** - Minimal default, plugin-friendly
- **Utilities** - Helper functions

*All modules <5ms load time*

</td>
<td width="50%">

### 🔌 Plugin Engine

- **5-Stage Pipeline** - Optimal load order
- **Auto-Detection** - Completion/syntax/theme
- **GitHub Shorthand** - `user/repo` format
- **Declarative Config** - Just list plugins
- **Graceful Errors** - Never breaks your shell
- **Debug Mode** - See what's happening

*Supports any GitHub plugin*

</td>
</tr>
</table>

---

## �� Quick Start

### One-Command Install

```bash
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh | bash
```

**That's it!** The installer:
- ✅ Validates prerequisites (Zsh ≥5.0, Git)
- ✅ Clones to `~/.local/share/pulse`
- ✅ Backs up your `.zshrc`
- ✅ Adds Pulse configuration
- ✅ Verifies everything works

<details>
<summary><b>📋 Manual Installation</b></summary>

```bash
# 1. Clone Pulse
git clone https://github.com/astrosteveo/pulse.git ~/.local/share/pulse

# 2. Add to .zshrc
cat >> ~/.zshrc <<'EOF'
# Pulse Configuration
plugins=()
source ~/.local/share/pulse/pulse.zsh
EOF

# 3. Restart shell
exec zsh
```

</details>

<details>
<summary><b>⚙️ Advanced Install Options</b></summary>

```bash
# Verify checksum (recommended)
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh -o pulse-install.sh
echo "859930b374f434a2bf3133cbdbfb087ba2b6bfebd8437252c5741a0313a08e26  pulse-install.sh" | sha256sum -c -
bash pulse-install.sh

# Verbose output
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh | bash -s -- --verbose

# Custom directory
PULSE_INSTALL_DIR=~/my-pulse bash scripts/pulse-install.sh

# Install specific version
PULSE_VERSION=v0.1.0 bash scripts/pulse-install.sh
```

**Environment Variables:**
- `PULSE_INSTALL_DIR` - Install location (default: `~/.local/share/pulse`)
- `PULSE_ZSHRC` - Config file (default: `~/.zshrc`)
- `PULSE_VERSION` - Git ref (default: `main`)

**Checksum:** `859930b374f434a2bf3133cbdbfb087ba2b6bfebd8437252c5741a0313a08e26`

</details>

---

## 📖 Usage

### Basic Setup

```zsh
# In your ~/.zshrc
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)

source ~/.local/share/pulse/pulse.zsh
```

**Even without plugins**, you get:
- ✅ Intelligent completions with caching
- ✅ Enhanced keybindings (Ctrl+R, Alt+B/F, etc.)
- ✅ Smart directory navigation
- ✅ Clean minimal prompt
- ✅ Optimized shell options

### Plugin Formats

```zsh
plugins=(
  # GitHub shorthand (most common)
  zsh-users/zsh-autosuggestions
  
  # Full Git URLs
  https://github.com/zsh-users/zsh-syntax-highlighting.git
  
  # Local paths
  ~/.local/share/my-plugin
  /usr/share/zsh/plugins/work-plugin
)
```

### Version Management

Pulse supports version pinning to ensure reproducible shell environments:

```zsh
plugins=(
  # Always use latest (default)
  zsh-users/zsh-autosuggestions@latest
  
  # Pin to specific version tag
  zsh-users/zsh-syntax-highlighting@v0.8.0
  
  # Pin to branch
  romkatv/powerlevel10k@main
  
  # Without version (same as @latest)
  zsh-users/zsh-completions
)
```

**Benefits:**
- 🔒 **Reproducible** - Lock to specific versions
- 🆕 **Up-to-date** - Use `@latest` for auto-updates
- 🔄 **Flexible** - Mix versioned and latest plugins

**Lock File (`plugins.lock`):**
Pulse automatically tracks installed plugin versions:

```ini
[zsh-autosuggestions]
url=https://github.com/zsh-users/zsh-autosuggestions.git
ref=
commit=a411ef3e0992d4839f0732ebeb9823024afaaaa8
timestamp=2025-01-15T10:30:00Z
stage=normal
```

Use CLI commands to manage versions (see below).

### CLI Commands

Pulse includes a command-line interface for plugin management:

```bash
# List installed plugins
pulse list

# Update plugins
pulse update                    # Update all plugins
pulse update zsh-autosuggestions  # Update specific plugin
pulse update --force            # Force update (discard local changes)
pulse update --check-only       # Check for updates without applying

# System diagnostics
pulse doctor                    # Run health checks

# Help
pulse --help                    # Show all commands
pulse list --help               # Command-specific help
```

**Example output:**

```
$ pulse list
┌──────────────────────────┬─────────┬──────────┐
│ PLUGIN                   │ VERSION │ COMMIT   │
├──────────────────────────┼─────────┼──────────┤
│ zsh-autosuggestions      │ latest  │ a411ef3  │
│ zsh-syntax-highlighting  │ v0.8.0  │ 754cefe  │
│ powerlevel10k            │ main    │ 5ce6aef  │
└──────────────────────────┴─────────┴──────────┘

3 plugins installed
```

### Configuration

<details>
<summary><b>🎛️ Customize Behavior</b></summary>

```zsh
# Disable framework modules
pulse_disabled_modules=(
  prompt     # Use Starship, Powerlevel10k, etc.
  keybinds   # Use your own keybindings
)

# Disable specific plugins
pulse_disabled_plugins=(
  unwanted-plugin
)

# Force plugin load order
typeset -gA pulse_plugin_stage
pulse_plugin_stage[my-plugin]="late"

# Custom directories
export PULSE_DIR="${HOME}/.pulse"
export PULSE_CACHE_DIR="${HOME}/.cache/pulse"

# Enable debug mode
export PULSE_DEBUG=1

# Then source Pulse
source ~/.local/share/pulse/pulse.zsh
```

</details>

<details>
<summary><b>🔧 Utility Functions</b></summary>

```zsh
# Check if command exists
if pulse_has_command fzf; then
  echo "fzf is installed"
fi

# Source file if exists (silent failure)
pulse_source_if_exists ~/.zshrc.local

# Detect OS
os=$(pulse_os_type)  # linux, macos, freebsd, etc.

# Extract any archive
pulse_extract myfile.tar.gz
pulse_extract plugin.zip /path/to/dest
```

</details>

### Examples

<details>
<summary><b>💼 Developer Setup</b></summary>

```zsh
plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-completions
)

source ~/.local/share/pulse/pulse.zsh
```

</details>

<details>
<summary><b>🚀 Power User Setup</b></summary>

```zsh
plugins=(
  # Suggestions & highlighting
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-completions
  
  # Navigation
  agkozak/zsh-z
  
  # Git tools
  wfxr/forgit
)

source ~/.local/share/pulse/pulse.zsh
```

</details>

---

## 🔍 How It Works

### The 5-Stage Pipeline

Pulse automatically sorts plugins into optimal load stages:

```
┌─────────────────────────────────────────────────────┐
│  Stage 1: Early    → Completion plugins            │
│  Stage 2: Compinit → Zsh completion init           │
│  Stage 3: Normal   → Standard plugins (most)       │
│  Stage 4: Late     → Syntax/themes (must be last)  │
│  Stage 5: Deferred → Lazy-loaded (future)          │
└─────────────────────────────────────────────────────┘
```

**Auto-Detection:**
- **Completion plugins** (has `_*` files) → Early
- **Syntax plugins** (name matches pattern) → Late  
- **Theme plugins** (has `.zsh-theme`) → Late
- **Everything else** → Normal

**You never have to think about load order!**

### Module Loading Order

```
environment → compinit → completions → keybinds → directory → prompt → utilities
```

Each module loads in <5ms, total framework <100ms.

---

## 📊 Performance

<table>
<tr>
<th>Module</th>
<th>Load Time</th>
<th>Target</th>
<th>Status</th>
</tr>
<tr>
<td>Environment</td>
<td>&lt;1ms</td>
<td>&lt;5ms</td>
<td>✅</td>
</tr>
<tr>
<td>Completion Init</td>
<td>&lt;1ms</td>
<td>&lt;15ms</td>
<td>✅</td>
</tr>
<tr>
<td>Completions</td>
<td>&lt;1ms</td>
<td>&lt;5ms</td>
<td>✅</td>
</tr>
<tr>
<td>Keybindings</td>
<td>&lt;1ms</td>
<td>&lt;5ms</td>
<td>✅</td>
</tr>
<tr>
<td>Directory</td>
<td>&lt;1ms</td>
<td>&lt;5ms</td>
<td>✅</td>
</tr>
<tr>
<td>Prompt</td>
<td>&lt;1ms</td>
<td>&lt;2ms</td>
<td>✅</td>
</tr>
<tr>
<td>Utilities</td>
<td>&lt;1ms</td>
<td>&lt;3ms</td>
<td>✅</td>
</tr>
<tr>
<th>Total Framework</th>
<th>&lt;10ms</th>
<th>&lt;50ms</th>
<th>✅</th>
</tr>
</table>

**Completion cache** refreshes every 24 hours for optimal startup speed.

---

## 🐛 Troubleshooting

<details>
<summary><b>Completions not working</b></summary>

```bash
# Clear cache and restart
rm -f "${PULSE_CACHE_DIR:-$HOME/.cache/pulse}/zcompdump"
exec zsh
```

</details>

<details>
<summary><b>Plugin not loading</b></summary>

```bash
# Enable debug mode
export PULSE_DEBUG=1
exec zsh

# Check if cloned
ls -la ~/.local/share/pulse/plugins/
```

</details>

<details>
<summary><b>Slow startup</b></summary>

```bash
# Profile with debug mode
export PULSE_DEBUG=1
exec zsh

# Look for slow plugins in output
# Consider removing heavy plugins
```

</details>

<details>
<summary><b>Prompt conflicts</b></summary>

```zsh
# For Starship, Powerlevel10k, etc.
export PULSE_PROMPT_SET=1
source ~/.local/share/pulse/pulse.zsh

# Or disable prompt module
pulse_disabled_modules=(prompt)
```

</details>

**📚 Full troubleshooting guide:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 🧪 Testing

```bash
# Run all tests
tests/bats-core/bin/bats tests/**/*.bats

# Specific test suites
tests/bats-core/bin/bats tests/integration/plugin_loading.bats
tests/bats-core/bin/bats tests/unit/plugin_type_detection.bats
```

**Test Coverage:**
- 📊 201 tests total
- ✅ 183 passing (91%)
- 🎯 100% core functionality
- ⚡ Performance validated

---

## 📚 Documentation

- 📖 [Installation Guide](docs/install/QUICKSTART.md)
- � [CLI Reference](docs/CLI_REFERENCE.md) - Complete command documentation
- �🔧 [Configuration Reference](specs/001-build-a-zsh/quickstart.md)
- 🐛 [Troubleshooting](TROUBLESHOOTING.md)
- ⚡ [Performance Guide](docs/PERFORMANCE.md)
- 🏗️ [Architecture](specs/001-build-a-zsh/spec.md)
- 📊 [Test Results](TEST_RESULTS.md)

---

## 🎨 Philosophy

Pulse is built on **five core principles**:

1. **Radical Simplicity** - Features serve 90% of users; edge cases excluded
2. **Quality Over Features** - Zsh conventions, tests, docs, performance
3. **Test-Driven Reliability** - 100% core coverage, TDD mandatory
4. **Consistent UX** - Sensible defaults, no surprises
5. **Zero Configuration** - Works immediately, smart detection

Every feature must justify its existence. **Deletion is considered before addition.**

---

## 🔮 Roadmap

**v0.2.0 (Current)**
- ✅ Core framework (7 modules)
- ✅ 5-stage plugin pipeline
- ✅ Auto-detection
- ✅ One-command installer
- ✅ CLI commands (`pulse list/update/doctor`)
- ✅ Plugin version management (`@latest`, `@tag`, `@branch`)
- ✅ Lock file for reproducibility

**v1.0.0 (Stable Release)**
- [ ] `pulse install/remove` commands
- [ ] Update notifications
- [ ] Advanced lazy loading
- [ ] Extended cross-platform testing

---

## 💡 Requirements

- **Zsh** ≥5.0
- **Git** (for plugin management)
- **Unix-like OS** (Linux, macOS, BSD)

---

## 🙏 Credits

Pulse is inspired by:
- [mattmc3/zsh_unplugged](https://github.com/mattmc3/zsh_unplugged)
- [mattmc3/zephyr](https://github.com/mattmc3/zephyr)

Both licensed under the Unlicense. Pulse continues in that spirit with gratitude and attribution.

Special thanks to the **Zsh community** for creating amazing plugins and sharing knowledge.

---

## 📄 License

**Unlicense** (Public Domain)

This is free and unencumbered software released into the public domain. See [LICENSE](LICENSE) for details.

---

## 🤝 Contributing

Contributions welcome! Pulse follows strict principles—see our [Constitution](.specify/memory/constitution.md) for development guidelines.

**Development:**
- 🧪 Tests required (TDD)
- 📖 Documentation required
- ⚡ Performance measured
- 🎯 Simplicity enforced

---

<div align="center">

**[⬆ Back to Top](#-pulse)**

Made with ❤️ by the Pulse community

</div>
