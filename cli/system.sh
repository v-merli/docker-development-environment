#!/bin/bash

# Module: System
# Commands: stats, info, cleanup

cmd_stats() {
    # Check for sub-commands
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor stats [command] [options]"
        echo ""
        echo "Display real-time statistics about PHPHarbor resource usage."
        echo ""
        echo "Commands:"
        echo "  resources         Show CPU/RAM usage of running containers (default)"
        echo "  disk              Show disk usage analysis"
        echo "  disk --detailed   Detailed breakdown per project"
        echo "  disk --compare    Compare shared vs dedicated architecture"
        echo "  disk --cleanup    Interactive cleanup of orphan volumes and images"
        echo ""
        echo "Examples:"
        echo "  ./phpharbor stats              # Show CPU/RAM resources"
        echo "  ./phpharbor stats disk         # Basic disk analysis"
        echo "  ./phpharbor stats disk --compare   # Savings simulation"
        echo "  ./phpharbor stats disk --cleanup   # Clean orphans"
        exit 0
    fi
    
    local subcmd=$1
    shift
    
    case $subcmd in
        disk)
            # Load the stats module for disk analysis
            source "$SCRIPT_DIR/cli/stats.sh"
            stats_disk "$@"
            return
            ;;
        resources|"")
            # Default: show resources (CPU/RAM)
            stats_resources "$@"
            ;;
        *)
            echo "Unknown stats command: $subcmd"
            echo "Run './phpharbor stats --help' for available commands."
            exit 1
            ;;
    esac
}

stats_resources() {
    print_title "Resource Usage Statistics"
    echo ""
    
    # Show general Docker statistics
    echo -e "${CYAN}Active Containers:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Size}}" | head -20
    
    echo ""
    echo -e "${CYAN}Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPU}}\t{{.MemUsage}}" | head -20
    
    echo ""
    echo -e "${CYAN}Images:${NC}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "php-laravel|mysql|redis|nginx-proxy" | head -10
    
    echo ""
    echo -e "${CYAN}Volumes:${NC}"
    docker volume ls | grep -E "mysql-data|redis-data" || echo "  No persistent volumes found"
    
    echo ""
    echo -e "${CYAN}Networks:${NC}"
    docker network ls | grep -E "phpharbor-proxy|backend"
    
    echo ""
    echo -e "${BLUE}💡 Tip: Use './phpharbor stats disk' for disk usage analysis${NC}"
}

