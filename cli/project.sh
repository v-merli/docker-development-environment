#!/bin/bash

# Module: Project Management
# Comandi: list, start, stop, restart, remove, logs

show_project_help() {
    echo "Uso: ./docker-dev <comando> [progetto]"
    echo ""
    echo "Comandi:"
    echo "  list                  Elenca tutti i progetti"
    echo "  start <progetto>      Avvia un progetto"
    echo "  stop <progetto>       Ferma un progetto"
    echo "  restart <progetto>    Riavvia un progetto"
    echo "  remove <progetto>     Rimuovi un progetto"
    echo "  logs <progetto> [-f]  Mostra log"
}

cmd_list() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Uso: ./docker-dev list"
        echo ""
        echo "Elenca tutti i progetti con stato (running/stopped), tipo e versione PHP."
        exit 0
    fi
    
    print_title "Progetti Disponibili"
    echo ""
    
    if [ ! -d "$PROJECTS_DIR" ] || [ -z "$(ls -A $PROJECTS_DIR 2>/dev/null)" ]; then
        echo "Nessun progetto trovato"
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
                
                # Verifica se i container sono in esecuzione
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
        echo "Uso: ./docker-dev start <progetto>"
        echo ""
        echo "Avvia tutti i container di un progetto."
        exit 0
    fi
    
    if [ -z "$1" ]; then
        print_error "Specifica il nome del progetto"
        echo "Uso: ./docker-dev start <progetto>"
        exit 1
    fi
    
    local project=$1
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Progetto '$project' non trovato"
        exit 1
    fi
    
    print_info "Avvio progetto $project..."
    cd "$project_path"
    $DOCKER_COMPOSE up -d
    print_success "Progetto $project avviato"
    
    # Mostra URL
    if [ -f ".env" ]; then
        domain=$(grep "^DOMAIN=" ".env" 2>/dev/null | cut -d'=' -f2)
        [ -n "$domain" ] && echo -e "\n${CYAN}→ http://$domain:8080${NC}"
    fi
}

cmd_stop() {
    if [ -z "$1" ]; then
        print_error "Specifica il nome del progetto"
        echo "Uso: ./docker-dev stop <progetto>"
        exit 1
    fi
    
    local project=$1
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Progetto '$project' non trovato"
        exit 1
    fi
    
    print_info "Arresto progetto $project..."
    cd "$project_path"
    $DOCKER_COMPOSE down
    print_success "Progetto $project fermato"
}

cmd_restart() {
    if [ -z "$1" ]; then
        print_error "Specifica il nome del progetto"
        echo "Uso: ./docker-dev restart <progetto>"
        exit 1
    fi
    
    local project=$1
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Progetto '$project' non trovato"
        exit 1
    fi
    
    print_info "Riavvio progetto $project..."
    cd "$project_path"
    $DOCKER_COMPOSE restart
    print_success "Progetto $project riavviato"
}

cmd_remove() {
    if [ -z "$1" ]; then
        print_error "Specifica il nome del progetto"
        echo "Uso: ./docker-dev remove <progetto>"
        exit 1
    fi
    
    local project=$1
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Progetto '$project' non trovato"
        exit 1
    fi
    
    print_warning "Sei sicuro di voler rimuovere il progetto '$project'?"
    echo "Questa operazione rimuoverà i container e i volumi (database incluso)"
    read -p "Digita 'yes' per confermare: " confirm
    
    if [ "$confirm" = "yes" ]; then
        cd "$project_path"
        $DOCKER_COMPOSE down -v
        cd "$SCRIPT_DIR"
        rm -rf "$project_path"
        print_success "Progetto $project rimosso"
    else
        echo "Operazione annullata"
    fi
}

cmd_logs() {
    if [ -z "$1" ]; then
        print_error "Specifica il nome del progetto"
        echo "Uso: ./docker-dev logs <progetto> [-f]"
        exit 1
    fi
    
    local project=$1
    shift
    local project_path="$PROJECTS_DIR/$project"
    
    if [ ! -d "$project_path" ]; then
        print_error "Progetto '$project' non trovato"
        exit 1
    fi
    
    cd "$project_path"
    $DOCKER_COMPOSE logs "$@"
}
