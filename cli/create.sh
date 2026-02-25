#!/bin/bash

# Module: Create
# Comando: create - Crea nuovo progetto

cmd_create() {
    # Check per --help
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_create_usage
        exit 0
    fi
    
    # Valori di default
    local PROJECT_TYPE="laravel"
    local PHP_VERSION="8.3"
    local NODE_VERSION="20"
    local MYSQL_VERSION="8.0"
    local INCLUDE_DB=true
    local INCLUDE_REDIS=true
    local USE_SHARED_DB=false
    local USE_SHARED_REDIS=false
    local USE_SHARED_PHP=false
    local INSTALL_FRAMEWORK=true
    
    # Parse argomenti
    if [ $# -eq 0 ]; then
        print_error "Nome progetto non specificato"
        echo ""
        show_create_usage
        exit 1
    fi
    
    local PROJECT_NAME=$1
    shift
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --type)
                PROJECT_TYPE="$2"
                shift 2
                ;;
            --php)
                PHP_VERSION="$2"
                shift 2
                ;;
            --node)
                NODE_VERSION="$2"
                shift 2
                ;;
            --mysql)
                MYSQL_VERSION="$2"
                shift 2
                ;;
            --no-db)
                INCLUDE_DB=false
                shift
                ;;
            --no-redis)
                INCLUDE_REDIS=false
                shift
                ;;
            --shared-db)
                USE_SHARED_DB=true
                INCLUDE_DB=true
                shift
                ;;
            --shared-redis)
                USE_SHARED_REDIS=true
                INCLUDE_REDIS=true
                shift
                ;;
            --shared)
                USE_SHARED_DB=true
                USE_SHARED_REDIS=true
                INCLUDE_DB=true
                INCLUDE_REDIS=true
                shift
                ;;
            --shared-php)
                USE_SHARED_PHP=true
                shift
                ;;
            --fully-shared)
                USE_SHARED_DB=true
                USE_SHARED_REDIS=true
                USE_SHARED_PHP=true
                INCLUDE_DB=true
                INCLUDE_REDIS=true
                shift
                ;;
            --no-install)
                INSTALL_FRAMEWORK=false
                shift
                ;;
            *)
                print_error "Opzione sconosciuta: $1"
                show_create_usage
                exit 1
                ;;
        esac
    done
    
    # Validazione
    if [[ ! "$PROJECT_TYPE" =~ ^(laravel|wordpress|php|html)$ ]]; then
        print_error "Tipo progetto non supportato: $PROJECT_TYPE"
        exit 1
    fi
    
    if [[ "$PROJECT_TYPE" == "html" ]]; then
        PHP_VERSION=""
        NODE_VERSION=""
        INCLUDE_DB=false
        INCLUDE_REDIS=false
    fi
    
    if [[ -n "$PHP_VERSION" ]] && [[ ! "$PHP_VERSION" =~ ^(7.3|7.4|8.1|8.2|8.3|8.5)$ ]]; then
        print_error "Versione PHP non supportata: $PHP_VERSION"
        exit 1
    fi
    
    # Genera nomi e percorsi
    local PROJECT_SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
    local DOMAIN="$PROJECT_SLUG.test"
    local PROJECT_PATH="$PROJECTS_DIR/$PROJECT_SLUG"
    
    # Mostra riepilogo
    print_title "Creazione Nuovo Progetto"
    echo ""
    echo "Nome:      $PROJECT_NAME"
    echo "Tipo:      $PROJECT_TYPE"
    echo "Dominio:   $DOMAIN"
    if [[ -n "$PHP_VERSION" ]]; then
        if [[ "$USE_SHARED_PHP" == true ]]; then
            echo "PHP:       Condiviso $PHP_VERSION"
        else
            echo "PHP:       Dedicato $PHP_VERSION"
        fi
    fi
    if [[ "$INCLUDE_DB" == true ]]; then
        if [[ "$USE_SHARED_DB" == true ]]; then
            echo "MySQL:     Condiviso"
        else
            echo "MySQL:     Dedicato $MYSQL_VERSION"
        fi
    fi
    if [[ "$INCLUDE_REDIS" == true ]]; then
        if [[ "$USE_SHARED_REDIS" == true ]]; then
            echo "Redis:     Condiviso"
        else
            echo "Redis:     Dedicato"
        fi
    fi
    echo ""
    
    # Verifica esistenza
    if [ -d "$PROJECT_PATH" ]; then
        print_error "Il progetto '$PROJECT_SLUG' esiste già"
        exit 1
    fi
    
    # Crea struttura
    print_info "Creazione struttura directory..."
    mkdir -p "$PROJECT_PATH/app"
    
    # Seleziona template docker-compose
    local USE_FULLY_SHARED_TEMPLATE=false
    local USE_SHARED_TEMPLATE=false
    local NGINX_CONF=""
    
    if [[ "$USE_SHARED_PHP" == true ]]; then
        USE_FULLY_SHARED_TEMPLATE=true
    elif [[ "$USE_SHARED_DB" == true ]] || [[ "$USE_SHARED_REDIS" == true ]]; then
        USE_SHARED_TEMPLATE=true
    fi
    
    case $PROJECT_TYPE in
        html)
            NGINX_CONF="html.conf"
            cp "$SCRIPT_DIR/shared/templates/docker-compose-html.yml" "$PROJECT_PATH/docker-compose.yml"
            ;;
        wordpress|php)
            NGINX_CONF="${PROJECT_TYPE}.conf"
            if [[ "$USE_SHARED_TEMPLATE" == true ]]; then
                cp "$SCRIPT_DIR/shared/templates/docker-compose-shared.yml" "$PROJECT_PATH/docker-compose.yml"
            else
                cp "$SCRIPT_DIR/shared/templates/docker-compose-php.yml" "$PROJECT_PATH/docker-compose.yml"
            fi
            ;;
        laravel)
            if [[ "$USE_FULLY_SHARED_TEMPLATE" == true ]]; then
                NGINX_CONF="laravel-shared.conf"
                cp "$SCRIPT_DIR/shared/templates/docker-compose-fully-shared.yml" "$PROJECT_PATH/docker-compose.yml"
            elif [[ "$USE_SHARED_TEMPLATE" == true ]]; then
                NGINX_CONF="laravel.conf"
                cp "$SCRIPT_DIR/shared/templates/docker-compose-shared.yml" "$PROJECT_PATH/docker-compose.yml"
            else
                NGINX_CONF="laravel.conf"
                cp "$SCRIPT_DIR/shared/templates/docker-compose.yml" "$PROJECT_PATH/docker-compose.yml"
            fi
            ;;
    esac
    
    # Crea nginx.conf per PHP condiviso
    if [[ "$USE_FULLY_SHARED_TEMPLATE" == true ]]; then
        print_info "Configurazione Nginx per PHP condiviso..."
        sed -e "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_SLUG/g" \
            -e "s/PHP_VERSION_PLACEHOLDER/php-$PHP_VERSION/g" \
            "$SCRIPT_DIR/shared/nginx/laravel-shared.conf" > "$PROJECT_PATH/nginx.conf"
    fi
    
    # Crea .env
    create_env_file "$PROJECT_PATH" "$PROJECT_SLUG" "$PROJECT_TYPE" "$DOMAIN" "$NGINX_CONF" \
                    "$PHP_VERSION" "$NODE_VERSION" "$MYSQL_VERSION" \
                    "$INCLUDE_DB" "$INCLUDE_REDIS" "$USE_SHARED_DB" "$USE_SHARED_REDIS"
    
    print_success "Struttura progetto creata"
    
    # Verifica rete proxy
    if ! docker network inspect proxy &> /dev/null; then
        print_info "Avvio reverse proxy..."
        cd "$SCRIPT_DIR/proxy"
        $DOCKER_COMPOSE up -d nginx-proxy acme-companion
        cd "$SCRIPT_DIR"
        sleep 3
    fi
    
    # Avvia servizi condivisi
    start_shared_if_needed "$USE_SHARED_DB" "$USE_SHARED_REDIS" "$USE_SHARED_PHP" "$PHP_VERSION"
    
    # Avvia container del progetto
    print_info "Avvio container..."
    cd "$PROJECT_PATH"
    $DOCKER_COMPOSE up -d --build
    
    # Genera SSL
    generate_ssl_cert "$DOMAIN"
    
    print_info "Attesa avvio container..."
    sleep 5
    
    # Installa framework
    if [ "$INSTALL_FRAMEWORK" = true ]; then
        install_framework "$PROJECT_TYPE" "$PROJECT_PATH" "$PROJECT_SLUG" "$INCLUDE_DB" "$INCLUDE_REDIS" "$USE_SHARED_DB" "$USE_SHARED_REDIS"
    fi
    
    # Riepilogo finale
    show_project_summary "$PROJECT_TYPE" "$DOMAIN" "$PROJECT_PATH" "$INSTALL_FRAMEWORK" "$INCLUDE_DB"
}

