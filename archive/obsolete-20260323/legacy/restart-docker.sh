#!/bin/bash

# Script per riavviare e verificare Docker Desktop

echo "🔄 Riavvio Docker Desktop..."

# Chiudi Docker Desktop
osascript -e 'quit app "Docker"' 2>/dev/null || echo "Docker già chiuso"

echo "⏳ Attesa chiusura (5 secondi)..."
sleep 5

# Riavvia Docker Desktop
echo "🚀 Avvio Docker Desktop..."
open -a Docker

# Aspetta l'avvio del daemon
echo "⏳ Attesa avvio Docker daemon..."
counter=0
max_wait=60

while [ $counter -lt $max_wait ]; do
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker è pronto!"
        docker version
        echo ""
        echo "📊 Stato container:"
        docker ps -a
        exit 0
    fi
    echo "   Attesa... ($counter/$max_wait secondi)"
    sleep 2
    counter=$((counter + 2))
done

echo "❌ Timeout: Docker non si è avviato in $max_wait secondi"
echo "   Prova a riavviare manualmente Docker Desktop"
echo "   Oppure: Troubleshoot → Restart dal menu Docker"
exit 1
