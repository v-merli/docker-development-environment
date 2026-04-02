# Benchmark Results

**Date:** 2026-04-02  
**System:** macOS (Apple Silicon M2)

## Test Methodology

Each command tested 10 times, average time reported.

### Commands Tested

1. `--help` - Show help message
2. `version` - Display version
3. `list` - List projects (mock data)

## Results

### Startup Time

| Implementation | `--help` | `version` | `list` |
|---------------|----------|-----------|--------|
| Bash          | TBD ms   | TBD ms    | TBD ms |
| Go            | TBD ms   | TBD ms    | TBD ms |
| Rust          | TBD ms   | TBD ms    | TBD ms |

### Binary Size

| Implementation | Size (uncompressed) | Size (compressed) |
|---------------|---------------------|-------------------|
| Bash          | N/A (scripts)       | N/A               |
| Go            | TBD MB              | TBD MB            |
| Rust          | TBD MB              | TBD MB            |

### Memory Usage

| Implementation | Resident Memory |
|---------------|-----------------|
| Bash          | TBD MB          |
| Go            | TBD MB          |
| Rust          | TBD MB          |

## Analysis

_To be completed after running benchmarks..._

### Performance

- **Winner:** TBD
- **Notes:** TBD

### Binary Size

- **Winner:** TBD  
- **Notes:** TBD

### Development Experience

- **Bash:** Simple, no compilation needed
- **Go:** Fast compilation, easy syntax
- **Rust:** Slower compilation, more verbose

## Recommendations

_To be completed after evaluation..._

## How to Run Benchmarks

```bash
# Bash
time ./phpharbor --help

# Go
cd cli-go
go build -o phpharbor .
time ./phpharbor --help

# Rust  
cd cli-rust
cargo build --release
time ./target/release/phpharbor --help
```
