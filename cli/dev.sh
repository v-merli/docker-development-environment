#!/bin/bash

# Module: Development Tools
# Commands: shell, artisan, composer, npm, mysql

show_dev_help() {
    echo "Usage: ./phpharbor <command> <project> [args]"
    echo ""
    echo "Commands:"
    echo "  shell <project>          Open bash shell"
    echo "  artisan <project> <cmd>  Run artisan command"
    echo "  composer <project> <cmd> Run composer command"
    echo "  npm <project> <cmd>      Run npm command"
    echo "  mysql <project>          MySQL CLI"
}

cmd_shell() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor shell <project>"
        echo ""
        echo "Opens an interactive bash shell in the project's PHP container."
        exit 0
    fi
    
    if [ -z "$1" ]; then
        print_error "Specify the project name"
        echo "Usage: ./phpharbor shell <project>"
        exit 1
    fi
    
    local project=$1
    local project_path="$PROJECTS_DIR/$project"
    
    if [  ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    cd "$project_path"
    
    # Check if project uses shared PHP
    # Check if "app" service does NOT exist in docker-compose.yml
    if [ -f "docker-compose.yml" ] && ! grep -q "^  app:" "docker-compose.yml" 2>/dev/null; then
        # Fully-shared project: use shared PHP
        if [ -f ".env" ]; then
            php_version=$(grep "^PHP_VERSION=" ".env" 2>/dev/null | cut -d'=' -f2)
            if [ -n "$php_version" ]; then
                print_info "Accessing shared PHP $php_version..."
                docker exec -it php-$php_version-shared bash -c "cd /var/www/projects/$project/app && bash"
                return
            fi
        fi
    fi
    
    # Project with dedicated PHP
    $DOCKER_COMPOSE exec app bash
}

cmd_artisan() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor artisan <project> <command>"
        echo ""
        echo "Runs a Laravel artisan command in the project container."
        echo ""
        echo "Examples:"
        echo "  ./phpharbor artisan myapp migrate"
        echo "  ./phpharbor artisan myapp make:controller UserController"
        exit 0
    fi
    
    if [ -z "$1" ]; then
        print_error "Specify the project name"
        echo "Usage: ./phpharbor artisan <project> <command>"
        exit 1
    fi
    
    local project=$1
    shift
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    cd "$project_path"
    
    # Check if project uses shared PHP
    # Check if "app" service does NOT exist in docker-compose.yml
    if [ -f "docker-compose.yml" ] && ! grep -q "^  app:" "docker-compose.yml" 2>/dev/null; then
        if [ -f ".env" ]; then
            php_version=$(grep "^PHP_VERSION=" ".env" 2>/dev/null | cut -d'=' -f2)
            if [ -n "$php_version" ]; then
                print_info "Using shared PHP $php_version..."
                docker exec php-$php_version-shared php /var/www/projects/$project/app/artisan "$@"
                return
            fi
        fi
    fi
    
    # Project with dedicated PHP
    $DOCKER_COMPOSE exec app php artisan "$@"
}

cmd_composer() {
    if [ -z "$1" ]; then
        print_error "Specify the project name"
        echo "Usage: ./phpharbor composer <project> <command>"
        exit 1
    fi
    
    local project=$1
    shift
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    cd "$project_path"
    
    # Check if project uses shared PHP
    # Check if "app" service does NOT exist in docker-compose.yml
    if [ -f "docker-compose.yml" ] && ! grep -q "^  app:" "docker-compose.yml" 2>/dev/null; then
        # Fully-shared project: use shared PHP
        if [ -f ".env" ]; then
            php_version=$(grep "^PHP_VERSION=" ".env" 2>/dev/null | cut -d'=' -f2)
            if [ -n "$php_version" ]; then
                print_info "Using shared PHP $php_version..."
                docker exec php-$php_version-shared bash -c "cd /var/www/projects/$project/app && composer $*"
                return
            fi
        fi
    fi
    
    # Project with dedicated PHP
    $DOCKER_COMPOSE exec app composer "$@"
}

cmd_npm() {
    if [ -z "$1" ]; then
        print_error "Specify the project name"
        echo "Usage: ./phpharbor npm <project> <command>"
        exit 1
    fi
    
    local project=$1
    shift
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    cd "$project_path"
    
    # Check if project uses shared PHP
    # Check if "app" service does NOT exist in docker-compose.yml
    if [ -f "docker-compose.yml" ] && ! grep -q "^  app:" "docker-compose.yml" 2>/dev/null; then
        if [ -f ".env" ]; then
            php_version=$(grep "^PHP_VERSION=" ".env" 2>/dev/null | cut -d'=' -f2)
            if [ -n "$php_version" ]; then
                print_info "Using shared PHP $php_version..."
                docker exec php-$php_version-shared bash -c "cd /var/www/projects/$project/app && npm $*"
                return
            fi
        fi
    fi
    
    # Project with dedicated PHP
    $DOCKER_COMPOSE exec app npm "$@"
}

cmd_mysql() {
    if [ -z "$1" ]; then
        print_error "Specify the project name"
        echo "Usage: ./phpharbor mysql <project>"
        exit 1
    fi
    
    local project=$1
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    cd "$project_path"
    
    # Check if using shared MySQL
    if [ -f ".env" ]; then
        db_host=$(grep "^DB_HOST=" ".env" 2>/dev/null | cut -d'=' -f2)
        db_name=$(grep "^MYSQL_DATABASE=" ".env" 2>/dev/null | cut -d'=' -f2)
        db_pass=$(grep "^MYSQL_ROOT_PASSWORD=" ".env" 2>/dev/null | cut -d'=' -f2)
        
        if [ "$db_host" = "mysql-shared" ]; then
            print_info "Connecting to shared MySQL (database: $db_name)..."
            docker exec -it mysql-shared mysql -uroot -p$db_pass $db_name
            return
        fi
    fi
    
    # Dedicated MySQL
    $DOCKER_COMPOSE exec mysql mysql -uroot -proot
}
