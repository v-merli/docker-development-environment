#!/bin/bash

# Module: Shared Services
# Commands: shared start/stop/status/logs/mysql/php

cmd_shared() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor shared <command>"
        echo ""
        echo "Commands:"
        echo "  start [service]   Start shared services (mysql/redis)"
        echo "  stop              Stop shared services"
        echo "  status            Show services status"
        echo "  logs              Show logs"
        echo "  mysql             Shared MySQL CLI"
        echo "  php <version>     Start shared PHP (7.3-8.5)"
        exit 0
    fi
    
    local subcmd=$1
    shift
    
    case $subcmd in
        start)
            shared_start "$@"
            ;;
        stop)
            shared_stop "$@"
            ;;
        status)
            shared_status "$@"
            ;;
        logs)
            shared_logs "$@"
            ;;
        mysql)
            shared_mysql "$@"
            ;;
        php)
            shared_php "$@"
            ;;
        *)
            print_error "Unknown sub-command: $subcmd"
            echo ""
            echo "Usage: ./phpharbor shared <command>"
            echo ""
            echo "Commands:"
            echo "  start [service]   Start shared services"
            echo "  stop              Stop shared services"
            echo "  status            Show services status"
            echo "  logs              Show logs"
            echo "  mysql             MySQL CLI"
            echo "  php <version>     Start shared PHP"
            exit 1
            ;;
    esac
}

shared_start() {
    cd "$SCRIPT_DIR/proxy"
    
    if [ -z "$1" ]; then
        # Start all shared services
        print_info "Starting shared services (MySQL + Redis)..."
        $DOCKER_COMPOSE --profile shared-services up -d mysql-shared redis-shared
        print_success "Shared services started"
        echo ""
        echo -e "${CYAN}MySQL:${NC} localhost:3306 (root/rootpassword)"
        echo -e "${CYAN}Redis:${NC} localhost:6379"
    else
        # Start specific service
        local service=$1
        print_info "Starting $service..."
        $DOCKER_COMPOSE --profile shared-services up -d $service-shared
        print_success "$service started"
    fi
}

shared_stop() {
    cd "$SCRIPT_DIR/proxy"
    print_info "Stopping shared services..."
    $DOCKER_COMPOSE --profile shared-services stop mysql-shared redis-shared 2>/dev/null || true
    
    # Also stop any shared PHP
    for version in 7.3 7.4 8.1 8.2 8.3 8.5; do
        docker stop php-$version-shared 2>/dev/null || true
    done
    
    print_success "Shared services stopped"
}

shared_status() {
    print_title "Shared Services Status"
    echo ""
    
    echo -e "${CYAN}Database and Cache:${NC}"
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "mysql-shared|redis-shared"; then
        echo ""
    else
        echo "  No DB/Cache services running"
    fi
    
    echo ""
    echo -e "${CYAN}Shared PHP-FPM:${NC}"
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep "php-.*-shared"; then
        echo ""
    else
        echo "  No shared PHP-FPM running"
    fi
}

shared_logs() {
    cd "$SCRIPT_DIR/proxy"
    
    # Show logs of all active shared services
    local services=""
    docker ps --format "{{.Names}}" | grep -E "shared" | while read container; do
        echo -e "\n${CYAN}=== $container ===${NC}"
        docker logs --tail=50 $container
    done
}

shared_mysql() {
    if ! docker ps | grep -q mysql-shared; then
        print_error "Shared MySQL not running"
        echo "Start it with: ./phpharbor shared start mysql"
        exit 1
    fi
    
    docker exec -it mysql-shared mysql -uroot -prootpassword
}

shared_php() {
    if [ -z "$1" ]; then
        print_error "Specify PHP version"
        echo "Usage: ./phpharbor shared php <version>"
        echo "Versions: 7.3, 7.4, 8.1, 8.2, 8.3, 8.5"
        exit 1
    fi
    
    local version=$1
    cd "$SCRIPT_DIR/proxy"
    
    print_info "Starting shared PHP $version..."
    $DOCKER_COMPOSE --profile shared-services up -d php-$version-shared
    print_success "Shared PHP $version started"
    echo ""
    echo "Container: php-$version-shared"
    echo "Path: /var/www/projects/<project>/app"
}
