# PHPHarbor TUI Makefile

.PHONY: build install clean test help

# Default target
all: build

# Build the TUI binary
build:
	@echo "🔨 Building PHPHarbor TUI..."
	@go build -ldflags="-s -w" -o phpharbor
	@echo "✅ Build complete: ./phpharbor ($(shell ls -lh phpharbor | awk '{print $$5}'))"

# Install to /usr/local/bin
install: build
	@echo "📦 Installing PHPHarbor TUI..."
	@sudo cp phpharbor /usr/local/bin/phpharbor-tui
	@sudo chmod +x /usr/local/bin/phpharbor-tui
	@echo "✅ Installed to /usr/local/bin/phpharbor-tui"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -f phpharbor *.bak
	@echo "✅ Clean complete"

# Run tests
test:
	@echo "🧪 Running tests..."
	@go test -v ./...

# Show help
help:
	@echo "PHPHarbor TUI - Make targets:"
	@echo ""
	@echo "  make build    - Build the TUI binary"
	@echo "  make install  - Install to /usr/local/bin/phpharbor-tui"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make test     - Run tests"
	@echo "  make help     - Show this help"
