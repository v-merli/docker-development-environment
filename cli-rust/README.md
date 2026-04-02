# PHPHarbor CLI - Rust POC 🦀

**Status:** 🧪 Experimental POC  
**Language:** Rust 1.94+  
**Created:** 2026-04-02

## 🎯 Objective

POC for evaluating a Rust-based TUI interface for PHPHarbor, similar to GitHub Copilot CLI.

## ✨ Features

### Interactive TUI Mode
- **Full-screen interface** with logo and command area
- **Command prompt** with cursor navigation
- **Output window** showing command results
- **Color-coded output** (success/error/info)
- **Mock commands** for testing the interface

### Traditional CLI Mode
- Standard CLI arguments with `clap`
- Colored terminal output
- Compatible with scripts

## 📦 Dependencies

- `clap` - Command-line argument parsing with derive macros
- `ratatui` - Terminal UI library (modern TUI framework)
- `crossterm` - Cross-platform terminal manipulation
- `serde` / `serde_json` - Serialization (for future config)
- `tokio` - Async runtime (for future Docker API)
- `colored` - Terminal colors for CLI mode

## 🚀 Quick Start

### Installation

```bash
# Install Rust (if not installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Build release binary
cargo build --release

# Run TUI mode (default)
./target/release/phpharbor

# Or use traditional CLI
./target/release/phpharbor list
./target/release/phpharbor create myapp
```

### TUI Mode Commands

Launch the TUI with `./target/release/phpharbor` (or `phpharbor tui`):

```
Available commands:
  • create <name> - Create a new project
  • list - List all projects
  • start <name> - Start a project
  • stop <name> - Stop a project
  • help - Show this help
  • quit - Exit application

Press ESC to quit
```

## 📊 POC Results

### Binary Size
- **Release build:** 1.3 MB (macOS x86_64)
- **Stripped:** ~1.0 MB (with `strip` command)

### Performance
- **Startup:** Near-instantaneous (<10ms)
- **Responsiveness:** Immediate UI feedback
- **Memory:** Minimal footprint

### User Experience
✅ **Pros:**
- Modern, clean interface
- Intuitive command input
- Real-time feedback
- Professional appearance

❌ **To Consider:**
- Requires full terminal control
- Not suitable for piping/scripting in TUI mode
- Learning curve for TUI navigation

## 🏗️ Architecture

```
cli-rust/
├── src/
│   ├── main.rs       # Entry point, CLI parsing
│   └── tui.rs        # TUI implementation (ratatui)
├── Cargo.toml        # Dependencies
└── README.md
```

### Key Components

1. **TUI Mode** (`tui.rs`)
   - Logo display
   - Command input with cursor control
   - Output area with color coding
   - Event handling (keyboard)

2. **CLI Mode** (`main.rs`)
   - Traditional argument parsing
   - Colored output
   - Scriptable commands

## 🎨 Interface Design

```
┌─────────────────────────────────────────┐
│   ____  __  ______  __  __              │
│  / __ \/ / / / __ \/ / / /____  ____    │
│ / /_/ / /_/ / /_/ / /_/ / __ \/ ___/    │
│/ ____/ __  / ____/ __  / /_/ / /        │
│\_/   /_/ /_/_/   /_/ /_/\__,_/_/         │
│                                         │
├─────────────────────────────────────────┤
│ Output                                  │
│ > create myapp                          │
│ ✓ Creating project 'myapp'...           │
│   - Type: Laravel                       │
│   - PHP: 8.3                            │
│ ✓ Project created successfully!         │
│                                         │
├─────────────────────────────────────────┤
│ Command (ESC to quit)                   │
│ █                                       │
└─────────────────────────────────────────┘
```

## 🔄 Next Steps (If Approved)

1. **Docker Integration**
   - Connect to Docker API
   - Real project management
   - Container status monitoring

2. **Configuration**
   - Read `.phpharbor/config.json`
   - Parse project settings
   - Manage shared services

3. **Enhanced TUI**
   - Multiple views (project list, logs, status)
   - Tab navigation
   - Search/filter

4. **Testing**
   - Unit tests
   - Integration tests
   - Cross-platform validation

## 📝 Comparison with Go Implementation

| Aspect | Rust | Go |
|--------|------|-----|
| Binary Size | 1.3 MB | TBD |
| Startup Time | <10ms | TBD |
| TUI Libraries | ratatui (mature) | bubbletea/tview |
| Learning Curve | Steep | Gentle |
| Safety | Compile-time | Runtime + GC |
| Ecosystem | Growing | Established |

## 🎯 Decision Criteria

**✅ Proceed with Rust if:**
- TUI experience is highly valued
- Performance is critical
- Team comfortable with Rust

**⚠️ Consider Go if:**
- Faster development needed
- Simpler maintenance preferred
- Team prefers Go ecosystem

## 📚 Resources

- [Ratatui Documentation](https://ratatui.rs/)
- [Crossterm Guide](https://docs.rs/crossterm/)
- [Clap Book](https://docs.rs/clap/)

---

**Note:** This is a POC to evaluate feasibility. The bash implementation remains the source of truth until a final decision is made.
