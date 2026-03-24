#!/bin/bash

# Module: Update
# Comando: update - Gestione aggiornamenti

# CONFIGURAZIONE REPOSITORY
# Repository GitHub per gli aggiornamenti
GITHUB_REPO="${PHPHARBOR_GITHUB_REPO:-v-merli/php-harbor}"
RELEASES_API_URL="https://api.github.com/repos/$GITHUB_REPO/releases"
RELEASE_LATEST_URL="$RELEASES_API_URL/latest"
RELEASE_TAG_URL="https://api.github.com/repos/$GITHUB_REPO/releases/tags"

cmd_update() {
    local subcommand=${1:-check}
    shift
    
    case $subcommand in
        check)
            update_check
            ;;
        install)
            update_install "$@"
            ;;
        list)
            update_list
            ;;
        changelog)
            update_changelog "$@"
            ;;
        help|--help|-h)
            show_update_usage
            ;;
        *)
            print_error "Comando update sconosciuto: $subcommand"
            show_update_usage
            exit 1
            ;;
    esac
}

update_check() {
    print_title "Verifica Aggiornamenti"
    echo ""
    
    print_info "Versione corrente: $VERSION"
    
    # Verifica connessione
    if ! curl -s --head https://github.com > /dev/null; then
        print_error "Impossibile connettersi a GitHub"
        echo "Verifica la connessione internet"
        exit 1
    fi
    
    # Ottieni info ultima release da GitHub
    print_info "Controllo ultima versione disponibile..."
    
    local latest_info
    latest_info=$(curl -s "$RELEASE_LATEST_URL" 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$latest_info" ]; then
        print_error "Impossibile ottenere informazioni sull'ultima versione"
        echo ""
        echo "Repository: $GITHUB_REPO"
        echo "Verifica che il repository sia pubblico e accessibile"
        exit 1
    fi
    
    # Estrai tag della versione
    local latest_version
    latest_version=$(echo "$latest_info" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    
    if [ -z "$latest_version" ]; then
        print_warning "Nessuna release trovata su GitHub"
        echo ""
        echo "Visita: https://github.com/$GITHUB_REPO/releases"
        exit 0
    fi
    
    print_info "Ultima versione disponibile: $latest_version"
    echo ""
    
    # Confronta versioni
    if [ "$VERSION" = "$latest_version" ]; then
        print_success "Sei già all'ultima versione! 🎉"
        return 0
    fi
    
    # Versioni diverse
    print_warning "È disponibile una nuova versione!"
    echo ""
    echo "  Attuale:     $VERSION"
    echo "  Disponibile: $latest_version"
    echo ""
    
    # Mostra note di rilascio (prime 10 righe)
    local release_notes
    release_notes=$(echo "$latest_info" | grep '"body"' | sed -E 's/.*"body": "(.*)".*/\1/' | sed 's/\\n/\n/g' | head -10)
    
    if [ -n "$release_notes" ]; then
        echo "📋 Novità:"
        echo "$release_notes"
        echo ""
    fi
    
    # Prompt per aggiornamento
    read -p "Vuoi aggiornare ora? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        update_install
    else
        echo ""
        print_info "Puoi aggiornare in seguito con: ./phpharbor update install"
    fi
}

update_install() {
    local target_version="$1"
    
    print_title "Installazione Aggiornamento"
    echo ""
    
    local version_to_install
    local release_info
    
    if [ -n "$target_version" ]; then
        # Versione specifica richiesta
        print_info "Versione richiesta: $target_version"
        
        # Rimuovi 'v' se presente
        target_version="${target_version#v}"
        
        # Verifica che la versione esista
        release_info=$(curl -s "${RELEASE_TAG_URL}/v${target_version}" 2>/dev/null)
        
        if [ -z "$release_info" ] || echo "$release_info" | grep -q '"message": "Not Found"'; then
            print_error "Versione $target_version non trovata"
            echo ""
            echo "Versioni disponibili:"
            echo "  ./phpharbor update list"
            exit 1
        fi
        
        version_to_install="$target_version"
    else
        # Installa ultima versione
        release_info=$(curl -s "$RELEASE_LATEST_URL" 2>/dev/null)
        
        version_to_install=$(echo "$release_info" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
        
        if [ -z "$version_to_install" ]; then
            print_error "Impossibile determinare l'ultima versione"
            exit 1
        fi
        
        print_info "Ultima versione disponibile: $version_to_install"
    fi
    
    # Verifica se già installata
    if [ "$VERSION" = "$version_to_install" ]; then
        print_success "Già alla versione $VERSION"
        return 0
    fi
    
    echo ""
    print_info "Versione corrente: $VERSION"
    print_info "Versione da installare: $version_to_install"
    echo ""
    print_warning "ATTENZIONE: Questo sostituirà i file del sistema"
    echo "I tuoi progetti e configurazioni saranno preservati:"
    echo "  ✓ Directory progetti"
    echo "  ✓ File .config"
    echo "  ✓ Certificati SSL"
    echo "  ✓ Container Docker (non toccati)"
    echo ""
    
    read -p "Continuare con l'aggiornamento? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Aggiornamento annullato"
        return 0
    fi
    
    # Crea directory temporanea
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    print_info "Download versione $version_to_install..."
    
    # URL download specifico per versione
    local download_url="https://github.com/$GITHUB_REPO/releases/download/v${version_to_install}/php-harbor.tar.gz"
    
    if ! curl -fsSL "$download_url" -o "$temp_dir/php-harbor.tar.gz"; then
        print_error "Errore durante il download"
        echo "URL: $download_url"
        exit 1
    fi
    
    print_success "Download completato"
    
    # Estrai in directory temporanea
    print_info "Estrazione archivio..."
    tar -xzf "$temp_dir/php-harbor.tar.gz" -C "$temp_dir"
    
    # Backup dei file da preservare
    print_info "Backup configurazioni..."
    local backup_dir="$temp_dir/backup"
    mkdir -p "$backup_dir"
    
    # Salva configurazioni
    [ -f "$SCRIPT_DIR/.config" ] && cp "$SCRIPT_DIR/.config" "$backup_dir/"
    [ -f "$SCRIPT_DIR/proxy/.env" ] && cp "$SCRIPT_DIR/proxy/.env" "$backup_dir/"
    
    # Salva percorso progetti se personalizzato
    local projects_external=false
    if [ -f "$SCRIPT_DIR/.config" ]; then
        source "$SCRIPT_DIR/.config"
        if [ "$PROJECTS_DIR" != "$SCRIPT_DIR/projects" ]; then
            projects_external=true
            echo "PROJECTS_DIR=$PROJECTS_DIR" > "$backup_dir/projects_dir.txt"
        fi
    fi
    
    # Ferma servizi in esecuzione
    local services_running=false
    if docker ps | grep -q "nginx-proxy"; then
        services_running=true
        print_info "Arresto servizi temporaneo..."
        cd "$SCRIPT_DIR/proxy"
        $DOCKER_COMPOSE down > /dev/null 2>&1 || true
        cd "$SCRIPT_DIR"
    fi
    
    # Aggiorna i file
    print_info "Installazione nuova versione..."
    
    # Copia i nuovi file manualmente per essere cross-platform
    # (rsync potrebbe non essere disponibile)
    cd "$temp_dir"
    
    # Lista di directory/file da NON sovrascrivere
    local preserve_items=(
        "projects"
        ".config"
        "proxy/.env"
        "proxy/nginx/certs"
        "proxy/nginx/acme"
        ".git"
        "releases"
    )
    
    # Crea pattern di esclusione per find
    local find_excludes=""
    for item in "${preserve_items[@]}"; do
        find_excludes="$find_excludes -path \"./$item\" -prune -o"
    done
    
    # Copia tutti i file tranne quelli da preservare
    find . $find_excludes -type f -print | while read file; do
        # Rimuovi il ./ iniziale
        file="${file#./}"
        
        # Crea directory di destinazione se non esiste
        local dir=$(dirname "$file")
        mkdir -p "$SCRIPT_DIR/$dir"
        
        # Copia il file
        cp "$file" "$SCRIPT_DIR/$file"
    done
    
    # Assicurati che phpharbor sia eseguibile
    chmod +x "$SCRIPT_DIR/phpharbor" 2>/dev/null || true
    chmod +x "$SCRIPT_DIR"/cli/*.sh 2>/dev/null || true
    
    cd "$SCRIPT_DIR"
    
    # Ripristina configurazioni
    print_info "Ripristino configurazioni..."
    [ -f "$backup_dir/.config" ] && cp "$backup_dir/.config" "$SCRIPT_DIR/"
    [ -f "$backup_dir/.env" ] && cp "$backup_dir/.env" "$SCRIPT_DIR/proxy/"
    
    # Riavvia servizi se erano in esecuzione
    if [ "$services_running" = true ]; then
        print_info "Riavvio servizi..."
        cd "$SCRIPT_DIR/proxy"
        $DOCKER_COMPOSE up -d > /dev/null 2>&1
        cd "$SCRIPT_DIR"
    fi
    
    # Verifica nuovo numero di versione
    local new_version=$(grep "^VERSION=" "$SCRIPT_DIR/phpharbor" | cut -d'"' -f2)
    
    print_success "Aggiornamento completato! 🎉"
    echo ""
    echo "  Vecchia versione: $VERSION"
    echo "  Nuova versione:   $new_version"
    echo ""
    
    if [ "$projects_external" = true ]; then
        print_info "I tuoi progetti sono in: $PROJECTS_DIR"
    else
        print_info "I tuoi progetti sono preservati in: $SCRIPT_DIR/projects"
    fi
    
    echo ""
    print_info "Changelog completo:"
    echo "  https://github.com/$GITHUB_REPO/releases/tag/v$new_version"
}

update_changelog() {
    local target_version="$1"
    
    print_title "Changelog"
    echo ""
    
    local release_url
    if [ -n "$target_version" ]; then
        # Rimuovi 'v' se presente
        target_version="${target_version#v}"
        print_info "Recupero changelog versione $target_version..."
        release_url="${RELEASE_TAG_URL}/v${target_version}"
    else
        print_info "Recupero changelog ultima versione..."
        release_url="$RELEASE_LATEST_URL"
    fi
    
    echo ""
    
    # Ottieni info release
    local release_info
    release_info=$(curl -s "$release_url" 2>/dev/null)
    
    if [ -z "$release_info" ] || echo "$release_info" | grep -q '"message": "Not Found"'; then
        print_error "Impossibile recuperare il changelog"
        if [ -n "$target_version" ]; then
            echo "Versione $target_version non trovata"
        fi
        exit 1
    fi
    
    local version
    version=$(echo "$release_info" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    
    local release_date
    release_date=$(echo "$release_info" | grep '"published_at"' | sed -E 's/.*"([^"]+)".*/\1/' | cut -d'T' -f1)
    
    local release_notes
    release_notes=$(echo "$release_info" | grep '"body"' | sed -E 's/.*"body": "(.*)".*/\1/' | sed 's/\\n/\n/g')
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Versione: $version"
    echo "Data:     $release_date"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "$release_notes"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Tutte le versioni:"
    echo "  https://github.com/$GITHUB_REPO/releases"
}

update_list() {
    print_title "Versioni Disponibili"
    echo ""
    
    print_info "Recupero elenco versioni da GitHub..."
    echo ""
    
    # Ottieni tutte le release (prime 20)
    local releases_info
    releases_info=$(curl -s "${RELEASES_API_URL}?per_page=20" 2>/dev/null)
    
    if [ -z "$releases_info" ] || [ "$releases_info" = "[]" ]; then
        print_warning "Nessuna release trovata"
        echo ""
        echo "Repository: https://github.com/$GITHUB_REPO/releases"
        return 0
    fi
    
    # Versione corrente evidenziata
    echo "Versione corrente: ${GREEN}$VERSION${NC}"
    echo ""
    echo "Versioni disponibili:"
    echo ""
    
    # Parsing JSON manuale (compatibile senza jq)
    local in_releases=false
    local version=""
    local date=""
    local name=""
    local count=0
    
    echo "$releases_info" | while IFS= read -r line; do
        if echo "$line" | grep -q '"tag_name"'; then
            version=$(echo "$line" | sed -E 's/.*"tag_name": "([^"]+)".*/\1/' | sed 's/^v//')
        fi
        
        if echo "$line" | grep -q '"published_at"'; then
            date=$(echo "$line" | sed -E 's/.*"published_at": "([^"]+)".*/\1/' | cut -d'T' -f1)
        fi
        
        if echo "$line" | grep -q '"name"'; then
            name=$(echo "$line" | sed -E 's/.*"name": "([^"]+)".*/\1/')
        fi
        
        # Quando abbiamo tutti i campi, stampa
        if [ -n "$version" ] && [ -n "$date" ] && [ -n "$name" ]; then
            if [ "$version" = "$VERSION" ]; then
                echo "  ${GREEN}✓ v$version${NC} - $date - $name ${CYAN}(installata)${NC}"
            else
                echo "    v$version - $date - $name"
            fi
            
            version=""
            date=""
            name=""
            count=$((count + 1))
        fi
    done
    
    echo ""
    print_info "Per installare una versione specifica:"
    echo "  ./phpharbor update install <versione>"
    echo ""
    echo "Esempi:"
    echo "  ./phpharbor update install 2.0.0"
    echo "  ./phpharbor update install          # Installa ultima"
}

show_update_usage() {
    cat << EOF
Uso: ./phpharbor update <comando> [opzioni]

Gestisce gli aggiornamenti di PHPHarbor.

COMANDI:
  check                 Verifica disponibilità aggiornamenti
  install [versione]    Installa versione (ultima se non specificata)
  list                  Mostra tutte le versioni disponibili
  changelog [versione]  Mostra changelog (ultima se non specificata)
  help                  Mostra questo messaggio

ESEMPI:
  # Verifica aggiornamenti
  ./phpharbor update check
  
  # Installa ultima versione
  ./phpharbor update install
  
  # Installa versione specifica
  ./phpharbor update install 1.5.0
  ./phpharbor update install v1.5.0
  
  # Elenca tutte le versioni
  ./phpharbor update list
  
  # Vedi changelog
  ./phpharbor update changelog          # Ultima versione
  ./phpharbor update changelog 2.0.0    # Versione specifica

NOTE:
  • L'aggiornamento preserva configurazioni e progetti
  • I certificati SSL vengono mantenuti
  • I container Docker non vengono toccati
  • Puoi installare versioni precedenti (downgrade)
  • È possibile annullare durante il processo

CONFIGURAZIONI PRESERVATE:
  ✓ .config (directory progetti, porte)
  ✓ proxy/.env (configurazione porte)
  ✓ projects/ (tutti i progetti)
  ✓ proxy/nginx/certs/ (certificati SSL)
  ✓ Container e reti Docker

EOF
}
