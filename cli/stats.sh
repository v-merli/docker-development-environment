#!/bin/bash

# Module: Stats
# Commands: stats disk

cmd_stats() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./phpharbor stats <command> [options]"
        echo ""
        echo "Display real-time statistics about PHPHarbor resource usage."
        echo ""
        echo "Commands:"
        echo "  disk              Show disk usage analysis (default)"
        echo "  disk --detailed   Detailed breakdown per project"
        echo "  disk --compare    Compare shared vs dedicated architecture"
        echo "  disk --cleanup    Interactive cleanup of orphan volumes and images"
        echo ""
        echo "Examples:"
        echo "  ./phpharbor stats disk              # Basic disk analysis"
        echo "  ./phpharbor stats disk --detailed   # Per-project breakdown"
        echo "  ./phpharbor stats disk --compare    # Savings simulation"
        echo "  ./phpharbor stats disk --cleanup    # Remove orphan volumes"
        exit 0
    fi
    
    local subcmd=$1
    shift
    
    case $subcmd in
        disk)
            stats_disk "$@"
            ;;
        "")
            # Default to disk stats
            stats_disk "$@"
            ;;
        *)
            echo "Unknown stats command: $subcmd"
            echo "Run './phpharbor stats --help' for available commands."
            exit 1
            ;;
    esac
}

