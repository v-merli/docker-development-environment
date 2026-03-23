#!/bin/bash

# Script helper per eseguire comandi artisan

PROJECT=$1
shift

if [ -z "$PROJECT" ]; then
    echo "Uso: $0 <progetto> <comando artisan>"
    echo ""
    echo "Esempi:"
    echo "  $0 ptest migrate"
    echo "  $0 ptest make:controller HomeController"
    echo "  $0 ptest tinker"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/projects/$PROJECT"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Progetto '$PROJECT' non trovato"
    exit 1
fi

cd "$PROJECT_DIR"
docker compose exec app php artisan "$@"
