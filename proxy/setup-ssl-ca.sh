#!/bin/bash

# Script to properly configure mkcert CA on macOS

set -e

echo "🔐 Certificate Authority Setup for local SSL certificates"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if mkcert is installed
if ! command -v mkcert &> /dev/null; then
    echo "⚠️  mkcert not found. Installing..."
    if command -v brew &> /dev/null; then
        brew install mkcert
        echo "✅ mkcert installed"
    else
        echo "❌ Homebrew not found. Install Homebrew first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
fi

# Check if nss is installed (required for Firefox)
if ! brew list nss &> /dev/null; then
    echo "📦 Installing nss (required for Firefox)..."
    brew install nss
fi

echo ""
echo "🔐 Installing local CA..."
echo "   System password will be required to install CA in keychain"
echo ""

# Install CA
mkcert -install

CA_ROOT="$(mkcert -CAROOT)"
echo ""
echo "✅ CA installed at: $CA_ROOT"
echo ""

# Verify keychain status
echo "🔍 Verifying keychain installation..."
if security find-certificate -c "mkcert" /Library/Keychains/System.keychain &> /dev/null; then
    echo "✅ CA certificate found in system keychain"
else
    echo "⚠️  CA certificate not found in system keychain"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Configuration completed!"
echo ""
echo "📋 Next steps:"
echo ""
echo "   1️⃣  Close ALL open browsers (Chrome, Firefox, Safari, etc.)"
echo "   2️⃣  Restart browsers"
echo "   3️⃣  Test: https://ptest.test:8443"
echo ""
echo "🔧 If browser still shows security warnings:"
echo ""
echo "   Chrome/Safari:"
echo "   • Open 'Keychain Access'"
echo "   • Select 'System' keychain in sidebar"
echo "   • Search for 'mkcert' in certificate list"
echo "   • Double-click the 'mkcert' certificate"
echo "   • Expand 'Trust' section"
echo "   • For 'SSL (Secure Sockets Layer)' select: 'Always Trust'"
echo "   • Close window (will require password)"
echo "   • Restart browser"
echo ""
echo "   Firefox:"
echo "   • Firefox uses its own certificate store"
echo "   • nss installation should have configured it automatically"
echo "   • If needed, go to about:preferences#privacy"
echo "   • Scroll to 'Certificates' > 'View Certificates'"
echo "   • Tab 'Authorities' > 'Import' > Select $CA_ROOT/rootCA.pem"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
