#!/bin/bash

# Create Release Package
# Genera un tarball pulito per la distribuzione, escludendo file di sviluppo

set -e

# Colori
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

VERSION=${1:-"latest"}
OUTPUT_DIR="./releases"
PACKAGE_NAME="php-harbor-${VERSION}"

echo -e "${BLUE}━━━ PHPHarbor - Release Builder ━━━${NC}"
echo ""
echo "📦 Versione: $VERSION"
echo ""

# Crea directory output
mkdir -p "$OUTPUT_DIR"

# Files e directory da ESCLUDERE (non servono agli utenti finali)
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

echo -e "${BLUE}File esclusi dalla release:${NC}"
for item in "${EXCLUDE_ITEMS[@]}"; do
    echo "  ❌ $item"
done
echo ""

# Genera file build info
echo -e "${BLUE}Generazione build info...${NC}"

GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
BUILD_DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
BUILD_TIMESTAMP=$(date +%s)

# Crea file .build-info
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

echo -e "${GREEN}✓${NC} Build info generato"
echo "  Hash: $GIT_HASH"
echo "  Commit: $GIT_COMMIT"
echo "  Data: $BUILD_DATE"
echo ""

# Crea tarball
echo -e "${BLUE}Creazione tarball...${NC}"

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

# Informazioni tarball
SIZE=$(du -h "$OUTPUT_DIR/${PACKAGE_NAME}.tar.gz" | cut -f1)

echo ""
echo -e "${GREEN}✅ Release creata con successo!${NC}"
echo ""
echo "📦 File: $OUTPUT_DIR/${PACKAGE_NAME}.tar.gz"
echo "📊 Dimensione: $SIZE"
echo ""

# Contenuto tarball
echo -e "${BLUE}Contenuto tarball (principali):${NC}"
tar -tzf "$OUTPUT_DIR/${PACKAGE_NAME}.tar.gz" | head -30
echo ""

# Checksum
echo -e "${BLUE}Checksum SHA256:${NC}"
shasum -a 256 "$OUTPUT_DIR/${PACKAGE_NAME}.tar.gz"
echo ""

# Istruzioni
echo -e "${YELLOW}━━━ Prossimi Passi ━━━${NC}"
echo ""
echo "1. Testa il tarball localmente:"
echo "   tar -xzf $OUTPUT_DIR/${PACKAGE_NAME}.tar.gz -C /tmp/test"
echo ""
echo "2. Crea release su GitHub:"
echo "   - Vai su: https://github.com/v-merli/php-harbor/releases/new"
echo "   - Tag: v${VERSION}"
echo "   - Titolo: Docker Dev Environment v${VERSION}"
echo "   - Carica: $OUTPUT_DIR/${PACKAGE_NAME}.tar.gz"
echo ""
echo "3. Aggiorna URL in install.sh con il nuovo tag release"
echo ""
