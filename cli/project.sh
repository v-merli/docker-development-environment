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
    echo "This operation will remove containers and volumes (including database)"
    read -p "Type 'yes' to confirm: " confirm
    
    if [ "$confirm" = "yes" ]; then
        cd "$project_path"
        
        # Find all project containers (including those with profiles)
        print_info "Stopping containers..."
        local containers=$(docker ps -aq --filter "name=^${project}-")
        
        if [ -n "$containers" ]; then
            echo "$containers" | xargs docker stop 2>/dev/null || true
            echo "$containers" | xargs docker rm 2>/dev/null || true
        fi
        
        # Remove project volumes
        print_info "Removing volumes..."
        local volumes=$(docker volume ls -q --filter "name=^${project}_")
        if [ -n "$volumes" ]; then
            echo "$volumes" | xargs docker volume rm 2>/dev/null || true
        fi
        
        # Remove network
        local network="${project}_backend"
        docker network rm "$network" 2>/dev/null || true
        
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
