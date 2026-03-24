#!/bin/bash

# Module: Create
# Comando: create - Crea nuovo progetto

# ==================================================
# MODALITÀ INTERATTIVA
# ==================================================
interactive_create() {
    print_title "Creazione Progetto Interattiva"
    echo ""
    
    # Nome progetto
    read -p "$(echo -e "${CYAN}Nome progetto:${NC} ")" PROJECT_NAME
    if [ -z "$PROJECT_NAME" ]; then
        print_error "Nome progetto obbligatorio"
        exit 1
    fi
    echo ""
    
    # Tipo progetto
    print_info "Tipo progetto:"
    PS3="$(echo -e "${CYAN}Scegli (1-4):${NC} ")"
    select type in "Laravel" "WordPress" "PHP" "HTML"; do
        case $type in
            Laravel) PROJECT_TYPE="laravel"; break;;
            WordPress) PROJECT_TYPE="wordpress"; break;;
            PHP) PROJECT_TYPE="php"; break;;
            HTML) PROJECT_TYPE="html"; break;;
            *) echo "Scelta non valida";;
        esac
    done
    echo ""
    
    # Versione PHP (solo se non HTML)
    if [ "$PROJECT_TYPE" != "html" ]; then
        print_info "Versione PHP:"
        PS3="$(echo -e "${CYAN}Scegli (1-7):${NC} ")"
        select php in "8.5" "8.4" "8.3" "8.2" "8.1" "7.4" "7.3"; do
            case $php in
                8.5|8.4|8.3|8.2|8.1|7.4|7.3) PHP_VERSION="$php"; break;;
                *) echo "Scelta non valida";;
            esac
        done
        echo ""
    fi
    
    # Versione Node (solo per Laravel)
    if [ "$PROJECT_TYPE" == "laravel" ]; then
        print_info "Versione Node.js:"
        PS3="$(echo -e "${CYAN}Scegli (1-3):${NC} ")"
        select node in "20 (LTS)" "21" "18"; do
            case $node in
                "20 (LTS)") NODE_VERSION="20"; break;;
                "21") NODE_VERSION="21"; break;;
                "18") NODE_VERSION="18"; break;;
                *) echo "Scelta non valida";;
            esac
        done
        echo ""
    fi
    
    # Database
    print_info "Database MySQL:"
    PS3="$(echo -e "${CYAN}Scegli (1-3):${NC} ")"
    select db_choice in "Dedicato" "Condiviso" "Nessuno"; do
        case $db_choice in
            "Dedicato")
                INCLUDE_DB=true
                USE_SHARED_DB=false
                
                # Versione MySQL
                print_info "Versione MySQL:"
                PS3="$(echo -e "${CYAN}Scegli (1-2):${NC} ")"
                select mysql in "8.0" "5.7"; do
                    case $mysql in
                        8.0|5.7) MYSQL_VERSION="$mysql"; break;;
                        *) echo "Scelta non valida";;
                    esac
                done
                break
                ;;
            "Condiviso")
                INCLUDE_DB=true
                USE_SHARED_DB=true
                break
                ;;
            "Nessuno")
                INCLUDE_DB=false
                break
                ;;
            *) echo "Scelta non valida";;
        esac
    done
    echo ""
    
    # Redis
    print_info "Cache Redis:"
    PS3="$(echo -e "${CYAN}Scegli (1-3):${NC} ")"
    select redis_choice in "Dedicato" "Condiviso" "Nessuno"; do
        case $redis_choice in
            "Dedicato")
                INCLUDE_REDIS=true
                USE_SHARED_REDIS=false
                break
                ;;
            "Condiviso")
                INCLUDE_REDIS=true
                USE_SHARED_REDIS=true
                break
                ;;
            "Nessuno")
                INCLUDE_REDIS=false
                break
                ;;
            *) echo "Scelta non valida";;
        esac
    done
    echo ""
    
    # PHP condiviso per scheduler/queue (solo Laravel)
    if [ "$PROJECT_TYPE" == "laravel" ]; then
        print_info "PHP per Scheduler/Queue:"
        PS3="$(echo -e "${CYAN}Scegli (1-2):${NC} ")"
        select php_choice in "Dedicato (immagine progetto)" "Condiviso (php-shared)"; do
            case $php_choice in
                "Dedicato"*)
                    USE_SHARED_PHP=false
                    break
                    ;;
                "Condiviso"*)
                    USE_SHARED_PHP=true
                    break
                    ;;
                *) echo "Scelta non valida";;
            esac
        done
        echo ""
    fi
    
    # Installare il framework
    if [ "$PROJECT_TYPE" == "laravel" ] || [ "$PROJECT_TYPE" == "wordpress" ]; then
        print_info "Installare $PROJECT_TYPE automaticamente?"
        PS3="$(echo -e "${CYAN}Scegli (1-2):${NC} ")"
        select install in "Sì" "No"; do
            case $install in
                "Sì")
                    INSTALL_FRAMEWORK=true
                    break
                    ;;
                "No")
                    INSTALL_FRAMEWORK=false
                    break
                    ;;
                *) echo "Scelta non valida";;
            esac
        done
        echo ""
    fi
    
    # Costruisci comando e chiama la funzione di creazione
    local cmd_args=("$PROJECT_NAME")
    [ "$PROJECT_TYPE" != "laravel" ] && cmd_args+=(--type "$PROJECT_TYPE")
    [ -n "$PHP_VERSION" ] && cmd_args+=(--php "$PHP_VERSION")
    [ -n "$NODE_VERSION" ] && cmd_args+=(--node "$NODE_VERSION")
    [ -n "$MYSQL_VERSION" ] && cmd_args+=(--mysql "$MYSQL_VERSION")
    [ "$USE_SHARED_DB" == true ] && cmd_args+=(--shared-db)
    [ "$USE_SHARED_REDIS" == true ] && cmd_args+=(--shared-redis)
    [ "$USE_SHARED_PHP" == true ] && cmd_args+=(--shared-php)
    [ "$INCLUDE_DB" == false ] && cmd_args+=(--no-db)
    [ "$INCLUDE_REDIS" == false ] && cmd_args+=(--no-redis)
    [ "$INSTALL_FRAMEWORK" == false ] && cmd_args+=(--no-install)
    
    # Chiama la funzione principale con i parametri raccolti
    cmd_create "${cmd_args[@]}"
}

