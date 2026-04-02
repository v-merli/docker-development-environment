# Compiled CLI Experiment

**Branch:** `experiment/compiled-cli`  
**Status:** 🧪 In Progress  
**Created:** 2026-04-02

## Objective

Evaluate rewriting PHPHarbor CLI in a compiled language (Rust or Go) to improve:
- Performance (faster startup, command execution)
- Cross-platform distribution (single binary)
- Error handling and type safety
- Dependency management

## Current Implementation

- **Language:** Bash (modular scripts in `cli/`)
- **Lines of code:** ~5000+
- **Pros:** Simple, easy to modify, Unix-native
- **Cons:** Slow, error-prone, platform-specific quirks

## Candidates

### Rust ✅ POC Complete
**Pros:**
- Excellent performance
- Memory safety without GC
- Rich ecosystem (clap for CLI, tokio for async, ratatui for TUI)
- Cross-compilation support
- **TUI Interface:** Full-screen interactive mode like Copilot CLI

**Cons:**
- Steeper learning curve
- Slower compile times
- Larger binary size (1.3 MB)

**POC Status:** ✅ Complete
- Interactive TUI mode implemented
- Traditional CLI mode working
- Mock commands for testing interface
- See `cli-rust/README.md` for details

### Go
**Pros:**
- Simple, readable syntax
- Fast compilation
- Built-in concurrency
- Smaller binary size
- Easy cross-compilation

**Cons:**
- Garbage collection overhead
- Less control over memory

**POC Status:** 🏗️ In Progress (separate branch)

## Evaluation Criteria

1. **Performance:** Startup time, command execution speed
2. **Binary size:** Final compiled size for macOS/Linux/Windows
3. **Development speed:** Time to implement core features
4. **Maintainability:** Code clarity, ease of contribution
5. **Cross-platform:** Build process, platform quirks
6. **Docker integration:** Interaction with Docker API

## Implementation Plan

### Phase 1: Prototype (Current)
- [x] Implement basic CLI structure (Rust) ✅
- [x] Implement TUI interface (Rust) ✅
- [x] Mock commands: `create`, `list`, `start`, `stop` ✅
- [ ] Implement basic CLI structure (Go)
- [ ] Implement 3 core commands in Go
- [ ] Benchmark performance vs bash
- [ ] Compare binary sizes

### Phase 2: Full Implementation (If promising)
- [ ] Port all CLI commands
- [ ] Docker operations
- [ ] Configuration management
- [ ] Interactive prompts
- [ ] Testing suite

### Phase 3: Migration (If approved)
- [ ] Gradual rollout strategy
- [ ] Backward compatibility layer
- [ ] Documentation update
- [ ] Community feedback

## Directory Structure

```
cli-rust/              # Rust POC ✅
│   ├── Cargo.toml     # Dependencies: clap, ratatui, crossterm
│   └── src/
│       ├── main.rs    # CLI entry point
│       └── tui.rs     # TUI implementation
├── cli-go/            # Go implementation (TBD)
│   ├── go.mod
│   └── main.go
└── benchmarks/        # Performance comparisons
    └── results.md
```

## Notes

- This is an **experiment**, not a commitment to rewrite
- Bash implementation remains the source of truth
- Goal: Make informed decision with data
- **Rust POC:** Full TUI interface working, shows promising UX

### Rust POC Results (2026-04-02)
- ✅ Binary size: 1.3 MB (macOS, release build)
- ✅ Startup time: <10ms (near-instantaneous)
- ✅ TUI experience: Professional, responsive interface
- ✅ Color-coded output with symbol indicators (✓/✗/→)
- ✅ Both interactive and CLI modes working
- 📝 See `cli-rust/README.md` and `cli-rust/DEMO.md` for details

## Decision Point

After Phase 1, evaluate if benefits justify rewrite effort:
- ✅ **Go ahead:** Significant performance gain + better UX
- ❌ **Stick with Bash:** Marginal improvements, not worth migration cost

---

**Updates will be logged here as the experiment progresses.**
