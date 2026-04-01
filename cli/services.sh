#!/bin/bash

# Module: Services
# Commands: service (unified service management)

# Available services by project type
LARAVEL_SERVICES="queue scheduler redis mysql mariadb"
WORDPRESS_SERVICES="redis mysql mariadb"
PHP_SERVICES="redis mysql mariadb"

# ==================================================
# HELPER FUNCTIONS
# ==================================================

# Find an available port starting from the given port
# Usage: find_available_port <start_port> <max_attempts>
# Returns: Available port number
find_available_port() {
    local start_port=${1:-8080}
    local max_attempts=${2:-100}
    local port=$start_port
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        # Check if port is in use (works on macOS and Linux)
        if ! lsof -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo "$port"
            return 0
        fi
        
        port=$((port + 1))
        attempt=$((attempt + 1))
    done
    
    # If no port found, return the start port anyway
    echo "$start_port"
    return 1
}

# Extract port variables from a docker-compose template
# Usage: extract_port_variables <template_file>
# Returns: Space-separated list of port variable names (e.g., "ELASTICSEARCH_PORT NODE_WORKER_PORT")
extract_port_variables() {
    local template_file=$1
    
    if [ ! -f "$template_file" ]; then
        return 1
    fi
    
    # Extract ${VAR_PORT:-default} patterns and return just the variable names
    grep -oE '\$\{[A-Z_]+_PORT:-[0-9]+\}' "$template_file" 2>/dev/null | \
        sed 's/\${\([A-Z_]*_PORT\):-[0-9]*}/\1/g' | \
        sort -u | \
        tr '\n' ' '
}

# ==================================================
# MAIN SERVICE COMMAND
# ==================================================

# Main service command (unified interface)
cmd_service() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [ $# -eq 0 ]; then
        echo "Usage: ./phpharbor service <command> [options]"
        echo ""
        echo "Manage project services and templates."
        echo ""
        echo "Commands:"
        echo "  add <project> <service>           Add service (queue/scheduler/redis/mysql/mariadb)"
        echo "  remove <project> <service>        Remove service"
        echo "  list <project>                    List active services for a project"
        echo "  templates                         List available service templates"
        echo "  add-template <project> <tmpl>     Install service template"
        echo "  remove-template <project> <tmpl>  Remove service template"
        echo ""
        echo "Examples:"
        echo "  ./phpharbor service add myblog queue"
        echo "  ./phpharbor service remove myblog scheduler"
        echo "  ./phpharbor service list myblog"
        echo "  ./phpharbor service templates"
        echo "  ./phpharbor service add-template myblog mailhog"
        echo ""
        echo "For detailed help on each command:"
        echo "  ./phpharbor service add --help"
        echo "  ./phpharbor service templates --help"
        exit 0
    fi
    
    local subcmd=$1
    shift
    
    case $subcmd in
        add)
            cmd_add_service "$@"
            ;;
        remove)
            cmd_remove_service "$@"
            ;;
        list)
            cmd_list_services "$@"
            ;;
        templates)
            cmd_list_templates "$@"
            ;;
        add-template)
            cmd_add_template "$@"
            ;;
        remove-template)
            cmd_remove_template "$@"
            ;;
        *)
            print_error "Unknown service command: $subcmd"
            echo ""
            echo "Usage: ./phpharbor service <command>"
            echo "Commands: add, remove, list, templates, add-template, remove-template"
            echo ""
            echo "Use './phpharbor service --help' for more information"
            exit 1
            ;;
    esac
}

