#!/bin/bash

# Module: System
# Comandi: stats, info

cmd_stats() {
    print_title "Statistiche Utilizzo Risorse"
    echo ""
    
    # Mostra statistiche Docker generali
    echo -e "${CYAN}Container Attivi:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Size}}" | head -20
    
    echo ""
    echo -e "${CYAN}Utilizzo Risorse:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPU}}\t{{.MemUsage}}" | head -20
    
    echo ""
    echo -e "${CYAN}Immagini:${NC}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "php-laravel|mysql|redis|nginx-proxy" | head -10
    
    echo ""
    echo -e "${CYAN}Volumi:${NC}"
    docker volume ls | grep -E "mysql-data|redis-data" || echo "  Nessun volume persistente trovato"
    
    echo ""
    echo -e "${CYAN}Reti:${NC}"
    docker network ls | grep -E "proxy|backend"
}

cmd_info() {
    print_title "Informazioni Ambiente"
    echo ""
    
    # Versioni
    echo -e "${CYAN}Versioni Software:${NC}"
    echo "  Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    echo "  Docker Compose: $(docker compose version --short)"
    
    if command -v mkcert >/dev/null 2>&1; then
        echo "  mkcert: $(mkcert -version 2>&1 | head -1)"
    else
        echo "  mkcert: non installato"
    fi
    
    if command -v dnsmasq >/dev/null 2>&1; then
        echo "  dnsmasq: installato"
    else
        echo "  dnsmasq: non installato"
    fi
    
    echo ""
    
    # Proxy status
    echo -e "${CYAN}Reverse Proxy:${NC}"
    if docker ps | grep -q nginx-proxy; then
        echo "  ✓ nginx-proxy in esecuzione"
        echo "  ✓ acme-companion per SSL"
    else
        echo "  ✗ Proxy non avviato"
        echo "    Avvialo con: ./phpharbor setup proxy"
    fi
    
    echo ""
    
    # Servizi condivisi
    echo -e "${CYAN}Servizi Condivisi:${NC}"
    local shared_count=0
    
    if docker ps | grep -q mysql-shared; then
        echo "  ✓ MySQL condiviso (porta 3306)"
        ((shared_count++))
    fi
    
    if docker ps | grep -q redis-shared; then
        echo "  ✓ Redis condiviso (porta 6379)"
        ((shared_count++))
    fi
    
    local php_shared=$(docker ps --format "{{.Names}}" | grep "php-.*-shared" | wc -l | tr -d ' ')
    if [ "$php_shared" -gt 0 ]; then
        echo "  ✓ PHP-FPM condivisi: $php_shared versioni attive"
        docker ps --format "    - {{.Names}}" | grep "php-.*-shared"
        shared_count=$((shared_count + php_shared))
    fi
    
    if [ "$shared_count" -eq 0 ]; then
        echo "  ✗ Nessun servizio condiviso attivo"
        echo "    Avviali con: ./phpharbor shared start"
    fi
    
    echo ""
    
    # Progetti
    echo -e "${CYAN}Progetti:${NC}"
    local total=$(ls -d "$PROJECTS_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
    local running=$(docker ps --format "{{.Names}}" | grep -E "^(php|nginx|mysql|redis)-" | cut -d'-' -f2 | sort -u | wc -l | tr -d ' ')
    
    echo "  Totali: $total"
    echo "  Attivi: $running"
    
    if [ "$running" -gt 0 ]; then
        echo ""
        echo "  Progetti in esecuzione:"
        docker ps --format "{{.Names}}" | grep -E "^nginx-" | cut -d'-' -f2 | while read proj; do
            echo "    - $proj"
        done
    fi
    
    echo ""
    
    # Architettura
    echo -e "${CYAN}Architettura:${NC}"
    echo "  Tipo: Ibrida (dedicati + condivisi)"
    echo "  Configurazioni disponibili:"
    echo "    - fully-shared: massimo risparmio (solo nginx per progetto)"
    echo "    - shared-db: MySQL/Redis condivisi, PHP dedicato"
    echo "    - shared-php: PHP condiviso, DB dedicato"
    echo "    - dedicated: tutti i servizi dedicati"
    
    echo ""
    
    # Directory
    echo -e "${CYAN}Percorsi:${NC}"
    echo "  Progetti: $PROJECTS_DIR"
    echo "  Proxy: $SCRIPT_DIR/proxy"
    echo "  Condivisi: $SCRIPT_DIR/shared"
    echo "  CLI: $SCRIPT_DIR/cli"
    
    echo ""
    
    # Link utili
    echo -e "${CYAN}Documentazione:${NC}"
    echo "  README: $SCRIPT_DIR/README.md"
    echo "  Quick Start: $SCRIPT_DIR/QUICK-START.md"
    echo "  Shared Services: $SCRIPT_DIR/SHARED-SERVICES.md"
    echo "  Architecture: $SCRIPT_DIR/ARCHITECTURE.md"
}
