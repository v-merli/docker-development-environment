#!/bin/bash

# Module: Create
# Command: create - Create new project

# ==================================================
# INTERACTIVE MODE
# ==================================================
interactive_create() {
    print_title "Interactive Project Creation"
    echo ""
    
    # Project name
    read -p "$(echo -e "${CYAN}Project name:${NC} ")" PROJECT_NAME
    if [ -z "$PROJECT_NAME" ]; then
        print_error "Project name is required"
        exit 1
    fi
    echo ""
    
    # Project type
    print_info "Project type:"
    PS3="$(echo -e "${CYAN}Choose (1-4):${NC} ")"
    select type in "Laravel" "WordPress" "PHP" "HTML"; do
        case $type in
            Laravel) PROJECT_TYPE="laravel"; break;;
            WordPress) PROJECT_TYPE="wordpress"; break;;
            PHP) PROJECT_TYPE="php"; break;;
            HTML) PROJECT_TYPE="html"; break;;
            *) echo "Invalid choice";;
        esac
    done
    echo ""
    
    # PHP version (only if not HTML)
    if [ "$PROJECT_TYPE" != "html" ]; then
        print_info "PHP version:"
        PS3="$(echo -e "${CYAN}Choose (1-7):${NC} ")"
        select php in "8.5" "8.4" "8.3" "8.2" "8.1" "7.4" "7.3"; do
            case $php in
                8.5|8.4|8.3|8.2|8.1|7.4|7.3) PHP_VERSION="$php"; break;;
                *) echo "Invalid choice";;
            esac
        done
        echo ""
    fi
    
    # Node version (Laravel only)
    if [ "$PROJECT_TYPE" == "laravel" ]; then
        print_info "Node.js version:"
        PS3="$(echo -e "${CYAN}Choose (1-3):${NC} ")"
        select node in "20 (LTS)" "21" "18"; do
            case $node in
                "20 (LTS)") NODE_VERSION="20"; break;;
                "21") NODE_VERSION="21"; break;;
                "18") NODE_VERSION="18"; break;;
                *) echo "Invalid choice";;
            esac
        done
        echo ""
    fi
    
    # Database
    print_info "MySQL Database:"
    PS3="$(echo -e "${CYAN}Choose (1-3):${NC} ")"
    select db_choice in "Dedicated" "Shared" "None"; do
        case $db_choice in
            "Dedicated")
                INCLUDE_DB=true
                USE_SHARED_DB=false
                
                # MySQL version
                print_info "MySQL version:"
                PS3="$(echo -e "${CYAN}Choose (1-2):${NC} ")"
                select mysql in "8.0" "5.7"; do
                    case $mysql in
                        8.0|5.7) MYSQL_VERSION="$mysql"; break;;
                        *) echo "Invalid choice";;
                    esac
                done
                break
                ;;
            "Shared")
                INCLUDE_DB=true
                USE_SHARED_DB=true
                break
                ;;
            "None")
                INCLUDE_DB=false
                break
                ;;
            *) echo "Invalid choice";;
        esac
    done
    echo ""
    
    # Redis
    print_info "Redis Cache:"
    PS3="$(echo -e "${CYAN}Choose (1-3):${NC} ")"
    select redis_choice in "Dedicated" "Shared" "None"; do
        case $redis_choice in
            "Dedicated")
                INCLUDE_REDIS=true
                USE_SHARED_REDIS=false
                break
                ;;
            "Shared")
                INCLUDE_REDIS=true
                USE_SHARED_REDIS=true
                break
                ;;
            "None")
                INCLUDE_REDIS=false
                break
                ;;
            *) echo "Invalid choice";;
        esac
    done
    echo ""
    
    # Shared PHP for scheduler/queue (only Laravel)
    if [ "$PROJECT_TYPE" == "laravel" ]; then
        print_info "PHP for Scheduler/Queue:"
        PS3="$(echo -e "${CYAN}Choose (1-2):${NC} ")"
        select php_choice in "Dedicated (project image)" "Shared (php-shared)"; do
            case $php_choice in
                "Dedicated"*)
                    USE_SHARED_PHP=false
                    break
                    ;;
                "Shared"*)
                    USE_SHARED_PHP=true
                    break
                    ;;
                *) echo "Invalid choice";;
            esac
        done
        echo ""
    fi
    
    # Install framework
    if [ "$PROJECT_TYPE" == "laravel" ] || [ "$PROJECT_TYPE" == "wordpress" ]; then
        print_info "Install $PROJECT_TYPE automatically?"
        PS3="$(echo -e "${CYAN}Choose (1-2):${NC} ")"
        select install in "Yes" "No"; do
            case $install in
                "Yes")
                    INSTALL_FRAMEWORK=true
                    break
                    ;;
                "No")
                    INSTALL_FRAMEWORK=false
                    break
                    ;;
                *) echo "Invalid choice";;
            esac
        done
        echo ""
    fi
    
    # Build command and call creation function
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
    
    # Call main function with collected parameters
    cmd_create "${cmd_args[@]}"
}

