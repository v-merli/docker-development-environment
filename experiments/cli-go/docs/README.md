# PHPHarbor TUI - Go Implementation

**Status:** 🚀 Ready for Production Migration  
**Language:** Go 1.25+  
**Build System:** Go modules

## Overview

Modern Go implementation of PHPHarbor with full Terminal User Interface (TUI) using Bubble Tea framework.

### Key Features

- **🎨 Interactive TUI:** Full-screen terminal interface con Bubble Tea
- **⚡ Single Binary:** Deploy semplice, zero dipendenze esterne
- **🔄 Backward Compatible:** Wrappa gli script bash esistenti durante la migrazione
- **🧙 Wizards:** Multi-step guided workflows per project creation e service configuration
- **📊 Rich UI:** Tabelle, scrolling, syntax highlighting con lipgloss
- **🌍 Cross-Platform:** Supporto macOS, Linux, Windows

## Architecture

```
cli-go/
├── main.go              # Entry point, Cobra commands, routing
├── tui.go               # Main TUI application (Bubble Tea)
├── advanced_wizard.go   # Service configuration wizard
├── wizard.go            # Project creation wizard
├── table.go             # Table rendering utilities
├── docs/                # Documentation
│   ├── MIGRATION_PLAN.md     # Complete migration roadmap
│   ├── BASH_INTEGRATION.md   # Bash wrapper documentation
│   ├── TUI_FEATURES.md       # TUI capabilities
│   └── WIZARD_GUIDE.md       # Wizard usage guide
├── go.mod
└── go.sum
```

## Dependencies

### Core Framework
- `github.com/spf13/cobra` - CLI command framework
- `github.com/charmbracelet/bubbletea` - TUI framework
- `github.com/charmbracelet/lipgloss` - Terminal styling
- `github.com/charmbracelet/bubbles` - TUI components

### Utilities
- `github.com/fatih/color` - ANSI colors
- `github.com/AlecAivazis/survey/v2` - Interactive prompts
- `github.com/briandowns/spinner` - Loading spinners

## Quick Start

### Build

```bash
# Install dependencies
go mod download

# Build binary
go build -o phpharbor .

# Run TUI (no arguments)
./phpharbor

# Run CLI commands
./phpharbor list
./phpharbor create myproject
./phpharbor start myproject
```

### Development

```bash
# Run without building
go run . 

# Run specific command
go run . list

# Enable Go race detector
go run -race .
```

## Cross-Compilation

```bash
# macOS (Intel)
GOOS=darwin GOARCH=amd64 go build -o phpharbor-darwin-amd64

# macOS (Apple Silicon)  
GOOS=darwin GOARCH=arm64 go build -o phpharbor-darwin-arm64

# Linux (amd64)
GOOS=linux GOARCH=amd64 go build -o phpharbor-linux-amd64

# Linux (arm64 - Raspberry Pi)
GOOS=linux GOARCH=arm64 go build -o phpharbor-linux-arm64

# Windows
GOOS=windows GOARCH=amd64 go build -o phpharbor.exe
```

## Current Implementation Status

### ✅ Completed (Experimental Phase)

#### TUI Core
- [x] Full-screen TUI with Bubble Tea
- [x] Header, content area, command bar, status bar
- [x] Vertical scrolling with PgUp/PgDown/arrows
- [x] Visual scrollbar indicator
- [x] Command suggestions with Tab completion
- [x] Multiple view types (home, projects, stats, etc.)

#### Wizards
- [x] Multi-step service configuration wizard
- [x] Tab/Shift+Tab navigation between steps
- [x] Real-time validation with visual feedback
- [x] Review mode (Cmd+R) to see all answers
- [x] Cancel/Complete handling

#### CLI Integration  
- [x] Router: No args → TUI, with args → CLI
- [x] Cobra commands (list, create, start, stop, etc.)
- [x] Bash script wrapper during transition
- [x] Banner suppression for TUI calls (`PHPHARBOR_NO_BANNER`)

#### UI Components
- [x] Lipgloss tables with styling
- [x] Color-coded status indicators
- [x] Full-width content rendering
- [x] Responsive layout (adapts to terminal size)

### 🚧 In Progress

- [ ] Migration from bash to native Go commands (see MIGRATION_PLAN.md)
- [ ] Docker SDK integration
- [ ] Native project listing/management

### 📋 Planned

See [MIGRATION_PLAN.md](./docs/MIGRATION_PLAN.md) for complete roadmap.

## Usage

### TUI Mode (Interactive)

```bash
# Launch TUI
./phpharbor

# In TUI, type commands with / prefix:
/list              # List projects
/create myproject  # Create project
/start myproject   # Start project  
/service           # Launch service wizard
/table             # Show PHP versions table
/help              # Show help
```

**TUI Keybindings:**
- `↑/↓` - Scroll content
- `PgUp/PgDown` - Page up/down
- `Home/End` - Jump to top/bottom
- `Tab` - Navigate suggestions
- `Enter` - Execute command / Select suggestion
- `Esc` - Back to home / Exit (press twice)
- `Ctrl+C` - Force quit

