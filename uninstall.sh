#!/bin/bash

# PHPHarbor - Uninstaller
# Completely removes the development environment

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
case "${OS}" in
    Linux*)     OS_TYPE=Linux;;
    Darwin*)    OS_TYPE=macOS;;
    *)          OS_TYPE="UNKNOWN:${OS}"
esac

# Directories
INSTALL_DIR="$HOME/.phpharbor"
BIN_LINK="/usr/local/bin/phpharbor"

print_title "PHPHarbor - Uninstallation"
echo ""

print_warning "WARNING: This operation will remove:"
echo "  • The phpharbor command"
echo "  • The directory $INSTALL_DIR"
echo "  • Shell autocompletion (from .zshrc/.bashrc)"
echo ""
echo "Optionally:"
echo "  • All existing projects"
echo "  • Shared services (proxy, MySQL, Redis, PHP)"
echo "  • Docker volumes with data (DATABASES LOST!)"
echo ""
read -p "$(echo -e "${RED}Continue with uninstallation? (y/n):${NC} ")" -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled"
    exit 0
fi

# ==================================================
# PROJECTS
# ==================================================
echo ""
print_info "Managing existing projects..."

if [ -d "$INSTALL_DIR/projects" ]; then
    PROJECT_COUNT=$(find "$INSTALL_DIR/projects" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$PROJECT_COUNT" -gt 0 ]; then
        print_warning "Found $PROJECT_COUNT projects"
        echo ""
        read -p "$(echo -e "${CYAN}Remove all projects? (y/n):${NC} ")" -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for project_dir in "$INSTALL_DIR/projects"/*; do
                if [ -d "$project_dir" ]; then
                    project_name=$(basename "$project_dir")
                    print_info "Stopping and removing $project_name..."
                    
                    # Stop and remove containers
                    docker stop $(docker ps -q --filter "name=^${project_name}-") 2>/dev/null || true
                    docker rm $(docker ps -aq --filter "name=^${project_name}-") 2>/dev/null || true
                    
                    # Remove volumes
                    docker volume rm "${project_name}-mysql-data" 2>/dev/null || true
                    docker volume rm "${project_name}-redis-data" 2>/dev/null || true
                    
                    # Remove network
                    docker network rm "${project_name}-network" 2>/dev/null || true
                fi
            done
            print_success "Projects removed"
        else
            print_warning "Projects kept in $INSTALL_DIR/projects"
        fi
    fi
fi

# ==================================================
# SHARED SERVICES
# ==================================================
echo ""
print_info "Managing shared services..."
echo ""
read -p "$(echo -e "${CYAN}Remove shared services (proxy, MySQL, Redis, PHP)? (y/n):${NC} ")" -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Stopping shared services..."
    
    # Stop and remove containers
    docker stop proxy mysql-shared redis-shared 2>/dev/null || true
    docker rm proxy mysql-shared redis-shared 2>/dev/null || true
    
    # Stop and remove shared PHP
    docker stop $(docker ps -q --filter "name=^proxy-php-") 2>/dev/null || true
    docker rm $(docker ps -aq --filter "name=^proxy-php-") 2>/dev/null || true
    
    print_success "Shared services removed"
    
    # Volumes
    echo ""
    print_warning "MySQL and Redis volumes contain databases"
    read -p "$(echo -e "${RED}Remove MySQL and Redis volumes (DATA LOST!)? (y/n):${NC} ")" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker volume rm mysql-data redis-data 2>/dev/null || true
        print_success "Volumes removed"
    else
        print_info "Volumes kept (mysql-data, redis-data)"
    fi
    
    # Network
    docker network rm proxy-network 2>/dev/null || true
fi

# ==================================================
# SYMLINK AND REPOSITORY
# ==================================================
echo ""
print_info "Removing installation..."

# Symlink
if [ -L "$BIN_LINK" ] || [ -f "$BIN_LINK" ]; then
    sudo rm -f "$BIN_LINK"
    print_success "Symlink removed: $BIN_LINK"
fi

# Repository
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    print_success "Repository removed: $INSTALL_DIR"
fi

# ==================================================
# SHELL CONFIGURATION
# ==================================================
echo ""
print_info "Cleaning shell configuration..."

for shell_rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    if [ -f "$shell_rc" ]; then
        # Remove phpharbor lines (macOS and Linux compatible)
        if [ "$OS_TYPE" = "macOS" ]; then
            sed -i.bak '/phpharbor-completion/d' "$shell_rc" 2>/dev/null || true
            sed -i.bak '/PHPHarbor/d' "$shell_rc" 2>/dev/null || true
            rm -f "${shell_rc}.bak"
        else
            sed -i '/phpharbor-completion/d' "$shell_rc" 2>/dev/null || true
            sed -i '/PHPHarbor/d' "$shell_rc" 2>/dev/null || true
        fi
        print_success "Autocompletion removed from $shell_rc"
    fi
done

# ==================================================
# COMPLETION
# ==================================================
echo ""
print_success "Uninstallation completed!"
echo ""
echo -e "${CYAN}━━━ Final Cleanup (Optional) ━━━${NC}"
echo ""
echo "To remove ALL created Docker images:"
echo "  ${YELLOW}docker image prune -a${NC}"
echo ""
echo "To remove ALL orphaned Docker volumes:"
echo "  ${YELLOW}docker volume prune${NC}"
echo ""
echo "To reload the shell:"
echo "  ${GREEN}source ~/.zshrc${NC}  # or ~/.bashrc"
echo ""
print_info "Thanks for using PHPHarbor! 👋"
