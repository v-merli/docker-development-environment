#!/bin/bash
# Quick test script for Rust TUI POC

set -e

cd "$(dirname "$0")"

echo "🦀 PHPHarbor Rust POC - Quick Test"
echo "=================================="
echo ""

# Check if binary exists
if [ ! -f "target/release/phpharbor" ]; then
    echo "❌ Binary not found. Building..."
    source "$HOME/.cargo/env" 2>/dev/null || true
    cargo build --release
    echo "✅ Build complete!"
    echo ""
fi

echo "Binary info:"
ls -lh target/release/phpharbor
file target/release/phpharbor
echo ""

echo "📋 Testing CLI mode..."
echo "---"
./target/release/phpharbor --help
echo ""

echo "---"
echo "📋 Testing version command..."
./target/release/phpharbor version
echo ""

echo "---"
echo "📋 Testing list command..."
./target/release/phpharbor list
echo ""

echo "=================================="
echo "✅ CLI mode tests passed!"
echo ""
echo "🎨 To test TUI mode, run:"
echo "   ./target/release/phpharbor"
echo ""
echo "   Or simply:"
echo "   ./target/release/phpharbor tui"
echo ""
echo "📚 See DEMO.md for usage examples"
