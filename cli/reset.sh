#!/bin/bash

# Module: Reset
# Commands: reset soft/hard/status

cmd_reset() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor reset <command>"
        echo ""
        echo "Reset PHPHarbor Docker environment with different levels of cleanup."
        echo ""
        echo "Commands:"
        echo "  soft      Soft reset (remove containers, keep volumes/data)"
        echo "  hard      Hard reset (remove containers AND volumes - DATA LOSS!)"
        echo "  status    Show current Docker environment status"
        echo ""
        echo "Examples:"
        echo "  ./phpharbor reset soft     # Quick reset, data preserved"
        echo "  ./phpharbor reset hard     # Complete reset with data deletion"
        echo "  ./phpharbor reset status   # Check current state"
        exit 0
    fi
    
    local subcmd=$1
    shift
    
    case $subcmd in
        soft)
            reset_soft "$@"
            ;;
        hard)
            reset_hard "$@"
            ;;
        status)
            reset_status "$@"
            ;;
        "")
            reset_interactive
            ;;
        *)
            print_error "Unknown sub-command: $subcmd"
            echo ""
            echo "Usage: ./phpharbor reset <command>"
            echo ""
            echo "Commands:"
            echo "  soft      Soft reset (remove containers, keep data)"
            echo "  hard      Hard reset (remove everything - DATA LOSS!)"
            echo "  status    Show current state"
            exit 1
            ;;
    esac
}

reset_status() {
    print_title "PHPHarbor Docker Environment Status"
    
    echo -e "${CYAN}Containers:${NC}"
    local containers=$(docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -E "(nginx-proxy|nginx-acme-companion|mysql-.*-shared|redis-.*-shared|php-.*-shared)" 2>/dev/null || echo "  No PHPHarbor containers found")
    echo "$containers"
    
    echo ""
    echo -e "${CYAN}Volumes:${NC}"
    local volumes=$(docker volume ls | grep -E "(mysql_.*_shared_data|redis_.*_shared_data)" 2>/dev/null || echo "  No shared service volumes found")
    echo "$volumes"
    
    echo ""
}

reset_soft() {
    print_title "Soft Reset - Removing Containers Only"
    
    print_info "This will:"
    echo "  • Stop and remove all PHPHarbor containers"
    echo "  • Keep all volumes (database data preserved)"
    echo "  • Keep network configuration"
    echo ""
    
    if [ "$1" != "--yes" ]; then
        read -p "Continue with soft reset? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            print_error "Reset cancelled"
            exit 0
        fi
    fi
    
    cd "$SCRIPT_DIR/proxy"
    
    print_info "Stopping all PHPHarbor services..."
    docker compose --profile shared-services down 2>/dev/null || true
    
    print_info "Removing any remaining PHPHarbor containers..."
    docker ps -a --format "{{.Names}}" | grep -E "^(nginx-proxy|nginx-acme-companion|mysql-.*-shared|redis-.*-shared|php-.*-shared)$" | xargs -r docker rm -f 2>/dev/null || true
    
    print_success "Soft reset completed!"
    echo ""
    print_info "To restart the environment:"
    echo "  ./phpharbor setup proxy"
    echo ""
    print_info "To restart shared services:"
    echo "  ./phpharbor shared start"
}

reset_hard() {
    print_title "Hard Reset - Removing Containers AND Volumes"
    
    print_warning "⚠️  DANGER ZONE ⚠️"
    echo ""
    print_error "This will PERMANENTLY DELETE:"
    echo "  • All PHPHarbor containers"
    echo "  • All shared service volumes (MySQL, Redis)"
    echo "  • ALL DATABASE DATA in shared services"
    echo ""
    print_warning "This action CANNOT be undone!"
    echo ""
    
    if [ "$1" != "--yes" ]; then
        read -p "Type 'DELETE EVERYTHING' to confirm hard reset: " confirm
        if [ "$confirm" != "DELETE EVERYTHING" ]; then
            print_error "Reset cancelled (confirmation text did not match)"
            exit 0
        fi
    fi
    
    cd "$SCRIPT_DIR/proxy"
    
    print_info "Stopping all PHPHarbor services..."
    docker compose --profile shared-services down 2>/dev/null || true
    
    print_info "Removing containers..."
    docker ps -a --format "{{.Names}}" | grep -E "^(nginx-proxy|nginx-acme-companion|mysql-.*-shared|redis-.*-shared|php-.*-shared)$" | xargs -r docker rm -f 2>/dev/null || true
    
    print_info "Removing shared service volumes..."
    docker volume rm \
        mysql_5_7_shared_data \
        mysql_8_0_shared_data \
        mysql_8_4_shared_data \
        mariadb_11_4_shared_data \
        mariadb_10_11_shared_data \
        mariadb_10_6_shared_data \
        redis_6_shared_data \
        redis_7_shared_data \
        2>/dev/null || true
    
    print_info "Removing PHPHarbor custom images..."
    docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(phpharbor-proxy-php-|mysql-.*-shared|mariadb-.*-shared|redis-.*-shared)" | xargs -r docker rmi -f 2>/dev/null || true
    
    print_info "Removing project images..."
    docker images --format "{{.Repository}}:{{.Tag}}" | grep -E ".*-app:.*" | xargs -r docker rmi -f 2>/dev/null || true
    
    print_info "Removing unused images (prune)..."
    docker image prune -f 2>/dev/null || true
    
    print_success "Hard reset completed!"
    echo ""
    print_info "Environment has been completely reset."
    print_info "To restart:"
    echo "  ./phpharbor setup init"
}

reset_interactive() {
    print_title "PHPHarbor Docker Environment Reset"
    
    reset_status
    
    echo "Choose reset type:"
    echo ""
    echo "  1) Soft Reset   - Remove containers only (keep data)"
    echo "  2) Hard Reset   - Remove containers AND volumes (DELETE ALL DATA)"
    echo "  3) Show Status  - Display current state"
    echo "  4) Cancel"
    echo ""
    
    read -p "Enter choice (1-4): " choice
    
    case $choice in
        1)
            reset_soft
            ;;
        2)
            reset_hard
            ;;
        3)
            reset_status
            echo ""
            reset_interactive
            ;;
        4)
            print_info "Reset cancelled"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}
