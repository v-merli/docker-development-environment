#!/bin/bash

# Module: Shared Services
# Commands: shared start/stop/status/logs/mysql/php

cmd_shared() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor shared <command>"
        echo ""
        echo "Commands:"
        echo "  start [service] [version]   Start shared services"
        echo "                              - no args: start all"
        echo "                              - mysql: start all MySQL versions"
        echo "                              - mysql 8.0: start MySQL 8.0"
        echo "                              - redis 7: start Redis 7"
        echo "  stop                        Stop shared services"
        echo "  status                      Show services status"
        echo "  logs                        Show logs"
        echo "  mysql [version]             Shared MySQL CLI"
        echo "  php <version>               Start shared PHP (7.3-8.5)"
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
            echo "  start [service] [version]   Start shared services"
            echo "  stop                        Stop shared services"
            echo "  status                      Show services status"
            echo "  logs                        Show logs"
            echo "  mysql [version]             MySQL CLI"
            echo "  php <version>               Start shared PHP"
            exit 1
            ;;
    esac
}

shared_start() {
    cd "$SCRIPT_DIR/proxy"
    
    if [ -z "$1" ]; then
        # Start all shared services (all versions)
        print_info "Starting all shared services (MySQL 5.7/8.0/8.4 + Redis 6/7)..."
        $DOCKER_COMPOSE --profile shared-services up -d \
            mysql-5.7-shared mysql-8.0-shared mysql-8.4-shared \
            redis-6-shared redis-7-shared
        print_success "Shared services started"
        echo ""
        echo -e "${CYAN}MySQL 8.0:${NC} localhost:3306 (root/rootpassword)"
        echo -e "${CYAN}MySQL 5.7:${NC} localhost:3307 (root/rootpassword)"
        echo -e "${CYAN}MySQL 8.4:${NC} localhost:3308 (root/rootpassword)"
        echo -e "${CYAN}Redis 7:${NC}   localhost:6379"
        echo -e "${CYAN}Redis 6:${NC}   localhost:6380"
    elif [ "$1" = "mysql" ]; then
        # Start specific MySQL version
        if [ -n "$2" ]; then
            print_info "Starting MySQL $2..."
            $DOCKER_COMPOSE --profile shared-services up -d mysql-$2-shared
            print_success "MySQL $2 started"
        else
            print_info "Starting all MySQL versions..."
            $DOCKER_COMPOSE --profile shared-services up -d mysql-5.7-shared mysql-8.0-shared mysql-8.4-shared
            print_success "All MySQL versions started"
        fi
    elif [ "$1" = "redis" ]; then
        # Start specific Redis version
        if [ -n "$2" ]; then
            print_info "Starting Redis $2..."
            $DOCKER_COMPOSE --profile shared-services up -d redis-$2-shared
            print_success "Redis $2 started"
        else
            print_info "Starting all Redis versions..."
            $DOCKER_COMPOSE --profile shared-services up -d redis-6-shared redis-7-shared
            print_success "All Redis versions started"
        fi
    else
        print_error "Unknown service: $1"
        echo "Usage: ./phpharbor shared start [mysql|redis] [version]"
        echo "Examples:"
        echo "  ./phpharbor shared start              # Start all services"
        echo "  ./phpharbor shared start mysql        # Start all MySQL versions"
        echo "  ./phpharbor shared start mysql 8.0    # Start MySQL 8.0 only"
        echo "  ./phpharbor shared start redis 7      # Start Redis 7 only"
        exit 1
    fi
}

shared_stop() {
    cd "$SCRIPT_DIR/proxy"
    print_info "Stopping shared services..."
    $DOCKER_COMPOSE --profile shared-services stop \
        mysql-5.7-shared mysql-8.0-shared mysql-8.4-shared \
        redis-6-shared redis-7-shared 2>/dev/null || true
    
    # Also stop any shared PHP
    for version in 7.3 7.4 8.1 8.2 8.3 8.4 8.5; do
        docker stop php-$version-shared 2>/dev/null || true
    done
    
    print_success "Shared services stopped"
}

shared_status() {
    print_title "Shared Services Status"
    echo ""
    
    echo -e "${CYAN}Database and Cache:${NC}"
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "mysql-.*-shared|redis-.*-shared"; then
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
    # Check which MySQL versions are running
    local running_versions=()
    docker ps --format "{{.Names}}" | grep "mysql-.*-shared" | while read container; do
        if [[ $container =~ mysql-([0-9.]+)-shared ]]; then
            running_versions+=("${BASH_REMATCH[1]}")
        fi
    done
    
    # Count running versions
    local count=$(docker ps --format "{{.Names}}" | grep -c "mysql-.*-shared" || echo "0")
    
    if [ "$count" -eq 0 ]; then
        print_error "No shared MySQL running"
        echo "Start with: ./phpharbor shared start mysql [version]"
        exit 1
    elif [ "$count" -eq 1 ] || [ -n "$1" ]; then
        # Only one version running or version specified
        local version="$1"
        if [ -z "$version" ]; then
            # Get the only running version
            version=$(docker ps --format "{{.Names}}" | grep "mysql-.*-shared" | sed 's/mysql-\(.*\)-shared/\1/')
        fi
        local container="mysql-$version-shared"
        if ! docker ps | grep -q "$container"; then
            print_error "MySQL $version not running"
            exit 1
        fi
        docker exec -it "$container" mysql -uroot -prootpassword
    else
        # Multiple versions, ask user
        print_info "Multiple MySQL versions running. Choose one:"
        echo ""
        PS3="$(echo -e "${CYAN}Choose version (1-$count):${NC} ")"
        local versions=()
        while IFS= read -r container; do
            if [[ $container =~ mysql-([0-9.]+)-shared ]]; then
                versions+=("${BASH_REMATCH[1]}")
            fi
        done < <(docker ps --format "{{.Names}}" | grep "mysql-.*-shared")
        
        select ver in "${versions[@]}"; do
            if [ -n "$ver" ]; then
                docker exec -it "mysql-$ver-shared" mysql -uroot -prootpassword
                break
            fi
        done
    fi
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
