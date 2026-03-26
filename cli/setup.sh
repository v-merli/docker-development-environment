#!/bin/bash

# Module: Setup
# Commands: setup dns/proxy/init

cmd_setup() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor setup <command>"
        echo ""
        echo "Commands:"
        echo "  config  Configure projects directory"
        echo "  ports   Configure service ports (HTTP, HTTPS, MySQL, Redis)"
        echo "  dns     Install and configure dnsmasq for *.test"
        echo "  proxy   Start nginx reverse proxy"
        echo "  init    Complete interactive setup"
        exit 0
    fi
    
    local subcmd=$1
    shift
    
    case $subcmd in
        config)
            setup_config "$@"
            ;;
        ports)
            setup_ports "$@"
            ;;
        dns)
            setup_dns "$@"
            ;;
        proxy)
            setup_proxy "$@"
            ;;
        init)
            setup_init "$@"
            ;;
        *)
            print_error "Unknown sub-command: $subcmd"
            echo ""
            echo "Usage: ./phpharbor setup <command>"
            echo ""
            echo "Commands:"
            echo "  config  Configure projects directory"
            echo "  ports   Configure service ports"
            echo "  dns     Install and configure dnsmasq for *.test"
            echo "  proxy   Start nginx reverse proxy"
            echo "  init    Initialize environment (dns + proxy)"
            exit 1
            ;;
    esac
}

