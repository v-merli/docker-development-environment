# PHPHarbor CLI - Go Implementation

**Status:** 🧪 Experimental  
**Language:** Go 1.21+

## Overview

Experimental Go implementation of PHPHarbor CLI to evaluate:
- Performance improvements
- Simple deployment (single binary)
- Cross-platform compatibility

## Dependencies

- `cobra` - Command-line framework
- `color` - Terminal colors

## Build

```bash
# Install dependencies
go mod download

# Build
go build -o phpharbor .

# Run
./phpharbor --help
```

## Cross-compile

```bash
# macOS (Intel)
GOOS=darwin GOARCH=amd64 go build -o phpharbor-darwin-amd64

# macOS (Apple Silicon)
GOOS=darwin GOARCH=arm64 go build -o phpharbor-darwin-arm64

# Linux
GOOS=linux GOARCH=amd64 go build -o phpharbor-linux-amd64

# Windows
GOOS=windows GOARCH=amd64 go build -o phpharbor-windows-amd64.exe
```

## Current Status

### Implemented
- ✅ Basic CLI structure with cobra
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
