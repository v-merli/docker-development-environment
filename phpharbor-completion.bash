#!/bin/bash
# Bash completion for phpharbor CLI
# Install with: cp phpharbor-completion.bash ~/.phpharbor-completion.bash
# Then add to ~/.bashrc or ~/.zshrc:
#   source ~/.phpharbor-completion.bash

_phpharbor_completion() {
    local cur prev commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    commands="create list start stop restart remove logs convert shell artisan composer npm mysql shared ssl setup update stats info cleanup reset version help"
    
    # Shared sub-commands
    shared_commands="start stop status logs mysql php"
    
    # Setup sub-commands
    setup_commands="config ports dns proxy init"
    
    # Reset sub-commands
    reset_commands="soft hard status"
    
    # SSL sub-commands
    ssl_commands="setup generate verify install"
    
    # Update sub-commands
    update_commands="check install changelog"
    
    # Stats sub-commands
    stats_commands="disk resources"
    stats_disk_options="--detailed --compare --cleanup"
    
    # If we're at the first argument, suggest main commands
    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        return 0
    fi
    
    # Sub-command handling
    local cmd="${COMP_WORDS[1]}"
    
    case "$cmd" in
        shared)
            if [ $COMP_CWORD -eq 2 ]; then
                COMPREPLY=( $(compgen -W "${shared_commands}" -- ${cur}) )
            elif [ $COMP_CWORD -eq 3 ] && [ "$prev" == "php" ]; then
                # Suggest PHP versions
                COMPREPLY=( $(compgen -W "7.3 7.4 8.1 8.2 8.3 8.5" -- ${cur}) )
            elif [ $COMP_CWORD -eq 3 ] && [ "$prev" == "start" ]; then
                # Suggest services
                COMPREPLY=( $(compgen -W "mysql redis" -- ${cur}) )
            fi
            return 0
            ;;
        setup)
            if [ $COMP_CWORD -eq 2 ]; then
                COMPREPLY=( $(compgen -W "${setup_commands}" -- ${cur}) )
            fi
            return 0
            ;;
        reset)
            if [ $COMP_CWORD -eq 2 ]; then
                COMPREPLY=( $(compgen -W "${reset_commands}" -- ${cur}) )
            fi
            return 0
            ;;
        ssl)
            if [ $COMP_CWORD -eq 2 ]; then
                COMPREPLY=( $(compgen -W "${ssl_commands}" -- ${cur}) )
            fi
            return 0
            ;;
        update)
            if [ $COMP_CWORD -eq 2 ]; then
                COMPREPLY=( $(compgen -W "${update_commands}" -- ${cur}) )
            fi
            return 0
            ;;
        stats)
            if [ $COMP_CWORD -eq 2 ]; then
                COMPREPLY=( $(compgen -W "${stats_commands}" -- ${cur}) )
            elif [ $COMP_CWORD -eq 3 ] && [ "$prev" == "disk" ]; then
                # Suggest disk options
                COMPREPLY=( $(compgen -W "${stats_disk_options}" -- ${cur}) )
            fi
            return 0
            ;;
        convert)
            if [ $COMP_CWORD -eq 2 ]; then
                # Suggest available projects
                local projects_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/projects"
                if [ -d "$projects_dir" ]; then
                    local projects=$(ls -1 "$projects_dir" 2>/dev/null)
                    COMPREPLY=( $(compgen -W "${projects}" -- ${cur}) )
                fi
            elif [ $COMP_CWORD -eq 3 ]; then
                # Suggest project types
                COMPREPLY=( $(compgen -W "laravel wordpress php" -- ${cur}) )
            fi
            return 0
            ;;
        create)
            # Suggest options for create
            if [[ ${cur} == -* ]]; then
                COMPREPLY=( $(compgen -W "--type --php --node --mysql --no-db --no-redis --shared-db --shared-redis --shared --shared-php --fully-shared --no-install --help" -- ${cur}) )
            fi
            return 0
            ;;
        start|stop|restart|remove|logs|shell|mysql)
            # Suggest available projects
            if [ $COMP_CWORD -eq 2 ]; then
                local projects_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/projects"
                if [ -d "$projects_dir" ]; then
                    local projects=$(ls -1 "$projects_dir" 2>/dev/null)
                    COMPREPLY=( $(compgen -W "${projects}" -- ${cur}) )
                fi
            fi
            return 0
            ;;
        artisan|composer|npm)
            # Suggest available projects as second argument
            if [ $COMP_CWORD -eq 2 ]; then
                local projects_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/projects"
                if [ -d "$projects_dir" ]; then
                    local projects=$(ls -1 "$projects_dir" 2>/dev/null)
                    COMPREPLY=( $(compgen -W "${projects}" -- ${cur}) )
                fi
            fi
            # Don't suggest for specific commands (too variable)
            return 0
            ;;
    esac
    
    return 0
}

# Register the completion function
complete -F _phpharbor_completion phpharbor
complete -F _phpharbor_completion ./phpharbor

# Common aliases (optional)
# alias dd='./phpharbor'
# complete -F _phpharbor_completion dd
