#!/bin/bash

# Create Release Package
# Generates a clean tarball for distribution, excluding development files

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

VERSION=${1:-"latest"}
OUTPUT_DIR="./releases"
PACKAGE_NAME="php-harbor-${VERSION}"

echo -e "${BLUE}━━━ PHPHarbor - Release Builder ━━━${NC}"
echo ""
echo "📦 Version: $VERSION"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Files and directories to EXCLUDE (not needed by end users)
EXCLUDE_ITEMS=(
    ".git"
    ".github"
    "archive"
    "legacy"
    "docs/publishing.md"
    "create-release.sh"
    "releases"
    ".DS_Store"
    "*.bak"
    "projects/*"
    "!projects/README.md"
)

echo -e "${BLUE}Files excluded from release:${NC}"
for item in "${EXCLUDE_ITEMS[@]}"; do
    echo "  ❌ $item"
done
echo ""

# Generate build info
echo -e "${BLUE}Generating build info...${NC}"

GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
BUILD_DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
BUILD_TIMESTAMP=$(date +%s)

# Create .build-info file
cat > .build-info << EOF
# PHPHarbor Build Information
# This file is generated automatically during release creation

VERSION="$VERSION"
GIT_HASH="$GIT_HASH"
GIT_COMMIT="$GIT_COMMIT"
BUILD_DATE="$BUILD_DATE"
BUILD_TIMESTAMP="$BUILD_TIMESTAMP"
REPOSITORY="https://github.com/v-merli/php-harbor"
EOF

echo -e "${GREEN}✓${NC} Build info generated"
echo "  Hash: $GIT_HASH"
echo "  Commit: $GIT_COMMIT"
echo "  Date: $BUILD_DATE"
echo ""

# Create tarball
echo -e "${BLUE}Creating tarball...${NC}"

tar -czf "$OUTPUT_DIR/${PACKAGE_NAME}.tar.gz" \
    --exclude='.git' \
    --exclude='.github' \
    --exclude='archive' \
    --exclude='legacy' \
    --exclude='docs/publishing.md' \
    --exclude='create-release.sh' \
    --exclude='releases' \
    --exclude='.DS_Store' \
    --exclude='*.bak' \
    --exclude='projects/*' \
    --exclude='.gitignore' \
    .

# Tarball information
SIZE=$(du -h "$OUTPUT_DIR/${PACKAGE_NAME}.tar.gz" | cut -f1)

echo ""
echo -e "${GREEN}✅ Release created successfully!${NC}"
echo ""
echo "📦 File: $OUTPUT_DIR/${PACKAGE_NAME}.tar.gz"
echo "📊 Size: $SIZE"
echo ""

# Tarball contents
echo -e "${BLUE}Tarball contents (main):${NC}"
tar -tzf "$OUTPUT_DIR/${PACKAGE_NAME}.tar.gz" | head -30
echo ""

# Checksum
echo -e "${BLUE}SHA256 Checksum:${NC}"
shasum -a 256 "$OUTPUT_DIR/${PACKAGE_NAME}.tar.gz"
echo ""

# Instructions
echo -e "${YELLOW}━━━ Next Steps ━━━${NC}"
echo ""
echo "1. Test the tarball locally:"
echo "   tar -xzf $OUTPUT_DIR/${PACKAGE_NAME}.tar.gz -C /tmp/test"
echo ""
echo "2. Create release on GitHub:"
echo "   - Go to: https://github.com/v-merli/php-harbor/releases/new"
echo "   - Tag: v${VERSION}"
echo "   - Title: PHPHarbor v${VERSION}"
echo "   - Upload: $OUTPUT_DIR/${PACKAGE_NAME}.tar.gz"
echo ""
echo "3. Update URL in install.sh with the new release tag"
echo ""
