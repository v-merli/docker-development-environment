#!/bin/bash

# Script per gestire i progetti Laravel Docker

set -e

# Colori
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECTS_DIR="$SCRIPT_DIR/projects"

# Rileva comando docker compose (v1 o v2)
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo "❌ Errore: né 'docker-compose' né 'docker compose' sono disponibili"
    exit 1
fi

# Funzione per mostrare l'uso
show_usage() {
    echo "Uso: $0 <comando> [opzioni]"
    echo ""
    echo "Comandi:"
    echo "  list                  Elenca tutti i progetti"
    echo "  start <progetto>      Avvia un progetto"
    echo "  stop <progetto>       Ferma un progetto"
    echo "  restart <progetto>    Riavvia un progetto"
    echo "  logs <progetto>       Mostra i log di un progetto"
    echo "  shell <progetto>      Apri una shell nel container PHP"
    echo "  artisan <progetto>    Esegui comandi artisan"
    echo "  composer <progetto>   Esegui comandi composer"
    echo "  npm <progetto>        Esegui comandi npm"
    echo "  mysql <progetto>      Apri MySQL CLI"
    echo "  db-info <progetto>    Mostra info connessione database"
    echo "  remove <progetto>     Rimuovi un progetto (con conferma)"
    echo ""
    echo "Gestione servizi condivisi:"
    echo "  shared-start          Avvia tutti i servizi condivisi (MySQL + Redis + PHP)"
    echo "  shared-stop           Ferma tutti i servizi condivisi"
    echo "  shared-status         Mostra lo stato dei servizi condivisi"
    echo "  shared-logs           Mostra i log dei servizi condivisi"
    echo "  shared-mysql          Apri MySQL CLI dei servizi condivisi"
    echo "  shared-php <ver>      Avvia PHP-FPM condiviso (es: 8.3)"
    echo "  shared-php-logs <ver> Log PHP-FPM condiviso"
}

