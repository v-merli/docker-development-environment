#!/bin/bash

# Module: Development Tools
# Comandi: shell, artisan, composer, npm, mysql

show_dev_help() {
    echo "Uso: ./phpharbor <comando> <progetto> [args]"
    echo ""
    echo "Comandi:"
    echo "  shell <progetto>          Apri shell bash"
    echo "  artisan <progetto> <cmd>  Esegui comando artisan"
    echo "  composer <progetto> <cmd> Esegui comando composer"
    echo "  npm <progetto> <cmd>      Esegui comando npm"
    echo "  mysql <progetto>          MySQL CLI"
}

cmd_shell() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Uso: ./phpharbor shell <progetto>"
        echo ""
        echo "Apre una shell bash interattiva nel container PHP del progetto."
        exit 0
    fi
    
    if [ -z "$1" ]; then
        print_error "Specifica il nome del progetto"
        echo "Uso: ./phpharbor shell <progetto>"
        exit 1
    fi
    
    local project=$1
    local project_path="$PROJECTS_DIR/$project"
    
    if [  ! -d "$project_path" ]; then
        print_error "Progetto '$project' non trovato"
        exit 1
    fi
    
    cd "$project_path"
    
    # Verifica se il progetto usa PHP condiviso
    # Controlla se NON esiste il servizio "app" nel docker-compose.yml
    if [ -f "docker-compose.yml" ] && ! grep -q "^  app:" "docker-compose.yml" 2>/dev/null; then
        # Progetto fully-shared: usa PHP condiviso
        if [ -f ".env" ]; then
            php_version=$(grep "^PHP_VERSION=" ".env" 2>/dev/null | cut -d'=' -f2)
            if [ -n "$php_version" ]; then
                print_info "Accesso a PHP $php_version condiviso..."
                docker exec -it php-$php_version-shared bash -c "cd /var/www/projects/$project/app && bash"
                return
            fi
        fi
    fi
    
    # Progetto con PHP dedicato
    $DOCKER_COMPOSE exec app bash
}

cmd_artisan() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Uso: ./phpharbor artisan <progetto> <comando>"
        echo ""
        echo "Esegue un comando artisan Laravel nel container del progetto."
        echo ""
        echo "Esempi:"
        echo "  ./phpharbor artisan myapp migrate"
        echo "  ./phpharbor artisan myapp make:controller UserController"
        exit 0
    fi
    
    if [ -z "$1" ]; then
        print_error "Specifica il nome del progetto"
        echo "Uso: ./phpharbor artisan <progetto> <comando>"
        exit 1
    fi
    
    local project=$1
    shift
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Progetto '$project' non trovato"
        exit 1
    fi
    
    cd "$project_path"
    
    # Verifica se il progetto usa PHP condiviso
    # Controlla se NON esiste il servizio "app" nel docker-compose.yml
    if [ -f "docker-compose.yml" ] && ! grep -q "^  app:" "docker-compose.yml" 2>/dev/null; then
        if [ -f ".env" ]; then
            php_version=$(grep "^PHP_VERSION=" ".env" 2>/dev/null | cut -d'=' -f2)
            if [ -n "$php_version" ]; then
                print_info "Usando PHP $php_version condiviso..."
                docker exec php-$php_version-shared php /var/www/projects/$project/app/artisan "$@"
                return
            fi
        fi
    fi
    
    # Progetto con PHP dedicato
    $DOCKER_COMPOSE exec app php artisan "$@"
}

cmd_composer() {
    if [ -z "$1" ]; then
        print_error "Specifica il nome del progetto"
        echo "Uso: ./phpharbor composer <progetto> <comando>"
        exit 1
    fi
    
    local project=$1
    shift
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Progetto '$project' non trovato"
        exit 1
    fi
    
    cd "$project_path"
    
    # Verifica se il progetto usa PHP condiviso
    # Controlla se NON esiste il servizio "app" nel docker-compose.yml
    if [ -f "docker-compose.yml" ] && ! grep -q "^  app:" "docker-compose.yml" 2>/dev/null; then
        # Progetto fully-shared: usa PHP condiviso
        if [ -f ".env" ]; then
            php_version=$(grep "^PHP_VERSION=" ".env" 2>/dev/null | cut -d'=' -f2)
            if [ -n "$php_version" ]; then
                print_info "Usando PHP $php_version condiviso..."
                docker exec php-$php_version-shared bash -c "cd /var/www/projects/$project/app && composer $*"
                return
            fi
        fi
    fi
    
    # Progetto con PHP dedicato
    $DOCKER_COMPOSE exec app composer "$@"
}

cmd_npm() {
    if [ -z "$1" ]; then
        print_error "Specifica il nome del progetto"
        echo "Uso: ./phpharbor npm <progetto> <comando>"
        exit 1
    fi
    
    local project=$1
    shift
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Progetto '$project' non trovato"
        exit 1
    fi
    
    cd "$project_path"
    
    # Verifica se il progetto usa PHP condiviso
    # Controlla se NON esiste il servizio "app" nel docker-compose.yml
    if [ -f "docker-compose.yml" ] && ! grep -q "^  app:" "docker-compose.yml" 2>/dev/null; then
        if [ -f ".env" ]; then
            php_version=$(grep "^PHP_VERSION=" ".env" 2>/dev/null | cut -d'=' -f2)
            if [ -n "$php_version" ]; then
                print_info "Usando PHP $php_version condiviso..."
                docker exec php-$php_version-shared bash -c "cd /var/www/projects/$project/app && npm $*"
                return
            fi
        fi
    fi
    
    # Progetto con PHP dedicato
    $DOCKER_COMPOSE exec app npm "$@"
}

cmd_mysql() {
    if [ -z "$1" ]; then
        print_error "Specifica il nome del progetto"
        echo "Uso: ./phpharbor mysql <progetto>"
        exit 1
    fi
    
    local project=$1
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Progetto '$project' non trovato"
        exit 1
    fi
    
    cd "$project_path"
    
    # Verifica se usa MySQL condiviso
    if [ -f ".env" ]; then
        db_host=$(grep "^DB_HOST=" ".env" 2>/dev/null | cut -d'=' -f2)
        db_name=$(grep "^MYSQL_DATABASE=" ".env" 2>/dev/null | cut -d'=' -f2)
        db_pass=$(grep "^MYSQL_ROOT_PASSWORD=" ".env" 2>/dev/null | cut -d'=' -f2)
        
        if [ "$db_host" = "mysql-shared" ]; then
            print_info "Connessione a MySQL condiviso (database: $db_name)..."
            docker exec -it mysql-shared mysql -uroot -p$db_pass $db_name
            return
        fi
    fi
    
    # MySQL dedicato
    $DOCKER_COMPOSE exec mysql mysql -uroot -proot
}