cmd_add_service() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor add-service <project> <service>"
        echo ""
        echo "Add an optional service to an existing project."
        echo ""
        echo "Arguments:"
        echo "  <project>    Project name"
        echo "  <service>    Service to add"
        echo ""
        echo "Available services:"
        echo "  queue        Laravel queue worker (Laravel only)"
        echo "  scheduler    Laravel scheduler (Laravel only)"
        echo "  redis        Dedicated Redis cache (all types)"
        echo "  mysql        Dedicated MySQL database (all types)"
        echo "  mariadb      Dedicated MariaDB database (all types)"
        echo ""
        echo "Notes:"
        echo "  • Services are enabled via Docker Compose profiles"
        echo "  • The project will be restarted after adding the service"
        echo "  • Some services require manual configuration in .env"
        echo ""
        echo "Examples:"
        echo "  ./phpharbor add-service myblog queue       # Add queue worker"
        echo "  ./phpharbor add-service mysite redis       # Add dedicated Redis"
        echo "  ./phpharbor add-service myapp mysql        # Add dedicated MySQL"
        exit 0
    fi
    
    local project=$1
    local service=$2
    
    # Validate arguments
    if [ -z "$project" ]; then
        print_error "Project name required"
        echo "Usage: ./phpharbor add-service <project> <service>"
        exit 1
    fi
    
    if [ -z "$service" ]; then
        print_error "Service name required"
        echo "Usage: ./phpharbor add-service <project> <service>"
        echo "Available services: queue, scheduler, redis, mysql, mariadb"
        exit 1
    fi
    
    # Check project exists
    local project_path="$PROJECTS_DIR/$project"
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    # Get project type
    local project_type=$(grep "^PROJECT_TYPE=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    
    if [ -z "$project_type" ]; then
        print_error "Cannot detect project type"
        exit 1
    fi
    
    # Validate service for project type
    validate_service "$service" "$project_type"
    
    # Get current profiles
    local current_profiles=$(grep "^COMPOSE_PROFILES=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    
    # Check if service already enabled
    if echo "$current_profiles" | grep -wq "$service"; then
        print_warning "Service '$service' is already enabled for project '$project'"
        exit 0
    fi
    
    # Map service to profile
    local profile=$(map_service_to_profile "$service" "$project_path")
    
    # Show confirmation
    print_title "Add Service to Project"
    echo ""
    echo "Project:      $project"
    echo "Type:         $project_type"
    echo "Service:      $service"
    echo "Profile:      $profile"
    echo ""
    print_info "This will enable the service and restart the project"
    echo ""
    
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_error "Operation cancelled"
        exit 0
    fi
    
    # Add service
    add_service_to_project "$project" "$project_path" "$service" "$profile" "$project_type"
}

cmd_remove_service() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor remove-service <project> <service>"
        echo ""
        echo "Remove an optional service from an existing project."
        echo ""
        echo "Arguments:"
        echo "  <project>    Project name"
        echo "  <service>    Service to remove"
        echo ""
        echo "Available services:"
        echo "  queue        Laravel queue worker"
        echo "  scheduler    Laravel scheduler"
        echo "  redis        Dedicated Redis cache"
        echo "  mysql        Dedicated MySQL database"
        echo "  mariadb      Dedicated MariaDB database"
        echo ""
        echo "Notes:"
        echo "  • This will stop and remove the service container"
        echo "  • Data volumes are preserved (use 'remove' to delete)"
        echo "  • The project will be restarted after removal"
        echo ""
        echo "Examples:"
        echo "  ./phpharbor remove-service myblog queue       # Remove queue worker"
        echo "  ./phpharbor remove-service mysite redis       # Remove dedicated Redis"
        exit 0
    fi
    
    local project=$1
    local service=$2
    
    # Validate arguments
    if [ -z "$project" ]; then
        print_error "Project name required"
        echo "Usage: ./phpharbor remove-service <project> <service>"
        exit 1
    fi
    
    if [ -z "$service" ]; then
        print_error "Service name required"
        echo "Usage: ./phpharbor remove-service <project> <service>"
        echo "Available services: queue, scheduler, redis, mysql, mariadb"
        exit 1
    fi
    
    # Check project exists
    local project_path="$PROJECTS_DIR/$project"
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    # Get project type
    local project_type=$(grep "^PROJECT_TYPE=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    
    if [ -z "$project_type" ]; then
        print_error "Cannot detect project type"
        exit 1
    fi
    
    # Get current profiles
    local current_profiles=$(grep "^COMPOSE_PROFILES=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    
    # Map service to profile
    local profile=$(map_service_to_profile "$service" "$project_path")
    
    # Check if service is enabled
    if ! echo "$current_profiles" | grep -wq "$profile"; then
        print_warning "Service '$service' is not enabled for project '$project'"
        exit 0
    fi
    
    # Show confirmation
    print_title "Remove Service from Project"
    echo ""
    echo "Project:      $project"
    echo "Type:         $project_type"
    echo "Service:      $service"
    echo "Profile:      $profile"
    echo ""
    print_warning "This will stop and remove the service container"
    print_info "Data volumes will be preserved"
    echo ""
    
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_error "Operation cancelled"
        exit 0
    fi
    
    # Remove service
    remove_service_from_project "$project" "$project_path" "$service" "$profile"
}

cmd_list_services() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor service list <project>"
        echo ""
        echo "List all active services for a project."
        echo ""
        echo "Shows:"
        echo "  • Standard services (queue, scheduler, redis, mysql, mariadb)"
        echo "  • Custom templates (mailhog, wp-cron, elasticsearch, etc.)"
        echo "  • Running containers"
        echo ""
        echo "Examples:"
        echo "  ./phpharbor service list myblog"
        exit 0
    fi
    
    local project=$1
    
    # Validate arguments
    if [ -z "$project" ]; then
        print_error "Project name required"
        echo "Usage: ./phpharbor service list <project>"
        exit 1
    fi
    
    # Check project exists
    local project_path="$PROJECTS_DIR/$project"
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    # Get project info
    local project_type=$(grep "^PROJECT_TYPE=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    local compose_profiles=$(grep "^COMPOSE_PROFILES=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    
    print_title "Services for Project: $project"
    echo ""
    echo "Type: $project_type"
    echo ""
    
    # Core services (always active)
    print_info "Core Services (always active):"
    echo "  • app - PHP application container"
    echo "  • nginx - Web server"
    
    # Optional services from profiles
    echo ""
    print_info "Optional Services:"
    
    local has_optional=false
    if [ -n "$compose_profiles" ]; then
        for profile in $compose_profiles; do
            case $profile in
                app)
                    # Skip - already shown in core services
                    ;;
                queue)
                    echo "  • queue - Laravel queue worker"
                    has_optional=true
                    ;;
                scheduler)
                    echo "  • scheduler - Laravel scheduler"
                    has_optional=true
                    ;;
                mysql-dedicated)
                    echo "  • mysql-dedicated - Dedicated MySQL database"
                    has_optional=true
                    ;;
                mariadb-dedicated)
                    echo "  • mariadb-dedicated - Dedicated MariaDB database"
                    has_optional=true
                    ;;
                redis-dedicated)
                    echo "  • redis-dedicated - Dedicated Redis cache"
                    has_optional=true
                    ;;
                *)
                    echo "  • $profile"
                    has_optional=true
                    ;;
            esac
        done
    fi
    
    if [ "$has_optional" = false ]; then
        echo "  (none)"
    fi
    
    # Check for templates (docker-compose.override.yml)
    echo ""
    if [ -f "$project_path/docker-compose.override.yml" ]; then
        print_info "Custom Templates (docker-compose.override.yml):"
        
        # Extract template labels from override file
        local templates=$(grep "phpharbor.template=" "$project_path/docker-compose.override.yml" 2>/dev/null | sed 's/.*phpharbor.template=//' | sort -u)
        
        if [ -n "$templates" ]; then
            while IFS= read -r template; do
                echo "  • $template"
            done <<< "$templates"
        else
            echo "  • Custom services (no template label)"
        fi
    else
        print_info "Custom Templates: (none)"
    fi
    
    # Show running containers
    echo ""
    print_info "Running Containers:"
    local containers=$(docker ps --filter "name=${project}-" --format "{{.Names}}" 2>/dev/null)
    
    if [ -z "$containers" ]; then
        echo "  (no containers running)"
    else
        while IFS= read -r container; do
            local short_name=$(echo "$container" | sed "s/^${project}-//")
            local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
            local uptime=$(docker inspect --format='{{.State.StartedAt}}' "$container" 2>/dev/null | xargs -I {} date -j -f "%Y-%m-%dT%H:%M:%S" {} "+%Y-%m-%d %H:%M" 2>/dev/null || echo "running")
            echo "  • $short_name ($status)"
        done <<< "$containers"
    fi
    
    echo ""
    print_info "Manage services:"
    echo "  Add:    ./phpharbor service add $project <service>"
    echo "  Remove: ./phpharbor service remove $project <service>"
    echo "  Templates: ./phpharbor service templates"
}