show_create_usage() {
    echo "Uso: ./docker-dev create <nome> [opzioni]"
    echo ""
    echo "Opzioni:"
    echo "  --type <tipo>         Tipo: laravel, wordpress, php, html (default: laravel)"
    echo "  --php <versione>      Versione PHP: 7.3, 7.4, 8.1, 8.2, 8.3, 8.5 (default: 8.3)"
    echo "  --node <versione>     Versione Node.js: 18, 20, 21 (default: 20)"
    echo "  --mysql <versione>    Versione MySQL: 5.7, 8.0 (default: 8.0)"
    echo "  --no-db               Senza MySQL"
    echo "  --no-redis            Senza Redis"
    echo "  --shared-db           MySQL condiviso"
    echo "  --shared-redis        Redis condiviso"
    echo "  --shared              MySQL + Redis condivisi"
    echo "  --shared-php          PHP condiviso"
    echo "  --fully-shared        Tutto condiviso (massimo risparmio)"
    echo "  --no-install          Non installare framework"
    echo ""
    echo "Esempi:"
    echo "  ./docker-dev create my-shop --type laravel"
    echo "  ./docker-dev create blog --type wordpress --php 8.2"
    echo "  ./docker-dev create api --fully-shared"
}

create_env_file() {
    local path=$1 slug=$2 type=$3 domain=$4 nginx_conf=$5
    local php_ver=$6 node_ver=$7 mysql_ver=$8
    local inc_db=$9 inc_redis=${10} shared_db=${11} shared_redis=${12}
    
    cat > "$path/.env" << EOF
PROJECT_NAME=$slug
PROJECT_TYPE=$type
DOMAIN=$domain
LETSENCRYPT_EMAIL=dev@localhost
NGINX_CONF=$nginx_conf
EOF
    
    if [[ -n "$php_ver" ]]; then
        cat >> "$path/.env" << EOF

PHP_VERSION=$php_ver
NODE_VERSION=$node_ver
EOF
    fi
    
    if [[ "$inc_db" == true ]]; then
        if [[ "$shared_db" == true ]]; then
            cat >> "$path/.env" << EOF

# MySQL (SHARED)
DB_HOST=mysql-shared
DB_PORT=3306
MYSQL_DATABASE=${slug//-/_}_db
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_USER=root
MYSQL_PASSWORD=rootpassword
EOF
        else
            local port=$((13306 + $(echo -n "$slug" | sum | cut -d' ' -f1) % 1000))
            cat >> "$path/.env" << EOF

# MySQL (DEDICATED)
MYSQL_DATABASE=${slug//-/_}_db
MYSQL_ROOT_PASSWORD=root
MYSQL_USER=$type
MYSQL_PASSWORD=secret
MYSQL_VERSION=$mysql_ver
MYSQL_PORT=$port
EOF
        fi
    fi
    
    if [[ "$inc_redis" == true ]]; then
        if [[ "$shared_redis" == true ]]; then
            cat >> "$path/.env" << EOF

# Redis (SHARED)
REDIS_HOST=redis-shared
REDIS_PORT=6379
EOF
        else
            cat >> "$path/.env" << EOF

# Redis (DEDICATED)
REDIS_PORT=6379
EOF
        fi
    fi
}

start_shared_if_needed() {
    local use_db=$1 use_redis=$2 use_php=$3 php_ver=$4
    
    if [[ "$use_db" == false ]] && [[ "$use_redis" == false ]] && [[ "$use_php" == false ]]; then
        return
    fi
    
    print_info "Verifica servizi condivisi..."
    cd "$SCRIPT_DIR/proxy"
    
    if [[ "$use_db" == true ]] && ! docker ps | grep -q mysql-shared; then
        print_info "Avvio MySQL condiviso..."
        $DOCKER_COMPOSE --profile shared-services up -d mysql-shared
        sleep 3
    fi
    
    if [[ "$use_redis" == true ]] && ! docker ps | grep -q redis-shared; then
        print_info "Avvio Redis condiviso..."
        $DOCKER_COMPOSE --profile shared-services up -d redis-shared
        sleep 2
    fi
    
    if [[ "$use_php" == true ]]; then
        local container="php-$php_ver-shared"
        if ! docker ps | grep -q "$container"; then
            print_info "Avvio PHP $php_ver condiviso..."
            $DOCKER_COMPOSE --profile shared-services up -d "$container"
            sleep 3
        fi
    fi
    
    cd "$SCRIPT_DIR"
}

generate_ssl_cert() {
    local domain=$1
    local certs_dir="$SCRIPT_DIR/proxy/nginx/certs"
    
    mkdir -p "$certs_dir"
    
    if ! command -v mkcert &> /dev/null; then
        print_warning "mkcert non trovato, installalo per SSL locale"
        return
    fi
    
    mkcert -install 2>/dev/null || true
    mkcert -key-file "$certs_dir/$domain.key" -cert-file "$certs_dir/$domain.crt" "$domain" "*.$domain" 2>/dev/null
    
    if [ -f "$certs_dir/$domain.crt" ]; then
        cp "$certs_dir/$domain.crt" "$certs_dir/$domain.chain.pem"
        print_success "Certificato SSL generato"
    fi
}

install_framework() {
    local type=$1 path=$2 slug=$3 inc_db=$4 inc_redis=$5 shared_db=$6 shared_redis=$7
    
    cd "$path"
    
    case $type in
        laravel)
            print_info "Installazione Laravel..."
            $DOCKER_COMPOSE exec -T app composer create-project --prefer-dist laravel/laravel . 2>/dev/null || true
            $DOCKER_COMPOSE exec -T app chmod -R 775 storage bootstrap/cache 2>/dev/null || true
            
            if [ ! -f "$path/app/.env" ]; then
                $DOCKER_COMPOSE exec -T app cp .env.example .env 2>/dev/null || true
            fi
            
            $DOCKER_COMPOSE exec -T app php artisan key:generate 2>/dev/null || true
            
            if [[ "$inc_db" == true ]]; then
                local db_host="mysql"
                [[ "$shared_db" == true ]] && db_host="mysql-shared"
                $DOCKER_COMPOSE exec -T app sed -i "s/DB_HOST=.*/DB_HOST=$db_host/" .env 2>/dev/null || true
                $DOCKER_COMPOSE exec -T app sed -i "s/DB_DATABASE=.*/DB_DATABASE=${slug//-/_}_db/" .env 2>/dev/null || true
            fi
            
            if [[ "$inc_redis" == true ]]; then
                local redis_host="redis"
                [[ "$shared_redis" == true ]] && redis_host="redis-shared"
                $DOCKER_COMPOSE exec -T app sed -i "s/REDIS_HOST=.*/REDIS_HOST=$redis_host/" .env 2>/dev/null || true
            fi
            
            print_success "Laravel installato"
            ;;
            
        wordpress)
            print_info "Download WordPress..."
            $DOCKER_COMPOSE exec -T app bash -c "curl -o /tmp/wp.tar.gz https://wordpress.org/latest.tar.gz && tar -xzf /tmp/wp.tar.gz -C /tmp && cp -r /tmp/wordpress/. /var/www/html/ && rm -rf /tmp/wordpress*" 2>/dev/null || true
            print_success "WordPress scaricato"
            ;;
            
        html)
            cat > "$path/app/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Benvenuto</title>
