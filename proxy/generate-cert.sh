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
    else
        echo "❌ Homebrew non trovato. Installa mkcert manualmente:"
        echo "   brew install mkcert"
        exit 1
    fi
fi

# Installa la CA nel sistema (se non già fatto)
echo "🔐 Configurazione CA locale..."
mkcert -install 2>/dev/null || true

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