# Validate service for project type
validate_service() {
    local service=$1
    local project_type=$2
    
    local valid_services=""
    
    case $project_type in
        laravel)
            valid_services=$LARAVEL_SERVICES
            ;;
        wordpress)
            valid_services=$WORDPRESS_SERVICES
            ;;
        php)
            valid_services=$PHP_SERVICES
            ;;
        *)
            print_error "Unknown project type: $project_type"
            exit 1
            ;;
    esac
    
    if ! echo "$valid_services" | grep -wq "$service"; then
        print_error "Service '$service' is not available for project type '$project_type'"
        echo ""
        echo "Available services for $project_type:"
        for svc in $valid_services; do
            echo "  • $svc"
        done
        echo ""
        if [[ "$service" == "queue" ]] || [[ "$service" == "scheduler" ]]; then
            print_info "Note: queue and scheduler require PROJECT_TYPE=laravel"
            echo "For custom workers, see documentation on extending docker-compose.yml"
        fi
        exit 1
    fi
}

# Map service name to Docker Compose profile
map_service_to_profile() {
    local service=$1
    local project_path=$2
    
    case $service in
        queue|scheduler)
            echo "$service"
            ;;
        redis)
            echo "redis-dedicated"
            ;;
        mysql)
            echo "mysql-dedicated"
            ;;
        mariadb)
            echo "mariadb-dedicated"
            ;;
        *)
            print_error "Unknown service: $service"
            exit 1
            ;;
    esac
}

