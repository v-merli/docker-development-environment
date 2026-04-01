# Funzione per convertire byte in formato human readable (compatibile macOS/Linux)
human_size() {
    local bytes=$1
    local kib=1024
    local mib=$((kib * 1024))
    local gib=$((mib * 1024))
    if [ "$bytes" -ge $gib ]; then
        echo "$(echo "scale=2; $bytes / $gib" | bc)G"
    elif [ "$bytes" -ge $mib ]; then
        echo "$(echo "scale=2; $bytes / $mib" | bc)M"
    elif [ "$bytes" -ge $kib ]; then
        echo "$(echo "scale=2; $bytes / $kib" | bc)K"
    else
        echo "${bytes}B"
    fi
}
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
    echo -e "${CYAN}║     PHPHARBOR DISK USAGE ANALYSIS (Real-time)              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # System overview
    echo -e "${YELLOW}📊 Docker system overview:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    docker system df
    echo ""
    
        # PHPHarbor images (from containers with compose project 'phpharbor-proxy')
        echo -e "${YELLOW}🐳 PHPHarbor images (phpharbor-proxy):${NC}"
        echo "─────────────────────────────────────────────────────────────"
        printf "%-30s %-15s %-15s\n" "REPOSITORY" "TAG" "SIZE"
        docker ps -a --filter 'label=phpharbor.project=phpharbor-proxy' --format '{{.Image}}' | \
            sort | uniq | \
            while read img; do
                if [[ "$img" == *:* ]]; then
                    repo="${img%%:*}"
                    tag="${img#*:}"
                else
                    repo="$img"
                    tag="latest"
                fi
                found=$(docker images --format '{{.Repository}}\t{{.Tag}}\t{{.Size}}' | awk -v r="$repo" -v t="$tag" -F'\t' '$1==r && $2==t {print $0}')
                if [ -n "$found" ]; then
                    printf "%-30s %-15s %-15s\n" "$repo" "$tag" "$(echo "$found" | awk -F'\t' '{print $3}')"
                else
                    printf "%-30s %-15s %-15s\n" "$repo" "$tag" "(image not found)"
                fi
            done
        echo ""
    
    # Shared volumes (only official shared services)
    echo -e "${YELLOW}💾 Shared volumes (official services):${NC}"
    echo "─────────────────────────────────────────────────────────────"
    local shared_volumes=$(docker volume ls --format "{{.Name}}" | grep -E "^(mysql_[0-9_]+_shared_data|mariadb_[0-9_]+_shared_data|redis_[0-9]+_shared_data|php_[0-9_]+_shared_data)$")
    
    if [ -n "$shared_volumes" ]; then
        echo "Volume Name                    Containers"
        echo "────────────────────────────   ──────────"
        echo "$shared_volumes" | while read vol; do
            containers=$(docker ps -a --filter volume=$vol --format "{{.Names}}" | wc -l | tr -d ' ')
            printf "%-30s %s\n" "$vol" "$containers"
        done
    else
        echo "  No shared volume found"
    fi
    echo ""

    # Bind mount locali per database
    echo -e "${YELLOW}🗄️  Database bind mounts (volumes/):${NC}"
    echo "─────────────────────────────────────────────────────────────"
    if [ -d "$PROJECTS_DIR/../volumes" ]; then
        find "$PROJECTS_DIR/../volumes" -mindepth 1 -maxdepth 1 -type d | while read dbdir; do
            dbtype=$(basename "$dbdir")
            echo "  $dbtype:"
            total_bytes=0
            if [ -d "$dbdir" ]; then
                for path in "$dbdir"/*; do
                    [ -e "$path" ] || continue
                    # du -sk restituisce la dimensione in KB (compatibile macOS/Linux)
                    kb=$(du -sk "$path" 2>/dev/null | awk '{print $1}')
                    bytes=$((kb * 1024))
                    mountname=$(basename "$path")
                    total_bytes=$((total_bytes + bytes))
                    # Mostra sempre in formato human readable (K, M, G)
                    size_human=$(human_size "$bytes")
                    printf "    %-20s %10s\n" "$mountname" "$size_human"
                done
                if [ "$total_bytes" -gt 0 ]; then
                    total_human=$(human_size "$total_bytes")
                    printf "    %-20s %10s\n" "TOTAL" "$total_human"
                fi
            else
                echo "    (nessun dato)"
            fi
            echo ""
        done
    else
        echo "  Nessuna directory volumes/ trovata"
    fi
    echo ""
    
    # Check for orphan volumes
    local orphan_count=$(docker volume ls -q | while read vol; do 
        containers=$(docker ps -a --filter volume=$vol -q | wc -l | tr -d ' ')
        if [ "$containers" -eq 0 ]; then echo "1"; fi
    done | wc -l | tr -d ' ')
    
    if [ "$orphan_count" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Orphan volumes (not attached to any container): ${orphan_count}${NC}"
        echo "─────────────────────────────────────────────────────────────"
        docker volume ls -q | while read vol; do 
            containers=$(docker ps -a --filter volume=$vol -q | wc -l | tr -d ' ')
            if [ "$containers" -eq 0 ]; then
                # Try to get size (may not work on macOS)
                echo "  • $vol"
            fi
        done | head -10
        
        if [ "$orphan_count" -gt 10 ]; then
            echo "  ... and $((orphan_count - 10)) more volumes"
        fi
        
        echo ""
        echo -e "${BLUE}💡 Clean up with: ./phpharbor stats disk --cleanup${NC}"
        echo ""
    fi
    
    # Check for orphan project images
    echo -e "${YELLOW}🖼️  Project images:${NC}"
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
    local project_images=$(docker images --format "{{.Repository}}" | grep -E ".*-(app|nginx)$" | grep -v -E "^(php-.*-shared|mysql-.*-shared|mariadb-.*-shared|redis-.*-shared|nginx-proxy)" | sort -u)
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
        echo -e "${YELLOW}⚠️  Orphan images (projects no longer exist): ${#orphan_images[@]}${NC}"
        local total_size=0
        for img in "${orphan_images[@]}"; do
            local size=$(docker images "$img" --format "{{.Size}}")
            echo "  • $img ($size)"
        done
        echo ""
        echo -e "${BLUE}💡 Clean up with: ./phpharbor stats disk --cleanup${NC}"
    else
        echo "  No orphan image found ✓"
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
    
    echo -e "${YELLOW}📁 Project statistics:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    echo "  Total projects:      $projects_count"
    echo "  Total containers:    $containers_count"
    echo "  Running containers:  $containers_running"
    echo ""
    
    # Detailed breakdown per project
    if [ "$detailed" = true ] && [ $projects_count -gt 0 ]; then
        echo -e "${YELLOW}🔍 Project breakdown:${NC}"
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
        echo -e "${YELLOW}💰 Estimated savings with shared architecture:${NC}"
        echo "─────────────────────────────────────────────────────────────"
        
        if [ $projects_count -eq 0 ]; then
            echo "  No project found to calculate savings"
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
            
            echo "  Projects analyzed:  $projects_count"
            echo ""
            echo "  ALL DEDICATED:"
            echo "    ${projects_count} projects × 2.35 GB = $(echo "scale=2; $dedicated_total / 1000" | bc) GB"
            echo ""
            echo "  ALL SHARED:"
            echo "    App files:    ${projects_count} × 0.15 GB = $(echo "scale=2; $projects_count * 150 / 1000" | bc) GB"
            echo "    Shared infra: (one-time) = 2.17 GB"
            echo "    ─────────────────────────────────"
            echo "    Total:        $(echo "scale=2; $shared_total / 1000" | bc) GB"
            echo ""
            echo -e "  ${GREEN}✨ SAVINGS: $(echo "scale=2; $saving / 1000" | bc) GB (${percent}%)${NC}"
            echo ""
            
            # RAM estimation
            local ram_dedicated=$((projects_count * 600))  # ~600 MB per project
            local ram_shared=650  # ~650 MB total infrastructure
            local ram_saving=$((ram_dedicated - ram_shared))
            
            if [ $projects_count -gt 1 ]; then
                echo "  📊 Bonus - Estimated RAM savings:"
                echo "    Dedicated:   $(echo "scale=2; $ram_dedicated / 1000" | bc) GB"
                echo "    Shared:      $(echo "scale=2; $ram_shared / 1000" | bc) GB"
                echo -e "    ${GREEN}Savings:  $(echo "scale=2; $ram_saving / 1000" | bc) GB${NC}"
                echo ""
            fi
            
            # Recommendations
            if [ $projects_count -eq 1 ]; then
                echo -e "  ${BLUE}💡 With 1 project, the difference is minimal${NC}"
                echo "     Consider shared for easier management"
            elif [ $projects_count -lt 5 ]; then
                echo -e "  ${BLUE}💡 With $projects_count projects, moderate savings${NC}"
                echo "     Shared is already worth it from 2+ projects"
            else
                echo -e "  ${GREEN}💡 With $projects_count projects, significant savings!${NC}"
                echo "     Shared is highly recommended (75%+ savings)"
            fi
        fi
        echo ""
    fi
    
    # Quick tips
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    echo "  • Use --detailed to see per-project breakdown"
    echo "  • Use --compare for shared vs dedicated savings simulation"
    echo "  • Use --cleanup to remove orphan volumes and images"
    echo "  • docker image prune -a cleans all unused images"
    echo "  • docker volume prune cleans dangling volumes"
    echo ""
}

stats_cleanup_orphans() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     ORPHAN RESOURCE CLEANUP                                ║${NC}"
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
    
    local project_images=$(docker images --format "{{.Repository}}" | grep -E ".*-(app|nginx)$" | grep -v -E "^(php-.*-shared|mysql-.*-shared|mariadb-.*-shared|redis-.*-shared|nginx-proxy)" | sort -u)
    local orphan_images=()
    
    if [ -n "$project_images" ]; then
        while IFS= read -r img_repo; do
            # Extract project name from image (remove -app or -nginx suffix)
            local img_project=$(echo "$img_repo" | sed -E 's/-(app|nginx)$//')
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
        echo -e "${GREEN}✅ No orphan resource found!${NC}"
        echo ""
        return
    fi
    
    if [ ${#orphan_volumes[@]} -gt 0 ]; then
        echo -e "${YELLOW}📦 Orphan volumes found: ${#orphan_volumes[@]}${NC}"
        echo "─────────────────────────────────────────────────────────────"
        for vol in "${orphan_volumes[@]}"; do
            echo "  • $vol"
        done
        echo ""
    fi
    
    if [ ${#orphan_images[@]} -gt 0 ]; then
        echo -e "${YELLOW}🖼️  Orphan images found: ${#orphan_images[@]}${NC}"
        echo "─────────────────────────────────────────────────────────────"
        for img in "${orphan_images[@]}"; do
            local size=$(docker images "$img" --format "{{.Size}}")
            echo "  • $img ($size)"
        done
        echo ""
    fi
    
    echo -e "${RED}⚠️  WARNING: This operation will delete ALL orphan resources!${NC}"
    echo "   • Volumes: Data will be lost permanently"
    echo "   • Images: Will need to be rebuilt if needed"
    echo ""
    
    read -p "Do you want to proceed? (yes/no): " confirm
    
    if [[ "$confirm" == "si" ]] || [[ "$confirm" == "s" ]] || [[ "$confirm" == "yes" ]] || [[ "$confirm" == "y" ]]; then
        echo ""
        
        # Remove volumes
        if [ ${#orphan_volumes[@]} -gt 0 ]; then
            echo -e "${YELLOW}Removing volumes...${NC}"
            local removed_vols=0
            local failed_vols=0
            
            for vol in "${orphan_volumes[@]}"; do
                if docker volume rm "$vol" >/dev/null 2>&1; then
                    echo -e "  ${GREEN}✓${NC} Removed volume: $vol"
                    ((removed_vols++))
                else
                    echo -e "  ${RED}✗${NC} Error volume: $vol"
                    ((failed_vols++))
                fi
            done
            echo ""
        fi
        
        # Remove images
        if [ ${#orphan_images[@]} -gt 0 ]; then
            echo -e "${YELLOW}Removing images...${NC}"
            local removed_imgs=0
            local failed_imgs=0
            
            for img in "${orphan_images[@]}"; do
                if docker rmi "$img" >/dev/null 2>&1; then
                    echo -e "  ${GREEN}✓${NC} Removed image: $img"
                    ((removed_imgs++))
                else
                    echo -e "  ${RED}✗${NC} Error image: $img"
                    ((failed_imgs++))
                fi
            done
            echo ""
        fi
        
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ Cleanup completed!${NC}"
        echo ""
        
        if [ ${#orphan_volumes[@]} -gt 0 ]; then
            echo "  Volumes removed:    ${removed_vols:-0}"
            if [ ${failed_vols:-0} -gt 0 ]; then
                echo "  Volumes failed:     $failed_vols"
            fi
        fi
        
        if [ ${#orphan_images[@]} -gt 0 ]; then
            echo "  Images removed:     ${removed_imgs:-0}"
            if [ ${failed_imgs:-0} -gt 0 ]; then
                echo "  Images failed:      $failed_imgs"
            fi
        fi
        echo ""
        
        # Show space reclaimed
        echo "💾 To see reclaimed space:"
        echo "   docker system df"
        echo ""
    else
        echo ""
        echo -e "${BLUE}ℹ️  Operation cancelled${NC}"
        echo ""
    fi
}