# ==================================================
# COMANDO CREATE
# ==================================================
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
    
    # Parse argomenti - se vuoto, modalità interattiva
    if [ $# -eq 0 ]; then
        interactive_create
        return
    fi
    
    local PROJECT_NAME=$1
    shift
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --type=*)
                PROJECT_TYPE="${1#*=}"
                shift
                ;;
            --type)
                PROJECT_TYPE="$2"
                shift 2
                ;;
            --php=*)
                PHP_VERSION="${1#*=}"
                shift
                ;;
            --php)
                PHP_VERSION="$2"
                shift 2
                ;;
            --node=*)
                NODE_VERSION="${1#*=}"
                shift
                ;;
            --node)
                NODE_VERSION="$2"
                shift 2
                ;;
            --mysql=*)
                MYSQL_VERSION="${1#*=}"
                shift
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
    
    if [[ -n "$PHP_VERSION" ]] && [[ ! "$PHP_VERSION" =~ ^(7.3|7.4|8.1|8.2|8.3|8.4|8.5)$ ]]; then
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
    # Ora usiamo SEMPRE il template unificato
    local NGINX_CONF=""
    
    case $PROJECT_TYPE in
        html)
            NGINX_CONF="html.conf"
            cp "$SCRIPT_DIR/shared/templates/docker-compose-html.yml" "$PROJECT_PATH/docker-compose.yml"
            ;;
        *)
            # Laravel, WordPress, PHP usano il template unificato
            case $PROJECT_TYPE in
                wordpress) NGINX_CONF="wordpress.conf" ;;
                php) NGINX_CONF="php.conf" ;;
                laravel)
                    if [[ "$USE_SHARED_PHP" == true ]]; then
                        NGINX_CONF="laravel-shared.conf"
                    else
                        NGINX_CONF="laravel.conf"
                    fi
                    ;;
            esac
            
            # Copia template unificato
            cp "$SCRIPT_DIR/shared/templates/docker-compose-unified.yml" "$PROJECT_PATH/docker-compose.yml"
            
            # Genera nginx.conf per progetti PHP condiviso
            if [[ "$USE_SHARED_PHP" == true ]]; then
                print_info "Configurazione Nginx per PHP condiviso..."
                sed -e "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_SLUG/g" \
                    -e "s/PHP_VERSION_PLACEHOLDER/php-$PHP_VERSION/g" \
                    "$SCRIPT_DIR/shared/nginx/laravel-shared.conf" > "$PROJECT_PATH/nginx.conf"
                # Imposta NGINX_CONF per montare il file locale invece del template
                NGINX_CONF="./nginx.conf"
            fi
            ;;
    esac
    
    # Crea .env con configurazione unificata
    create_unified_env_file "$PROJECT_PATH" "$PROJECT_SLUG" "$PROJECT_TYPE" "$DOMAIN" "$NGINX_CONF" \
                    "$PHP_VERSION" "$NODE_VERSION" "$MYSQL_VERSION" \
                    "$INCLUDE_DB" "$INCLUDE_REDIS" "$USE_SHARED_DB" "$USE_SHARED_REDIS" "$USE_SHARED_PHP"
    
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
    
    # Costruisci i flag --profile basandosi sul .env
    local profile_flags="--profile app"
    
    if [[ "$INCLUDE_DB" == true ]] && [[ "$USE_SHARED_DB" != true ]]; then
        profile_flags="$profile_flags --profile mysql-dedicated"
    fi
    
    if [[ "$INCLUDE_REDIS" == true ]] && [[ "$USE_SHARED_REDIS" != true ]]; then
        profile_flags="$profile_flags --profile redis-dedicated"
    fi
    
    # Attiva sempre scheduler/queue per progetti Laravel
    # I container aspetteranno che artisan esista prima di partire
    if [[ "$PROJECT_TYPE" == "laravel" ]]; then
        profile_flags="$profile_flags --profile scheduler --profile queue"
    fi
    
    # Build delle immagini necessarie
    print_info "Build immagine app..."
    $DOCKER_COMPOSE build app
    
    # Avvia i container con i profili appropriati
    $DOCKER_COMPOSE $profile_flags up -d
    
    # Genera SSL
    generate_ssl_cert "$DOMAIN"
    
    print_info "Attesa avvio container..."
    sleep 5
    
    # Installa framework
    if [ "$INSTALL_FRAMEWORK" = true ]; then
        install_framework "$PROJECT_TYPE" "$PROJECT_PATH" "$PROJECT_SLUG" "$INCLUDE_DB" "$INCLUDE_REDIS" "$USE_SHARED_DB" "$USE_SHARED_REDIS" "$USE_SHARED_PHP" "$PHP_VERSION"
    fi
    
    # Riepilogo finale
    show_project_summary "$PROJECT_TYPE" "$DOMAIN" "$PROJECT_PATH" "$INSTALL_FRAMEWORK" "$INCLUDE_DB"
}