stats_disk() {
    local detailed=false
    local compare=false
    local cleanup=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --detailed)
                detailed=true
                shift
                ;;
            --compare)
                compare=true
                shift
                ;;
            --cleanup)
                cleanup=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # If cleanup mode, run cleanup and exit
    if [ "$cleanup" = true ]; then
        stats_cleanup_orphans
        return
    fi
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     ANALISI CONSUMO DISCO PHPHARBOR (Real-time)           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # System overview
    echo -e "${YELLOW}📊 Panoramica sistema Docker:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    docker system df
    echo ""
    
    # PHPHarbor images
    echo -e "${YELLOW}🐳 Immagini PHPHarbor:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -1
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | \
        grep -E "(php-harbor|phpharbor|mysql.*shared|redis.*shared|nginx-proxy)" | sort
    echo ""
    
    # Shared volumes (only official shared services)
    echo -e "${YELLOW}💾 Volumi shared (servizi ufficiali):${NC}"
    echo "─────────────────────────────────────────────────────────────"
    local shared_volumes=$(docker volume ls --format "{{.Name}}" | grep -E "^(mysql_[0-9_]+_shared_data|redis_[0-9]+_shared_data|php_[0-9_]+_shared_data)$")
    
    if [ -n "$shared_volumes" ]; then
        echo "Volume Name                    Containers"
        echo "────────────────────────────   ──────────"
        echo "$shared_volumes" | while read vol; do
            containers=$(docker ps -a --filter volume=$vol --format "{{.Names}}" | wc -l | tr -d ' ')
            printf "%-30s %s\n" "$vol" "$containers"
        done
    else
        echo "  Nessun volume shared trovato"
    fi
    echo ""
    
    # Check for orphan volumes
    local orphan_count=$(docker volume ls -q | while read vol; do 
        containers=$(docker ps -a --filter volume=$vol -q | wc -l | tr -d ' ')
        if [ "$containers" -eq 0 ]; then echo "1"; fi
    done | wc -l | tr -d ' ')
    
    if [ "$orphan_count" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Volumi orfani (non collegati a container): ${orphan_count}${NC}"
        echo "─────────────────────────────────────────────────────────────"
        docker volume ls -q | while read vol; do 
            containers=$(docker ps -a --filter volume=$vol -q | wc -l | tr -d ' ')
            if [ "$containers" -eq 0 ]; then
                # Try to get size (may not work on macOS)
                echo "  • $vol"
            fi
        done | head -10
        
        if [ "$orphan_count" -gt 10 ]; then
            echo "  ... e altri $((orphan_count - 10)) volumi"
        fi
        
        echo ""
        echo -e "${BLUE}💡 Pulisci con: ./phpharbor stats disk --cleanup${NC}"
        echo ""
    fi
    
    # Check for orphan project images
    echo -e "${YELLOW}🖼️  Immagini progetti:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    
    # Get existing projects
    local existing_projects=()
    if [ -d "$PROJECTS_DIR" ]; then
        while IFS= read -r project_dir; do
            if [ -d "$project_dir" ]; then
                existing_projects+=("$(basename "$project_dir")")
            fi
        done < <(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d)
    fi
    
    # Find project images (looking for *-app pattern)
    local project_images=$(docker images --format "{{.Repository}}" | grep -E ".*-app$" | grep -v -E "^(php-.*-shared|mysql-.*-shared|redis-.*-shared)" | sort -u)
    local orphan_images=()
    
    if [ -n "$project_images" ]; then
        while IFS= read -r img_repo; do
            # Extract project name from image (remove -app suffix)
            local img_project=$(echo "$img_repo" | sed 's/-app$//')
            
            # Check if project exists
            local project_exists=false
            for existing_proj in "${existing_projects[@]}"; do
                if [ "$existing_proj" = "$img_project" ]; then
                    project_exists=true
                    break
                fi
            done
            
            if [ "$project_exists" = false ]; then
                orphan_images+=("$img_repo")
            fi
        done <<< "$project_images"
    fi
    
    if [ ${#orphan_images[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Immagini orfane (progetti non più esistenti): ${#orphan_images[@]}${NC}"
        local total_size=0
        for img in "${orphan_images[@]}"; do
            local size=$(docker images "$img" --format "{{.Size}}")
            echo "  • $img ($size)"
        done
        echo ""
        echo -e "${BLUE}💡 Pulisci con: ./phpharbor stats disk --cleanup${NC}"
    else
        echo "  Nessuna immagine orfana trovata ✓"
    fi
    echo ""
    
    # Projects count
    local projects_count=0
    if [ -d "$PROJECTS_DIR" ]; then
        projects_count=$(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    # Containers count
    local containers_count=$(docker ps -a --filter "name=phpharbor" --format "{{.Names}}" 2>/dev/null | wc -l | tr -d ' ')
    local containers_running=$(docker ps --filter "name=phpharbor" --format "{{.Names}}" 2>/dev/null | wc -l | tr -d ' ')
    
    echo -e "${YELLOW}📁 Statistiche progetti:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    echo "  Progetti totali:      $projects_count"
    echo "  Container totali:     $containers_count"
    echo "  Container attivi:     $containers_running"
    echo ""
    
    # Detailed breakdown per project
    if [ "$detailed" = true ] && [ $projects_count -gt 0 ]; then
        echo -e "${YELLOW}🔍 Dettaglio per progetto:${NC}"
        echo "─────────────────────────────────────────────────────────────"
        
        for project_dir in "$PROJECTS_DIR"/*/ ; do
            if [ -d "$project_dir" ]; then
                local project_name=$(basename "$project_dir")
                local app_size=$(du -sh "$project_dir" 2>/dev/null | cut -f1)
                
                # Check if project has dedicated containers
                local dedicated_containers=$(docker ps -a --filter "name=${project_name}" --format "{{.Names}}" 2>/dev/null | wc -l | tr -d ' ')
                
                echo "  📦 $project_name"
                echo "      App files:        $app_size"
                echo "      Containers:       $dedicated_containers"
                
                # Check project type from .env
                if [ -f "$project_dir/.env" ]; then
                    local project_type=$(grep "^PROJECT_TYPE=" "$project_dir/.env" 2>/dev/null | cut -d'=' -f2)
                    local php_shared=$(grep "^PHP_SHARED=" "$project_dir/.env" 2>/dev/null | cut -d'=' -f2)
                    local mysql_shared=$(grep "^MYSQL_SHARED=" "$project_dir/.env" 2>/dev/null | cut -d'=' -f2)
                    
                    echo "      Type:             ${project_type:-unknown}"
                    echo "      PHP shared:       ${php_shared:-false}"
                    echo "      MySQL shared:     ${mysql_shared:-false}"
                fi
                echo ""
            fi
        done
    fi
    
    # Savings calculation
    if [ "$compare" = true ] || [ $projects_count -gt 1 ]; then
        echo -e "${YELLOW}💰 Stima risparmio architettura shared:${NC}"
        echo "─────────────────────────────────────────────────────────────"
        
        if [ $projects_count -eq 0 ]; then
            echo "  Nessun progetto trovato per calcolare il risparmio"
        else
            # Estimates in MB (based on actual measurements)
            local dedicated_per_project=2350  # MB per project (all dedicated)
            local shared_per_project=150      # MB per project (only app files)
            local shared_infrastructure=2170  # MB (one-time shared services)
            
            local dedicated_total=$((projects_count * dedicated_per_project))
            local shared_total=$((projects_count * shared_per_project + shared_infrastructure))
            local saving=$((dedicated_total - shared_total))
            local percent=0
            
            if [ $dedicated_total -gt 0 ]; then
                percent=$((saving * 100 / dedicated_total))
            fi
            
            echo "  Progetti analizzati:  $projects_count"
            echo ""
            echo "  TUTTI DEDICATI:"
            echo "    ${projects_count} progetti × 2.35 GB = $(echo "scale=2; $dedicated_total / 1000" | bc) GB"
            echo ""
            echo "  TUTTI SHARED:"
            echo "    App files:    ${projects_count} × 0.15 GB = $(echo "scale=2; $projects_count * 150 / 1000" | bc) GB"
            echo "    Infra shared: (una tantum) = 2.17 GB"
            echo "    ─────────────────────────────────"
            echo "    Totale:       $(echo "scale=2; $shared_total / 1000" | bc) GB"
            echo ""
            echo -e "  ${GREEN}✨ RISPARMIO: $(echo "scale=2; $saving / 1000" | bc) GB (${percent}%)${NC}"
            echo ""
            
            # RAM estimation
            local ram_dedicated=$((projects_count * 600))  # ~600 MB per project
            local ram_shared=650  # ~650 MB total infrastructure
            local ram_saving=$((ram_dedicated - ram_shared))
            
            if [ $projects_count -gt 1 ]; then
                echo "  📊 Bonus - Stima risparmio RAM:"
                echo "    Dedicato:   $(echo "scale=2; $ram_dedicated / 1000" | bc) GB"
                echo "    Shared:     $(echo "scale=2; $ram_shared / 1000" | bc) GB"
                echo -e "    ${GREEN}Risparmio:  $(echo "scale=2; $ram_saving / 1000" | bc) GB${NC}"
                echo ""
            fi
            
            # Recommendations
            if [ $projects_count -eq 1 ]; then
                echo -e "  ${BLUE}💡 Con 1 progetto, la differenza è minima${NC}"
                echo "     Considera shared per facilità di gestione"
            elif [ $projects_count -lt 5 ]; then
                echo -e "  ${BLUE}💡 Con $projects_count progetti, risparmio moderato${NC}"
                echo "     Shared conviene già da 2+ progetti"
            else
                echo -e "  ${GREEN}💡 Con $projects_count progetti, risparmio significativo!${NC}"
                echo "     Shared è altamente consigliato (75%+ risparmio)"
            fi
        fi
        echo ""
    fi
    
    # Quick tips
    echo -e "${YELLOW}💡 Suggerimenti:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    echo "  • Usa --detailed per vedere breakdown per progetto"
    echo "  • Usa --compare per simulazione risparmio shared vs dedicato"
    echo "  • Usa --cleanup per rimuovere volumi e immagini orfane"
    echo "  • docker image prune -a pulisce tutte le immagini non usate"
    echo "  • docker volume prune pulisce i volumi dangling"
    echo ""
}

stats_cleanup_orphans() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     PULIZIA RISORSE ORFANE                                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Find orphan volumes
    local orphan_volumes=()
    while IFS= read -r vol; do
        containers=$(docker ps -a --filter volume=$vol -q | wc -l | tr -d ' ')
        if [ "$containers" -eq 0 ]; then
            orphan_volumes+=("$vol")
        fi
    done < <(docker volume ls -q)
    
    # Find orphan images
    local existing_projects=()
    if [ -d "$PROJECTS_DIR" ]; then
        while IFS= read -r project_dir; do
            if [ -d "$project_dir" ]; then
                existing_projects+=("$(basename "$project_dir")")
            fi
        done < <(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d)
    fi
    
    local project_images=$(docker images --format "{{.Repository}}" | grep -E ".*-app$" | grep -v -E "^(php-.*-shared|mysql-.*-shared|redis-.*-shared)" | sort -u)
    local orphan_images=()
    
    if [ -n "$project_images" ]; then
        while IFS= read -r img_repo; do
            local img_project=$(echo "$img_repo" | sed 's/-app$//')
            local project_exists=false
            for existing_proj in "${existing_projects[@]}"; do
                if [ "$existing_proj" = "$img_project" ]; then
                    project_exists=true
                    break
                fi
            done
            if [ "$project_exists" = false ]; then
                orphan_images+=("$img_repo")
            fi
        done <<< "$project_images"
    fi
    
    # Show summary
    if [ ${#orphan_volumes[@]} -eq 0 ] && [ ${#orphan_images[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ Nessuna risorsa orfana trovata!${NC}"
        echo ""
        return
    fi
    
    if [ ${#orphan_volumes[@]} -gt 0 ]; then
        echo -e "${YELLOW}📦 Volumi orfani trovati: ${#orphan_volumes[@]}${NC}"
        echo "─────────────────────────────────────────────────────────────"
        for vol in "${orphan_volumes[@]}"; do
            echo "  • $vol"
        done
        echo ""
    fi
    
    if [ ${#orphan_images[@]} -gt 0 ]; then
        echo -e "${YELLOW}🖼️  Immagini orfane trovate: ${#orphan_images[@]}${NC}"
        echo "─────────────────────────────────────────────────────────────"
        for img in "${orphan_images[@]}"; do
            local size=$(docker images "$img" --format "{{.Size}}")
            echo "  • $img ($size)"
        done
        echo ""
    fi
    
    echo -e "${RED}⚠️  ATTENZIONE: Questa operazione eliminerà TUTTE le risorse orfane!${NC}"
    echo "   • Volumi: I dati contenuti saranno persi permanentemente"
    echo "   • Immagini: Dovranno essere ricostruite se necessarie"
    echo ""
    
    read -p "Vuoi procedere? (si/no): " confirm
    
    if [[ "$confirm" == "si" ]] || [[ "$confirm" == "s" ]] || [[ "$confirm" == "yes" ]] || [[ "$confirm" == "y" ]]; then
        echo ""
        
        # Remove volumes
        if [ ${#orphan_volumes[@]} -gt 0 ]; then
            echo -e "${YELLOW}Eliminazione volumi in corso...${NC}"
            local removed_vols=0
            local failed_vols=0
            
            for vol in "${orphan_volumes[@]}"; do
                if docker volume rm "$vol" >/dev/null 2>&1; then
                    echo -e "  ${GREEN}✓${NC} Rimosso volume: $vol"
                    ((removed_vols++))
                else
                    echo -e "  ${RED}✗${NC} Errore volume: $vol"
                    ((failed_vols++))
                fi
            done
            echo ""
        fi
        
        # Remove images
        if [ ${#orphan_images[@]} -gt 0 ]; then
            echo -e "${YELLOW}Eliminazione immagini in corso...${NC}"
            local removed_imgs=0
            local failed_imgs=0
            
            for img in "${orphan_images[@]}"; do
                if docker rmi "$img" >/dev/null 2>&1; then
                    echo -e "  ${GREEN}✓${NC} Rimossa immagine: $img"
                    ((removed_imgs++))
                else
                    echo -e "  ${RED}✗${NC} Errore immagine: $img"
                    ((failed_imgs++))
                fi
            done
            echo ""
        fi
        
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ Pulizia completata!${NC}"
        echo ""
        
        if [ ${#orphan_volumes[@]} -gt 0 ]; then
            echo "  Volumi rimossi:    ${removed_vols:-0}"
            if [ ${failed_vols:-0} -gt 0 ]; then
                echo "  Volumi falliti:    $failed_vols"
            fi
        fi
        
        if [ ${#orphan_images[@]} -gt 0 ]; then
            echo "  Immagini rimosse:  ${removed_imgs:-0}"
            if [ ${failed_imgs:-0} -gt 0 ]; then
                echo "  Immagini fallite:  $failed_imgs"
            fi
        fi
        echo ""
        
        # Show space reclaimed
        echo "💾 Per vedere lo spazio recuperato:"
        echo "   docker system df"
        echo ""
    else
        echo ""
        echo -e "${BLUE}ℹ️  Operazione annullata${NC}"
        echo ""
    fi
}