setup_config() {
    print_title "Projects Directory Configuration"
    echo ""
    
    local default_dir="$SCRIPT_DIR/projects"
    local current_dir="${PROJECTS_DIR:-$default_dir}"
    
    echo "Current directory: $current_dir"
    echo ""
    echo "Where do you want to save your Docker projects?"
    echo ""
    echo "1) $default_dir (default)"
    echo "2) $HOME/Development/docker-projects"
    echo "3) Custom path"
    echo "4) Keep current ($current_dir)"
    echo ""
    
    read -p "Choice [4]: " choice
    choice=${choice:-4}
    
    case $choice in
        1)
            PROJECTS_DIR="$default_dir"
            ;;
        2)
            PROJECTS_DIR="$HOME/Development/docker-projects"
            ;;
        3)
            read -p "Enter the complete path: " custom_path
            # Expand ~ and variables
            PROJECTS_DIR=$(eval echo "$custom_path")
            ;;
        4)
            print_info "Keeping current configuration"
            return
            ;;
        *)
            print_warning "Invalid choice, keeping current configuration"
            return
            ;;
    esac
    
    # Check if there are projects in current directory
    if [ -d "$current_dir" ] && [ "$(ls -A "$current_dir" 2>/dev/null)" ]; then
        echo ""
        print_warning "WARNING: Found projects in $current_dir"
        echo ""
        read -p "Do you want to move them to the new directory? (y/n): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Create new directory if it doesn't exist
            mkdir -p "$PROJECTS_DIR"
            
            # Move projects (excluding README.md)
            print_info "Moving projects..."
            for project in "$current_dir"/*; do
                if [ -d "$project" ] && [ "$(basename "$project")" != "README.md" ]; then
                    project_name=$(basename "$project")
                    print_info "Moving $project_name..."
                    mv "$project" "$PROJECTS_DIR/"
                fi
            done
            print_success "Projects moved!"
        fi
    fi
    
    # Create directory if it doesn't exist
    if [ ! -d "$PROJECTS_DIR" ]; then
        print_info "Creating directory: $PROJECTS_DIR"
        mkdir -p "$PROJECTS_DIR"
    fi
    
    # Save configuration
    save_config
    
    print_success "Configuration updated!"
    echo ""
    echo "New projects directory: $PROJECTS_DIR"
    echo ""
    print_info "Reload the terminal or run: source ~/.zshrc (or ~/.bashrc)"
}

setup_ports() {
    print_title "Service Ports Configuration"
    echo ""
    
    echo "Current configuration:"
    echo "  HTTP:  $HTTP_PORT"
    echo "  HTTPS: $HTTPS_PORT"
    echo "  MySQL: $MYSQL_SHARED_PORT"
    echo "  Redis: $REDIS_SHARED_PORT"
    echo ""
    
    # Check if services are running
    local proxy_running=false
    if docker ps | grep -q nginx-proxy; then
        proxy_running=true
        print_warning "WARNING: Proxy is running!"
        echo "Port changes will require a proxy restart."
        echo ""
    fi
    
    # Menu
    echo "What do you want to configure?"
    echo ""
    echo "1) Proxy Ports (HTTP/HTTPS)"
    echo "2) Shared Services Ports (MySQL/Redis)"
    echo "3) All ports"
    echo "4) Restore defaults (8080, 8443, 3306, 6379)"
    echo "5) Cancel"
    echo ""
    
    read -p "Choice [5]: " choice
    choice=${choice:-5}
    
    case $choice in
        1)
            configure_proxy_ports
            ;;
        2)
            configure_shared_ports
            ;;
        3)
            configure_proxy_ports
            configure_shared_ports
            ;;
        4)
            HTTP_PORT=8080
            HTTPS_PORT=8443
            MYSQL_SHARED_PORT=3306
            REDIS_SHARED_PORT=6379
            print_success "Ports restored to default values"
            ;;
        5)
            print_info "Operation canceled"
            return
            ;;
        *)
            print_error "Invalid choice"
            return
            ;;
    esac
    
    # Save configuration
    save_config
    
    print_success "Port configuration updated!"
    echo ""
    echo "New ports:"
    echo "  HTTP:  $HTTP_PORT"
    echo "  HTTPS: $HTTPS_PORT"
    echo "  MySQL: $MYSQL_SHARED_PORT"
    echo "  Redis: $REDIS_SHARED_PORT"
    echo ""
    
    # Warn if restart needed
    if [ "$proxy_running" = true ]; then
        print_warning "To apply changes, restart the proxy:"
        echo "  phpharbor setup proxy"
        echo ""
        read -p "Do you want to restart the proxy now? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$SCRIPT_DIR/proxy"
            $DOCKER_COMPOSE down
            $DOCKER_COMPOSE up -d
            print_success "Proxy restarted with new ports!"
        fi
    fi
}

# Helper function to configure proxy ports
configure_proxy_ports() {
    echo ""
    echo "=== Proxy Ports Configuration ==="
    echo ""
    
    # HTTP Port
    while true; do
        read -p "HTTP port [$HTTP_PORT]: " new_http
        new_http=${new_http:-$HTTP_PORT}
        
        if validate_port "$new_http"; then
            HTTP_PORT=$new_http
            break
        else
            print_error "Invalid port (1-65535)"
        fi
    done
    
    # HTTPS Port
    while true; do
        read -p "HTTPS port [$HTTPS_PORT]: " new_https
        new_https=${new_https:-$HTTPS_PORT}
        
        if validate_port "$new_https"; then
            if [ "$new_https" -eq "$HTTP_PORT" ]; then
                print_error "HTTPS port cannot be the same as HTTP port"
            else
                HTTPS_PORT=$new_https
                break
            fi
        else
            print_error "Invalid port (1-65535)"
        fi
    done
    
    print_success "Proxy ports configured"
}

# Helper function to configure shared services ports
configure_shared_ports() {
    echo ""
    echo "=== Shared Services Ports Configuration ==="
    echo ""
    
    # MySQL Port
    while true; do
        read -p "MySQL port [$MYSQL_SHARED_PORT]: " new_mysql
        new_mysql=${new_mysql:-$MYSQL_SHARED_PORT}
        
        if validate_port "$new_mysql"; then
            MYSQL_SHARED_PORT=$new_mysql
            break
        else
            print_error "Invalid port (1-65535)"
        fi
    done
    
    # Redis Port
    while true; do
        read -p "Redis port [$REDIS_SHARED_PORT]: " new_redis
        new_redis=${new_redis:-$REDIS_SHARED_PORT}
        
        if validate_port "$new_redis"; then
            if [ "$new_redis" -eq "$MYSQL_SHARED_PORT" ]; then
                print_error "Redis port cannot be the same as MySQL port"
            else
                REDIS_SHARED_PORT=$new_redis
                break
            fi
        else
            print_error "Invalid port (1-65535)"
        fi
    done
    
    print_success "Shared services ports configured"
}

# Validate port
validate_port() {
    local port=$1
    
    # Check it's a number
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Check valid range
    if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    
    return 0
}

setup_dns() {
    print_title "DNS Configuration (dnsmasq)"
    echo ""
    
    # Detect operating system
    local OS=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi microsoft /proc/version 2>/dev/null; then
            OS="wsl"
        else
            OS="linux"
        fi
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    # Check if dnsmasq is already installed
    if command -v dnsmasq >/dev/null 2>&1; then
        print_info "dnsmasq already installed"
    else
        print_info "Installing dnsmasq..."
        
        if [ "$OS" = "macos" ]; then
            # macOS: use Homebrew
            if ! command -v brew >/dev/null 2>&1; then
                print_error "Homebrew not found. Install it from https://brew.sh"
                exit 1
            fi
            brew install dnsmasq
        else
            # Linux/WSL2: use apt-get
            print_info "Requesting sudo permissions for installation..."
            sudo apt-get update
            sudo apt-get install -y dnsmasq
        fi
    fi
    
    # OS-specific configuration
    if [ "$OS" = "macos" ]; then
        # ===== macOS =====
        print_info "Configuring dnsmasq (macOS)..."
        mkdir -p /usr/local/etc/dnsmasq.d
        
        # Copy configuration
        cp "$SCRIPT_DIR/shared/dnsmasq/dnsmasq.conf" /usr/local/etc/dnsmasq.conf
        
        # Configure macOS resolver
        sudo mkdir -p /etc/resolver
        echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/test > /dev/null
        
        # Start service
        print_info "Starting dnsmasq service..."
        sudo brew services start dnsmasq
        
    else
        # ===== Linux/WSL2 =====
        print_info "Configuring dnsmasq (Linux)..."
        
        # Copy configuration
        sudo cp "$SCRIPT_DIR/shared/dnsmasq/dnsmasq.conf" /etc/dnsmasq.d/phpharbor-test.conf
        
        # Configure dnsmasq to listen only on localhost
        if ! grep -q "listen-address=127.0.0.1" /etc/dnsmasq.conf 2>/dev/null; then
            echo "listen-address=127.0.0.1" | sudo tee -a /etc/dnsmasq.conf > /dev/null
        fi
        
        # On Linux, configure systemd-resolved if present
        if systemctl is-active systemd-resolved >/dev/null 2>&1; then
            print_info "Configuring systemd-resolved..."
            
            # Create configuration for *.test
            echo "[Resolve]
DNS=127.0.0.1
Domains=~test" | sudo tee /etc/systemd/resolved.conf.d/phpharbor.conf > /dev/null 2>&1 || true
            
            # Disable DNSStubListener to avoid port 53 conflict
            sudo mkdir -p /etc/systemd/resolved.conf.d
            echo "[Resolve]
DNSStubListener=no" | sudo tee /etc/systemd/resolved.conf.d/phpharbor-stub.conf > /dev/null
            
            sudo systemctl restart systemd-resolved
        fi
        
        # Restart dnsmasq
        print_info "Starting dnsmasq service..."
        sudo systemctl enable dnsmasq
        sudo systemctl restart dnsmasq
        
        # Check status
        if ! sudo systemctl is-active dnsmasq >/dev/null 2>&1; then
            print_warning "dnsmasq may not have started correctly"
            echo "Check logs: sudo journalctl -u dnsmasq -n 50"
        fi
    fi
    
    print_success "DNS configured!"
    echo ""
    echo -e "${CYAN}All *.test domains point to 127.0.0.1${NC}"
    echo ""
    
    if [ "$OS" = "linux" ] || [ "$OS" = "wsl" ]; then
        echo "NOTE: On some Linux systems you may need to:"
        echo "  1. Edit /etc/resolv.conf to use 127.0.0.1"
        echo "  2. Or use 127.0.0.1 as DNS in network settings"
        echo ""
    fi
    
    echo "Test: ping progetto.test"
}

setup_proxy() {
    print_title "Starting Reverse Proxy"
    echo ""
    
    cd "$SCRIPT_DIR/proxy"
    
    # Check if already running
    if docker ps | grep -q nginx-proxy; then
        print_info "Proxy is already running"
        return
    fi
    
    # Make sure .env file exists
    if [ ! -f ".env" ]; then
        print_info "Creating proxy configuration file..."
        update_proxy_env
    fi
    
    print_info "Starting nginx-proxy and acme-companion..."
    $DOCKER_COMPOSE up -d nginx-proxy acme-companion
    
    # Wait for it to be ready
    print_info "Waiting for proxy to be ready..."
    sleep 3
    
    if docker ps | grep -q nginx-proxy; then
        print_success "Proxy started!"
        echo ""
        echo -e "${CYAN}Network:${NC} proxy (bridge)"
        echo -e "${CYAN}Port:${NC} 80 (HTTP), 443 (HTTPS)"
        echo ""
        echo "The proxy automatically manages SSL certificates and routing"
    else
        print_error "Error starting proxy"
        exit 1
    fi
}

setup_init() {
    print_title "PHPHarbor Initialization"
    echo ""
    
    # ==================================================
    # Projects Directory Configuration
    # ==================================================
    print_info "Configuring projects directory..."
    echo ""
    
    local default_dir="$SCRIPT_DIR/projects"
    local current_dir="${PROJECTS_DIR:-$default_dir}"
    
    echo "Where do you want to save your Docker projects?"
    echo ""
    echo "1) $default_dir (default)"
    echo "2) $HOME/Development/docker-projects"
    echo "3) Custom path"
    echo ""
    
    # If config exists, show current one
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}Current configuration: $current_dir${NC}"
        echo ""
    fi
    
    read -p "Choice [1]: " choice
    choice=${choice:-1}
    
    case $choice in
        1)
            PROJECTS_DIR="$default_dir"
            ;;
        2)
            PROJECTS_DIR="$HOME/Development/docker-projects"
            ;;
        3)
            read -p "Enter the complete path: " custom_path
            # Expand ~ and variables
            PROJECTS_DIR=$(eval echo "$custom_path")
            ;;
        *)
            print_warning "Invalid choice, using default"
            PROJECTS_DIR="$default_dir"
            ;;
    esac
    
    # Create directory if it doesn't exist
    if [ ! -d "$PROJECTS_DIR" ]; then
        print_info "Creating directory: $PROJECTS_DIR"
        mkdir -p "$PROJECTS_DIR"
    fi
    
    # Save configuration
    save_config
    
    print_success "Projects directory: $PROJECTS_DIR"
    echo ""
    
    # Create README if it doesn't exist
    if [ ! -f "$PROJECTS_DIR/README.md" ]; then
        cat > "$PROJECTS_DIR/README.md" << 'EOF'
# Docker Projects

This directory contains all Docker projects created with phpharbor

Each project has its own directory with:
- `docker-compose.yml` - Container configuration
- `.env` - Environment variables
- `app/` - Application code

## Useful Commands

```bash
# List projects
phpharbor project list

# Start project
phpharbor dev PROJECT

# Shell in container
phpharbor project shell PROJECT

# Remove project
phpharbor project remove PROJECT
```
EOF
        print_info "Created README in $PROJECTS_DIR"
    fi
    
    echo ""
    
    # ==================================================
    # Check Docker
    # ==================================================
    
    # Check Docker
    print_info "Checking Docker..."
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker not running"
        echo "Start it from Docker Desktop and try again"
        exit 1
    fi
    print_success "Docker OK"
    
    # Check Docker Compose
    if ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose not available"
        exit 1
    fi
    print_success "Docker Compose OK"
    
    echo ""
    
    # Configure DNS
    read -p "Configure dnsmasq for *.test? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_dns
        echo ""
    fi
    
    # Start proxy
    read -p "Start reverse proxy? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_proxy
        echo ""
    fi
    
    # Install mkcert if not present
    if ! command -v mkcert >/dev/null 2>&1; then
        echo ""
        print_info "For local SSL certificates, install mkcert:"
        local os=$(detect_os)
        if [ "$os" = "macos" ]; then
            echo "  brew install mkcert"
        else
            echo "  # See: https://github.com/FiloSottile/mkcert#installation"
        fi
        echo "  mkcert -install"
    else
        print_success "mkcert installed"
    fi
    
    echo ""
    print_success "Environment configured!"
    echo ""
    echo "Next steps:"
    echo "  1. Create a project: ./phpharbor create"
    echo "  2. List projects: ./phpharbor list"
    echo "  3. Start project: ./phpharbor start <name>"
}
