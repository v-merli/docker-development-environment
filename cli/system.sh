#!/bin/bash

# Module: System
# Commands: stats, info

cmd_stats() {
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
    docker network ls | grep -E "proxy|backend"
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
    
    if docker ps | grep -q mysql-shared; then
        echo "  ✓ Shared MySQL (port $MYSQL_SHARED_PORT)"
        ((shared_count++))
    fi
    
    if docker ps | grep -q redis-shared; then
        echo "  ✓ Shared Redis (port $REDIS_SHARED_PORT)"
        ((shared_count++))
    fi
    
    local php_shared=$(docker ps --format "{{.Names}}" | grep "php-.*-shared" | wc -l | tr -d ' ')
    if [ "$php_shared" -gt 0 ]; then
        echo "  ✓ Shared PHP-FPM: $php_shared active versions"
        docker ps --format "    - {{.Names}}" | grep "php-.*-shared"
        shared_count=$((shared_count + php_shared))
    fi
    
    if [ "$shared_count" -eq 0 ]; then
        echo "  ✗ No shared services active"
        echo "    Start them with: ./phpharbor shared start"
        echo "    Configured ports: MySQL=$MYSQL_SHARED_PORT, Redis=$REDIS_SHARED_PORT"
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
