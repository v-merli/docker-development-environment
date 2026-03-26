#!/bin/bash

# Script to generate SSL certificates with mkcert

set -e

DOMAIN=$1
CERTS_DIR="$(dirname "$0")/nginx/certs"

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 ptest.test"
    exit 1
fi

# Check if mkcert is installed
if ! command -v mkcert &> /dev/null; then
    echo "⚠️  mkcert not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install mkcert
        echo "✅ mkcert installed"
    else
        echo "❌ Homebrew not found. Install mkcert manually:"
        echo "   brew install mkcert"
        exit 1
    fi
fi

# Check if CA is already installed
CA_ROOT="$(mkcert -CAROOT)"
if [ ! -f "$CA_ROOT/rootCA.pem" ]; then
    echo "🔐 Installing local CA (will require system password)..."
    mkcert -install
    echo ""
    echo "✅ Local CA installed"
    echo ""
    echo "⚠️  IMPORTANT: If browser still shows security warning:"
    echo "   1. Open 'Keychain Access'"
    echo "   2. Search for 'mkcert' in 'System' section"
    echo "   3. Double-click the 'mkcert' certificate"
    echo "   4. Expand 'Trust' and select 'Always Trust' for SSL"
    echo "   5. Restart browser"
    echo ""
else
    echo "✅ Local CA already configured"
fi

echo "🔐 Generating SSL certificate for $DOMAIN..."

# Create certs directory if it doesn't exist
mkdir -p "$CERTS_DIR"

# Generate certificate with mkcert
mkcert -key-file "$CERTS_DIR/$DOMAIN.key" -cert-file "$CERTS_DIR/$DOMAIN.crt" "$DOMAIN" "*.$DOMAIN" 2>/dev/null

# Verify generated files
CERT_FILE="$CERTS_DIR/$DOMAIN.crt"
KEY_FILE="$CERTS_DIR/$DOMAIN.key"

if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
    cp "$CERT_FILE" "$CERTS_DIR/$DOMAIN.chain.pem"
    echo "✅ Certificate generated:"
    echo "   - $KEY_FILE"
    echo "   - $CERT_FILE"
    echo "   - $CERTS_DIR/$DOMAIN.chain.pem"
    echo ""
    echo "🔄 Restart nginx-proxy to apply certificates:"
    echo "   cd proxy && docker compose restart nginx-proxy"
else
    echo "❌ Error generating certificate"
    exit 1
fi
