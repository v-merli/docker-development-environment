#!/bin/bash

# Script per avviare PHP-FPM condivisi
# Uso: ./start-shared-php.sh [versione]
# Se non specificato, avvia tutte le versioni

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Colori
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Rileva comando docker compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo "❌ Errore: Docker Compose non disponibile"
    exit 1
fi

cd "$SCRIPT_DIR/proxy"

if [ -z "$1" ]; then
    echo -e "${BLUE}🐘 Avvio di tutte le versioni PHP condivise...${NC}"
    echo ""
    $DOCKER_COMPOSE --profile shared-services up -d \
        php-7.3-shared \
        php-7.4-shared \
        php-8.1-shared \
        php-8.2-shared \
        php-8.3-shared \
        php-8.5-shared
    echo ""
    echo -e "${GREEN}✅ PHP-FPM condivisi avviati per tutte le versioni${NC}"
    echo ""
    echo "Versioni disponibili:"
    echo "  • PHP 7.3 (php-7.3-shared)"
    echo "  • PHP 7.4 (php-7.4-shared)"
    echo "  • PHP 8.1 (php-8.1-shared)"
    echo "  • PHP 8.2 (php-8.2-shared)"
    echo "  • PHP 8.3 (php-8.3-shared)"
    echo "  • PHP 8.5 (php-8.5-shared)"
else
    PHP_VERSION=$1
    echo -e "${BLUE}🐘 Avvio PHP $PHP_VERSION condiviso...${NC}"
    $DOCKER_COMPOSE --profile shared-services up -d php-$PHP_VERSION-shared
    echo -e "${GREEN}✅ PHP $PHP_VERSION condiviso avviato${NC}"
fi

echo ""
echo "Usa: ./new-project.sh myproject --shared-php --php $PHP_VERSION"
echo "  o: ./new-project.sh myproject --fully-shared --php $PHP_VERSION"
