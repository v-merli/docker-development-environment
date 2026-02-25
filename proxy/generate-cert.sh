#!/bin/bash

# Script per generare certificati SSL con mkcert

set -e

DOMAIN=$1
CERTS_DIR="$(dirname "$0")/nginx/certs"

if [ -z "$DOMAIN" ]; then
    echo "Uso: $0 <dominio>"
    echo "Esempio: $0 ptest.test"
    exit 1
fi

# Verifica se mkcert è installato
if ! command -v mkcert &> /dev/null; then
    echo "⚠️  mkcert non trovato. Installazione tramite Homebrew..."
    if command -v brew &> /dev/null; then
        brew install mkcert
        echo "✅ mkcert installato"
    else
        echo "❌ Homebrew non trovato. Installa mkcert manualmente:"
        echo "   brew install mkcert"
        exit 1
    fi
fi

# Verifica se la CA è già installata
CA_ROOT="$(mkcert -CAROOT)"
if [ ! -f "$CA_ROOT/rootCA.pem" ]; then
    echo "🔐 Installazione CA locale (richiederà la password di sistema)..."
    mkcert -install
    echo ""
    echo "✅ CA locale installata"
    echo ""
    echo "⚠️  IMPORTANTE: Se il browser mostra ancora l'avviso di sicurezza:"
    echo "   1. Apri 'Accesso Portachiavi' (Keychain Access)"
    echo "   2. Cerca 'mkcert' nella sezione 'Sistema'"
    echo "   3. Fai doppio clic sul certificato 'mkcert'"
    echo "   4. Espandi 'Fidati' e seleziona 'Fidati sempre' per SSL"
    echo "   5. Riavvia il browser"
    echo ""
else
    echo "✅ CA locale già configurata"
fi

echo "🔐 Generazione certificato SSL per $DOMAIN..."

# Crea directory certs se non esiste
mkdir -p "$CERTS_DIR"

# Genera certificato con mkcert
mkcert -key-file "$CERTS_DIR/$DOMAIN.key" -cert-file "$CERTS_DIR/$DOMAIN.crt" "$DOMAIN" "*.$DOMAIN" 2>/dev/null

# Verifica i file generati
CERT_FILE="$CERTS_DIR/$DOMAIN.crt"
KEY_FILE="$CERTS_DIR/$DOMAIN.key"

if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
    cp "$CERT_FILE" "$CERTS_DIR/$DOMAIN.chain.pem"
    echo "✅ Certificato generato:"
    echo "   - $KEY_FILE"
    echo "   - $CERT_FILE"
    echo "   - $CERTS_DIR/$DOMAIN.chain.pem"
    echo ""
    echo "🔄 Riavvia nginx-proxy per applicare i certificati:"
    echo "   cd proxy && docker compose restart nginx-proxy"
else
    echo "❌ Errore nella generazione del certificato"
    exit 1
fi
