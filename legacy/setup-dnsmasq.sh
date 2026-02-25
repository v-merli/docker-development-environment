#!/bin/bash

# Script per configurare dnsmasq su macOS

echo "=== Setup dnsmasq per domini .test ==="
echo ""

# Verifica se Homebrew è installato
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew non è installato. Installalo da https://brew.sh/"
    exit 1
fi

# Installa dnsmasq se non presente
if ! brew list dnsmasq &> /dev/null; then
    echo "📦 Installazione dnsmasq..."
    brew install dnsmasq
else
    echo "✅ dnsmasq già installato"
fi

# Crea directory di configurazione se non esiste
echo "📁 Creazione directory di configurazione..."
sudo mkdir -p /etc/resolver
sudo mkdir -p $(brew --prefix)/etc

# Copia la configurazione dnsmasq
echo "📝 Configurazione dnsmasq..."
DNSMASQ_CONF="$(brew --prefix)/etc/dnsmasq.conf"
cat > "$DNSMASQ_CONF" << 'EOF'
# Risolvi tutti i domini *.test a 127.0.0.1
address=/.test/127.0.0.1

# Porta di ascolto
port=53

# Non leggere /etc/resolv.conf
no-resolv

# Server DNS upstream
server=8.8.8.8
server=8.8.4.4

# Log queries (commentare per disabilitare)
# log-queries
EOF

# Configura il resolver per .test
echo "🔧 Configurazione resolver per .test..."
sudo tee /etc/resolver/test > /dev/null << EOF
nameserver 127.0.0.1
EOF

# Avvia dnsmasq
echo "🚀 Avvio dnsmasq..."
sudo brew services start dnsmasq

# Verifica la configurazione
echo ""
echo "=== Verifica Configurazione ==="
echo "Controllo risoluzione DNS per 'test.test'..."
sleep 2

if ping -c 1 test.test &> /dev/null; then
    echo "✅ Configurazione completata con successo!"
    echo "✅ I domini .test ora puntano a 127.0.0.1"
else
    echo "⚠️  Attenzione: la risoluzione DNS potrebbe richiedere qualche secondo"
    echo "   Prova a eseguire: ping test.test"
fi

echo ""
echo "=== Comandi utili ==="
echo "Riavviare dnsmasq:  sudo brew services restart dnsmasq"
echo "Fermare dnsmasq:    sudo brew services stop dnsmasq"
echo "Stato dnsmasq:      sudo brew services list"
echo "Log dnsmasq:        tail -f $(brew --prefix)/var/log/dnsmasq.log"
