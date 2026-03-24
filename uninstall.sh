#!/bin/bash

# PHPHarbor - Uninstaller
# Rimuove completamente l'ambiente di sviluppo

set -e

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funzioni di output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_title() { echo -e "${CYAN}━━━ $1 ━━━${NC}"; }

# Rileva sistema operativo
OS="$(uname -s)"
case "${OS}" in
    Linux*)     OS_TYPE=Linux;;
    Darwin*)    OS_TYPE=macOS;;
    *)          OS_TYPE="UNKNOWN:${OS}"
esac

# Directory
INSTALL_DIR="$HOME/.phpharbor"
BIN_LINK="/usr/local/bin/phpharbor"

print_title "PHPHarbor - Disinstallazione"
echo ""

print_warning "ATTENZIONE: Questa operazione rimuoverà:"
echo "  • Il comando phpharbor"
echo "  • La directory $INSTALL_DIR"
echo "  • Autocompletamento shell (da .zshrc/.bashrc)"
echo ""
echo "Opzionalmente:"
echo "  • Tutti i progetti esistenti"
echo "  • Servizi condivisi (proxy, MySQL, Redis, PHP)"
echo "  • Volumi Docker con dati (DATABASE PERSI!)"
echo ""
read -p "$(echo -e "${RED}Continuare con la disinstallazione? (y/n):${NC} ")" -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Disinstallazione annullata"
    exit 0
fi

# ==================================================
# PROGETTI
# ==================================================
echo ""
print_info "Gestione progetti esistenti..."

if [ -d "$INSTALL_DIR/projects" ]; then
    PROJECT_COUNT=$(find "$INSTALL_DIR/projects" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$PROJECT_COUNT" -gt 0 ]; then
        print_warning "Trovati $PROJECT_COUNT progetti"
        echo ""
        read -p "$(echo -e "${CYAN}Rimuovere tutti i progetti? (y/n):${NC} ")" -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for project_dir in "$INSTALL_DIR/projects"/*; do
                if [ -d "$project_dir" ]; then
                    project_name=$(basename "$project_dir")
                    print_info "Stop e rimozione $project_name..."
                    
                    # Stop e rimuovi container
                    docker stop $(docker ps -q --filter "name=^${project_name}-") 2>/dev/null || true
                    docker rm $(docker ps -aq --filter "name=^${project_name}-") 2>/dev/null || true
                    
                    # Rimuovi volumi
                    docker volume rm "${project_name}-mysql-data" 2>/dev/null || true
                    docker volume rm "${project_name}-redis-data" 2>/dev/null || true
                    
                    # Rimuovi network
                    docker network rm "${project_name}-network" 2>/dev/null || true
                fi
            done
            print_success "Progetti rimossi"
        else
            print_warning "Progetti mantenuti in $INSTALL_DIR/projects"
        fi
    fi
fi

# ==================================================
# SERVIZI CONDIVISI
# ==================================================
echo ""
print_info "Gestione servizi condivisi..."
echo ""
read -p "$(echo -e "${CYAN}Rimuovere servizi condivisi (proxy, MySQL, Redis, PHP)? (y/n):${NC} ")" -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Stop servizi condivisi..."
    
    # Stop e rimuovi container
    docker stop proxy mysql-shared redis-shared 2>/dev/null || true
    docker rm proxy mysql-shared redis-shared 2>/dev/null || true
    
    # Stop e rimuovi PHP condivisi
    docker stop $(docker ps -q --filter "name=^proxy-php-") 2>/dev/null || true
    docker rm $(docker ps -aq --filter "name=^proxy-php-") 2>/dev/null || true
    
    print_success "Servizi condivisi rimossi"
    
    # Volumi
    echo ""
    print_warning "I volumi MySQL e Redis contengono i database"
    read -p "$(echo -e "${RED}Rimuovere volumi MySQL e Redis (DATI PERSI!)? (y/n):${NC} ")" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker volume rm mysql-data redis-data 2>/dev/null || true
        print_success "Volumi rimossi"
    else
        print_info "Volumi mantenuti (mysql-data, redis-data)"
    fi
    
    # Network
    docker network rm proxy-network 2>/dev/null || true
fi

# ==================================================
# SYMLINK E REPOSITORY
# ==================================================
echo ""
print_info "Rimozione installazione..."

# Symlink
if [ -L "$BIN_LINK" ] || [ -f "$BIN_LINK" ]; then
    sudo rm -f "$BIN_LINK"
    print_success "Symlink rimosso: $BIN_LINK"
fi

# Repository
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    print_success "Repository rimosso: $INSTALL_DIR"
fi

# ==================================================
# SHELL CONFIGURATION
# ==================================================
echo ""
print_info "Pulizia configurazione shell..."

for shell_rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    if [ -f "$shell_rc" ]; then
        # Rimuovi righe phpharbor (compatibile con macOS e Linux)
        if [ "$OS_TYPE" = "macOS" ]; then
            sed -i.bak '/phpharbor-completion/d' "$shell_rc" 2>/dev/null || true
            sed -i.bak '/PHPHarbor/d' "$shell_rc" 2>/dev/null || true
            rm -f "${shell_rc}.bak"
        else
            sed -i '/phpharbor-completion/d' "$shell_rc" 2>/dev/null || true
            sed -i '/PHPHarbor/d' "$shell_rc" 2>/dev/null || true
        fi
        print_success "Autocompletamento rimosso da $shell_rc"
    fi
done

# ==================================================
# COMPLETAMENTO
# ==================================================
echo ""
print_success "Disinstallazione completata!"
echo ""
echo -e "${CYAN}━━━ Pulizia Finale (Opzionale) ━━━${NC}"
echo ""
echo "Per rimuovere TUTTE le immagini Docker create:"
echo "  ${YELLOW}docker image prune -a${NC}"
echo ""
echo "Per rimuovere TUTTI i volumi Docker orfani:"
echo "  ${YELLOW}docker volume prune${NC}"
echo ""
echo "Per ricaricare la shell:"
echo "  ${GREEN}source ~/.zshrc${NC}  # o ~/.bashrc"
echo ""
print_info "Grazie per aver usato PHPHarbor! 👋"
