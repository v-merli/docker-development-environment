#!/bin/bash

# Module: Setup
# Comandi: setup dns/proxy/init

cmd_setup() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Uso: ./docker-dev setup <comando>"
        echo ""
        echo "Comandi:"
        echo "  dns     Installa e configura dnsmasq per *.test"
        echo "  proxy   Avvia il reverse proxy nginx"
        echo "  init    Setup completo interattivo"
        exit 0
    fi
    
    local subcmd=$1
    shift
    
    case $subcmd in
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
            print_error "Sotto-comando sconosciuto: $subcmd"
            echo ""
            echo "Uso: ./docker-dev setup <comando>"
            echo ""
            echo "Comandi:"
            echo "  dns     Installa e configura dnsmasq per *.test"
            echo "  proxy   Avvia il reverse proxy nginx"
            echo "  init    Inizializza l'ambiente (dns + proxy)"
            exit 1
            ;;
    esac
}

setup_dns() {
    print_title "Configurazione DNS (dnsmasq)"
    echo ""
    
    # Controlla se dnsmasq è già installato
    if command -v dnsmasq >/dev/null 2>&1; then
        print_info "dnsmasq già installato"
    else
        print_info "Installazione dnsmasq via Homebrew..."
        if ! command -v brew >/dev/null 2>&1; then
            print_error "Homebrew non trovato. Installalo da https://brew.sh"
            exit 1
        fi
        brew install dnsmasq
    fi
    
    # Crea directory configurazione
    print_info "Configurazione dnsmasq..."
    mkdir -p /usr/local/etc/dnsmasq.d
    
    # Copia configurazione
    cp "$SCRIPT_DIR/shared/dnsmasq/dnsmasq.conf" /usr/local/etc/dnsmasq.conf
    
    # Configura resolver macOS
    sudo mkdir -p /etc/resolver
    echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/test > /dev/null
    
    # Avvia servizio
    print_info "Avvio servizio dnsmasq..."
    sudo brew services start dnsmasq
    
    print_success "DNS configurato!"
    echo ""
    echo -e "${CYAN}Tutti i domini *.test puntano a 127.0.0.1${NC}"
    echo ""
    echo "Test: ping progetto.test"
}

setup_proxy() {
    print_title "Avvio Reverse Proxy"
    echo ""
    
    cd "$SCRIPT_DIR/proxy"
    
    # Controlla se è già in esecuzione
    if docker ps | grep -q nginx-proxy; then
        print_info "Il proxy è già in esecuzione"
        return
    fi
    
    print_info "Avvio nginx-proxy e acme-companion..."
    $DOCKER_COMPOSE up -d nginx-proxy acme-companion
    
    # Attendi che sia pronto
    print_info "Attendo che il proxy sia pronto..."
    sleep 3
    
    if docker ps | grep -q nginx-proxy; then
        print_success "Proxy avviato!"
        echo ""
        echo -e "${CYAN}Rete:${NC} proxy (bridge)"
        echo -e "${CYAN}Porta:${NC} 80 (HTTP), 443 (HTTPS)"
        echo ""
        echo "Il proxy gestisce automaticamente i certificati SSL e il routing"
    else
        print_error "Errore nell'avvio del proxy"
        exit 1
    fi
}

setup_init() {
    print_title "Inizializzazione Ambiente Docker Dev"
    echo ""
    
    # Verifica Docker
    print_info "Verifica Docker..."
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker non in esecuzione"
        echo "Avvialo da Docker Desktop e riprova"
        exit 1
    fi
    print_success "Docker OK"
    
    # Verifica Docker Compose
    if ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose non disponibile"
        exit 1
    fi
    print_success "Docker Compose OK"
    
    echo ""
    
    # Configura DNS
    read -p "Configurare dnsmasq per *.test? [s/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        setup_dns
        echo ""
    fi
    
    # Avvia proxy
    read -p "Avviare il reverse proxy? [s/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        setup_proxy
        echo ""
    fi
    
    # Installa mkcert se non presente
    if ! command -v mkcert >/dev/null 2>&1; then
        echo ""
        print_info "Per i certificati SSL locali, installa mkcert:"
        echo "  brew install mkcert"
        echo "  mkcert -install"
    else
        print_success "mkcert installato"
    fi
    
    echo ""
    print_success "Ambiente configurato!"
    echo ""
    echo "Prossimi passi:"
    echo "  1. Crea un progetto: ./docker-dev create"
    echo "  2. Elenca progetti: ./docker-dev list"
    echo "  3. Avvia progetto: ./docker-dev start <nome>"
}
