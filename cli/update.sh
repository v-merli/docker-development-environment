#!/bin/bash

# Module: Update
# Command: update - Update management

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
            print_error "Unknown update command: $subcommand"
            show_update_usage
            exit 1
            ;;
    esac
}

update_check() {
    print_title "Checking for Updates"
    echo ""
    
    print_info "Current version: $VERSION"
    
    # Check connection
    if ! curl -s --head https://github.com > /dev/null; then
        print_error "Unable to connect to GitHub"
        echo "Check your internet connection"
        exit 1
    fi
    
    # Get latest release info from GitHub
    print_info "Checking latest available version..."
    
    local latest_info
    latest_info=$(curl -s "$RELEASE_LATEST_URL" 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$latest_info" ]; then
        print_error "Unable to get latest version information"
        echo ""
        echo "Repository: $GITHUB_REPO"
        echo "Check that the repository is public and accessible"
        exit 1
    fi
    
    # Extract version tag
    local latest_version
    latest_version=$(echo "$latest_info" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    
    if [ -z "$latest_version" ]; then
        print_warning "No releases found on GitHub"
        echo ""
        echo "Visit: https://github.com/$GITHUB_REPO/releases"
        exit 0
    fi
    
    print_info "Latest available version: $latest_version"
    echo ""
    
    # Compare versions
    if [ "$VERSION" = "$latest_version" ]; then
        print_success "You are already on the latest version! 🎉"
        return 0
    fi
    
    # Different versions
    print_warning "A new version is available!"
    echo ""
    echo "  Current:   $VERSION"
    echo "  Available: $latest_version"
    echo ""
    
    # Show release notes (first 10 lines)
    local release_notes
    release_notes=$(echo "$latest_info" | grep '"body"' | sed -E 's/.*"body": "(.*)".*/\1/' | sed 's/\\n/\n/g' | head -10)
    
    if [ -n "$release_notes" ]; then
        echo "📋 What's new:"
        echo "$release_notes"
        echo ""
    fi
    
    # Prompt for update
    read -p "Update now? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        update_install
    else
        echo ""
        print_info "You can update later with: ./phpharbor update install"
    fi
}

update_install() {
    local target_version="$1"
    
    print_title "Installing Update"
    echo ""
    
    local version_to_install
    local release_info
    
    if [ -n "$target_version" ]; then
        # Specific version requested
        print_info "Requested version: $target_version"
        
        # Remove 'v' if present
        target_version="${target_version#v}"
        
        # Check that the version exists
        release_info=$(curl -s "${RELEASE_TAG_URL}/v${target_version}" 2>/dev/null)
        
        if [ -z "$release_info" ] || echo "$release_info" | grep -q '"message": "Not Found"'; then
            print_error "Version $target_version not found"
            echo ""
            echo "Available versions:"
            echo "  ./phpharbor update list"
            exit 1
        fi
        
        version_to_install="$target_version"
    else
        # Install latest version
        release_info=$(curl -s "$RELEASE_LATEST_URL" 2>/dev/null)
        
        version_to_install=$(echo "$release_info" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
        
        if [ -z "$version_to_install" ]; then
            print_error "Unable to determine latest version"
            exit 1
        fi
        
        print_info "Latest available version: $version_to_install"
    fi
    
    # Check if already installed
    if [ "$VERSION" = "$version_to_install" ]; then
        print_success "Already on version $VERSION"
        return 0
    fi
    
    echo ""
    print_info "Current version: $VERSION"
    print_info "Version to install: $version_to_install"
    echo ""
    print_warning "WARNING: This will replace system files"
    echo "Your projects and configurations will be preserved:"
    echo "  ✓ Projects directory"
    echo "  ✓ .config file"
    echo "  ✓ SSL certificates"
    echo "  ✓ Docker containers (not touched)"
    echo ""
    
    read -p "Continue with update? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Update cancelled"
        return 0
    fi
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    print_info "Downloading version $version_to_install..."
    
    # Version-specific download URL
    local download_url="https://github.com/$GITHUB_REPO/releases/download/v${version_to_install}/php-harbor.tar.gz"
    
    if ! curl -fsSL "$download_url" -o "$temp_dir/php-harbor.tar.gz"; then
        print_error "Error during download"
        echo "URL: $download_url"
        exit 1
    fi
    
    print_success "Download completed"
    
    # Extract to temporary directory
    print_info "Extracting archive..."
    tar -xzf "$temp_dir/php-harbor.tar.gz" -C "$temp_dir"
    
    # Backup of files to preserve
    print_info "Backing up configurations..."
    local backup_dir="$temp_dir/backup"
    mkdir -p "$backup_dir"
    
    # Save configurations
    [ -f "$SCRIPT_DIR/.config" ] && cp "$SCRIPT_DIR/.config" "$backup_dir/"
    [ -f "$SCRIPT_DIR/proxy/.env" ] && cp "$SCRIPT_DIR/proxy/.env" "$backup_dir/"
    
    # Save projects path if custom
    local projects_external=false
    if [ -f "$SCRIPT_DIR/.config" ]; then
        source "$SCRIPT_DIR/.config"
        if [ "$PROJECTS_DIR" != "$SCRIPT_DIR/projects" ]; then
            projects_external=true
            echo "PROJECTS_DIR=$PROJECTS_DIR" > "$backup_dir/projects_dir.txt"
        fi
    fi
    
    # Stop running services
    local services_running=false
    if docker ps | grep -q "nginx-proxy"; then
        services_running=true
        print_info "Stopping services temporarily..."
        cd "$SCRIPT_DIR/proxy"
        $DOCKER_COMPOSE down > /dev/null 2>&1 || true
        cd "$SCRIPT_DIR"
    fi
    
    # Update files
    print_info "Installing new version..."
    
    # Copy new files manually to be cross-platform
    # (rsync might not be available)
    cd "$temp_dir"
    
    # List of directories/files NOT to overwrite
    local preserve_items=(
        "projects"
        ".config"
        "proxy/.env"
        "proxy/nginx/certs"
        "proxy/nginx/acme"
        ".git"
        "releases"
    )
    
    # Create exclusion pattern for find
    local find_excludes=""
    for item in "${preserve_items[@]}"; do
        find_excludes="$find_excludes -path \"./$item\" -prune -o"
    done
    
    # Copy all files except those to preserve
    find . $find_excludes -type f -print | while read file; do
        # Remove leading ./
        file="${file#./}"
        
        # Create destination directory if it doesn't exist
        local dir=$(dirname "$file")
        mkdir -p "$SCRIPT_DIR/$dir"
        
        # Copy the file
        cp "$file" "$SCRIPT_DIR/$file"
    done
    
    # Make sure phpharbor is executable
    chmod +x "$SCRIPT_DIR/phpharbor" 2>/dev/null || true
    chmod +x "$SCRIPT_DIR"/cli/*.sh 2>/dev/null || true
    
    cd "$SCRIPT_DIR"
    
    # Restore configurations
    print_info "Restoring configurations..."
    [ -f "$backup_dir/.config" ] && cp "$backup_dir/.config" "$SCRIPT_DIR/"
    [ -f "$backup_dir/.env" ] && cp "$backup_dir/.env" "$SCRIPT_DIR/proxy/"
    
    # Restart services if they were running
    if [ "$services_running" = true ]; then
        print_info "Restarting services..."
        cd "$SCRIPT_DIR/proxy"
        $DOCKER_COMPOSE up -d > /dev/null 2>&1
        cd "$SCRIPT_DIR"
    fi
    
    # Check new version number
    local new_version=$(grep "^VERSION=" "$SCRIPT_DIR/phpharbor" | cut -d'"' -f2)
    
    print_success "Update completed! 🎉"
    echo ""
    echo "  Old version: $VERSION"
    echo "  New version: $new_version"
    echo ""
    
    if [ "$projects_external" = true ]; then
        print_info "Your projects are in: $PROJECTS_DIR"
    else
        print_info "Your projects are preserved in: $SCRIPT_DIR/projects"
    fi
    
    echo ""
    print_info "Full changelog:"
    echo "  https://github.com/$GITHUB_REPO/releases/tag/v$new_version"
}

update_changelog() {
    local target_version="$1"
    
    print_title "Changelog"
    echo ""
    
    local release_url
    if [ -n "$target_version" ]; then
        # Remove 'v' if present
        target_version="${target_version#v}"
        print_info "Fetching changelog for version $target_version..."
        release_url="${RELEASE_TAG_URL}/v${target_version}"
    else
        print_info "Fetching changelog for latest version..."
        release_url="$RELEASE_LATEST_URL"
    fi
    
    echo ""
    
    # Get release info
    local release_info
    release_info=$(curl -s "$release_url" 2>/dev/null)
    
    if [ -z "$release_info" ] || echo "$release_info" | grep -q '"message": "Not Found"'; then
        print_error "Unable to fetch changelog"
        if [ -n "$target_version" ]; then
            echo "Version $target_version not found"
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
    echo "Version: $version"
    echo "Date:    $release_date"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "$release_notes"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "All versions:"
    echo "  https://github.com/$GITHUB_REPO/releases"
}

update_list() {
    print_title "Available Versions"
    echo ""
    
    print_info "Fetching version list from GitHub..."
    echo ""
    
    # Get all releases (first 20)
    local releases_info
    releases_info=$(curl -s "${RELEASES_API_URL}?per_page=20" 2>/dev/null)
    
    if [ -z "$releases_info" ] || [ "$releases_info" = "[]" ]; then
        print_warning "No releases found"
        echo ""
        echo "Repository: https://github.com/$GITHUB_REPO/releases"
        return 0
    fi
    
    # Current version highlighted
    echo "Current version: ${GREEN}$VERSION${NC}"
    echo ""
    echo "Available versions:"
    echo ""
    
    # Manual JSON parsing (compatible without jq)
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
        
        # When we have all fields, print
        if [ -n "$version" ] && [ -n "$date" ] && [ -n "$name" ]; then
            if [ "$version" = "$VERSION" ]; then
                echo "  ${GREEN}✓ v$version${NC} - $date - $name ${CYAN}(installed)${NC}"
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
    print_info "To install a specific version:"
    echo "  ./phpharbor update install <version>"
    echo ""
    echo "Examples:"
    echo "  ./phpharbor update install 2.0.0"
    echo "  ./phpharbor update install          # Install latest"
}

show_update_usage() {
    cat << EOF
Usage: ./phpharbor update <command> [options]

Manages PHPHarbor updates.

COMMANDS:
  check                 Check for available updates
  install [version]     Install version (latest if not specified)
  list                  Show all available versions
  changelog [version]   Show changelog (latest if not specified)
  help                  Show this message

EXAMPLES:
  # Check for updates
  ./phpharbor update check
  
  # Install latest version
  ./phpharbor update install
  
  # Install specific version
  ./phpharbor update install 1.5.0
  ./phpharbor update install v1.5.0
  
  # List all versions
  ./phpharbor update list
  
  # View changelog
  ./phpharbor update changelog          # Latest version
  ./phpharbor update changelog 2.0.0    # Specific version

NOTES:
  • Update preserves configurations and projects
  • SSL certificates are kept
  • Docker containers are not touched
  • You can install previous versions (downgrade)
  • You can cancel during the process

PRESERVED CONFIGURATIONS:
  ✓ .config (projects directory, ports)
  ✓ proxy/.env (port configuration)
  ✓ projects/ (all projects)
  ✓ proxy/nginx/certs/ (SSL certificates)
  ✓ Docker containers and networks

EOF
}