</head>
<body>
    <h1>🎉 Il tuo progetto è pronto!</h1>
    <p>Modifica <code>app/index.html</code></p>
</body>
</html>
EOF
            ;;
            
        php)
            cat > "$path/app/index.php" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>PHP Info</title></head>
<body>
    <h1>🎉 PHP è funzionante!</h1>
    <p>Versione: <?php echo phpversion(); ?></p>
    <?php phpinfo(); ?>
</body>
</html>
EOF
            ;;
    esac
}

show_project_summary() {
    local type=$1 domain=$2 path=$3 installed=$4 inc_db=$5
    
    echo ""
    print_success "Progetto creato con successo!"
    echo ""
    echo -e "${CYAN}URL:${NC}       http://$domain"
    echo -e "${CYAN}HTTPS:${NC}     https://$domain"
    echo -e "${CYAN}Path:${NC}      $path"
    echo ""
    echo "Comandi rapidi:"
    echo "  ./docker-dev start $( basename $path)"
    echo "  ./docker-dev logs $( basename $path)"
    echo "  ./docker-dev shell $( basename $path)"
    
    if [[ "$type" == "laravel" ]] && [[ "$installed" == true ]] && [[ "$inc_db" == true ]]; then
        echo ""
        print_info "Esegui le migrazioni: ./docker-dev artisan $(basename $path) migrate"
    fi
}
