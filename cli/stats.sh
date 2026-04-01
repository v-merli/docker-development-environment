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
        echo "  disk --cleanup    Interactive cleanup of orphan volumes and images"
        echo ""
        echo "Examples:"
        echo "  ./phpharbor stats disk              # Basic disk analysis"
        echo "  ./phpharbor stats disk --detailed   # Per-project breakdown"
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
    local cleanup=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --detailed)
                detailed=true
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
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     PHPHARBOR DISK USAGE ANALYSIS (Real-time).                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # System overview
    echo -e "${YELLOW}📊 Docker system overview:${NC}"
    echo "───────────────────────────────────────────────────────────────────────"
    docker system df
    echo ""
    
        # PHPHarbor images (from containers with compose project 'phpharbor-proxy')
        echo -e "${YELLOW}🐳 PHPHarbor images (phpharbor-proxy):${NC}"
        echo "───────────────────────────────────────────────────────────────────────"
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
    echo "───────────────────────────────────────────────────────────────────────"
    
    # Get volumes from containers with phpharbor.service.type=shared label
    local shared_volumes=$(docker ps -a --filter 'label=phpharbor.service.type=shared' --format '{{.ID}}' | \
        xargs -I {} docker inspect {} --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{"\n"}}{{end}}{{end}}' 2>/dev/null | \
        sort | uniq)
    
    if [ -n "$shared_volumes" ]; then
        printf "%-30s %10s\n" "VOLUME NAME" "CONTAINERS"
        echo "───────────────────────────────────────────────────────────────────────"
        echo "$shared_volumes" | while read vol; do
            containers=$(docker ps -a --filter volume=$vol --format "{{.Names}}" | wc -l | tr -d ' ')
            printf "%-30s %10s\n" "$vol" "$containers"
        done
    else
        echo "  No shared volume found"
    fi
    echo ""

    # Bind mount locali per database
    echo -e "${YELLOW}🗄️  Database bind mounts (volumes/):${NC}"
    echo "───────────────────────────────────────────────────────────────────────"
    if [ -d "$PROJECTS_DIR/../volumes" ]; then
        printf "%-15s %-35s %10s\n" "TYPE" "MOUNT NAME" "SIZE"
        echo "───────────────────────────────────────────────────────────────────────"
        
        local first_group=true
        find "$PROJECTS_DIR/../volumes" -mindepth 1 -maxdepth 1 -type d | sort | while read dbdir; do
            dbtype=$(basename "$dbdir")
            
            # Add blank line between groups (except before first)
            if [ "$first_group" = false ]; then
                echo ""
            fi
            first_group=false
            
            total_bytes=0
            local first_mount=true
            
            if [ -d "$dbdir" ]; then
                for path in "$dbdir"/*; do
                    [ -e "$path" ] || continue
                    # du -sk restituisce la dimensione in KB (compatibile macOS/Linux)
                    kb=$(du -sk "$path" 2>/dev/null | awk '{print $1}')
                    bytes=$((kb * 1024))
                    mountname=$(basename "$path")
                    total_bytes=$((total_bytes + bytes))
                    size_human=$(human_size "$bytes")
                    
                    # Show type only on first mount of the group
                    if [ "$first_mount" = true ]; then
                        printf "%-15s %-35s %10s\n" "$dbtype" "$mountname" "$size_human"
                        first_mount=false
                    else
                        printf "%-15s %-35s %10s\n" "" "$mountname" "$size_human"
                    fi
                done
                
                # Show subtotal for the group
                if [ "$total_bytes" -gt 0 ]; then
                    total_human=$(human_size "$total_bytes")
                    printf "%-15s %-35s %10s\n" "" "Subtotal" "$total_human"
                fi
            else
                printf "%-15s %-35s %10s\n" "$dbtype" "(nessun dato)" "-"
            fi
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
        echo "───────────────────────────────────────────────────────────────────────"
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
    
    # Project images breakdown
    echo -e "${YELLOW}🖼️  Project images:${NC}"
    echo "───────────────────────────────────────────────────────────────────────"
    
    # Get all project labels from containers (format: phpharbor-app-<projectname>)
    local project_labels=$(docker ps -a --filter 'label=phpharbor.project' --format '{{.Label "phpharbor.project"}}' | \
        grep '^phpharbor-app-' | \
        sort -u)
    
    if [ -z "$project_labels" ]; then
        echo "  No project images found"
        echo ""
    else
        printf "%-20s %-30s %-12s %s\n" "PROJECT" "IMAGE" "SIZE" "STATUS"
        echo "───────────────────────────────────────────────────────────────────────"
        
        local total_size_bytes=0
        local active_count=0
        local orphan_count=0
        
        while IFS= read -r label; do
            # Extract project name (remove phpharbor-app- prefix)
            local project_name="${label#phpharbor-app-}"
            
            # Check if project directory exists
            local is_orphan=false
            if [ ! -d "$PROJECTS_DIR/$project_name" ]; then
                is_orphan=true
            fi
            
            # Get images from containers with this label
            local images=$(docker ps -a --filter "label=phpharbor.project=$label" --format '{{.Image}}' | sort -u)
            
            while IFS= read -r img; do
                if [ -n "$img" ]; then
                    # Skip shared infrastructure images (only show project-specific images)
                    # Skip: nginx:*, mysql:*, redis:*, mariadb:*, phpharbor-proxy-*
                    if [[ "$img" =~ ^(nginx|mysql|redis|mariadb): ]] || [[ "$img" =~ ^phpharbor-proxy- ]]; then
                        continue
                    fi
                    
                    # Get image size
                    local size=$(docker images "$img" --format "{{.Size}}" 2>/dev/null)
                    local size_bytes=$(docker images "$img" --format "{{.Size}}" 2>/dev/null | sed 's/[A-Z]//g' | sed 's/\..*//g' 2>/dev/null || echo "0")
                    
                    # Determine status
                    local status="Active"
                    local status_color="${GREEN}"
                    if [ "$is_orphan" = true ]; then
                        status="${RED}Orphan ⚠️${NC}"
                        ((orphan_count++))
                    else
                        status="${GREEN}Active${NC}"
                        ((active_count++))
                    fi
                    
                    # Extract short image name (remove sha256 prefix if present)
                    local short_img="$img"
                    if [[ "$img" == sha256:* ]]; then
                        short_img="$(echo "$img" | cut -c 1-19)..."
                    fi
                    
                    printf "%-20s %-30s %-12s %b\n" "$project_name" "$short_img" "$size" "$status"
                fi
            done <<< "$images"
        done <<< "$project_labels"
        
        echo "───────────────────────────────────────────────────────────────────────"
        printf "%-52s %d active, %d orphan\n" "Total project images:" "$active_count" "$orphan_count"
        
        if [ "$orphan_count" -gt 0 ]; then
            echo ""
            echo -e "${BLUE}💡 Clean up orphan images with: ./phpharbor stats disk --cleanup${NC}"
        fi
        echo ""
    fi
    
    # Projects count
    local projects_count=0
    if [ -d "$PROJECTS_DIR" ]; then
        projects_count=$(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    # Containers count (only project containers, not proxy infrastructure)
    local containers_count=$(docker ps -a --filter 'label=phpharbor.project' --format '{{.Label "phpharbor.project"}}' 2>/dev/null | grep '^phpharbor-app-' | wc -l | tr -d ' ')
    local containers_running=$(docker ps --filter 'label=phpharbor.project' --format '{{.Label "phpharbor.project"}}' 2>/dev/null | grep '^phpharbor-app-' | wc -l | tr -d ' ')
    
    echo -e "${YELLOW}📁 Project statistics:${NC}"
    echo "───────────────────────────────────────────────────────────────────────"
    echo "  Total projects:      $projects_count"
    echo "  Total containers:    $containers_count"
    echo "  Running containers:  $containers_running"
    echo ""
    
    # Detailed breakdown per project
    if [ "$detailed" = true ] && [ $projects_count -gt 0 ]; then
        echo -e "${YELLOW}🔍 Project breakdown:${NC}"
        echo "───────────────────────────────────────────────────────────────────────"
        
        for project_dir in "$PROJECTS_DIR"/*/ ; do
            if [ -d "$project_dir" ]; then
                local project_name=$(basename "$project_dir")
                local app_size=$(du -sh "$project_dir" 2>/dev/null | cut -f1)
                
                # Check if project has containers (using label)
                local project_containers=$(docker ps -a --filter "label=phpharbor.project=phpharbor-app-${project_name}" --format "{{.Names}}" 2>/dev/null | wc -l | tr -d ' ')
                
                echo "  📦 $project_name"
                echo "      App files:        $app_size"
                echo "      Containers:       $project_containers"
                
                # Check project type from .env
                if [ -f "$project_dir/.env" ]; then
                    local project_type=$(grep "^PROJECT_TYPE=" "$project_dir/.env" 2>/dev/null | cut -d'=' -f2)
                    
                    # Check if using shared PHP (USE_SHARED_PHP=true means unified mode with shared PHP)
                    local use_shared_php=$(grep "^USE_SHARED_PHP=" "$project_dir/.env" 2>/dev/null | cut -d'=' -f2)
                    local php_shared="false"
                    if [ "$use_shared_php" = "true" ]; then
                        php_shared="true"
                    fi
                    
                    # Check if using shared DB (detecting *-shared in service names)
                    local db_service=$(grep "^DB_SERVICE=" "$project_dir/.env" 2>/dev/null | cut -d'=' -f2)
                    local mysql_shared="false"
                    if [[ "$db_service" == *"-shared" ]]; then
                        mysql_shared="true"
                    fi
                    
                    # Check if using shared Redis
                    local redis_service=$(grep "^REDIS_SERVICE=" "$project_dir/.env" 2>/dev/null | cut -d'=' -f2)
                    local redis_shared="false"
                    if [[ "$redis_service" == *"-shared" ]]; then
                        redis_shared="true"
                    fi
                    
                    echo "      Type:             ${project_type:-unknown}"
                    echo "      PHP shared:       ${php_shared}"
                    echo "      MySQL shared:     ${mysql_shared}"
                    echo "      Redis shared:     ${redis_shared}"
                fi
                echo ""
            fi
        done
    fi
    
    # Quick tips
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo "───────────────────────────────────────────────────────────────────────"
    echo "  • Use --detailed to see per-project breakdown"
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
        echo "───────────────────────────────────────────────────────────────────────"
        for vol in "${orphan_volumes[@]}"; do
            echo "  • $vol"
        done
        echo ""
    fi
    
    if [ ${#orphan_images[@]} -gt 0 ]; then
        echo -e "${YELLOW}🖼️  Orphan images found: ${#orphan_images[@]}${NC}"
        echo "───────────────────────────────────────────────────────────────────────"
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