show_create_usage() {
    echo "Uso: ./docker-dev create <nome> [opzioni]"
    echo ""
    echo "Opzioni:"
    echo "  --type <tipo>         Tipo: laravel, wordpress, php, html (default: laravel)"
    echo "  --php <versione>      Versione PHP: 7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5 (default: 8.3)"
    echo "  --node <versione>     Versione Node.js: 18, 20, 21 (default: 20)"
    echo "  --mysql <versione>    Versione MySQL: 5.7, 8.0 (default: 8.0)"
    echo ""
    echo "Cherry-picking servizi condivisi:"
    echo "  --shared-db           Usa MySQL condiviso"
    echo "  --shared-redis        Usa Redis condiviso"
    echo "  --shared-php          Scheduler/Queue usano PHP condiviso"
    echo "  --no-db               Senza MySQL"
    echo "  --no-redis            Senza Redis"
    echo ""
    echo "Preset (shortcut):"
    echo "  --shared              Equivalente a: --shared-db --shared-redis"
    echo "  --fully-shared        Equivalente a: --shared-db --shared-redis --shared-php"
    echo ""
    echo "Altro:"
    echo "  --no-install          Non installare framework"
    echo ""
    echo "Esempi:"
    echo "  ./docker-dev create my-shop"
    echo "  ./docker-dev create blog --shared-db --shared-redis"
    echo "  ./docker-dev create api --fully-shared"
    echo "  ./docker-dev create cms --shared-db --no-redis"
}

