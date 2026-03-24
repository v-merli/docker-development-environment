#!/bin/bash

# Module: Shared Services
# Comandi: shared start/stop/status/logs/mysql/php

cmd_shared() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Uso: ./phpharbor shared <comando>"
        echo ""
        echo "Comandi:"
        echo "  start [service]   Avvia servizi condivisi (mysql/redis)"
        echo "  stop              Ferma servizi condivisi"
        echo "  status            Mostra stato servizi"
        echo "  logs              Mostra log"
        echo "  mysql             MySQL CLI condiviso"
        echo "  php <version>     Avvia PHP condiviso (7.3-8.5)"
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
            print_error "Sotto-comando sconosciuto: $subcmd"
            echo ""
            echo "Uso: ./phpharbor shared <comando>"
            echo ""
            echo "Comandi:"
            echo "  start [service]   Avvia servizi condivisi"
            echo "  stop              Ferma servizi condivisi"
            echo "  status            Mostra stato servizi"
            echo "  logs              Mostra log"
            echo "  mysql             MySQL CLI"
            echo "  php <version>     Avvia PHP condiviso"
            exit 1
            ;;
    esac
}

shared_start() {
    cd "$SCRIPT_DIR/proxy"
    
    if [ -z "$1" ]; then
        # Avvia tutti i servizi condivisi
        print_info "Avvio servizi condivisi (MySQL + Redis)..."
        $DOCKER_COMPOSE --profile shared-services up -d mysql-shared redis-shared
        print_success "Servizi condivisi avviati"
        echo ""
        echo -e "${CYAN}MySQL:${NC} localhost:3306 (root/rootpassword)"
        echo -e "${CYAN}Redis:${NC} localhost:6379"
    else
        # Avvia servizio specifico
        local service=$1
        print_info "Avvio $service..."
        $DOCKER_COMPOSE --profile shared-services up -d $service-shared
        print_success "$service avviato"
    fi
}

shared_stop() {
    cd "$SCRIPT_DIR/proxy"
    print_info "Arresto servizi condivisi..."
    $DOCKER_COMPOSE --profile shared-services stop mysql-shared redis-shared 2>/dev/null || true
    
    # Ferma anche eventuali PHP condivisi
    for version in 7.3 7.4 8.1 8.2 8.3 8.5; do
        docker stop php-$version-shared 2>/dev/null || true
    done
    
    print_success "Servizi condivisi arrestati"
}

shared_status() {
    print_title "Stato Servizi Condivisi"
    echo ""
    
    echo -e "${CYAN}Database e Cache:${NC}"
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "mysql-shared|redis-shared"; then
        echo ""
    else
        echo "  Nessun servizio DB/Cache in esecuzione"
    fi
    
    echo ""
    echo -e "${CYAN}PHP-FPM Condivisi:${NC}"
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep "php-.*-shared"; then
        echo ""
    else
        echo "  Nessun PHP-FPM condiviso in esecuzione"
    fi
}

shared_logs() {
    cd "$SCRIPT_DIR/proxy"
    
    # Mostra log di tutti i servizi condivisi attivi
    local services=""
    docker ps --format "{{.Names}}" | grep -E "shared" | while read container; do
        echo -e "\n${CYAN}=== $container ===${NC}"
        docker logs --tail=50 $container
    done
}

shared_mysql() {
    if ! docker ps | grep -q mysql-shared; then
        print_error "MySQL condiviso non in esecuzione"
        echo "Avvialo con: ./phpharbor shared start mysql"
        exit 1
    fi
    
    docker exec -it mysql-shared mysql -uroot -prootpassword
}

shared_php() {
    if [ -z "$1" ]; then
        print_error "Specifica la versione PHP"
        echo "Uso: ./phpharbor shared php <versione>"
        echo "Versioni: 7.3, 7.4, 8.1, 8.2, 8.3, 8.5"
        exit 1
    fi
    
    local version=$1
    cd "$SCRIPT_DIR/proxy"
    
    print_info "Avvio PHP $version condiviso..."
    $DOCKER_COMPOSE --profile shared-services up -d php-$version-shared
    print_success "PHP $version condiviso avviato"
    echo ""
    echo "Container: php-$version-shared"
    echo "Percorso: /var/www/projects/<progetto>/app"
}
