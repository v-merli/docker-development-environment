#!/bin/bash

# Script rapido per avviare i servizi condivisi
# Usa questo script per avviare MySQL e Redis condivisi prima di creare progetti con --shared

set -e

# Colori
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Rileva comando docker compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo "❌ Errore: né 'docker-compose' né 'docker compose' sono disponibili"
    exit 1
fi

echo -e "${BLUE}🚀 Avvio servizi condivisi...${NC}"
echo ""

cd "$SCRIPT_DIR/proxy"

# Verifica se il proxy è attivo
if ! docker ps | grep -q nginx-proxy; then
    echo -e "${YELLOW}⚠️  Proxy non attivo, avvio in corso...${NC}"
    $DOCKER_COMPOSE up -d
    sleep 3
fi

# Avvia servizi condivisi
$DOCKER_COMPOSE --profile shared-services up -d mysql-shared redis-shared

echo ""
echo -e "${GREEN}✅ Servizi condivisi avviati!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Informazioni di connessione:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🗄️  MySQL:"
echo "   Host:     localhost (o mysql-shared da container)"
echo "   Porta:    3306"
echo "   User:     root"
echo "   Password: rootpassword"
echo ""
echo "🔴 Redis:"
echo "   Host:     localhost (o redis-shared da container)"
echo "   Porta:    6379"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Ora puoi creare progetti con servizi condivisi:"
echo "   ./new-project.sh myproject --shared"
echo ""
echo "📊 Monitora lo stato:"
echo "   ./manage-projects.sh shared-status"
echo ""