create_unified_env_file() {
    local path=$1 slug=$2 type=$3 domain=$4 nginx_conf=$5
    local php_ver=$6 node_ver=$7 mysql_ver=$8
    local inc_db=$9 inc_redis=${10} shared_db=${11} shared_redis=${12} shared_php=${13}
    
    # Determina servizi e configurazione
    local db_service="mysql"
    local db_host="mysql"
    local redis_service="redis"
    local redis_host="redis"
    local scheduler_image="\${PROJECT_NAME}-app"
    local queue_image="\${PROJECT_NAME}-app"
    local profiles="app"
    
    if [[ "$shared_db" == true ]]; then
        db_service="mysql-shared"
        db_host="mysql-shared"
    elif [[ "$inc_db" == true ]]; then
        profiles="$profiles mysql-dedicated"
    fi
    
    if [[ "$shared_redis" == true ]]; then
        redis_service="redis-shared"
        redis_host="redis-shared"
    elif [[ "$inc_redis" == true ]]; then
        profiles="$profiles redis-dedicated"
    fi
    
    if [[ "$shared_php" == true ]]; then
        scheduler_image="proxy-php-\${PHP_VERSION}-shared"
        queue_image="proxy-php-\${PHP_VERSION}-shared"
    fi
    
    # Aggiungi sempre scheduler ai profiles per progetti con PHP
    if [[ -n "$php_ver" ]] && [[ "$type" == "laravel" ]]; then
        profiles="$profiles scheduler"
    fi
    
    # Crea .env
    cat > "$path/.env" << EOF
# ============================================
# PROJECT BASICS
# ============================================
PROJECT_NAME=$slug
PROJECT_TYPE=$type
DOMAIN=$domain
LETSENCRYPT_EMAIL=dev@localhost

# ============================================
# WEB SERVER
# ============================================
EOF

    # Determina path nginx.conf in base al tipo di configurazione
    if [[ "$nginx_conf" == "./"* ]]; then
        # Path locale (per shared-php)
        cat >> "$path/.env" << EOF
NGINX_CONF_PATH=$nginx_conf
EOF
    else
        # Path in shared (standard)
        cat >> "$path/.env" << EOF
NGINX_CONF_PATH=../../shared/nginx/$nginx_conf
EOF
    fi

    cat >> "$path/.env" << EOF

# ============================================
# VERSIONS
# ============================================
EOF

    if [[ -n "$php_ver" ]]; then
        cat >> "$path/.env" << EOF
PHP_VERSION=$php_ver
NODE_VERSION=$node_ver
EOF
    fi
    
    if [[ "$inc_db" == true ]]; then
        cat >> "$path/.env" << EOF
MYSQL_VERSION=$mysql_ver

# ============================================
# DATABASE CONFIGURATION
# ============================================
DB_SERVICE=$db_service
DB_HOST=$db_host
DB_CONNECTION=mysql
EOF

        if [[ "$shared_db" == true ]]; then
            cat >> "$path/.env" << EOF

# MySQL (SHARED)
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
MYSQL_PORT=$port
EOF
        fi
    fi
    
    if [[ "$inc_redis" == true ]]; then
        cat >> "$path/.env" << EOF

# ============================================
# REDIS CONFIGURATION
# ============================================
REDIS_SERVICE=$redis_service
REDIS_HOST=$redis_host
EOF

        if [[ "$shared_redis" != true ]]; then
            cat >> "$path/.env" << EOF
REDIS_PORT=6379
EOF
        fi
    fi
    
    if [[ -n "$php_ver" ]]; then
        cat >> "$path/.env" << EOF

# ============================================
# SCHEDULER & QUEUE CONFIGURATION
# ============================================
SCHEDULER_IMAGE=$scheduler_image
QUEUE_IMAGE=$queue_image
EOF
    fi
    
    # Vite port
    if [[ -n "$node_ver" ]]; then
        local vite_port=$(find_available_port 5173 100)
        cat >> "$path/.env" << EOF

# ============================================
# VITE DEV SERVER
# ============================================
VITE_PORT=$vite_port
EOF
    fi
    
    # Compose profiles
    cat >> "$path/.env" << EOF

# ============================================
# DOCKER COMPOSE PROFILES
# ============================================
# Enabled profiles: $profiles
COMPOSE_PROFILES=$profiles
EOF
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
    
    # Vite dev server port (calculate unique port based on project name)
    if [[ -n "$node_ver" ]]; then
        local vite_port=$(find_available_port 5173 100)
        cat >> "$path/.env" << EOF

# Vite Dev Server
VITE_PORT=$vite_port
EOF
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
    local first_time=false
    
    mkdir -p "$certs_dir"
    
    if ! command -v mkcert &> /dev/null; then
        print_warning "mkcert non trovato"
        echo ""
        echo "Per abilitare HTTPS locale, installa mkcert:"
        local os=$(detect_os)
        if [ "$os" = "macos" ]; then
            echo "  brew install mkcert"
        else
            echo "  # Vedi: https://github.com/FiloSottile/mkcert#installation"
        fi
        echo "  $SCRIPT_DIR/proxy/setup-ssl-ca.sh"
        return
    fi
    
    # Verifica se la CA è già installata
    local ca_root="$(mkcert -CAROOT)"
    if [ ! -f "$ca_root/rootCA.pem" ]; then
        first_time=true
        print_info "Prima installazione CA locale (richiederà password)..."
        mkcert -install
    fi
    
    # Genera certificato
    mkcert -key-file "$certs_dir/$domain.key" -cert-file "$certs_dir/$domain.crt" "$domain" "*.$domain" 2>/dev/null
    
    if [ -f "$certs_dir/$domain.crt" ]; then
        cp "$certs_dir/$domain.crt" "$certs_dir/$domain.chain.pem"
        print_success "Certificato SSL generato"
        
        # Riavvia nginx-proxy per caricare i nuovi certificati
        print_info "Ricaricamento configurazione SSL..."
        cd "$SCRIPT_DIR/proxy"
        $DOCKER_COMPOSE restart nginx-proxy > /dev/null 2>&1
        cd "$SCRIPT_DIR"
        
        # Mostra istruzioni se è la prima volta
        if [ "$first_time" = true ]; then
            echo ""
            print_warning "IMPORTANTE: Chiudi e riavvia tutti i browser per riconoscere i certificati SSL"
        fi
    fi
}

