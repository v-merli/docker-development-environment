#!/bin/bash

# Docker Development Environment - Installer
# Installa e configura l'ambiente di sviluppo Docker locale

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
IS_WSL=false

case "${OS}" in
    Linux*)     
        OS_TYPE=Linux
        # Verifica se è WSL
        if grep -qi microsoft /proc/version 2>/dev/null || grep -qi wsl /proc/version 2>/dev/null; then
            IS_WSL=true
            OS_TYPE="Linux (WSL2)"
        fi
        ;;
    Darwin*)    OS_TYPE=macOS;;
    *)          OS_TYPE="UNKNOWN:${OS}"
esac

# Directory di installazione
INSTALL_DIR="$HOME/.docker-dev-env"
BIN_LINK="/usr/local/bin/docker-dev"

print_title "Docker Development Environment - Installer"
echo ""
print_info "Sistema operativo rilevato: $OS_TYPE"

# Messaggio specifico WSL
if [ "$IS_WSL" = true ]; then
    print_info "WSL2 rilevato! Assicurati che Docker Desktop sia installato su Windows"
    print_info "con integrazione WSL2 abilitata (Settings → Resources → WSL Integration)"
fi

echo ""

# ==================================================
# VERIFICA PREREQUISITI
# ==================================================
print_info "Verifica prerequisiti..."

# Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker non installato"
    echo "Installa Docker Desktop da: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose non disponibile"
    exit 1
fi

# Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose non disponibile"
    exit 1
fi

# mkcert (opzionale ma consigliato)
if ! command -v mkcert &> /dev/null; then
    print_warning "mkcert non installato (opzionale per SSL locale)"
    if [ "$OS_TYPE" = "macOS" ]; then
        echo "    Installa con: brew install mkcert"
    else
        echo "    Installa con: https://github.com/FiloSottile/mkcert#installation"
        echo "    Debian/Ubuntu: scarica binary da GitHub releases"
    fi
    echo "    Necessario per certificati HTTPS locali"
fi

print_success "Prerequisiti verificati"
echo ""

# ==================================================
# INSTALLAZIONE
# ==================================================

# GitHub repository info
GITHUB_USER="v-merli"
GITHUB_REPO="docker-development-environment"
RELEASE_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/releases/latest/download/docker-dev-env.tar.gz"

print_info "Directory di installazione: $INSTALL_DIR"

# Controlla se già installato
if [ -d "$INSTALL_DIR" ]; then
    print_warning "Installazione esistente trovata"
    read -p "$(echo -e "${CYAN}Aggiornare l'installazione esistente? (y/n):${NC} ")" -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installazione annullata"
        exit 0
    fi
    
    print_info "Scaricamento ultima versione..."
    
    # Backup configurazione esistente (se presente)
    if [ -f "$INSTALL_DIR/.env" ]; then
        cp "$INSTALL_DIR/.env" "$INSTALL_DIR/.env.backup"
    fi
    
    # Rimuovi installazione vecchia (ma mantieni projects/)
    TEMP_PROJECTS="$HOME/.docker-dev-env-projects-backup"
    if [ -d "$INSTALL_DIR/projects" ]; then
        mv "$INSTALL_DIR/projects" "$TEMP_PROJECTS"
    fi
    
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # Scarica e estrai
    curl -fsSL "$RELEASE_URL" | tar -xz -C "$INSTALL_DIR" --strip-components=1
    
    # Ripristina projects/
    if [ -d "$TEMP_PROJECTS" ]; then
        mv "$TEMP_PROJECTS" "$INSTALL_DIR/projects"
    fi
    
    print_success "Aggiornamento completato"
else
    print_info "Scaricamento Docker Dev Environment..."
    
    # Crea directory
    mkdir -p "$INSTALL_DIR"
    
    # Scarica e estrai release
    if curl -fsSL "$RELEASE_URL" | tar -xz -C "$INSTALL_DIR" --strip-components=1; then
        print_success "Download completato"
    else
        print_error "Errore durante il download"
        echo "Verifica che la release sia disponibile su:"
        echo "$RELEASE_URL"
        echo ""
        echo "Se il progetto è in sviluppo, usa git clone manualmente:"
        echo "git clone https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git $INSTALL_DIR"
        exit 1
    fi
fi

print_success "Installazione completata"
echo ""

# ==================================================
# PERMESSI E SYMLINK
# ==================================================
print_info "Configurazione permessi..."

# Assicura che docker-dev sia eseguibile
chmod +x "$INSTALL_DIR/docker-dev"

print_info "Creazione symlink per comando docker-dev..."

if [ -L "$BIN_LINK" ] || [ -f "$BIN_LINK" ]; then
    sudo rm -f "$BIN_LINK"
fi

# Il symlink eredita automaticamente i permessi del file originale
sudo ln -sf "$INSTALL_DIR/docker-dev" "$BIN_LINK"

print_success "Comando docker-dev disponibile globalmente"
echo ""

# ==================================================
# BASH COMPLETION
# ==================================================
print_info "Configurazione autocompletamento..."

# Rileva shell
SHELL_RC=""
if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
    # Rimuovi righe esistenti (compatibile con macOS e Linux)
    if [ "$OS_TYPE" = "macOS" ]; then
        sed -i.bak '/docker-dev-completion/d' "$SHELL_RC"
        rm -f "${SHELL_RC}.bak"
    else
        sed -i '/docker-dev-completion/d' "$SHELL_RC"
    fi
    
    # Aggiungi completion
    echo "" >> "$SHELL_RC"
    echo "# Docker Development Environment - Autocompletamento" >> "$SHELL_RC"
    echo "[ -f $INSTALL_DIR/docker-dev-completion.bash ] && source $INSTALL_DIR/docker-dev-completion.bash" >> "$SHELL_RC"
    
    print_success "Autocompletamento configurato in $SHELL_RC"
else
    print_warning "Shell RC file non trovato, autocompletamento non configurato"
fi

echo ""

# ==================================================
# SETUP INIZIALE
# ==================================================
print_info "Vuoi eseguire il setup iniziale ora?"
echo "    - Configura nginx reverse proxy"
echo "    - Setup SSL/HTTPS locale"
echo "    - Configura rete Docker"
echo ""
read -p "$(echo -e "${CYAN}Eseguire setup? (y/n):${NC} ")" -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$INSTALL_DIR"
    ./docker-dev setup init
    echo ""
fi

# ==================================================
# COMPLETAMENTO
# ==================================================
print_success "Installazione completata!"
echo ""
echo -e "${CYAN}━━━ Prossimi Passi ━━━${NC}"
echo ""
echo "1) Ricarica la shell per attivare autocompletamento:"
echo "   ${GREEN}source $SHELL_RC${NC}"
echo ""
echo "2) Verifica installazione:"
echo "   ${GREEN}docker-dev version${NC}"
echo ""
echo "3) Crea il tuo primo progetto:"
echo "   ${GREEN}docker-dev create${NC}  # Modalità interattiva"
echo "   ${GREEN}docker-dev create myapp --type laravel${NC}"
echo ""
echo "4) Documenta te stesso:"
echo "   ${GREEN}docker-dev help${NC}"
echo ""
echo -e "${BLUE}Repository:${NC} $INSTALL_DIR"
echo -e "${BLUE}Documentazione:${NC} https://github.com/v-merli/docker-development-environment"
echo ""
print_success "Buon sviluppo! 🚀"
