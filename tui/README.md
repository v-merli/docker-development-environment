# PHPHarbor TUI

Interactive Terminal User Interface for PHPHarbor, built with Go and Bubble Tea.

## 🎯 Features

- **Interactive TUI Mode**: Launch without arguments for full TUI experience
- **CLI Mode**: Pass arguments for traditional command-line interface
- **Project Creation Wizard**: 3-step interactive wizard for new projects
- **Vertical Scrolling**: Navigate long content with arrow keys
- **Bash Integration**: Wraps existing PHPHarbor bash scripts

## 🚀 Quick Start

```bash
# Build
make build

# Run TUI mode (no arguments)
./phpharbor

# Run CLI mode (with arguments)
./phpharbor list
./phpharbor start myproject
```

## 📦 Installation

```bash
# Install to /usr/local/bin
make install

# Now available system-wide
phpharbor-tui
```

## 🎨 TUI Commands

Inside the TUI, use these commands (prefix with `/`):

- `/list` - List all projects
- `/wizard` or `/create` - Launch project creation wizard
- `/service` - Configure services (alias for /create)
- `/stats` - Show system statistics
- `/table` - Show PHP versions table
- `/help` - Show help
- `/test` - Test long output scrolling

**Navigation:**
- **↑/↓** - Scroll content
- **PgUp/PgDn** - Page up/down
- **Home/End** - Jump to top/bottom
- **Tab** - Navigate wizard steps forward
- **Shift+Tab** - Navigate wizard steps backward
- **Ctrl+R** - Review wizard answers
- **Esc** - Cancel wizard or exit

## 🏗️ Architecture

```
PHPHarbor TUI (Go + Bubble Tea)
         ↓ wraps
PHPHarbor Bash Scripts (../../phpharbor, ../../cli/*)
```

The TUI is a **wrapper** around existing bash functionality, not a replacement. This means:
- ✅ All existing bash logic preserved
- ✅ No duplication of business logic
- ✅ TUI provides better UX only

## 📁 Files

- `main.go` - Entry point, CLI/TUI router
- `tui.go` - Main TUI application (Bubble Tea)
- `create_wizard.go` - 3-step project creation wizard
- `wizard_shared.go` - Shared wizard utilities and styles
- `go.mod` / `go.sum` - Go modules

## 🛠️ Development

```bash
# Build
go build -o phpharbor

# Run with hot reload (requires entr or similar)
ls *.go | entr -r go run .

# Format code
go fmt ./...

# Check for issues
go vet ./...
```

## 📝 TODO

- [ ] Live output streaming for long-running commands
- [ ] Improved error formatting
- [ ] Loading indicators
- [ ] More wizards (update, SSL, etc.)
- [ ] Tests

## 🤝 Contributing

See [../CONTRIBUTING.md](../CONTRIBUTING.md)

## 📄 License

See [../LICENSE](../LICENSE)
