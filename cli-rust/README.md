# PHPHarbor CLI - Rust Implementation

**Status:** 🧪 Experimental  
**Language:** Rust 1.75+

## Overview

Experimental Rust implementation of PHPHarbor CLI to evaluate:
- Performance improvements
- Type safety
- Cross-platform binary distribution

## Dependencies

- `clap` - Command-line argument parsing
- `serde` - Serialization/deserialization  
- `tokio` - Async runtime
- `colored` - Terminal colors

## Build

**Note:** Requires Rust toolchain installed.

```bash
# Install Rust (if not installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Build
cargo build --release

# Run
./target/release/phpharbor --help
```

## Current Status

### Implemented
- ✅ Basic CLI structure with clap
- ✅ Commands: `create`, `list`, `start`, `version`
- ✅ Colored output

### TODO
- [ ] Docker API integration
- [ ] Project creation logic  
- [ ] Configuration file parsing
- [ ] Interactive prompts
- [ ] Full parity with bash CLI

## Benchmarks

See `../benchmarks/results.md` for performance comparisons.

## Notes

- Binary size (release): ~TBD
- Startup time: ~TBD  
- Cross-compilation: Easy with `cargo build --target`
