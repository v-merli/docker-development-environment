#!/bin/bash

# Module: Convert
# Commands: convert project to different type (laravel/wordpress/php)

cmd_convert() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor convert <project> <type>"
        echo ""
        echo "Convert a project to a different type (laravel/wordpress/php)."
        echo ""
        echo "Arguments:"
        echo "  <project>    Project name"
        echo "  <type>       Target type: laravel, wordpress, php"
        echo ""
        echo "This will:"
        echo "  • Update PROJECT_TYPE in .env"
        echo "  • Update nginx configuration"
        echo "  • Add/remove Laravel scheduler/queue (if applicable)"
        echo "  • Restart the project"
        echo ""
        echo "Examples:"
        echo "  ./phpharbor convert mysite laravel     # Convert to Laravel"
        echo "  ./phpharbor convert myblog wordpress   # Convert to WordPress"
        echo "  ./phpharbor convert myapp php          # Convert to plain PHP"
        exit 0
    fi
    
    local project=$1
    local new_type=$2
    
    # Validate arguments
    if [ -z "$project" ]; then
        print_error "Project name required"
        echo "Usage: ./phpharbor convert <project> <type>"
        exit 1
    fi
    
    if [ -z "$new_type" ]; then
        print_error "Target type required"
        echo "Usage: ./phpharbor convert <project> <type>"
        echo "Types: laravel, wordpress, php"
        exit 1
    fi
    
    # Validate type
    if [[ ! "$new_type" =~ ^(laravel|wordpress|php)$ ]]; then
        print_error "Invalid type: $new_type"
        echo "Valid types: laravel, wordpress, php"
        exit 1
    fi
    
    # Check project exists
    local project_path="$PROJECTS_DIR/$project"
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    # Get current type
    local current_type=$(grep "^PROJECT_TYPE=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    
    if [ -z "$current_type" ]; then
        print_error "Cannot detect current project type"
        exit 1
    fi
    
    if [ "$current_type" == "$new_type" ]; then
        print_warning "Project is already type '$new_type'"
        exit 0
    fi
    
    # Confirm conversion
    print_title "Convert Project Type"
    echo ""
    echo "Project:      $project"
    echo "Current type: $current_type"
    echo "New type:     $new_type"
    echo ""
    print_warning "This will modify project configuration files"
    echo ""
    
    read -p "Continue with conversion? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_error "Conversion cancelled"
        exit 0
    fi
    
    # Perform conversion
    convert_project "$project" "$project_path" "$current_type" "$new_type"
}

convert_project() {
    local project=$1
    local project_path=$2
    local from_type=$3
    local to_type=$4
    
    print_info "Converting $project from '$from_type' to '$to_type'..."
    
    # Detect if using shared PHP
    local uses_shared_php=false
    local php_version=""
    local nginx_conf_path=$(grep "^NGINX_CONF_PATH=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    
    if [[ "$nginx_conf_path" == "./nginx.conf" ]]; then
        uses_shared_php=true
        php_version=$(grep "^PHP_VERSION=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    fi
    
    # Step 1: Update PROJECT_TYPE in .env
    print_info "Updating project type..."
    sed -i '' "s/^PROJECT_TYPE=.*/PROJECT_TYPE=$to_type/" "$project_path/.env"
    
    # Step 2: Update nginx configuration
    print_info "Updating nginx configuration..."
    
    if [ "$uses_shared_php" == true ]; then
        # Shared PHP: regenerate nginx.conf with correct template
        local nginx_template=""
        case $to_type in
            laravel) nginx_template="laravel-shared.conf" ;;
            wordpress) nginx_template="wordpress-shared.conf" ;;
            php) nginx_template="php-shared.conf" ;;
        esac
        
        sed -e "s/PROJECT_NAME_PLACEHOLDER/$project/g" \
            -e "s/PHP_VERSION_PLACEHOLDER/php-$php_version/g" \
            "$SCRIPT_DIR/shared/nginx/$nginx_template" > "$project_path/nginx.conf"
        
        print_success "Generated new nginx.conf for shared PHP"
    else
        # Dedicated PHP: update NGINX_CONF_PATH to point to correct template
        local nginx_template=""
        case $to_type in
            laravel) nginx_template="laravel.conf" ;;
            wordpress) nginx_template="wordpress.conf" ;;
            php) nginx_template="php.conf" ;;
        esac
        
        sed -i '' "s|^NGINX_CONF_PATH=.*|NGINX_CONF_PATH=../../shared/nginx/$nginx_template|" "$project_path/.env"
        print_success "Updated nginx configuration path"
    fi
    
    # Step 3: Handle Laravel-specific services (scheduler/queue)
    if [ "$to_type" == "laravel" ] && [ "$from_type" != "laravel" ]; then
        print_info "Adding Laravel scheduler/queue to profiles..."
        # Add scheduler and queue to COMPOSE_PROFILES if not present
        local profiles=$(grep "^COMPOSE_PROFILES=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
        if [[ ! "$profiles" =~ scheduler ]]; then
            profiles="$profiles scheduler"
        fi
        if [[ ! "$profiles" =~ queue ]]; then
            profiles="$profiles queue"
        fi
        sed -i '' "s/^COMPOSE_PROFILES=.*/COMPOSE_PROFILES=$profiles/" "$project_path/.env"
        print_success "Laravel services enabled"
    elif [ "$from_type" == "laravel" ] && [ "$to_type" != "laravel" ]; then
        print_info "Removing Laravel scheduler/queue from profiles..."
        local profiles=$(grep "^COMPOSE_PROFILES=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
        profiles=$(echo "$profiles" | sed 's/scheduler//g' | sed 's/queue//g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
        sed -i '' "s/^COMPOSE_PROFILES=.*/COMPOSE_PROFILES=$profiles/" "$project_path/.env"
        print_success "Laravel services disabled"
    fi
    
    # Step 4: Restart project
    print_info "Restarting project..."
    cd "$project_path"
    
    # Stop containers
    $DOCKER_COMPOSE down 2>/dev/null || true
    
    # Start with new configuration
    local profiles=$(grep "^COMPOSE_PROFILES=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    if [ -n "$profiles" ]; then
        local profile_flags=""
        for profile in $profiles; do
            profile_flags="$profile_flags --profile $profile"
        done
        $DOCKER_COMPOSE $profile_flags up -d
    else
        $DOCKER_COMPOSE up -d
    fi
    
    cd "$SCRIPT_DIR"
    
    print_success "Project converted successfully!"
    echo ""
    print_info "Project '$project' is now type '$to_type'"
    echo ""
    echo "URL: https://$project.test"
    echo ""
    
    if [ "$to_type" == "laravel" ]; then
        print_info "Laravel-specific notes:"
        echo "  • Scheduler and queue services are enabled"
        echo "  • Make sure to run: ./phpharbor artisan $project migrate"
        echo "  • Configure Laravel .env in: $project_path/app/.env"
    elif [ "$to_type" == "wordpress" ]; then
        print_info "WordPress-specific notes:"
        echo "  • Install WordPress through the web interface"
        echo "  • Or use WP-CLI: ./phpharbor shell $project"
    fi
}
