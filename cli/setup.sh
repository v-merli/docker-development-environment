#!/bin/bash

# Module: Setup
# Comandi: setup dns/proxy/init

cmd_setup() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Uso: ./docker-dev setup <comando>"
        echo ""
        echo "Comandi:"
        echo "  config  Configura directory progetti"
        echo "  ports   Configura porte servizi (HTTP, HTTPS, MySQL, Redis)"
        echo "  dns     Installa e configura dnsmasq per *.test"
        echo "  proxy   Avvia il reverse proxy nginx"
        echo "  init    Setup completo interattivo"
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
            print_error "Sotto-comando sconosciuto: $subcmd"
            echo ""
            echo "Uso: ./docker-dev setup <comando>"
            echo ""
            echo "Comandi:"
            echo "  config  Configura directory progetti"
            echo "  ports   Configura porte servizi"
            echo "  dns     Installa e configura dnsmasq per *.test"
            echo "  proxy   Avvia il reverse proxy nginx"
            echo "  init    Inizializza l'ambiente (dns + proxy)"
            exit 1
            ;;
    esac
}

setup_config() {
    print_title "Configurazione Directory Progetti"
    echo ""
    
    local default_dir="$SCRIPT_DIR/projects"
    local current_dir="${PROJECTS_DIR:-$default_dir}"
    
    echo "Directory attuale: $current_dir"
    echo ""
    echo "Dove vuoi salvare i tuoi progetti Docker?"
    echo ""
    echo "1) $default_dir (default)"
    echo "2) $HOME/Development/docker-projects"
    echo "3) Percorso personalizzato"
    echo "4) Mantieni attuale ($current_dir)"
    echo ""
    
    read -p "Scelta [4]: " choice
    choice=${choice:-4}
    
    case $choice in
        1)
            PROJECTS_DIR="$default_dir"
            ;;
        2)
            PROJECTS_DIR="$HOME/Development/docker-projects"
            ;;
        3)
            read -p "Inserisci il percorso completo: " custom_path
            # Espandi ~ e variabili
            PROJECTS_DIR=$(eval echo "$custom_path")
            ;;
        4)
            print_info "Mantengo configurazione attuale"
            return
            ;;
        *)
            print_warning "Scelta non valida, mantengo configurazione attuale"
            return
            ;;
    esac
    
    # Verifica se ci sono progetti nella directory attuale
    if [ -d "$current_dir" ] && [ "$(ls -A "$current_dir" 2>/dev/null)" ]; then
        echo ""
        print_warning "ATTENZIONE: Trovati progetti in $current_dir"
        echo ""
        read -p "Vuoi spostarli nella nuova directory? (y/n): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Crea nuova directory se non esiste
            mkdir -p "$PROJECTS_DIR"
            
            # Sposta progetti (escludendo README.md)
            print_info "Spostamento progetti..."
            for project in "$current_dir"/*; do
                if [ -d "$project" ] && [ "$(basename "$project")" != "README.md" ]; then
                    project_name=$(basename "$project")
                    print_info "Spostamento $project_name..."
                    mv "$project" "$PROJECTS_DIR/"
                fi
            done
            print_success "Progetti spostati!"
        fi
    fi
    
    # Crea directory se non esiste
    if [ ! -d "$PROJECTS_DIR" ]; then
        print_info "Creazione directory: $PROJECTS_DIR"
        mkdir -p "$PROJECTS_DIR"
    fi
    
    # Salva configurazione
    save_config
    
    print_success "Configurazione aggiornata!"
    echo ""
    echo "Nuova directory progetti: $PROJECTS_DIR"
    echo ""
    print_info "Ricarica il terminale o esegui: source ~/.zshrc (o ~/.bashrc)"
}

setup_ports() {
    print_title "Configurazione Porte Servizi"
    echo ""
    
    echo "Configurazione attuale:"
    echo "  HTTP:  $HTTP_PORT"
    echo "  HTTPS: $HTTPS_PORT"
    echo "  MySQL: $MYSQL_SHARED_PORT"
    echo "  Redis: $REDIS_SHARED_PORT"
    echo ""
    
    # Verifica se ci sono servizi in esecuzione
    local proxy_running=false
    if docker ps | grep -q nginx-proxy; then
        proxy_running=true
        print_warning "ATTENZIONE: Il proxy è in esecuzione!"
        echo "Le modifiche alle porte richiederanno un riavvio del proxy."
        echo ""
    fi
    
    # Menu
    echo "Cosa vuoi configurare?"
    echo ""
    echo "1) Porte Proxy (HTTP/HTTPS)"
    echo "2) Porte Servizi Condivisi (MySQL/Redis)"
    echo "3) Tutte le porte"
    echo "4) Ripristina default (8080, 8443, 3306, 6379)"
    echo "5) Annulla"
    echo ""
    
    read -p "Scelta [5]: " choice
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
            print_success "Porte ripristinate ai valori default"
            ;;
        5)
            print_info "Operazione annullata"
            return
            ;;
        *)
            print_error "Scelta non valida"
            return
            ;;
    esac
    
    # Salva configurazione
    save_config
    
    print_success "Configurazione porte aggiornata!"
    echo ""
    echo "Nuove porte:"
    echo "  HTTP:  $HTTP_PORT"
    echo "  HTTPS: $HTTPS_PORT"
    echo "  MySQL: $MYSQL_SHARED_PORT"
    echo "  Redis: $REDIS_SHARED_PORT"
    echo ""
    
    # Avvisa se serve riavvio
    if [ "$proxy_running" = true ]; then
        print_warning "Per applicare le modifiche, riavvia il proxy:"
        echo "  docker-dev setup proxy"
        echo ""
        read -p "Vuoi riavviare ora il proxy? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$SCRIPT_DIR/proxy"
            $DOCKER_COMPOSE down
            $DOCKER_COMPOSE up -d
            print_success "Proxy riavviato con nuove porte!"
        fi
    fi
}

# Funzione helper per configurare porte proxy
configure_proxy_ports() {
    echo ""
    echo "=== Configurazione Porte Proxy ==="
    echo ""
    
    # HTTP Port
    while true; do
        read -p "Porta HTTP [$HTTP_PORT]: " new_http
        new_http=${new_http:-$HTTP_PORT}
        
        if validate_port "$new_http"; then
            HTTP_PORT=$new_http
            break
        else
            print_error "Porta non valida (1-65535)"
        fi
    done
    
    # HTTPS Port
    while true; do
        read -p "Porta HTTPS [$HTTPS_PORT]: " new_https
        new_https=${new_https:-$HTTPS_PORT}
        
        if validate_port "$new_https"; then
            if [ "$new_https" -eq "$HTTP_PORT" ]; then
                print_error "La porta HTTPS non può essere uguale alla porta HTTP"
            else
                HTTPS_PORT=$new_https
                break
            fi
        else
            print_error "Porta non valida (1-65535)"
        fi
    done
    
    print_success "Porte proxy configurate"
}

# Funzione helper per configurare porte servizi condivisi
configure_shared_ports() {
    echo ""
    echo "=== Configurazione Porte Servizi Condivisi ==="
    echo ""
    
    # MySQL Port
    while true; do
        read -p "Porta MySQL [$MYSQL_SHARED_PORT]: " new_mysql
        new_mysql=${new_mysql:-$MYSQL_SHARED_PORT}
        
        if validate_port "$new_mysql"; then
            MYSQL_SHARED_PORT=$new_mysql
            break
        else
            print_error "Porta non valida (1-65535)"
        fi
    done
    
    # Redis Port
    while true; do
        read -p "Porta Redis [$REDIS_SHARED_PORT]: " new_redis
        new_redis=${new_redis:-$REDIS_SHARED_PORT}
        
        if validate_port "$new_redis"; then
            if [ "$new_redis" -eq "$MYSQL_SHARED_PORT" ]; then
                print_error "La porta Redis non può essere uguale alla porta MySQL"
            else
                REDIS_SHARED_PORT=$new_redis
                break
            fi
        else
            print_error "Porta non valida (1-65535)"
        fi
    done
    
    print_success "Porte servizi condivisi configurate"
}

# Valida porta
validate_port() {
    local port=$1
    
    # Verifica che sia un numero
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Verifica range valido
    if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    
    return 0
}

setup_dns() {
    print_title "Configurazione DNS (dnsmasq)"
    echo ""
    
    # Rileva sistema operativo
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
        print_error "Sistema operativo non supportato: $OSTYPE"
        exit 1
    fi
    
    # Controlla se dnsmasq è già installato
    if command -v dnsmasq >/dev/null 2>&1; then
        print_info "dnsmasq già installato"
    else
        print_info "Installazione dnsmasq..."
        
        if [ "$OS" = "macos" ]; then
            # macOS: usa Homebrew
            if ! command -v brew >/dev/null 2>&1; then
                print_error "Homebrew non trovato. Installalo da https://brew.sh"
                exit 1
            fi
            brew install dnsmasq
        else
            # Linux/WSL2: usa apt-get
            print_info "Richiesta permessi sudo per installazione..."
            sudo apt-get update
            sudo apt-get install -y dnsmasq
        fi
    fi
    
    # Configurazione specifica per OS
    if [ "$OS" = "macos" ]; then
        # ===== macOS =====
        print_info "Configurazione dnsmasq (macOS)..."
        mkdir -p /usr/local/etc/dnsmasq.d
        
        # Copia configurazione
        cp "$SCRIPT_DIR/shared/dnsmasq/dnsmasq.conf" /usr/local/etc/dnsmasq.conf
        
        # Configura resolver macOS
        sudo mkdir -p /etc/resolver
        echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/test > /dev/null
        
        # Avvia servizio
        print_info "Avvio servizio dnsmasq..."
        sudo brew services start dnsmasq
        
    else
        # ===== Linux/WSL2 =====
        print_info "Configurazione dnsmasq (Linux)..."
        
        # Copia configurazione
        sudo cp "$SCRIPT_DIR/shared/dnsmasq/dnsmasq.conf" /etc/dnsmasq.d/docker-dev-test.conf
        
        # Configura dnsmasq per ascoltare solo su localhost
        if ! grep -q "listen-address=127.0.0.1" /etc/dnsmasq.conf 2>/dev/null; then
            echo "listen-address=127.0.0.1" | sudo tee -a /etc/dnsmasq.conf > /dev/null
        fi
        
        # Su Linux, configura systemd-resolved se presente
        if systemctl is-active systemd-resolved >/dev/null 2>&1; then
            print_info "Configurazione systemd-resolved..."
            
            # Crea configurazione per *.test
            echo "[Resolve]
DNS=127.0.0.1
Domains=~test" | sudo tee /etc/systemd/resolved.conf.d/docker-dev.conf > /dev/null 2>&1 || true
            
            # Disabilita DNSStubListener per evitare conflitto porta 53
            sudo mkdir -p /etc/systemd/resolved.conf.d
            echo "[Resolve]
DNSStubListener=no" | sudo tee /etc/systemd/resolved.conf.d/docker-dev-stub.conf > /dev/null
            
            sudo systemctl restart systemd-resolved
        fi
        
        # Riavvia dnsmasq
        print_info "Avvio servizio dnsmasq..."
        sudo systemctl enable dnsmasq
        sudo systemctl restart dnsmasq
        
        # Verifica stato
        if ! sudo systemctl is-active dnsmasq >/dev/null 2>&1; then
            print_warning "dnsmasq potrebbe non essere avviato correttamente"
            echo "Controlla i log: sudo journalctl -u dnsmasq -n 50"
        fi
    fi
    
    print_success "DNS configurato!"
    echo ""
    echo -e "${CYAN}Tutti i domini *.test puntano a 127.0.0.1${NC}"
    echo ""
    
    if [ "$OS" = "linux" ] || [ "$OS" = "wsl" ]; then
        echo "NOTA: Su alcuni sistemi Linux potrebbe essere necessario:"
        echo "  1. Modificare /etc/resolv.conf per usare 127.0.0.1"
        echo "  2. Oppure usare 127.0.0.1 come DNS nelle impostazioni di rete"
        echo ""
    fi
    
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
    
    # Assicurati che il file .env esista
    if [ ! -f ".env" ]; then
        print_info "Creazione file di configurazione proxy..."
        update_proxy_env
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
    
    # ==================================================
    # Configurazione Directory Progetti
    # ==================================================
    print_info "Configurazione directory progetti..."
    echo ""
    
    local default_dir="$SCRIPT_DIR/projects"
    local current_dir="${PROJECTS_DIR:-$default_dir}"
    
    echo "Dove vuoi salvare i tuoi progetti Docker?"
    echo ""
    echo "1) $default_dir (default)"
    echo "2) $HOME/Development/docker-projects"
    echo "3) Percorso personalizzato"
    echo ""
    
    # Se esiste già config, mostra quella attuale
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}Configurazione attuale: $current_dir${NC}"
        echo ""
    fi
    
    read -p "Scelta [1]: " choice
    choice=${choice:-1}
    
    case $choice in
        1)
            PROJECTS_DIR="$default_dir"
            ;;
        2)
            PROJECTS_DIR="$HOME/Development/docker-projects"
            ;;
        3)
            read -p "Inserisci il percorso completo: " custom_path
            # Espandi ~ e variabili
            PROJECTS_DIR=$(eval echo "$custom_path")
            ;;
        *)
            print_warning "Scelta non valida, uso default"
            PROJECTS_DIR="$default_dir"
            ;;
    esac
    
    # Crea directory se non esiste
    if [ ! -d "$PROJECTS_DIR" ]; then
        print_info "Creazione directory: $PROJECTS_DIR"
        mkdir -p "$PROJECTS_DIR"
    fi
    
    # Salva configurazione
    save_config
    
    print_success "Directory progetti: $PROJECTS_DIR"
    echo ""
    
    # Crea README se non esiste
    if [ ! -f "$PROJECTS_DIR/README.md" ]; then
        cat > "$PROJECTS_DIR/README.md" << 'EOF'
# Docker Projects

Questa directory contiene tutti i progetti Docker creati con docker-dev.

Ogni progetto ha la sua directory con:
- `docker-compose.yml` - Configurazione container
- `.env` - Variabili d'ambiente
- `app/` - Codice applicazione

## Comandi Utili

```bash
# Lista progetti
docker-dev project list

# Avvia progetto
docker-dev dev PROGETTO

# Shell nel container
docker-dev project shell PROGETTO

# Rimuovi progetto
docker-dev project remove PROGETTO
```
EOF
        print_info "Creato README in $PROJECTS_DIR"
    fi
    
    echo ""
    
    # ==================================================
    # Verifica Docker
    # ==================================================
    
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
        local os=$(detect_os)
        if [ "$os" = "macos" ]; then
            echo "  brew install mkcert"
        else
            echo "  # Vedi: https://github.com/FiloSottile/mkcert#installation"
        fi
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