# ==================================================
# CREATE COMMAND
# ==================================================
cmd_create() {
    # Check for --help
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_create_usage
        exit 0
    fi
    
    # Default values
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
    
    # Parse arguments - if empty, interactive mode
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
                print_error "Unknown option: $1"
                show_create_usage
                exit 1
                ;;
        esac
    done
    
    # Validation
    if [[ ! "$PROJECT_TYPE" =~ ^(laravel|wordpress|php|html)$ ]]; then
        print_error "Unsupported project type: $PROJECT_TYPE"
        exit 1
    fi
    
    if [[ "$PROJECT_TYPE" == "html" ]]; then
        PHP_VERSION=""
        NODE_VERSION=""
        INCLUDE_DB=false
        INCLUDE_REDIS=false
    fi
    
    if [[ -n "$PHP_VERSION" ]] && [[ ! "$PHP_VERSION" =~ ^(7.3|7.4|8.1|8.2|8.3|8.4|8.5)$ ]]; then
        print_error "Unsupported PHP version: $PHP_VERSION"
        exit 1
    fi
    
    # Generate names and paths
    local PROJECT_SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
    local DOMAIN="$PROJECT_SLUG.test"
    local PROJECT_PATH="$PROJECTS_DIR/$PROJECT_SLUG"
    
    # Show summary
    print_title "Creating New Project"
    echo ""
    echo "Name:      $PROJECT_NAME"
    echo "Type:      $PROJECT_TYPE"
    echo "Domain:    $DOMAIN"
    if [[ -n "$PHP_VERSION" ]]; then
        if [[ "$USE_SHARED_PHP" == true ]]; then
            echo "PHP:       Shared $PHP_VERSION"
        else
            echo "PHP:       Dedicated $PHP_VERSION"
        fi
    fi
    if [[ "$INCLUDE_DB" == true ]]; then
        if [[ "$USE_SHARED_DB" == true ]]; then
            echo "MySQL:     Shared"
        else
            echo "MySQL:     Dedicated $MYSQL_VERSION"
        fi
    fi
    if [[ "$INCLUDE_REDIS" == true ]]; then
        if [[ "$USE_SHARED_REDIS" == true ]]; then
            echo "Redis:     Shared"
        else
            echo "Redis:     Dedicated"
        fi
    fi
    echo ""
    
    # Check existence
    if [ -d "$PROJECT_PATH" ]; then
        print_error "Project '$PROJECT_SLUG' already exists"
        exit 1
    fi
    
    # Create structure
    print_info "Creating directory structure..."
    mkdir -p "$PROJECT_PATH/app"
    
    # Select docker-compose template
    # Now we ALWAYS use the unified template
    local NGINX_CONF=""
    
    case $PROJECT_TYPE in
        html)
            NGINX_CONF="html.conf"
            cp "$SCRIPT_DIR/shared/templates/docker-compose-html.yml" "$PROJECT_PATH/docker-compose.yml"
            ;;
        *)
            # Laravel, WordPress, PHP use the unified template
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
            
            # Copy unified template
            cp "$SCRIPT_DIR/shared/templates/docker-compose-unified.yml" "$PROJECT_PATH/docker-compose.yml"
            
            # Generate nginx.conf for shared PHP projects
            if [[ "$USE_SHARED_PHP" == true ]]; then
                print_info "Configuring Nginx for shared PHP..."
                sed -e "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_SLUG/g" \
                    -e "s/PHP_VERSION_PLACEHOLDER/php-$PHP_VERSION/g" \
                    "$SCRIPT_DIR/shared/nginx/laravel-shared.conf" > "$PROJECT_PATH/nginx.conf"
                # Set NGINX_CONF to mount the local file instead of the template
                NGINX_CONF="./nginx.conf"
            fi
            ;;
    esac
    
    # Create .env with unified configuration
    create_unified_env_file "$PROJECT_PATH" "$PROJECT_SLUG" "$PROJECT_TYPE" "$DOMAIN" "$NGINX_CONF" \
                    "$PHP_VERSION" "$NODE_VERSION" "$MYSQL_VERSION" \
                    "$INCLUDE_DB" "$INCLUDE_REDIS" "$USE_SHARED_DB" "$USE_SHARED_REDIS" "$USE_SHARED_PHP"
    
    print_success "Project structure created"
    
    # Check proxy network
    if ! docker network inspect phpharbor-proxy &> /dev/null; then
        print_info "Creating phpharbor-proxy network..."
        docker network create phpharbor-proxy
        print_info "Starting reverse proxy..."
        cd "$SCRIPT_DIR/proxy"
        $DOCKER_COMPOSE up -d nginx-proxy acme-companion
        cd "$SCRIPT_DIR"
        sleep 3
    fi
    
    # Start shared services
    start_shared_if_needed "$USE_SHARED_DB" "$USE_SHARED_REDIS" "$USE_SHARED_PHP" "$PHP_VERSION"
    
    # Start project containers
    print_info "Starting containers..."
    cd "$PROJECT_PATH"
    
    # Build the --profile flags based on .env
    local profile_flags="--profile app"
    
    if [[ "$INCLUDE_DB" == true ]] && [[ "$USE_SHARED_DB" != true ]]; then
        profile_flags="$profile_flags --profile mysql-dedicated"
    fi
    
    if [[ "$INCLUDE_REDIS" == true ]] && [[ "$USE_SHARED_REDIS" != true ]]; then
        profile_flags="$profile_flags --profile redis-dedicated"
    fi
    
    # Always enable scheduler/queue for Laravel projects
    # Containers will wait for artisan to exist before starting
    if [[ "$PROJECT_TYPE" == "laravel" ]]; then
        profile_flags="$profile_flags --profile scheduler --profile queue"
    fi
    
    # Build required images
    print_info "Building app image..."
    $DOCKER_COMPOSE build app
    
    # Start containers with appropriate profiles
    $DOCKER_COMPOSE $profile_flags up -d
    
    # Generate SSL
    generate_ssl_cert "$DOMAIN"
    
    print_info "Waiting for containers to start..."
    sleep 5
    
    # Install framework
    if [ "$INSTALL_FRAMEWORK" = true ]; then
        install_framework "$PROJECT_TYPE" "$PROJECT_PATH" "$PROJECT_SLUG" "$INCLUDE_DB" "$INCLUDE_REDIS" "$USE_SHARED_DB" "$USE_SHARED_REDIS" "$USE_SHARED_PHP" "$PHP_VERSION"
    fi
    
    # Copy VS Code configuration for Xdebug (always, except for HTML)
    if [ "$PROJECT_TYPE" != "html" ]; then
        print_info "Configuring VS Code for Xdebug..."
        mkdir -p "$PROJECT_PATH/app/.vscode"
        if [ -f "$SCRIPT_DIR/shared/templates/vscode/launch.json" ]; then
            cp "$SCRIPT_DIR/shared/templates/vscode/launch.json" "$PROJECT_PATH/app/.vscode/"
            cp "$SCRIPT_DIR/shared/templates/vscode/XDEBUG-GUIDE.md" "$PROJECT_PATH/app/" 2>/dev/null || true
            print_success "VS Code configuration and Xdebug guide added"
        fi
    fi
    
    # Final summary
    show_project_summary "$PROJECT_TYPE" "$DOMAIN" "$PROJECT_PATH" "$INSTALL_FRAMEWORK" "$INCLUDE_DB"
}