# Lista progetti
list_projects() {
    echo -e "${BLUE}=== Progetti Laravel disponibili ===${NC}"
    echo ""
    
    if [ ! -d "$PROJECTS_DIR" ] || [ -z "$(ls -A $PROJECTS_DIR 2>/dev/null)" ]; then
        echo "Nessun progetto trovato"
        return
    fi
    
    for dir in "$PROJECTS_DIR"/*/ ; do
        if [ -d "$dir" ]; then
            project=$(basename "$dir")
            env_file="$dir/.env"
            
            if [ -f "$env_file" ]; then
                domain=$(grep "^DOMAIN=" "$env_file" | cut -d'=' -f2)
                php_version=$(grep "^PHP_VERSION=" "$env_file" | cut -d'=' -f2)
                node_version=$(grep "^NODE_VERSION=" "$env_file" | cut -d'=' -f2)
                
                # Verifica se i container sono in esecuzione
                cd "$dir"
                if $DOCKER_COMPOSE ps | grep -q "Up"; then
                    status="${GREEN}●${NC} Running"
                else
                    status="○ Stopped"
                fi
                
                echo -e "$status  $project"
                echo "       URL: http://$domain"
                echo "       PHP: $php_version | Node: $node_version"
                echo ""
            fi
        fi
    done
}

# Main
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1
shift

case $COMMAND in
    list)
        list_projects
        ;;
    start)
        if [ -z "$1" ]; then
            echo "Specifica il nome del progetto"
            exit 1
        fi
        PROJECT_PATH="$PROJECTS_DIR/$1"
        if [ ! -d "$PROJECT_PATH" ]; then
            echo "Progetto '$1' non trovato"
            exit 1
        fi
        cd "$PROJECT_PATH"
        $DOCKER_COMPOSE up -d
        echo -e "${GREEN}✅ Progetto $1 avviato${NC}"
        ;;
    stop)
        if [ -z "$1" ]; then
            echo "Specifica il nome del progetto"
            exit 1
        fi
        PROJECT_PATH="$PROJECTS_DIR/$1"
        cd "$PROJECT_PATH"
        $DOCKER_COMPOSE down
        echo -e "${GREEN}✅ Progetto $1 fermato${NC}"
        ;;
    restart)
        if [ -z "$1" ]; then
            echo "Specifica il nome del progetto"
            exit 1
        fi
        PROJECT_PATH="$PROJECTS_DIR/$1"
        cd "$PROJECT_PATH"
        $DOCKER_COMPOSE restart
        echo -e "${GREEN}✅ Progetto $1 riavviato${NC}"
        ;;
    logs)
        if [ -z "$1" ]; then
            echo "Specifica il nome del progetto"
            exit 1
        fi
        PROJECT_PATH="$PROJECTS_DIR/$1"
        cd "$PROJECT_PATH"
        $DOCKER_COMPOSE logs -f
        ;;
    shell)
        if [ -z "$1" ]; then
            echo "Specifica il nome del progetto"
            exit 1
        fi
        PROJECT_PATH="$PROJECTS_DIR/$1"
        cd "$PROJECT_PATH"
        $DOCKER_COMPOSE exec app bash
        ;;
    artisan)
        if [ -z "$1" ]; then
            echo "Specifica il nome del progetto"
            exit 1
        fi
        PROJECT=$1
        shift
        PROJECT_PATH="$PROJECTS_DIR/$PROJECT"
        cd "$PROJECT_PATH"
        $DOCKER_COMPOSE exec app php artisan "$@"
        ;;
    composer)
        if [ -z "$1" ]; then
            echo "Specifica il nome del progetto"
            exit 1
        fi
        PROJECT=$1
        shift
        PROJECT_PATH="$PROJECTS_DIR/$PROJECT"
        cd "$PROJECT_PATH"
        $DOCKER_COMPOSE exec app composer "$@"
        ;;
    npm)
        if [ -z "$1" ]; then
            echo "Specifica il nome del progetto"
            exit 1
        fi
        PROJECT=$1
        shift
        PROJECT_PATH="$PROJECTS_DIR/$PROJECT"
        cd "$PROJECT_PATH"
        $DOCKER_COMPOSE exec app npm "$@"
        ;;
    mysql)
        if [ -z "$1" ]; then
            echo "Specifica il nome del progetto"
            exit 1
        fi
        PROJECT_PATH="$PROJECTS_DIR/$1"
        cd "$PROJECT_PATH"
        $DOCKER_COMPOSE exec mysql mysql -uroot -proot
        ;;
    db-info)
        if [ -z "$1" ]; then
            echo "Specifica il nome del progetto"
            exit 1
        fi
        "$SCRIPT_DIR/db-connect.sh" "$1"
        ;;
    remove)
        if [ -z "$1" ]; then
            echo "Specifica il nome del progetto"
            exit 1
        fi
        PROJECT_PATH="$PROJECTS_DIR/$1"
        echo -e "${YELLOW}⚠️  Sei sicuro di voler rimuovere il progetto '$1'?${NC}"
        echo "Questa operazione rimuoverà i container e i volumi (database incluso)"
        read -p "Digita 'yes' per confermare: " confirm
        if [ "$confirm" = "yes" ]; then
            cd "$PROJECT_PATH"
            $DOCKER_COMPOSE down -v
            cd "$SCRIPT_DIR"
            rm -rf "$PROJECT_PATH"
            echo -e "${GREEN}✅ Progetto $1 rimosso${NC}"
        else
            echo "Operazione annullata"
        fi
        ;;
    shared-start)
        cd "$SCRIPT_DIR/proxy"
        echo -e "${BLUE}Avvio servizi condivisi...${NC}"
        $DOCKER_COMPOSE --profile shared-services up -d mysql-shared redis-shared
        echo -e "${GREEN}✅ Servizi condivisi avviati${NC}"
        echo ""
        echo "MySQL: localhost:3306 (user: root, password: rootpassword)"
        echo "Redis: localhost:6379"
        ;;
    shared-stop)
        cd "$SCRIPT_DIR/proxy"
        echo -e "${BLUE}Arresto servizi condivisi...${NC}"
        $DOCKER_COMPOSE --profile shared-services stop mysql-shared redis-shared
        echo -e "${GREEN}✅ Servizi condivisi arrestati${NC}"
        ;;
    shared-status)
        echo -e "${BLUE}=== Stato servizi condivisi ===${NC}"
        echo ""
        echo "Database e Cache:"
        if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "mysql-shared|redis-shared"; then
            echo ""
        else
            echo "  Nessun servizio DB/Cache in esecuzione"
        fi
        echo ""
        echo "PHP-FPM Condivisi:"
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep "php-.*-shared"; then
            echo ""
        else
            echo "  Nessun PHP-FPM condiviso in esecuzione"
        fi
        ;;
    shared-logs)
        cd "$SCRIPT_DIR/proxy"
        $DOCKER_COMPOSE --profile shared-services logs -f mysql-shared redis-shared
        ;;
    shared-mysql)
        docker exec -it mysql-shared mysql -uroot -prootpassword
        ;;
    shared-php)
        if [ -z "$1" ]; then
            echo "Specifica la versione PHP (7.3, 7.4, 8.1, 8.2, 8.3, 8.5)"
            exit 1
        fi
        PHP_VERSION="$1"
        cd "$SCRIPT_DIR/proxy"
        echo -e "${BLUE}Avvio PHP $PHP_VERSION condiviso...${NC}"
        $DOCKER_COMPOSE --profile shared-services up -d php-$PHP_VERSION-shared
        echo -e "${GREEN}✅ PHP $PHP_VERSION condiviso avviato${NC}"
        ;;
    shared-php-logs)
        if [ -z "$1" ]; then
            echo "Specifica la versione PHP (7.3, 7.4, 8.1, 8.2, 8.3, 8.5)"
            exit 1
        fi
        PHP_VERSION="$1"
        docker logs -f php-$PHP_VERSION-shared
        ;;
    *)
        echo "Comando sconosciuto: $COMMAND"
        show_usage
        exit 1
        ;;
esac
