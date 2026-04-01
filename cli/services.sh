#!/bin/bash

# Module: Services
# Commands: add-service, remove-service

# Available services by project type
LARAVEL_SERVICES="queue scheduler redis mysql mariadb"
WORDPRESS_SERVICES="redis mysql mariadb"
PHP_SERVICES="redis mysql mariadb"

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