show_create_usage() {
    echo "Usage: ./phpharbor create <name> [options]"
    echo ""
    echo "Options:"
    echo "  --type <type>         Type: laravel, wordpress, php, html (default: laravel)"
    echo "  --php <version>       PHP version: 7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5 (default: 8.3)"
    echo "  --node <version>      Node.js version: 18, 20, 21 (default: 20)"
    echo "  --mysql <version>     MySQL version: 5.7, 8.0 (default: 8.0)"
    echo ""
    echo "Cherry-picking shared services:"
    echo "  --shared-db           Use shared MySQL"
    echo "  --shared-redis        Use shared Redis"
    echo "  --shared-php          Scheduler/Queue use shared PHP"
    echo "  --no-db               Without MySQL"
    echo "  --no-redis            Without Redis"
    echo ""
    echo "Presets (shortcuts):"
    echo "  --shared              Equivalent to: --shared-db --shared-redis"
    echo "  --fully-shared        Equivalent to: --shared-db --shared-redis --shared-php"
    echo ""
    echo "Other:"
    echo "  --no-install          Don't install framework"
    echo ""
    echo "Examples:"
    echo "  ./phpharbor create my-shop"
    echo "  ./phpharbor create blog --shared-db --shared-redis"
    echo "  ./phpharbor create api --fully-shared"
    echo "  ./phpharbor create cms --shared-db --no-redis"
}