install_framework() {
    local type=$1 path=$2 slug=$3 inc_db=$4 inc_redis=$5 shared_db=$6 shared_redis=$7 shared_php=$8 php_version=$9
    local project=$(basename "$path")
    
    cd "$path"
    
    case $type in
        laravel)
            print_info "Installazione Laravel..."
            
            if [[ "$shared_php" == true ]]; then
                # Fully-shared: usa container PHP condiviso
                docker exec php-${php_version}-shared bash -c "cd /var/www/projects/$project/app && composer create-project --prefer-dist laravel/laravel ." 2>/dev/null || true
                docker exec php-${php_version}-shared bash -c "cd /var/www/projects/$project/app && chmod -R 775 storage bootstrap/cache" 2>/dev/null || true
                
                if [ ! -f "$path/app/.env" ]; then
                    docker exec php-${php_version}-shared bash -c "cd /var/www/projects/$project/app && cp .env.example .env" 2>/dev/null || true
                fi
                
                docker exec php-${php_version}-shared bash -c "cd /var/www/projects/$project/app && php artisan key:generate" 2>/dev/null || true
                
                if [[ "$inc_db" == true ]]; then
                    local db_host="mysql"
                    local db_password="root"
                    if [[ "$shared_db" == true ]]; then
                        db_host="mysql-shared"
                        db_password="rootpassword"
                    fi
                    docker exec php-${php_version}-shared bash -c "cd /var/www/projects/$project/app && sed -i 's/DB_HOST=.*/DB_HOST=$db_host/' .env" 2>/dev/null || true
                    docker exec php-${php_version}-shared bash -c "cd /var/www/projects/$project/app && sed -i 's/DB_DATABASE=.*/DB_DATABASE=${slug//-/_}_db/' .env" 2>/dev/null || true
                    docker exec php-${php_version}-shared bash -c "cd /var/www/projects/$project/app && sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=$db_password/' .env" 2>/dev/null || true
                fi
                
                if [[ "$inc_redis" == true ]]; then
                    local redis_host="redis"
                    [[ "$shared_redis" == true ]] && redis_host="redis-shared"
                    docker exec php-${php_version}-shared bash -c "cd /var/www/projects/$project/app && sed -i 's/REDIS_HOST=.*/REDIS_HOST=$redis_host/' .env" 2>/dev/null || true
                fi
            else
                # Dedicato: usa container app del progetto
                $DOCKER_COMPOSE exec -T app composer create-project --prefer-dist laravel/laravel . 2>/dev/null || true
                $DOCKER_COMPOSE exec -T app chmod -R 775 storage bootstrap/cache 2>/dev/null || true
                
                if [ ! -f "$path/app/.env" ]; then
                    $DOCKER_COMPOSE exec -T app cp .env.example .env 2>/dev/null || true
                fi
                
                $DOCKER_COMPOSE exec -T app php artisan key:generate 2>/dev/null || true
                
                if [[ "$inc_db" == true ]]; then
                    local db_host="mysql"
                    local db_password="root"
                    if [[ "$shared_db" == true ]]; then
                        db_host="mysql-shared"
                        db_password="rootpassword"
                    fi
                    $DOCKER_COMPOSE exec -T app sed -i "s/DB_HOST=.*/DB_HOST=$db_host/" .env 2>/dev/null || true
                    $DOCKER_COMPOSE exec -T app sed -i "s/DB_DATABASE=.*/DB_DATABASE=${slug//-/_}_db/" .env 2>/dev/null || true
                    $DOCKER_COMPOSE exec -T app sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$db_password/" .env 2>/dev/null || true
                fi
                
                if [[ "$inc_redis" == true ]]; then
                    local redis_host="redis"
                    [[ "$shared_redis" == true ]] && redis_host="redis-shared"
                    $DOCKER_COMPOSE exec -T app sed -i "s/REDIS_HOST=.*/REDIS_HOST=$redis_host/" .env 2>/dev/null || true
                fi
            fi
            
            print_success "Laravel installato"
            ;;
            
        wordpress)
            print_info "Download WordPress..."
            if [[ "$shared_php" == true ]]; then
                docker exec php-${php_version}-shared bash -c "curl -o /tmp/wp.tar.gz https://wordpress.org/latest.tar.gz && tar -xzf /tmp/wp.tar.gz -C /tmp && cp -r /tmp/wordpress/. /var/www/projects/$project/app/ && rm -rf /tmp/wordpress*" 2>/dev/null || true
            else
                $DOCKER_COMPOSE exec -T app bash -c "curl -o /tmp/wp.tar.gz https://wordpress.org/latest.tar.gz && tar -xzf /tmp/wp.tar.gz -C /tmp && cp -r /tmp/wordpress/. /var/www/html/ && rm -rf /tmp/wordpress*" 2>/dev/null || true
            fi
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
