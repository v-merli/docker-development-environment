#!/bin/bash
# Bash completion per phpharbor CLI
# Installa con: cp phpharbor-completion.bash ~/.phpharbor-completion.bash
# Poi aggiungi a ~/.bashrc o ~/.zshrc:
#   source ~/.phpharbor-completion.bash

_phpharbor_completion() {
    local cur prev commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Comandi principali
    commands="create list start stop restart remove logs shell artisan composer npm mysql shared setup stats info version help"
    
    # Sotto-comandi shared
    shared_commands="start stop status logs mysql php"
    
    # Sotto-comandi setup
    setup_commands="dns proxy init"
    
    # Se siamo al primo argomento, suggerisci comandi principali
    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        return 0
    fi
    
    # Gestione sotto-comandi
    local cmd="${COMP_WORDS[1]}"
    
    case "$cmd" in
        shared)
            if [ $COMP_CWORD -eq 2 ]; then
                COMPREPLY=( $(compgen -W "${shared_commands}" -- ${cur}) )
            elif [ $COMP_CWORD -eq 3 ] && [ "$prev" == "php" ]; then
                # Suggerisci versioni PHP
                COMPREPLY=( $(compgen -W "7.3 7.4 8.1 8.2 8.3 8.5" -- ${cur}) )
            elif [ $COMP_CWORD -eq 3 ] && [ "$prev" == "start" ]; then
                # Suggerisci servizi
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
        create)
            # Suggerisci opzioni per create
            if [[ ${cur} == -* ]]; then
                COMPREPLY=( $(compgen -W "--type --php --node --mysql --no-db --no-redis --shared-db --shared-redis --shared --shared-php --fully-shared --no-install --help" -- ${cur}) )
            fi
            return 0
            ;;
        start|stop|restart|remove|logs|shell|mysql)
            # Suggerisci progetti disponibili
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
            # Suggerisci progetti disponibili come secondo argomento
            if [ $COMP_CWORD -eq 2 ]; then
                local projects_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/projects"
                if [ -d "$projects_dir" ]; then
                    local projects=$(ls -1 "$projects_dir" 2>/dev/null)
                    COMPREPLY=( $(compgen -W "${projects}" -- ${cur}) )
                fi
            fi
            # Non suggest per i comandi specifici (troppo variabili)
            return 0
            ;;
    esac
    
    return 0
}

# Registra la funzione di completion
complete -F _phpharbor_completion phpharbor
complete -F _phpharbor_completion ./phpharbor

# Alias comuni (opzionale)
# alias dd='./phpharbor'
# complete -F _phpharbor_completion dd