create_unified_env_file() {
    local path=$1 slug=$2 type=$3 domain=$4 nginx_conf=$5
    local php_ver=$6 node_ver=$7 mysql_ver=$8
    local inc_db=$9 inc_redis=${10} shared_db=${11} shared_redis=${12} shared_php=${13}
    
    # Determine services and configuration
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
        scheduler_image="phpharbor-proxy-php-\${PHP_VERSION}-shared"
        queue_image="phpharbor-proxy-php-\${PHP_VERSION}-shared"
    fi
    
    # Always add scheduler to profiles for PHP projects
    if [[ -n "$php_ver" ]] && [[ "$type" == "laravel" ]]; then
        profiles="$profiles scheduler"
    fi
    
    # Create .env
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

    # Determine nginx.conf path based on configuration type
    if [[ "$nginx_conf" == "./"* ]]; then
        # Local path (for shared-php)
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
    
    print_info "Checking shared services..."
    cd "$SCRIPT_DIR/proxy"
    
    if [[ "$use_db" == true ]] && ! docker ps | grep -q mysql-shared; then
        print_info "Starting shared MySQL..."
        $DOCKER_COMPOSE --profile shared-services up -d mysql-shared
        sleep 3
    fi
    
    if [[ "$use_redis" == true ]] && ! docker ps | grep -q redis-shared; then
        print_info "Starting shared Redis..."
        $DOCKER_COMPOSE --profile shared-services up -d redis-shared
        sleep 2
    fi
    
    if [[ "$use_php" == true ]]; then
        local container="php-$php_ver-shared"
        if ! docker ps | grep -q "$container"; then
            print_info "Starting shared PHP $php_ver..."
            $DOCKER_COMPOSE --profile shared-services up -d "$container"
            sleep 3
        fi
    fi
    
    cd "$SCRIPT_DIR"
}