**Wizard Navigation:**
- `Tab` - Next step
- `Shift+Tab` - Previous step
- `Cmd+R` - Review all answers
- `Enter` - Submit current step
- `Esc` - Cancel wizard

### CLI Mode (Commands)

```bash
# List projects
./phpharbor list

# Create project (interactive)
./phpharbor create

# Create project (non-interactive)
./phpharbor create myproject --type laravel --php 8.3

# Start project
./phpharbor start myproject

# Show version
./phpharbor version

# Interactive wizards
./phpharbor wizard           # Project creation wizard
./phpharbor projects-table   # Projects table view
./phpharbor stats-table      # Stats table view
```

## Configuration

### Environment Variables

- `PHPHARBOR_NO_BANNER=1` - Suppress ASCII banner (used internally by TUI)

### Project Structure

Binary expects to be in `experiments/cli-go/` with bash scripts at root:
```
php-harbor/
├── phpharbor              # Main bash script
├── cli/                   # Bash command modules
│   ├── project.sh
│   ├── create.sh
│   └── ...
└── experiments/
    └── cli-go/
        └── phpharbor      # Go binary
```

## Testing

```bash
# Run all tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run tests with race detector
go test -race ./...

# Verbose output
go test -v ./...
```

## Troubleshooting

### Binary doesn't find bash scripts

Ensure binary is in `experiments/cli-go/` or adjust paths in `executeBashScript()`.

### TUI not launching

Check terminal size: minimum 80x24 recommended.

### Commands show mock data

This is expected during transition. Real bash integration is active.  
Mock data will be replaced as commands are ported to Go (see MIGRATION_PLAN.md).

## Documentation

- [MIGRATION_PLAN.md](./docs/MIGRATION_PLAN.md) - Complete migration roadmap
- [BASH_INTEGRATION.md](./docs/BASH_INTEGRATION.md) - How bash wrapping works  
- [TUI_FEATURES.md](./docs/TUI_FEATURES.md) - TUI capabilities and features
- [WIZARD_GUIDE.md](./docs/WIZARD_GUIDE.md) - Wizard usage and customization
- [TODOS.md](./docs/TODOS.md) - Development tasks and ideas

## Contributing

### Code Style

- Follow Go standard formatting (`gofmt`)
- Use meaningful variable names
- Comment exported functions
- Keep functions small and focused

### Commit Messages

```
feat: add project listing command
fix: correct scrollbar positioning  
docs: update migration plan
refactor: extract docker client to pkg/
test: add unit tests for project.go
```

## License

Same as PHPHarbor main project.

## Next Steps

1. Review [MIGRATION_PLAN.md](./docs/MIGRATION_PLAN.md)
2. Create `commands/` package structure  
3. Implement `commands/project.go` (first native Go command)
4. Write tests
5. Iterate through migration phases

---

**Version:** 0.1.0-experimental  
**Last Updated:** 3 April 2026  
**Status:** Ready for migration to production
- ✅ Commands: `create`, `list`, `start`, `version`
- ✅ Colored output
- ✅ Go modules setup
- ✅ **Full-featured TUI** with Bubble Tea framework
- ✅ **Advanced Interactive Wizard** integrated in TUI
  - Multi-step form with navigation (↑/↓ to move between questions)
  - Edit previous answers by going back
  - Real-time validation with visual feedback
  - Review mode (Ctrl+R) to see all answers
  - Generates docker-compose.yml snippets
- ✅ Stats tables and overview views
- ✅ Projects table with interactive display
- ✅ Auto-complete suggestions in TUI

### Featured: Service Configuration Wizard

The advanced wizard provides a professional UX for configuring custom services:

```bash
./phpharbor tui
# Then type: /service
```

**Key Features:**
- 🔄 **Bidirectional Navigation**: Tab/Shift+Tab to move between questions
- ✏️ **Edit Answers**: Go back to modify previous responses
- ✅ **Live Validation**: Instant feedback on input validity
- 📋 **Review Mode**: See all answers before confirming (Ctrl+R)
- 📜 **Always-On Scrolling**: Arrow keys for vertical scrolling at any time
- 🎨 **Rich UI**: Progress indicators, color coding, clear feedback
- 🚀 **Zero Context Switch**: Fully integrated in TUI, no separate commands

See [WIZARD_GUIDE.md](WIZARD_GUIDE.md) for complete documentation.

### TODO  
- [ ] Docker API integration (use `github.com/docker/docker/client`)
- [ ] Project creation logic
- [ ] Configuration file parsing
- [x] Interactive prompts (using `github.com/AlecAivazis/survey/v2` and Bubble Tea)
- [ ] Full parity with bash CLI

## Benchmarks

See `../benchmarks/results.md` for performance comparisons.

## Notes

- Binary size (no compression): ~TBD
- Startup time: ~TBD
- Cross-compilation: Native Go feature, very easy
