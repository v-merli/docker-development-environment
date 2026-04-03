#!/bin/bash

# Module: Development Tools
# Commands: shell, artisan, composer, npm, mysql

show_dev_help() {
    echo "Usage: ./phpharbor <command> <project> [args]"
    echo ""
    echo "Commands:"
    echo "  shell <project>          Open bash shell (PHP + Node.js)"
    echo "  artisan <project> <cmd>  Run artisan command"
    echo "  composer <project> <cmd> Run composer command"
    echo "  npm <project> <cmd>      Run npm command"
    echo "  mysql <project>          MySQL CLI"
    echo "  queue <project> <action> Manage queue worker (restart|logs|status)"
}

cmd_shell() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor shell <project>"
        echo ""
        echo "Opens an interactive bash shell in the project's app container."
        echo "Has access to: PHP, Composer, Artisan, Node.js, npm"
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
    
    # Always use app container for consistent UX
    # Use -it for interactive terminal with proper TTY allocation
    $DOCKER_COMPOSE exec -it app bash
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
    
    # Always use app container for consistent UX
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
    
    # Always use app container for consistent UX
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
    
    # npm always runs in app container (either full PHP+Node or node-only)
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
        
        # Check if it's a shared MySQL (format: mysql-X.X-shared)
        if [[ "$db_host" =~ ^mysql-.*-shared$ ]]; then
            print_info "Connecting to shared MySQL $db_host (database: $db_name)..."
            docker exec -it "$db_host" mysql -uroot -p$db_pass $db_name
            return
        fi
    fi
    
    # Dedicated MySQL
    $DOCKER_COMPOSE exec mysql mysql -uroot -proot
}

cmd_queue() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor queue <project> <action>"
        echo ""
        echo "Manage Laravel queue worker."
        echo ""
        echo "Actions:"
        echo "  restart    Restart the queue worker (loads new code)"
        echo "  logs       Show queue worker logs"
        echo "  status     Show queue worker status"
        echo ""
        echo "Examples:"
        echo "  ./phpharbor queue myapp restart"
        echo "  ./phpharbor queue myapp logs"
        exit 0
    fi
    
    if [ -z "$1" ]; then
        print_error "Specify the project name"
        echo "Usage: ./phpharbor queue <project> <action>"
        exit 1
    fi
    
    local project=$1
    local action=${2:-restart}
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    cd "$project_path"
    
    case $action in
        restart)
            print_info "Restarting queue worker for $project..."
            if docker ps --format '{{.Names}}' | grep -q "^${project}-queue$"; then
                docker restart "${project}-queue"
                print_success "Queue worker restarted"
                echo ""
                echo "💡 Tip: Monitor with './phpharbor queue $project logs'"
            else
                print_warning "Queue worker not running"
                echo "Start it with: ./phpharbor start $project"
            fi
            ;;
        logs)
            if docker ps --format '{{.Names}}' | grep -q "^${project}-queue$"; then
                echo "Showing queue worker logs (Ctrl+C to exit)..."
                echo ""
                docker logs -f "${project}-queue"
            else
                print_error "Queue worker not running"
                exit 1
            fi
            ;;
        status)
            if docker ps --format '{{.Names}}' | grep -q "^${project}-queue$"; then
                print_success "Queue worker is running"
                echo ""
                docker ps --filter "name=${project}-queue" --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"
            else
                print_warning "Queue worker is not running"
                exit 1
            fi
            ;;
        *)
            print_error "Unknown action: $action"
            echo "Available actions: restart, logs, status"
            echo "Run './phpharbor queue --help' for more info"
            exit 1
            ;;
    esac
}