# Add service to project
add_service_to_project() {
    local project=$1
    local project_path=$2
    local service=$3
    local profile=$4
    local project_type=$5
    
    print_info "Adding service '$service' to project '$project'..."
    
    # Update COMPOSE_PROFILES in .env
    local current_profiles=$(grep "^COMPOSE_PROFILES=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    local new_profiles="$current_profiles $profile"
    new_profiles=$(echo "$new_profiles" | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
    
    sed -i '' "s/^COMPOSE_PROFILES=.*/COMPOSE_PROFILES=$new_profiles/" "$project_path/.env"
    
    print_success "Service added to profiles"
    
    # Additional configuration for specific services
    case $service in
        redis)
            print_info "Configuring dedicated Redis..."
            # Ensure required env vars exist
            if ! grep -q "^REDIS_PORT=" "$project_path/.env" 2>/dev/null; then
                echo "REDIS_PORT=6379" >> "$project_path/.env"
            fi
            print_info "Update your application .env to use: REDIS_HOST=${project}-redis"
            ;;
        mysql)
            print_info "Configuring dedicated MySQL..."
            ensure_mysql_vars "$project_path" "mysql"
            print_info "Update your application .env to use: DB_HOST=${project}-mysql"
            ;;
        mariadb)
            print_info "Configuring dedicated MariaDB..."
            ensure_mysql_vars "$project_path" "mariadb"
            print_info "Update your application .env to use: DB_HOST=${project}-mariadb"
            ;;
        queue|scheduler)
            print_info "Laravel $service service enabled"
            ;;
    esac
    
    # Restart project
    print_info "Restarting project..."
    cd "$project_path"
    
    # Stop and remove orphaned containers
    $DOCKER_COMPOSE down --remove-orphans 2>/dev/null || true
    
    # Start with new profile
    local all_profiles=$(grep "^COMPOSE_PROFILES=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    if [ -n "$all_profiles" ]; then
        local profile_flags=""
        for p in $all_profiles; do
            profile_flags="$profile_flags --profile $p"
        done
        $DOCKER_COMPOSE $profile_flags up -d
    else
        $DOCKER_COMPOSE up -d
    fi
    
    cd "$SCRIPT_DIR"
    
    print_success "Service '$service' added successfully!"
    echo ""
    print_info "Project: $project"
    echo "URL: https://$project.test"
    echo ""
    
    # Service-specific instructions
    show_service_instructions "$service" "$project" "$project_type"
}