cmd_info() {
    print_title "Environment Information"
    echo ""
    
    # Build information
    echo -e "${CYAN}PHPHarbor:${NC}"
    if [ "$BUILD_INFO_LOADED" = "true" ]; then
        echo "  Version: $VERSION ($GIT_HASH)"
        echo "  Build: $BUILD_DATE"
        if [ -n "$REPOSITORY" ]; then
            echo "  Repository: $REPOSITORY/commit/$GIT_COMMIT"
        fi
    else
        local dev_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        echo "  Version: $VERSION ($dev_hash)"
        echo "  Environment: development"
    fi
    echo ""
    
    # Versions
    echo -e "${CYAN}Software Versions:${NC}"
    echo "  Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    echo "  Docker Compose: $(docker compose version --short)"
    
    if command -v mkcert >/dev/null 2>&1; then
        echo "  mkcert: $(mkcert -version 2>&1 | head -1)"
    else
        echo "  mkcert: not installed"
    fi
    
    if command -v dnsmasq >/dev/null 2>&1; then
        echo "  dnsmasq: installed"
    else
        echo "  dnsmasq: not installed"
    fi
    
    echo ""
    
    # Proxy status
    echo -e "${CYAN}Reverse Proxy:${NC}"
    if docker ps | grep -q nginx-proxy; then
        echo "  ✓ nginx-proxy running"
        echo "    HTTP:  http://localhost:$HTTP_PORT"
        echo "    HTTPS: https://localhost:$HTTPS_PORT"
        echo "  ✓ acme-companion for SSL"
    else
        echo "  ✗ Proxy not started"
        echo "    Start it with: ./phpharbor setup proxy"
        echo "    Configured ports: HTTP=$HTTP_PORT, HTTPS=$HTTPS_PORT"
    fi
    
    echo ""
    
    # Shared services
    echo -e "${CYAN}Shared Services:${NC}"
    local shared_count=0
    
    # Check MySQL versions
    local mysql_containers=$(docker ps --format "{{.Names}}" | grep "mysql-.*-shared" 2>/dev/null || true)
    if [ -n "$mysql_containers" ]; then
        while IFS= read -r container; do
            if [[ "$container" =~ mysql-([0-9.]+)-shared ]]; then
                local ver="${BASH_REMATCH[1]}"
                local port=$(docker port "$container" 3306 2>/dev/null | cut -d: -f2 || echo "N/A")
                echo "  ✓ Shared MySQL $ver (port $port)"
                shared_count=$((shared_count + 1))
            fi
        done <<< "$mysql_containers"
    fi
    
    # Check Redis versions
    local redis_containers=$(docker ps --format "{{.Names}}" | grep "redis-.*-shared" 2>/dev/null || true)
    if [ -n "$redis_containers" ]; then
        while IFS= read -r container; do
            if [[ "$container" =~ redis-([0-9.]+)-shared ]]; then
                local ver="${BASH_REMATCH[1]}"
                local port=$(docker port "$container" 6379 2>/dev/null | cut -d: -f2 || echo "N/A")
                echo "  ✓ Shared Redis $ver (port $port)"
                shared_count=$((shared_count + 1))
            fi
        done <<< "$redis_containers"
    fi
    
    local php_shared=$(docker ps --format "{{.Names}}" | grep "php-.*-shared" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$php_shared" -gt 0 ]; then
        echo "  ✓ Shared PHP-FPM: $php_shared active versions"
        docker ps --format "    - {{.Names}}" | grep "php-.*-shared" 2>/dev/null || true
        shared_count=$((shared_count + php_shared))
    fi
    
    if [ "$shared_count" -eq 0 ]; then
        echo "  ✗ No shared services active"
        echo "    Start them with: ./phpharbor shared start"
        echo "    Available: MySQL 5.7, 8.0, 8.4 | Redis 6, 7"
    fi
    
    echo ""
    
    # Projects
    echo -e "${CYAN}Projects:${NC}"
    local total=$(ls -d "$PROJECTS_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
    local running=$(docker ps --format "{{.Names}}" | grep -E "^(php|nginx|mysql|redis)-" | cut -d'-' -f2 | sort -u | wc -l | tr -d ' ')
    
    echo "  Total: $total"
    echo "  Active: $running"
    
    if [ "$running" -gt 0 ]; then
        echo ""
        echo "  Running projects:"
        docker ps --format "{{.Names}}" | grep -E "^nginx-" | cut -d'-' -f2 | while read proj; do
            echo "    - $proj"
        done
    fi
    
    echo ""
    
    # Architecture
    echo -e "${CYAN}Architecture:${NC}"
    echo "  Type: Hybrid (dedicated + shared)"
    echo "  Available configurations:"
    echo "    - fully-shared: maximum savings (only nginx per project)"
    echo "    - shared-db: Shared MySQL/Redis, dedicated PHP"
    echo "    - shared-php: Shared PHP, dedicated DB"
    echo "    - dedicated: all dedicated services"
    
    echo ""
    
    # Directories
    echo -e "${CYAN}Paths:${NC}"
    echo "  Projects: $PROJECTS_DIR"
    
    # Show if custom config
    if [ -f "$CONFIG_FILE" ]; then
        local default_dir="$SCRIPT_DIR/projects"
        if [ "$PROJECTS_DIR" != "$default_dir" ]; then
            echo "           ${GREEN}(custom configuration)${NC}"
            echo "           To change it: phpharbor setup config"
        fi
    else
        echo "           ${YELLOW}(default - configure with: phpharbor setup config)${NC}"
    fi
    
    echo "  Proxy: $SCRIPT_DIR/proxy"
    echo "  Shared: $SCRIPT_DIR/shared"
    echo "  CLI: $SCRIPT_DIR/cli"
    
    echo ""
    
    # Useful links
    echo -e "${CYAN}Documentation:${NC}"
    echo "  README: $SCRIPT_DIR/README.md"
    echo "  Docs: $SCRIPT_DIR/docs/"
    echo "  Quick Start: $SCRIPT_DIR/docs/quick-start.md"
    echo "  CLI Reference: $SCRIPT_DIR/docs/cli-reference.md"
}

cmd_cleanup() {
    print_title "Cleanup Orphaned Resources"
    echo ""
    
    print_info "Searching for orphaned SSL certificates and volumes..."
    echo ""
    
    local acme_base="$SCRIPT_DIR/proxy/nginx/acme"
    local cleaned=0
    
    # Get list of existing projects
    local existing_projects=()
    if [ -d "$PROJECTS_DIR" ]; then
        for project_dir in "$PROJECTS_DIR"/*/; do
            if [ -d "$project_dir" ]; then
                local proj_name=$(basename "$project_dir")
                existing_projects+=("${proj_name}.test")
            fi
        done
    fi
    
    # Function to check and clean certificate directories
    check_and_clean_certs() {
        local cert_dir=$1
        local cert_type=$2
        
        if [ ! -d "$cert_dir" ]; then
            return
        fi
        
        for domain_dir in "$cert_dir"/*.test/; do
            if [ ! -d "$domain_dir" ]; then
                continue
            fi
            
            local domain=$(basename "$domain_dir")
            local found=false
            
            # Check if project exists
            for existing in "${existing_projects[@]}"; do
                if [ "$domain" = "$existing" ]; then
                    found=true
                    break
                fi
            done
            
            if [ "$found" = false ]; then
                echo -e "  ${RED}✗${NC} $domain ${YELLOW}($cert_type)${NC} - project not found"
                rm -rf "$domain_dir"
                ((cleaned++))
            else
                echo -e "  ${GREEN}✓${NC} $domain ${CYAN}($cert_type)${NC}"
            fi
        done
    }
    
    # Clean staging certificates
    check_and_clean_certs "$acme_base/staging" "staging"
    
    # Clean dev@localhost certificates
    check_and_clean_certs "$acme_base/dev@localhost" "dev"
    
    echo ""
    
    # Clean mkcert certificates
    print_info "Checking mkcert certificates..."
    echo ""
    
    local mkcert_dir="$SCRIPT_DIR/proxy/nginx/certs"
    local mkcert_cleaned=0
    
    if [ -d "$mkcert_dir" ]; then
        # Clean certificate files - process only .crt files to avoid duplicates
        for cert_file in "$mkcert_dir"/*.test.crt; do
            if [ ! -f "$cert_file" ]; then
                continue
            fi
            
            local filename=$(basename "$cert_file")
            # Extract domain: remove .crt extension
            local domain="${filename%.crt}"
            
            local found=false
            
            # Check if project exists
            for existing in "${existing_projects[@]}"; do
                if [ "$domain" = "$existing" ]; then
                    found=true
                    break
                fi
            done
            
            if [ "$found" = false ]; then
                echo -e "  ${RED}✗${NC} $domain ${YELLOW}(mkcert)${NC} - project not found"
                # Remove all certificate files for this domain
                rm -f "$mkcert_dir/$domain.crt"
                rm -f "$mkcert_dir/$domain.key"
                rm -f "$mkcert_dir/$domain.chain.pem"
                ((mkcert_cleaned+=3))
            else
                echo -e "  ${GREEN}✓${NC} $domain ${CYAN}(mkcert)${NC}"
            fi
        done
        
        # Clean _test_* ACME directories (check if project exists)
        for test_dir in "$mkcert_dir"/_test_*.test/; do
            if [ -d "$test_dir" ]; then
                local dir_name=$(basename "$test_dir")
                # Remove _test_ prefix to get actual domain
                local domain="${dir_name#_test_}"
                local found=false
                
                # Check if project exists
                for existing in "${existing_projects[@]}"; do
                    if [ "$domain" = "$existing" ]; then
                        found=true
                        break
                    fi
                done
                
                if [ "$found" = false ]; then
                    echo -e "  ${RED}✗${NC} $domain ${YELLOW}(acme dir)${NC} - project not found"
                    rm -rf "$test_dir"
                    ((mkcert_cleaned++))
                else
                    echo -e "  ${GREEN}✓${NC} $domain ${CYAN}(acme dir)${NC}"
                fi
            fi
        done
    fi
    
    echo ""
    
    local total_cleaned=$((cleaned + mkcert_cleaned))
    
    if [ $total_cleaned -gt 0 ]; then
        print_success "Cleaned total: $total_cleaned orphaned SSL resources"
        echo "  - ACME certificates: $cleaned"
        echo "  - mkcert certificates: $mkcert_cleaned"
    else
        print_success "No orphaned SSL certificates found"
    fi
    
    echo ""
    print_info "Checking for orphaned local volumes..."
    echo ""
    
    local volumes_dir="$SCRIPT_DIR/volumes"
    local volumes_cleaned=0
    
    # Get list of project names (without .test suffix)
    local existing_project_names=()
    if [ -d "$PROJECTS_DIR" ]; then
        for project_dir in "$PROJECTS_DIR"/*/; do
            if [ -d "$project_dir" ]; then
                local proj_name=$(basename "$project_dir")
                existing_project_names+=("$proj_name")
            fi
        done
    fi
    
    # Function to check and clean volume directories
    check_and_clean_volumes() {
        local volume_type=$1
        local volume_base="$volumes_dir/$volume_type"
        
        if [ ! -d "$volume_base" ]; then
            return
        fi
        
        for volume_dir in "$volume_base"/*/; do
            if [ ! -d "$volume_dir" ]; then
                continue
            fi
            
            local volume_name=$(basename "$volume_dir")
            
            # Skip .gitkeep and other hidden/special files
            if [[ "$volume_name" == .* ]] || [[ "$volume_name" == *"-shared" ]]; then
                continue
            fi
            
            local found=false
            
            # Check if project exists
            for existing in "${existing_project_names[@]}"; do
                if [ "$volume_name" = "$existing" ]; then
                    found=true
                    break
                fi
            done
            
            if [ "$found" = false ]; then
                echo -e "  ${RED}✗${NC} $volume_type/$volume_name - project not found"
                rm -rf "$volume_dir"
                ((volumes_cleaned++))
            else
                echo -e "  ${GREEN}✓${NC} $volume_type/$volume_name"
            fi
        done
    }
    
    # Clean volumes for each type
    check_and_clean_volumes "mysql"
    check_and_clean_volumes "mariadb"
    check_and_clean_volumes "redis"
    check_and_clean_volumes "other"
    
    if [ $volumes_cleaned -gt 0 ]; then
        echo ""
        print_success "Removed $volumes_cleaned orphaned volume director$([ $volumes_cleaned -eq 1 ] && echo 'y' || echo 'ies')"
    else
        echo ""
        echo "  No orphaned volumes found"
    fi
    
    echo ""
    print_info "Checking for unused Docker resources..."
    echo ""
    
    # Show Docker cleanup summary
    echo "Docker system prune will remove:"
    echo "  - Stopped containers"
    echo "  - Unused networks"
    echo "  - Dangling images"
    echo "  - Build cache"
    echo ""
    
    read -p "Run docker system prune? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker system prune -f
        echo ""
        print_success "Docker cleanup completed"
    else
        echo "Docker cleanup skipped"
    fi
    
    echo ""
    print_info "Cleanup finished"
    echo ""
    echo -e "${CYAN}💡 Additional cleanup commands:${NC}"
    echo "  • ./phpharbor stats disk --cleanup    # Remove orphan volumes and project images"
    echo "  • ./phpharbor reset hard              # Complete reset (removes all data)"
    echo ""
}
