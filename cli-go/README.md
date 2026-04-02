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

### TODO  
- [ ] Docker API integration (use `github.com/docker/docker/client`)
- [ ] Project creation logic
- [ ] Configuration file parsing
- [ ] Interactive prompts (use `github.com/AlecAivazis/survey/v2`)
- [ ] Full parity with bash CLI

## Benchmarks

See `../benchmarks/results.md` for performance comparisons.

## Notes

- Binary size (no compression): ~TBD
- Startup time: ~TBD
- Cross-compilation: Native Go feature, very easy
