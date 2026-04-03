# PHPHarbor TUI - Go Implementation

> Modern Terminal User Interface for PHPHarbor built with Go and Bubble Tea

## Quick Start

```bash
# Build
go build -o phpharbor .

# Run TUI
./phpharbor

# Run CLI command
./phpharbor list
```

## Documentation

📖 **Complete documentation available in [`docs/`](./docs/)**

- **[README.md](./docs/README.md)** - Complete guide, usage, and reference
- **[MIGRATION_PLAN.md](./docs/MIGRATION_PLAN.md)** - Roadmap for bash→Go migration
- **[BASH_INTEGRATION.md](./docs/BASH_INTEGRATION.md)** - How bash wrapping works
- **[TUI_FEATURES.md](./docs/TUI_FEATURES.md)** - TUI capabilities
- **[WIZARD_GUIDE.md](./docs/WIZARD_GUIDE.md)** - Interactive wizards guide

## Project Status

**Phase:** 🚀 Experimental → Production Migration  
**Version:** 0.1.0-experimental

### What's Working

✅ Full TUI with scrolling, wizards, tables  
✅ CLI/TUI routing  
✅ Bash integration wrapper  
✅ Interactive service configuration  
✅ Cross-platform builds

### Next Steps

See [MIGRATION_PLAN.md](./docs/MIGRATION_PLAN.md) for complete roadmap.

## Files Overview

```
cli-go/
├── README.md              ← You are here
├── main.go                # Entry point & CLI commands
├── tui.go                 # Main TUI application  
├── advanced_wizard.go     # Service wizard
├── wizard.go              # Project wizard
├── table.go               # Table utilities
├── docs/                  # 📖 Documentation
├── go.mod                 # Go dependencies
└── phpharbor              # Compiled binary
```

## Contributing

Read [docs/README.md](./docs/README.md) for development guide.