# Generate SSL certificate using mkcert (local development)
# This is the PRIMARY SSL system for .test domains
# acme-companion will also try but fail (can't validate .test domains)
# nginx-proxy will use mkcert certificates when available
generate_ssl_cert() {
    local domain=$1
    local certs_dir="$SCRIPT_DIR/proxy/nginx/certs"
    local first_time=false
    
    mkdir -p "$certs_dir"
    
    if ! command -v mkcert &> /dev/null; then
        print_warning "mkcert not found"
        echo ""
        echo "To enable local HTTPS, install mkcert:"
        local os=$(detect_os)
        if [ "$os" = "macos" ]; then
            echo "  brew install mkcert"
        else
            echo "  # See: https://github.com/FiloSottile/mkcert#installation"
        fi
        echo "  $SCRIPT_DIR/proxy/setup-ssl-ca.sh"
        echo ""
        echo "Note: acme-companion will run but can't generate valid certs for .test domains"
        return
    fi
    
    # Check if CA is already installed
    local ca_root="$(mkcert -CAROOT)"
    if [ ! -f "$ca_root/rootCA.pem" ]; then
        first_time=true
        print_info "First CA installation (will ask for password)..."
        mkcert -install
    fi
    
    # Generate certificate
    mkcert -key-file "$certs_dir/$domain.key" -cert-file "$certs_dir/$domain.crt" "$domain" "*.$domain" 2>/dev/null
    
    if [ -f "$certs_dir/$domain.crt" ]; then
        cp "$certs_dir/$domain.crt" "$certs_dir/$domain.chain.pem"
        print_success "SSL certificate generated"
        
        # Restart nginx-proxy to load new certificates
        print_info "Reloading SSL configuration..."
        cd "$SCRIPT_DIR/proxy"
        $DOCKER_COMPOSE restart nginx-proxy > /dev/null 2>&1
        cd "$SCRIPT_DIR"
        
        # Show instructions if first time
        if [ "$first_time" = true ]; then
            echo ""
            print_warning "IMPORTANT: Close and restart all browsers to recognize SSL certificates"
        fi
    fi
}

install_framework() {
    local type=$1 path=$2 slug=$3 inc_db=$4 inc_redis=$5 shared_db=$6 shared_redis=$7 shared_php=$8 php_version=$9
    local project=$(basename "$path")
    
    cd "$path"
    
    case $type in
        laravel)
            print_info "Installing Laravel..."
            
            if [[ "$shared_php" == true ]]; then
                # Fully-shared: use shared PHP container
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
                # Dedicated: use project's app container
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
            
            print_success "Laravel installed"
            ;;
            
        wordpress)
            print_info "Downloading WordPress..."
            if [[ "$shared_php" == true ]]; then
                docker exec php-${php_version}-shared bash -c "curl -o /tmp/wp.tar.gz https://wordpress.org/latest.tar.gz && tar -xzf /tmp/wp.tar.gz -C /tmp && cp -r /tmp/wordpress/. /var/www/projects/$project/app/ && rm -rf /tmp/wordpress*" 2>/dev/null || true
            else
                $DOCKER_COMPOSE exec -T app bash -c "curl -o /tmp/wp.tar.gz https://wordpress.org/latest.tar.gz && tar -xzf /tmp/wp.tar.gz -C /tmp && cp -r /tmp/wordpress/. /var/www/html/ && rm -rf /tmp/wordpress*" 2>/dev/null || true
            fi
            print_success "WordPress downloaded"
            ;;
            
        html)
            cat > "$path/app/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
</head>
<body>
    <h1>🎉 Your project is ready!</h1>
    <p>Edit <code>app/index.html</code></p>
</body>
</html>
EOF
            # Note: HTML doesn't use PHP, so no Xdebug config needed
            ;;
            
        php)
            cat > "$path/app/index.php" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>PHP Info</title></head>
<body>
    <h1>🎉 PHP is working!</h1>
    <p>Version: <?php echo phpversion(); ?></p>
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
    print_success "Project created successfully!"
    echo ""
    echo -e "${CYAN}URL:${NC}       http://$domain"
    echo -e "${CYAN}HTTPS:${NC}     https://$domain"
    echo -e "${CYAN}Path:${NC}      $path"
    echo ""
    echo "Quick commands:"
    echo "  ./phpharbor start $( basename $path)"
    echo "  ./phpharbor logs $( basename $path)"
    echo "  ./phpharbor shell $( basename $path)"
    
    if [[ "$type" == "laravel" ]] && [[ "$installed" == true ]] && [[ "$inc_db" == true ]]; then
        echo ""
        print_info "Run migrations: ./phpharbor artisan $(basename $path) migrate"
    fi
}
