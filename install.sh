#!/bin/bash

# PHPHarbor - Installer
# Installs and configures local Docker development environment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Output functions
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_title() { echo -e "${CYAN}━━━ $1 ━━━${NC}"; }

# Detect operating system
OS="$(uname -s)"
IS_WSL=false

case "${OS}" in
    Linux*)     
        OS_TYPE=Linux
        # Check if WSL
        if grep -qi microsoft /proc/version 2>/dev/null || grep -qi wsl /proc/version 2>/dev/null; then
            IS_WSL=true
            OS_TYPE="Linux (WSL2)"
        fi
        ;;
    Darwin*)    OS_TYPE=macOS;;
    *)          OS_TYPE="UNKNOWN:${OS}"
esac

# Installation directory
INSTALL_DIR="$HOME/.phpharbor"
BIN_LINK="/usr/local/bin/phpharbor"

print_title "PHPHarbor - Installer"
echo ""
print_info "Operating system detected: $OS_TYPE"

# WSL-specific message
if [ "$IS_WSL" = true ]; then
    print_info "WSL2 detected! Make sure Docker Desktop is installed on Windows"
    print_info "with WSL2 integration enabled (Settings → Resources → WSL Integration)"
fi

echo ""

# ==================================================
# CHECK PREREQUISITES
# ==================================================
print_info "Checking prerequisites..."

# Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker not installed"
    echo "Install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose not available"
    exit 1
fi

# Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose not available"
    exit 1
fi

# mkcert (optional but recommended)
if ! command -v mkcert &> /dev/null; then
    print_warning "mkcert not installed (optional for local SSL)"
    if [ "$OS_TYPE" = "macOS" ]; then
        echo "    Install with: brew install mkcert"
    else
        echo "    Install with: https://github.com/FiloSottile/mkcert#installation"
        echo "    Debian/Ubuntu: download binary from GitHub releases"
    fi
    echo "    Required for local HTTPS certificates"
fi

print_success "Prerequisites checked"
echo ""

# ==================================================
# INSTALLATION
# ==================================================

# GitHub repository info
GITHUB_USER="v-merli"
GITHUB_REPO="php-harbor"
RELEASE_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/releases/latest/download/php-harbor.tar.gz"

print_info "Installation directory: $INSTALL_DIR"

# Check if already installed
if [ -d "$INSTALL_DIR" ]; then
    print_warning "Existing installation found"
    read -p "$(echo -e "${CYAN}Update existing installation? (y/n):${NC} ")" -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
    
    print_info "Downloading latest version..."
    
    # Backup existing configuration (if present)
    if [ -f "$INSTALL_DIR/.env" ]; then
        cp "$INSTALL_DIR/.env" "$INSTALL_DIR/.env.backup"
    fi
    
    # Remove old installation (but keep projects/)
    TEMP_PROJECTS="$HOME/.php-harbor-projects-backup"
    if [ -d "$INSTALL_DIR/projects" ]; then
        mv "$INSTALL_DIR/projects" "$TEMP_PROJECTS"
    fi
    
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # Download and extract
    curl -fsSL "$RELEASE_URL" | tar -xz -C "$INSTALL_DIR" --strip-components=1
    
    # Restore projects/
    if [ -d "$TEMP_PROJECTS" ]; then
        mv "$TEMP_PROJECTS" "$INSTALL_DIR/projects"
    fi
    
    print_success "Update completed"
else
    print_info "Downloading PHPHarbor..."
    
    # Create directory
    mkdir -p "$INSTALL_DIR"
    
    # Download and extract release
    if curl -fsSL "$RELEASE_URL" | tar -xz -C "$INSTALL_DIR" --strip-components=1; then
        print_success "Download completed"
    else
        print_error "Error during download"
        echo "Check that the release is available at:"
        echo "$RELEASE_URL"
        echo ""
        echo "If the project is in development, use git clone manually:"
        echo "git clone https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git $INSTALL_DIR"
        exit 1
    fi
fi

print_success "Installation completed"
echo ""

# ==================================================
# PERMISSIONS AND SYMLINK
# ==================================================
print_info "Configuring permissions..."

# Make sure phpharbor is executable
chmod +x "$INSTALL_DIR/phpharbor"

print_info "Creating symlink for phpharbor command..."

if [ -L "$BIN_LINK" ] || [ -f "$BIN_LINK" ]; then
    sudo rm -f "$BIN_LINK"
fi

# Symlink automatically inherits original file permissions
sudo ln -sf "$INSTALL_DIR/phpharbor" "$BIN_LINK"

print_success "Command phpharbor available globally"
echo ""

# ==================================================
# BASH COMPLETION
# ==================================================
print_info "Configuring autocompletion..."

# Detect shell
SHELL_RC=""
if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
    # Remove existing lines (macOS and Linux compatible)
    if [ "$OS_TYPE" = "macOS" ]; then
        sed -i.bak '/phpharbor-completion/d' "$SHELL_RC"
        rm -f "${SHELL_RC}.bak"
    else
        sed -i '/phpharbor-completion/d' "$SHELL_RC"
    fi
    
    # Add completion
    echo "" >> "$SHELL_RC"
    echo "# PHPHarbor - Autocompletion" >> "$SHELL_RC"
    echo "[ -f $INSTALL_DIR/phpharbor-completion.bash ] && source $INSTALL_DIR/phpharbor-completion.bash" >> "$SHELL_RC"
    
    print_success "Autocompletion configured in $SHELL_RC"
else
    print_warning "Shell RC file not found, autocompletion not configured"
fi

echo ""

# ==================================================
# INITIAL SETUP
# ==================================================
print_info "Do you want to run the initial setup now?"
echo "    - Configure nginx reverse proxy"
echo "    - Setup local SSL/HTTPS"
echo "    - Configure Docker network"
echo ""
read -p "$(echo -e "${CYAN}Run setup? (y/n):${NC} ")" -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$INSTALL_DIR"
    ./phpharbor setup init
    echo ""
fi

# ==================================================
# COMPLETION
# ==================================================
print_success "Installation completed!"
echo ""
echo -e "${CYAN}━━━ Next Steps ━━━${NC}"
echo ""
echo "1) Reload shell to activate autocompletion:"
echo "   ${GREEN}source $SHELL_RC${NC}"
echo ""
echo "2) Verify installation:"
echo "   ${GREEN}phpharbor version${NC}"
echo ""
echo "3) Create your first project:"
echo "   ${GREEN}phpharbor create${NC}  # Interactive mode"
echo "   ${GREEN}phpharbor create myapp --type laravel${NC}"
echo ""
echo "4) Explore the documentation:"
echo "   ${GREEN}phpharbor help${NC}"
echo ""
echo -e "${BLUE}Repository:${NC} $INSTALL_DIR"
echo -e "${BLUE}Documentation:${NC} https://github.com/v-merli/php-harbor"
echo ""
print_success "Happy coding! 🚀"