# Remove service from project
remove_service_from_project() {
    local project=$1
    local project_path=$2
    local service=$3
    local profile=$4
    
    print_info "Removing service '$service' from project '$project'..."
    
    # Update COMPOSE_PROFILES in .env
    local current_profiles=$(grep "^COMPOSE_PROFILES=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    # Add spaces around to handle word boundaries correctly on BSD sed (macOS)
    local new_profiles=$(echo " $current_profiles " | sed "s/ $profile / /g" | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
    
    sed -i '' "s/^COMPOSE_PROFILES=.*/COMPOSE_PROFILES=$new_profiles/" "$project_path/.env"
    
    print_success "Service removed from profiles"
    
    # Determine container name
    local container_name="${project}-${service}"
    if [[ "$service" == "redis" ]]; then
        container_name="${project}-redis"
    elif [[ "$service" == "mysql" ]]; then
        container_name="${project}-mysql"
    elif [[ "$service" == "mariadb" ]]; then
        container_name="${project}-mariadb"
    fi
    
    # Stop and remove the specific container first
    print_info "Stopping service container..."
    docker stop "$container_name" 2>/dev/null || true
    docker rm "$container_name" 2>/dev/null || true
    
    # Restart project
    print_info "Restarting project..."
    cd "$project_path"
    
    # Stop and remove orphaned containers
    $DOCKER_COMPOSE down --remove-orphans 2>/dev/null || true
    
    # Start with remaining profiles
    local all_profiles=$(grep "^COMPOSE_PROFILES=" "$project_path/.env" 2>/dev/null | cut -d'=' -f2)
    if [ -n "$all_profiles" ]; then
        local profile_flags=""
        for p in $all_profiles; do
            profile_flags="$profile_flags --profile $p"
        done
        $DOCKER_COMPOSE $profile_flags up -d
    else
        $DOCKER_COMPOSE up -d
    fi
    
    cd "$SCRIPT_DIR"
    
    print_success "Service '$service' removed successfully!"
    echo ""
    print_info "Project: $project"
    echo "URL: https://$project.test"
    echo ""
    
    # Warnings for data
    if [[ "$service" == "mysql" ]] || [[ "$service" == "mariadb" ]] || [[ "$service" == "redis" ]]; then
        print_warning "Data volume preserved at: volumes/${service}/${project}"
        print_info "To remove data, use: ./phpharbor remove $project"
    fi
}

# Ensure MySQL/MariaDB environment variables exist
ensure_mysql_vars() {
    local project_path=$1
    local db_type=$2
    
    if ! grep -q "^MYSQL_VERSION=" "$project_path/.env" 2>/dev/null; then
        if [ "$db_type" == "mariadb" ]; then
            echo "MYSQL_VERSION=11.4" >> "$project_path/.env"
        else
            echo "MYSQL_VERSION=8.0" >> "$project_path/.env"
        fi
    fi
    
    if ! grep -q "^MYSQL_DATABASE=" "$project_path/.env" 2>/dev/null; then
        local project=$(basename "$project_path")
        echo "MYSQL_DATABASE=${project}" >> "$project_path/.env"
        echo "MYSQL_ROOT_PASSWORD=root" >> "$project_path/.env"
        echo "MYSQL_USER=${project}" >> "$project_path/.env"
        echo "MYSQL_PASSWORD=secret" >> "$project_path/.env"
        echo "MYSQL_PORT=3306" >> "$project_path/.env"
    fi
}

# Show service-specific instructions
show_service_instructions() {
    local service=$1
    local project=$2
    local project_type=$3
    
    case $service in
        queue)
            echo "Queue worker instructions:"
            echo "  • Container: ${project}-queue"
            echo "  • Manages: php artisan queue:work"
            echo "  • Control: ./phpharbor queue $project <restart|logs|status>"
            ;;
        scheduler)
            echo "Scheduler instructions:"
            echo "  • Container: ${project}-scheduler"
            echo "  • Runs: php artisan schedule:run every minute"
            echo "  • Logs: ./phpharbor logs $project | grep scheduler"
            ;;
        redis)
            echo "Redis instructions:"
            echo "  • Container: ${project}-redis"
            echo "  • Host: ${project}-redis"
            echo "  • Port: 6379"
            echo "  • Configure in app .env: REDIS_HOST=${project}-redis"
            ;;
        mysql)
            echo "MySQL instructions:"
            echo "  • Container: ${project}-mysql"
            echo "  • Host: ${project}-mysql"
            echo "  • Port: 3306"
            echo "  • Database: $project"
            echo "  • Configure in app .env: DB_HOST=${project}-mysql"
            echo "  • CLI: ./phpharbor mysql $project"
            ;;
        mariadb)
            echo "MariaDB instructions:"
            echo "  • Container: ${project}-mariadb"
            echo "  • Host: ${project}-mariadb"
            echo "  • Port: 3306"
            echo "  • Database: $project"
            echo "  • Configure in app .env: DB_HOST=${project}-mariadb"
            echo "  • CLI: ./phpharbor mysql $project"
            ;;
    esac
}

# ============================================
# TEMPLATE COMMANDS
# ============================================

