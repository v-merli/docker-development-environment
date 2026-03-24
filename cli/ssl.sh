#!/bin/bash

# Module: SSL
# Comando: ssl - Gestione certificati SSL

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
                print_error "Dominio non specificato"
                echo "Uso: ./docker-dev ssl generate <dominio>"
                exit 1
            fi
            ssl_generate "$2"
            ;;
        verify)
            ssl_verify
            ;;
        help|--help|-h)
            show_ssl_usage
            ;;
        *)
            print_error "Comando SSL sconosciuto: $subcommand"
            show_ssl_usage
            exit 1
            ;;
    esac
}

ssl_setup() {
    print_info "Configurazione Certificate Authority locale..."
    "$SCRIPT_DIR/proxy/setup-ssl-ca.sh"
}

ssl_install_ca() {
    if ! command -v mkcert &> /dev/null; then
        print_error "mkcert non trovato"
        echo ""
        echo "Installa mkcert:"
        local os=$(detect_os)
        if [ "$os" = "macos" ]; then
            echo "  brew install mkcert"
        else
            echo "  # Installazione da source"
            echo "  curl -JLO https://dl.filippo.io/mkcert/latest?for=linux/amd64"
            echo "  chmod +x mkcert-v*-linux-amd64"
            echo "  sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert"
        fi
        exit 1
    fi
    
    print_info "Installazione CA locale..."
    mkcert -install
    
    local ca_root="$(mkcert -CAROOT)"
    echo ""
    print_success "CA installata in: $ca_root"
    echo ""
    print_warning "Riavvia tutti i browser per applicare le modifiche"
}

ssl_generate() {
    local domain=$1
    local certs_dir="$SCRIPT_DIR/proxy/nginx/certs"
    
    if ! command -v mkcert &> /dev/null; then
        print_error "mkcert non trovato"
        echo ""
        echo "Installa prima mkcert:"
        echo "  ./docker-dev ssl setup"
        exit 1
    fi
    
    mkdir -p "$certs_dir"
    
    print_info "Generazione certificato SSL per $domain..."
    
    mkcert -key-file "$certs_dir/$domain.key" \
           -cert-file "$certs_dir/$domain.crt" \
           "$domain" "*.$domain"
    
    if [ -f "$certs_dir/$domain.crt" ]; then
        cp "$certs_dir/$domain.crt" "$certs_dir/$domain.chain.pem"
        
        print_success "Certificato generato:"
        echo "  • $certs_dir/$domain.key"
        echo "  • $certs_dir/$domain.crt"
        echo "  • $certs_dir/$domain.chain.pem"
        
        print_info "Riavvio nginx-proxy..."
        cd "$SCRIPT_DIR/proxy"
        $DOCKER_COMPOSE restart nginx-proxy
        cd "$SCRIPT_DIR"
        
        echo ""
        print_success "Il sito è ora accessibile via HTTPS: https://$domain"
    else
        print_error "Errore nella generazione del certificato"
        exit 1
    fi
}

ssl_verify() {
    print_info "Verifica configurazione SSL..."
    echo ""
    
    # Verifica mkcert
    if command -v mkcert &> /dev/null; then
        print_success "mkcert installato: $(which mkcert)"
        local version=$(mkcert -version 2>&1 | head -1)
        echo "  Versione: $version"
    else
        print_error "mkcert non installato"
        local os=$(detect_os)
        if [ "$os" = "macos" ]; then
            echo "  Installa: brew install mkcert"
        else
            echo "  Installa: https://github.com/FiloSottile/mkcert#installation"
        fi
        return 1
    fi
    
    echo ""
    
    # Verifica CA
    local ca_root="$(mkcert -CAROOT)"
    if [ -f "$ca_root/rootCA.pem" ]; then
        print_success "CA locale configurata"
        echo "  Directory: $ca_root"
        
        # Verifica installazione CA nel sistema
        local os=$(detect_os)
        if [ "$os" = "macos" ]; then
            # Verifica nel keychain (macOS)
            if security find-certificate -c "mkcert" /Library/Keychains/System.keychain &> /dev/null; then
                print_success "CA installata nel keychain di sistema"
            else
                print_warning "CA non trovata nel keychain di sistema"
                echo "  Esegui: ./docker-dev ssl install"
            fi
        else
            # Su Linux verifica nel certutil o certificate store
            if certutil -d sql:$HOME/.pki/nssdb -L 2>/dev/null | grep -q "mkcert"; then
                print_success "CA installata nel certificate store (NSS)"
            elif [ -f "/usr/local/share/ca-certificates/mkcert-rootCA.crt" ]; then
                print_success "CA installata in /usr/local/share/ca-certificates"
            else
                print_warning "CA potrebbe non essere installata nel sistema"
                echo "  Esegui: ./docker-dev ssl install"
            fi
        fi
    else
        print_warning "CA locale non configurata"
        echo "  Esegui: ./docker-dev ssl install"
    fi
    
    echo ""
    
    # Lista certificati generati
    local certs_dir="$SCRIPT_DIR/proxy/nginx/certs"
    if [ -d "$certs_dir" ]; then
        local cert_count=$(find "$certs_dir" -name "*.crt" -type f | wc -l | tr -d ' ')
        if [ "$cert_count" -gt 0 ]; then
            print_info "Certificati generati: $cert_count"
            echo ""
            find "$certs_dir" -name "*.crt" -type f | while read cert; do
                local domain=$(basename "$cert" .crt)
                echo "  ✓ $domain"
            done
        else
            print_info "Nessun certificato generato"
        fi
    fi
    
    echo ""
    print_info "Per generare un nuovo certificato:"
    echo "  ./docker-dev ssl generate <dominio>"
}

show_ssl_usage() {
    echo "Uso: ./docker-dev ssl <comando> [opzioni]"
    echo ""
    echo "Comandi:"
    echo "  setup              Configura Certificate Authority locale (prima volta)"
    echo "  install            Installa/reinstalla CA nel sistema"
    echo "  generate <domain>  Genera certificato SSL per un dominio"
    echo "  verify             Verifica configurazione SSL"
    echo "  help               Mostra questo help"
    echo ""
    echo "Esempi:"
    echo "  ./docker-dev ssl setup                  # Setup iniziale"
    echo "  ./docker-dev ssl generate myapp.test    # Genera cert per dominio"
    echo "  ./docker-dev ssl verify                 # Verifica configurazione"
}
