#!/bin/bash

# Script helper per connettersi a MySQL di un progetto

set -e

PROJECT=$1
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "$PROJECT" ]; then
    echo "Uso: $0 <nome-progetto>"
    echo ""
    echo "Progetti disponibili:"
    ls -1 "$SCRIPT_DIR/projects" 2>/dev/null | grep -v "^\." || echo "  Nessun progetto trovato"
    exit 1
fi

PROJECT_DIR="$SCRIPT_DIR/projects/$PROJECT"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Progetto '$PROJECT' non trovato"
    exit 1
fi

# Carica variabili dal .env
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
else
    echo "❌ File .env non trovato in $PROJECT_DIR"
    exit 1
fi

echo "📊 Connessione dettagli per progetto: $PROJECT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Host:     127.0.0.1 (o localhost)"
echo "Porta:    ${MYSQL_PORT:-3306}"
echo "Database: $MYSQL_DATABASE"
echo "User:     $MYSQL_USER"
echo "Password: $MYSQL_PASSWORD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Connessione con mysql client:"
echo "  mysql -h 127.0.0.1 -P ${MYSQL_PORT:-3306} -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE"
echo ""
echo "Connessione con Docker (se non hai mysql client):"
echo "  docker exec -it ${PROJECT_NAME}-mysql mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE"
echo ""
echo "Strumenti GUI:"
echo "  - TablePlus:  mysql://$MYSQL_USER:$MYSQL_PASSWORD@127.0.0.1:${MYSQL_PORT:-3306}/$MYSQL_DATABASE"
echo "  - Sequel Ace: Host=127.0.0.1, Port=${MYSQL_PORT:-3306}, User=$MYSQL_USER, Password=$MYSQL_PASSWORD, DB=$MYSQL_DATABASE"
echo ""

# Offri connessione diretta
read -p "Vuoi connetterti ora? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker exec -it ${PROJECT_NAME}-mysql mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE
fi
