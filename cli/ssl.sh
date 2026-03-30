#!/bin/bash

# Module: SSL
# Command: ssl - SSL certificate management

cmd_ssl() {
    local subcommand=${1:-help}
    
    case $subcommand in
        setup)
            ssl_setup
            ;;
        install)
            ssl_install_ca
            ;;
        generate)
            if [ -z "$2" ]; then
                print_error "Domain not specified"
                echo "Usage: ./phpharbor ssl generate <domain>"
                exit 1
            fi
            ssl_generate "$2"
            ;;
        verify)
            ssl_verify
            ;;
        cleanup)
            ssl_cleanup
            ;;
        help|--help|-h)
            show_ssl_usage
            ;;
        *)
            print_error "Unknown SSL command: $subcommand"
            show_ssl_usage
            exit 1
            ;;
    esac

}

# Remove orphaned SSL certificates (not associated with any existing project)
ssl_cleanup() {
    print_info "Cleaning orphaned SSL certificates..."
    local acme_base="$SCRIPT_DIR/proxy/nginx/acme"
    local mkcert_dir="$SCRIPT_DIR/proxy/nginx/certs"
    local projects_dir="$PROJECTS_DIR"

    # Get list of active domains from projects
    local active_domains=()
    if [ -d "$projects_dir" ]; then
        for project_dir in "$projects_dir"/*/ ; do
            [ -d "$project_dir" ] || continue
            if [ -f "$project_dir/.env" ]; then
                domain=$(grep "^DOMAIN=" "$project_dir/.env" | cut -d'=' -f2)
                [ -n "$domain" ] && active_domains+=("$domain")
            fi
        done
    fi

    # Function to check if a domain is active
    is_active_domain() {
        local d="$1"
        for ad in "${active_domains[@]}"; do
            [ "$ad" = "$d" ] && return 0
        done
        return 1
    }

    # Cleanup ACME (staging/dev@localhost)
    for acme_env in staging dev@localhost; do
        if [ -d "$acme_base/$acme_env" ]; then
            for d in "$acme_base/$acme_env"/*; do
                [ -d "$d" ] || continue
                dom=$(basename "$d")
                is_active_domain "$dom" || {
                    print_warning "Removing orphan ACME certificate: $acme_env/$dom"
                    rm -rf "$d"
                }
            done
        fi
    done

    # Cleanup mkcert (crt/key/chain)
    if [ -d "$mkcert_dir" ]; then
        for f in "$mkcert_dir"/*.crt; do
            [ -f "$f" ] || continue
            dom=$(basename "$f" .crt)
            is_active_domain "$dom" || {
                print_warning "Removing orphan mkcert certificate: $dom"
                rm -f "$mkcert_dir/$dom.crt" "$mkcert_dir/$dom.key" "$mkcert_dir/$dom.chain.pem"
            }
        done
    fi

    print_success "Orphaned SSL certificates cleanup completed."
}

ssl_setup() {
    print_info "Configuring local Certificate Authority..."
    "$SCRIPT_DIR/proxy/setup-ssl-ca.sh"
}

ssl_install_ca() {
    if ! command -v mkcert &> /dev/null; then
        print_error "mkcert not found"
        echo ""
        echo "Install mkcert:"
        local os=$(detect_os)
        if [ "$os" = "macos" ]; then
            echo "  brew install mkcert"
        else
            echo "  # Install from source"
            echo "  curl -JLO https://dl.filippo.io/mkcert/latest?for=linux/amd64"
            echo "  chmod +x mkcert-v*-linux-amd64"
            echo "  sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert"
        fi
        exit 1
    fi
    
    print_info "Installing local CA..."
    mkcert -install
    
    local ca_root="$(mkcert -CAROOT)"
    echo ""
    print_success "CA installed in: $ca_root"
    echo ""
    print_warning "Restart all browsers to apply changes"
}

ssl_generate() {
    local domain=$1
    local certs_dir="$SCRIPT_DIR/proxy/nginx/certs"
    
    if ! command -v mkcert &> /dev/null; then
        print_error "mkcert not found"
        echo ""
        echo "Install mkcert first:"
        echo "  ./phpharbor ssl setup"
        exit 1
    fi
    
    mkdir -p "$certs_dir"
    
    print_info "Generating SSL certificate for $domain..."
    
    mkcert -key-file "$certs_dir/$domain.key" \
           -cert-file "$certs_dir/$domain.crt" \
           "$domain" "*.$domain"
    
    if [ -f "$certs_dir/$domain.crt" ]; then
        cp "$certs_dir/$domain.crt" "$certs_dir/$domain.chain.pem"
        
        print_success "Certificate generated:"
        echo "  • $certs_dir/$domain.key"
        echo "  • $certs_dir/$domain.crt"
        echo "  • $certs_dir/$domain.chain.pem"
        
        print_info "Restarting nginx-proxy..."
        cd "$SCRIPT_DIR/proxy"
        $DOCKER_COMPOSE restart nginx-proxy
        cd "$SCRIPT_DIR"
        
        echo ""
        print_success "Site is now accessible via HTTPS: https://$domain"
    else
        print_error "Error generating certificate"
        exit 1
    fi
}

ssl_verify() {
    print_info "Verifying SSL configuration..."
    echo ""
    
    # Check mkcert
    if command -v mkcert &> /dev/null; then
        print_success "mkcert installed: $(which mkcert)"
        local version=$(mkcert -version 2>&1 | head -1)
        echo "  Version: $version"
    else
        print_error "mkcert not installed"
        local os=$(detect_os)
        if [ "$os" = "macos" ]; then
            echo "  Install: brew install mkcert"
        else
            echo "  Install: https://github.com/FiloSottile/mkcert#installation"
        fi
        return 1
    fi
    
    echo ""
    
    # Check CA
    local ca_root="$(mkcert -CAROOT)"
    if [ -f "$ca_root/rootCA.pem" ]; then
        print_success "Local CA configured"
        echo "  Directory: $ca_root"
        
        # Check CA installation in system
        local os=$(detect_os)
        if [ "$os" = "macos" ]; then
            # Check in keychain (macOS)
            if security find-certificate -c "mkcert" /Library/Keychains/System.keychain &> /dev/null; then
                print_success "CA installed in system keychain"
            else
                print_warning "CA not found in system keychain"
                echo "  Run: ./phpharbor ssl install"
            fi
        else
            # On Linux check in certutil or certificate store
            if certutil -d sql:$HOME/.pki/nssdb -L 2>/dev/null | grep -q "mkcert"; then
                print_success "CA installed in certificate store (NSS)"
            elif [ -f "/usr/local/share/ca-certificates/mkcert-rootCA.crt" ]; then
                print_success "CA installed in /usr/local/share/ca-certificates"
            else
                print_warning "CA may not be installed in the system"
                echo "  Run: ./phpharbor ssl install"
            fi
        fi
    else
        print_warning "Local CA not configured"
        echo "  Run: ./phpharbor ssl install"
    fi
    
    echo ""
    
    # List generated certificates
    local certs_dir="$SCRIPT_DIR/proxy/nginx/certs"
    if [ -d "$certs_dir" ]; then
        local cert_count=$(find "$certs_dir" -name "*.crt" -type f | wc -l | tr -d ' ')
        if [ "$cert_count" -gt 0 ]; then
            print_info "Generated certificates: $cert_count"
            echo ""
            find "$certs_dir" -name "*.crt" -type f | while read cert; do
                local domain=$(basename "$cert" .crt)
                echo "  ✓ $domain"
            done
        else
            print_info "No certificates generated"
        fi
    fi
    
    echo ""
    print_info "To generate a new certificate:"
    echo "  ./phpharbor ssl generate <domain>"
}

show_ssl_usage() {
    echo "Usage: ./phpharbor ssl <command> [options]"
    echo ""
    echo "Commands:"
    echo "  setup              Configure local Certificate Authority (first time)"
    echo "  install            Install/reinstall CA in the system"
    echo "  generate <domain>  Generate SSL certificate for a domain"
    echo "  verify             Verify SSL configuration"
    echo "  help               Show this help"
    echo ""
    echo "Examples:"
    echo "  ./phpharbor ssl setup                  # Initial setup"
    echo "  ./phpharbor ssl generate myapp.test    # Generate cert for domain"
    echo "  ./phpharbor ssl verify                 # Verify configuration"
}
