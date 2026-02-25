#!/bin/bash

# Script per configurare correttamente la CA di mkcert su macOS

set -e

echo "🔐 Setup Certificate Authority per certificati SSL locali"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verifica se mkcert è installato
if ! command -v mkcert &> /dev/null; then
    echo "⚠️  mkcert non trovato. Installazione..."
    if command -v brew &> /dev/null; then
        brew install mkcert
        echo "✅ mkcert installato"
    else
        echo "❌ Homebrew non trovato. Installa prima Homebrew:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
fi

# Verifica se nss è installato (necessario per Firefox)
if ! brew list nss &> /dev/null; then
    echo "📦 Installazione nss (necessario per Firefox)..."
    brew install nss
fi

echo ""
echo "🔐 Installazione CA locale..."
echo "   Verrà richiesta la password di sistema per installare la CA nel keychain"
echo ""

# Installa la CA
mkcert -install

CA_ROOT="$(mkcert -CAROOT)"
echo ""
echo "✅ CA installata in: $CA_ROOT"
echo ""

# Verifica lo stato nel keychain
echo "🔍 Verifica installazione nel keychain..."
if security find-certificate -c "mkcert" /Library/Keychains/System.keychain &> /dev/null; then
    echo "✅ Certificato CA trovato nel keychain di sistema"
else
    echo "⚠️  Certificato CA non trovato nel keychain di sistema"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Configurazione completata!"
echo ""
echo "📋 Passi successivi:"
echo ""
echo "   1️⃣  Chiudi TUTTI i browser aperti (Chrome, Firefox, Safari, ecc.)"
echo "   2️⃣  Riavvia i browser"
echo "   3️⃣  Testa: https://ptest.test:8443"
echo ""
echo "🔧 Se il browser mostra ancora avvisi di sicurezza:"
echo ""
echo "   Chrome/Safari:"
echo "   • Apri 'Accesso Portachiavi' (Keychain Access)"
echo "   • Seleziona il keychain 'Sistema' nella barra laterale"
echo "   • Cerca 'mkcert' nella lista dei certificati"
echo "   • Fai doppio clic sul certificato 'mkcert'"
echo "   • Espandi la sezione 'Fidati'"
echo "   • Per 'SSL (Secure Sockets Layer)' seleziona: 'Fidati sempre'"
echo "   • Chiudi la finestra (richiederà la password)"
echo "   • Riavvia il browser"
echo ""
echo "   Firefox:"
echo "   • Firefox usa il proprio archivio certificati"
echo "   • L'installazione di nss dovrebbe averlo configurato automaticamente"
echo "   • Se necessario, vai su about:preferences#privacy"
echo "   • Scorri a 'Certificati' > 'Visualizza certificati'"
echo "   • Tab 'Autorità' > 'Importa' > Seleziona $CA_ROOT/rootCA.pem"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