cmd_list_templates() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor list-templates"
        echo ""
        echo "List available service templates that can be added to projects."
        echo ""
        echo "Templates are pre-configured services like:"
        echo "  • mailhog - Email testing tool"
        echo "  • wp-cron - WordPress cron worker"
        echo "  • elasticsearch - Search engine"
        echo "  • node-worker - Node.js background service"
        echo "  • redis-commander - Redis web UI"
        echo ""
        echo "Use 'add-template' to add a template to a project."
        exit 0
    fi
    
    local templates_dir="$SCRIPT_DIR/shared/service-templates"
    
    print_title "Available Service Templates"
    echo ""
    
    if [ ! -d "$templates_dir" ]; then
        print_error "Templates directory not found"
        exit 1
    fi
    
    # List templates with descriptions
    for template_dir in "$templates_dir"/*; do
        if [ -d "$template_dir" ]; then
            local template_name=$(basename "$template_dir")
            local readme="$template_dir/README.md"
            
            # Extract first line of README as description
            local description=""
            if [ -f "$readme" ]; then
                description=$(head -n 1 "$readme" | sed 's/^# //')
            fi
            
            printf "  ${GREEN}%-20s${NC} %s\n" "$template_name" "$description"
        fi
    done
    
    echo ""
    print_info "Use: ./phpharbor service add-template <project> <template>"
    print_info "Help: ./phpharbor service add-template --help"
}

cmd_add_template() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor add-template <project> <template>"
        echo ""
        echo "Add a pre-configured service template to a project."
        echo ""
        echo "Arguments:"
        echo "  <project>    Project name"
        echo "  <template>   Template name (see list-templates)"
        echo ""
        echo "Available templates:"
        echo "  wp-cron          WordPress cron worker"
        echo "  elasticsearch    Search engine"
        echo "  node-worker      Node.js background service"
        echo "  redis-commander  Redis web UI"
        echo ""
        echo "The template will be copied to the project's docker-compose.override.yml"
        echo "and the project will be restarted automatically."
        echo "Dynamic port assignment will be used to avoid conflicts."
        echo ""
        echo "Examples:"
        echo "  ./phpharbor add-template mysite wp-cron"
        echo "  ./phpharbor add-template myapp node-worker"
        echo "  ./phpharbor add-template myblog elasticsearch"
        exit 0
    fi
    
    local project=$1
    local template=$2
    
    # Validate arguments
    if [ -z "$project" ]; then
        print_error "Project name required"
        echo "Usage: ./phpharbor add-template <project> <template>"
        exit 1
    fi
    
    if [ -z "$template" ]; then
        print_error "Template name required"
        echo "Usage: ./phpharbor add-template <project> <template>"
        echo "Use './phpharbor list-templates' to see available templates"
        exit 1
    fi
    
    # Check project exists
    local project_path="$PROJECTS_DIR/$project"
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    # Check template exists
    local templates_dir="$SCRIPT_DIR/shared/service-templates"
    local template_path="$templates_dir/$template"
    
    if [ ! -d "$template_path" ]; then
        print_error "Template '$template' not found"
        echo ""
        echo "Available templates:"
        ./phpharbor service templates
        exit 1
    fi
    
    # Check if template is already installed
    local override_file="$project_path/docker-compose.override.yml"
    if [ -f "$override_file" ]; then
        if grep -q "phpharbor.template=$template" "$override_file" 2>/dev/null; then
            print_warning "Template '$template' is already installed in project '$project'"
            echo ""
            print_info "To reinstall, first remove it with:"
            echo "  ./phpharbor service remove-template $project $template"
            exit 0
        fi
    fi
    
    # Extract and assign dynamic ports
    local template_override="$template_path/docker-compose.override.yml"
    if [ ! -f "$template_override" ]; then
        print_error "Template docker-compose.override.yml not found"
        exit 1
    fi
    
    # Get list of port variables needed by this template
    local port_vars=$(extract_port_variables "$template_override")
    local port_assignments=()
    local env_additions=""
    
    if [ -n "$port_vars" ]; then
        print_info "Assigning dynamic ports for template..."
        
        for port_var in $port_vars; do
            # Extract default port from the template
            local default_port=$(grep -oE "\\\$\{${port_var}:-([0-9]+)\}" "$template_override" | grep -oE '[0-9]+' | head -1)
            
            # Find available port starting from default
            local assigned_port=$(find_available_port "$default_port" 100)
            
            # Store assignment for display and env file
            port_assignments+=("$port_var=$assigned_port")
            env_additions="${env_additions}${port_var}=${assigned_port}\n"
            
            print_success "  $port_var: $assigned_port (default: $default_port)"
        done
        
        echo ""
    fi
    
    # Check if override file already exists
    local backup_needed=false
    
    if [ -f "$override_file" ]; then
        backup_needed=true
    fi
    
    # Show confirmation
    print_title "Add Service Template"
    echo ""
    echo "Project:      $project"
    echo "Template:     $template"
    echo "Target:       docker-compose.override.yml"
    
    if [ "$backup_needed" = true ]; then
        echo ""
        print_warning "Existing override file will be backed up"
        echo "Backup:       docker-compose.override.yml.backup"
    fi
    
    if [ ${#port_assignments[@]} -gt 0 ]; then
        echo ""
        print_info "Port assignments:"
        for assignment in "${port_assignments[@]}"; do
            echo "  • $assignment"
        done
    fi
    
    echo ""
    print_info "The project will be restarted after adding the template"
    echo ""
    
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_error "Operation cancelled"
        exit 0
    fi
    
    # Add port variables to .env if needed
    if [ -n "$env_additions" ]; then
        print_info "Adding port variables to .env..."
        
        local env_file="$project_path/.env"
        
        # Check if .env exists
        if [ ! -f "$env_file" ]; then
            print_error ".env file not found in project"
            exit 1
        fi
        
        # Add a section header and port variables
        {
            echo ""
            echo "# ============================================"
            echo "# SERVICE TEMPLATE: $template (added $(date +%Y-%m-%d))"
            echo "# ============================================"
            printf "$env_additions"
        } >> "$env_file"
        
        print_success "Port variables added to .env"
    fi
    
    # Backup existing override if needed
    if [ "$backup_needed" = true ]; then
        print_info "Backing up existing override file..."
        cp "$override_file" "$override_file.backup"
        print_success "Backup created: docker-compose.override.yml.backup"
    fi
    
    # Copy template
    print_info "Copying template to project..."
    
    local template_override="$template_path/docker-compose.override.yml"
    local template_readme="$template_path/README.md"
    
    if [ ! -f "$template_override" ]; then
        print_error "Template docker-compose.override.yml not found"
        exit 1
    fi
    
    # If backup exists, merge templates
    if [ "$backup_needed" = true ]; then
        print_info "Merging with existing services..."
        
        # Create a temporary file with merged content
        local temp_file="$override_file.temp"
        
        # Step 1: Copy everything from existing file EXCEPT the networks section
        awk '/^networks:/,0{next} {print}' "$override_file.backup" > "$temp_file"
        
        # Step 2: Add header for new template
        echo "" >> "$temp_file"
        echo "# ============================================" >> "$temp_file"
        echo "# Template: $template (added $(date +%Y-%m-%d))" >> "$temp_file"
        echo "# ============================================" >> "$temp_file"
        
        # Step 3: Extract only the service definition from template (skip 'services:' and 'networks:' lines)
        awk '/^services:/,/^networks:/{if (!/^services:/ && !/^networks:/) print}' "$template_override" >> "$temp_file"
        
        # Step 4: Add back the networks section from the template
        echo "" >> "$temp_file"
        awk '/^networks:/,0{print}' "$template_override" >> "$temp_file"
        
        # Replace original file with merged version
        mv "$temp_file" "$override_file"
        
        print_success "Template merged with existing services"
    else
        # Just copy the template
        cp "$template_override" "$override_file"
        print_success "Template copied successfully"
    fi
    
    # Copy README if available
    if [ -f "$template_readme" ]; then
        cp "$template_readme" "$project_path/SERVICE-${template}-README.md"
        print_success "Documentation copied: SERVICE-${template}-README.md"
    fi
    
    # Restart project
    print_info "Restarting project..."
    cd "$project_path"
    
    $DOCKER_COMPOSE down --remove-orphans 2>/dev/null || true
    $DOCKER_COMPOSE up -d
    
    cd "$SCRIPT_DIR"
    
    print_success "Template '$template' added successfully!"
    echo ""
    print_info "Project: $project"
    echo "URL: https://$project.test"
    echo ""
    
    if [ -f "$project_path/SERVICE-${template}-README.md" ]; then
        print_info "Documentation: projects/$project/SERVICE-${template}-README.md"
    fi
    
    # Show template-specific instructions with dynamic ports
    case $template in
        wp-cron)
            echo ""
            echo "WP-Cron instructions:"
            echo "  • Add to wp-config.php: define('DISABLE_WP_CRON', true);"
            echo "  • View logs: docker logs ${project}-wp-cron -f"
            ;;
        elasticsearch)
            # Extract assigned port from port_assignments
            local es_port=""
            for assignment in "${port_assignments[@]}"; do
                if [[ "$assignment" == "ELASTICSEARCH_PORT="* ]]; then
                    es_port="${assignment#*=}"
                fi
            done
            echo ""
            echo "ElasticSearch instructions:"
            echo "  • HTTP API: http://localhost:${es_port:-9200}"
            echo "  • Host (from containers): elasticsearch:9200"
            echo "  • Check health: curl http://localhost:${es_port:-9200}"
            ;;
        node-worker)
            # Extract assigned port
            local node_port=""
            for assignment in "${port_assignments[@]}"; do
                if [[ "$assignment" == "NODE_WORKER_PORT="* ]]; then
                    node_port="${assignment#*=}"
                fi
            done
            echo ""
            echo "Node.js Worker instructions:"
            echo "  • Edit command in docker-compose.override.yml"
            echo "  • Access: http://localhost:${node_port:-3000}"
            echo "  • Logs: docker logs ${project}-node-worker -f"
            ;;
        redis-commander)
            # Extract assigned port
            local rc_port=""
            for assignment in "${port_assignments[@]}"; do
                if [[ "$assignment" == "REDIS_COMMANDER_PORT="* ]]; then
                    rc_port="${assignment#*=}"
                fi
            done
            echo ""
            echo "Redis Commander instructions:"
            echo "  • Web UI: http://localhost:${rc_port:-8081}"
            echo "  • Browse and manage Redis data"
            ;;
    esac
}

cmd_remove_template() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor remove-template <project> <template>"
        echo ""
        echo "Remove a service template from a project."
        echo ""
        echo "Arguments:"
        echo "  <project>    Project name"
        echo "  <template>   Template name"
        echo ""
        echo "Note: This command will help you remove the template service,"
        echo "but you may need to manually edit docker-compose.override.yml"
        echo "if you have other custom services defined."
        echo ""
        echo "Examples:"
        echo "  ./phpharbor remove-template myblog mailhog"
        exit 0
    fi
    
    local project=$1
    local template=$2
    
    # Validate arguments
    if [ -z "$project" ]; then
        print_error "Project name required"
        echo "Usage: ./phpharbor remove-template <project> <template>"
        exit 1
    fi
    
    if [ -z "$template" ]; then
        print_error "Template name required"
        echo "Usage: ./phpharbor remove-template <project> <template>"
        exit 1
    fi
    
    # Check project exists
    local project_path="$PROJECTS_DIR/$project"
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    # Check if template is actually installed
    local override_file="$project_path/docker-compose.override.yml"
    if [ ! -f "$override_file" ]; then
        print_warning "No custom templates installed in project '$project'"
        echo ""
        print_info "Available templates:"
        echo "  ./phpharbor service templates"
        exit 0
    fi
    
    if ! grep -q "phpharbor.template=$template" "$override_file" 2>/dev/null; then
        print_warning "Template '$template' is not installed in project '$project'"
        echo ""
        print_info "Installed templates:"
        grep "phpharbor.template=" "$override_file" 2>/dev/null | sed 's/.*phpharbor.template=/  • /' || echo "  (none)"
        exit 0
    fi
    
    # Stop and remove container
    print_title "Remove Service Template"
    echo ""
    echo "Project:      $project"
    echo "Template:     $template"
    echo ""
    print_warning "This will stop and remove the template's container"
    print_info "You may need to manually edit docker-compose.override.yml"
    echo ""
    
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_error "Operation cancelled"
        exit 0
    fi
    
    # Determine container name based on template
    local container_name="${project}-${template}"
    
    print_info "Stopping container..."
    docker stop "$container_name" 2>/dev/null || true
    docker rm "$container_name" 2>/dev/null || true
    
    print_success "Container removed"
    
    # Remove README if exists
    local readme_file="$project_path/SERVICE-${template}-README.md"
    if [ -f "$readme_file" ]; then
        rm "$readme_file"
        print_success "Documentation removed"
    fi
    
    echo ""
    print_warning "Manual cleanup required:"
    echo "  1. Edit: projects/$project/docker-compose.override.yml"
    echo "  2. Remove the '$template' service definition"
    echo "  3. Restart: cd projects/$project && docker-compose up -d"
    echo ""
    print_info "Or delete the entire override file if this was the only custom service"
}
