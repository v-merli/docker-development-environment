#!/bin/bash

# Module: Project Management
# Commands: list, start, stop, restart, remove, logs

show_project_help() {
    echo "Usage: ./phpharbor <command> [project]"
    echo ""
    echo "Commands:"
    echo "  list                  List all projects"
    echo "  start <project>       Start a project"
    echo "  stop <project>        Stop a project"
    echo "  restart <project>     Restart a project"
    echo "  remove <project>      Remove a project"
    echo "  logs <project> [-f]   Show logs"
}

cmd_list() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor list"
        echo ""
        echo "List all projects with status (running/stopped), type and PHP version."
        exit 0
    fi
    
    print_title "Available Projects"
    echo ""
    
    if [ ! -d "$PROJECTS_DIR" ] || [ -z "$(ls -A $PROJECTS_DIR 2>/dev/null)" ]; then
        echo "No projects found"
        return
    fi
    
    for dir in "$PROJECTS_DIR"/*/ ; do
        if [ -d "$dir" ]; then
            project=$(basename "$dir")
            env_file="$dir/.env"
            
            if [ -f "$env_file" ]; then
                domain=$(grep "^DOMAIN=" "$env_file" 2>/dev/null | cut -d'=' -f2)
                php_version=$(grep "^PHP_VERSION=" "$env_file" 2>/dev/null | cut -d'=' -f2)
                project_type=$(grep "^PROJECT_TYPE=" "$env_file" 2>/dev/null | cut -d'=' -f2)
                
                # Check if containers are running
                cd "$dir"
                if $DOCKER_COMPOSE ps 2>/dev/null | grep -q "Up"; then
                    status="${GREEN}●${NC} Running"
                else
                    status="○ Stopped"
                fi
                
                echo -e "$status  ${CYAN}$project${NC}"
                [ -n "$domain" ] && echo "       URL: http://$domain:8080"
                [ -n "$project_type" ] && echo "       Type: $project_type"
                [ -n "$php_version" ] && echo "       PHP: $php_version"
                echo ""
            fi
        fi
    done
}

cmd_start() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor start <project>"
        echo ""
        echo "Start all containers of a project."
        exit 0
    fi
    
    if [ -z "$1" ]; then
        print_error "Specify the project name"
        echo "Usage: ./phpharbor start <project>"
        exit 1
    fi
    
    local project=$1
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    print_info "Starting project $project..."
    cd "$project_path"
    $DOCKER_COMPOSE up -d
    print_success "Project $project started"
    
    # Show URL
    if [ -f ".env" ]; then
        domain=$(grep "^DOMAIN=" ".env" 2>/dev/null | cut -d'=' -f2)
        [ -n "$domain" ] && echo -e "\n${CYAN}→ http://$domain:8080${NC}"
    fi
}

cmd_stop() {
    if [ -z "$1" ]; then
        print_error "Specify the project name"
        echo "Usage: ./phpharbor stop <project>"
        exit 1
    fi
    
    local project=$1
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    print_info "Stopping project $project..."
    cd "$project_path"
    $DOCKER_COMPOSE down
    print_success "Project $project stopped"
}

cmd_restart() {
    if [ -z "$1" ]; then
        print_error "Specify the project name"
        echo "Usage: ./phpharbor restart <project>"
        exit 1
    fi
    
    local project=$1
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    print_info "Restarting project $project..."
    cd "$project_path"
    $DOCKER_COMPOSE restart
    print_success "Project $project restarted"
}

cmd_remove() {
    if [ -z "$1" ]; then
        print_error "Specify the project name"
        echo "Usage: ./phpharbor remove <project>"
        exit 1
    fi
    
    local project=$1
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    print_warning "Are you sure you want to remove project '$project'?"
    echo "This operation will remove:"
    echo "  • Containers and Docker volumes"
    echo "  • Local volume directories (database data in volumes/)"
    echo "  • Docker images (PHP app)"
    echo "  • SSL certificates"
    echo "  • Project files"
    read -p "Type 'yes' to confirm: " confirm
    
    if [ "$confirm" = "yes" ]; then
        cd "$project_path"
        
        # Find all project containers using Docker label
        print_info "Stopping containers..."
        local containers=$(docker ps -aq --filter "label=com.docker.compose.project=phpharbor-app-$project")
        
        if [ -n "$containers" ]; then
            echo "$containers" | xargs docker stop 2>/dev/null || true
            echo "$containers" | xargs docker rm 2>/dev/null || true
        fi
        
        # Remove project volumes (Docker named volumes)
        print_info "Removing Docker volumes..."
        local volumes=$(docker volume ls -q --filter "name=^${project}_")
        if [ -n "$volumes" ]; then
            echo "$volumes" | xargs docker volume rm 2>/dev/null || true
        fi
        
        # Remove local volume directories
        print_info "Removing local volume directories..."
        local volumes_removed=0
        
        if [ -d "$SCRIPT_DIR/volumes/mysql/$project" ]; then
            rm -rf "$SCRIPT_DIR/volumes/mysql/$project"
            echo "  Removed: volumes/mysql/$project"
            volumes_removed=$((volumes_removed + 1))
        fi
        
        if [ -d "$SCRIPT_DIR/volumes/mariadb/$project" ]; then
            rm -rf "$SCRIPT_DIR/volumes/mariadb/$project"
            echo "  Removed: volumes/mariadb/$project"
            volumes_removed=$((volumes_removed + 1))
        fi
        
        if [ -d "$SCRIPT_DIR/volumes/redis/$project" ]; then
            rm -rf "$SCRIPT_DIR/volumes/redis/$project"
            echo "  Removed: volumes/redis/$project"
            volumes_removed=$((volumes_removed + 1))
        fi
        
        if [ -d "$SCRIPT_DIR/volumes/other/$project" ]; then
            rm -rf "$SCRIPT_DIR/volumes/other/$project"
            echo "  Removed: volumes/other/$project"
            volumes_removed=$((volumes_removed + 1))
        fi
        
        if [ $volumes_removed -eq 0 ]; then
            echo "  No local volumes found"
        else
            print_success "Removed $volumes_removed local volume director$([ $volumes_removed -eq 1 ] && echo 'y' || echo 'ies')"
        fi
        
        # Remove network
        local network="${project}_backend"
        docker network rm "$network" 2>/dev/null || true
        
        # Clean SSL/ACME certificates
        print_info "Cleaning SSL certificates..."
        local domain="${project}.test"
        local acme_base="$SCRIPT_DIR/proxy/nginx/acme"
        local mkcert_dir="$SCRIPT_DIR/proxy/nginx/certs"
        
        # Remove ACME certificates from staging
        if [ -d "$acme_base/staging/$domain" ]; then
            rm -rf "$acme_base/staging/$domain"
        fi
        
        # Remove ACME certificates from dev@localhost
        if [ -d "$acme_base/dev@localhost/$domain" ]; then
            rm -rf "$acme_base/dev@localhost/$domain"
        fi
        
        # Remove mkcert certificates
        if [ -f "$mkcert_dir/$domain.crt" ]; then
            rm -f "$mkcert_dir/$domain.crt"
            rm -f "$mkcert_dir/$domain.key"
            rm -f "$mkcert_dir/$domain.chain.pem"
        fi
        
        # Remove ACME directory from nginx/certs
        if [ -d "$mkcert_dir/_test_$domain" ]; then
            rm -rf "$mkcert_dir/_test_$domain"
        fi
        
        print_success "SSL certificates removed"
        
        # Remove Docker images
        print_info "Removing Docker images..."
        local images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^${project}-")
        if [ -n "$images" ]; then
            echo "$images" | while read img; do
                docker rmi "$img" 2>/dev/null || true
                echo "  Removed: $img"
            done
            print_success "Docker images removed"
        else
            echo "  No custom images found"
        fi
        
        cd "$SCRIPT_DIR"
        rm -rf "$project_path"
        print_success "Project $project removed"
    else
        echo "Operation cancelled"
    fi
}

cmd_logs() {
    if [ -z "$1" ]; then
        print_error "Specify the project name"
        echo "Usage: ./phpharbor logs <project> [-f]"
        exit 1
    fi
    
    local project=$1
    shift
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project '$project' not found"
        exit 1
    fi
    
    cd "$project_path"
    $DOCKER_COMPOSE logs "$@"
}
