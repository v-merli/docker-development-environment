# Docker Development Environment - CLI Unificato

Il nuovo CLI unificato `docker-dev` sostituisce i vari script individuali con un'interfaccia coerente e modulare.

## 🎯 Vantaggi

- **Un solo comando**: `./docker-dev` invece di 5+ script diversi
- **Help integrato**: `./docker-dev help` e `./docker-dev <comando> --help`
- **Modularità**: Architettura a moduli in `cli/`
- **Completezza**: Gestione progetti, sviluppo, servizi condivisi, setup

## 📦 Struttura

```
docker-dev              # Entrypoint principale
cli/
  ├── project.sh        # Gestione progetti (list, start, stop, etc)
  ├── dev.sh            # Strumenti sviluppo (shell, artisan, composer, etc)
  ├── shared.sh         # Servizi condivisi (mysql, redis, php)
  ├── setup.sh          # Setup sistema (dns, proxy, init)
  ├── create.sh         # Creazione progetti
  └── system.sh         # Info e statistiche
```

## 🚀 Comandi Principali

### Gestione Progetti

```bash
# Creare nuovo progetto
./docker-dev create myshop --type laravel --php 8.3
./docker-dev create blog --fully-shared --php 8.3
./docker-dev create api --shared-db --php 8.2

# Elencare progetti
./docker-dev list

# Gestione lifecycle
./docker-dev start myshop
./docker-dev stop myshop
./docker-dev restart myshop
./docker-dev logs myshop
./docker-dev remove myshop
```

### Strumenti Sviluppo

```bash
# Shell nel container PHP
./docker-dev shell myshop

# Comandi Laravel
./docker-dev artisan myshop migrate
./docker-dev artisan myshop make:controller UserController

# Composer
./docker-dev composer myshop require laravel/sanctum
./docker-dev composer myshop update

# NPM
./docker-dev npm myshop install
./docker-dev npm myshop run dev

# MySQL CLI
./docker-dev mysql myshop
```

### Servizi Condivisi

```bash
# Avviare servizi
./docker-dev shared start              # MySQL + Redis
./docker-dev shared start mysql        # Solo MySQL
./docker-dev shared start redis        # Solo Redis
./docker-dev shared php 8.3            # PHP-FPM condiviso

# Stato e info
./docker-dev shared status
./docker-dev shared logs

# MySQL CLI condiviso
./docker-dev shared mysql

# Fermare servizi
./docker-dev shared stop
```

### Setup Sistema

```bash
# Setup iniziale completo
./docker-dev setup init

# Setup componenti individuali
./docker-dev setup dns        # dnsmasq per *.test
./docker-dev setup proxy      # nginx reverse proxy
```

### Informazioni

```bash
# Statistiche risorse Docker
./docker-dev stats

# Info ambiente completo
./docker-dev info

# Versione
./docker-dev version
```

## 🎨 Opzioni Creazione Progetto

```bash
./docker-dev create <nome> [opzioni]

Opzioni:
  --type <tipo>         laravel, wordpress, php, html (default: laravel)
  --php <versione>      7.3, 7.4, 8.1, 8.2, 8.3, 8.5 (default: 8.3)
  --node <versione>     18, 20, 21 (default: 20)
  --mysql <versione>    5.7, 8.0 (default: 8.0)
  --no-db               Senza MySQL
  --no-redis            Senza Redis
  --shared-db           MySQL condiviso
  --shared-redis        Redis condiviso
  --shared              MySQL + Redis condivisi
  --shared-php          PHP condiviso
  --fully-shared        Tutto condiviso (massimo risparmio)
  --no-install          Non installare framework automaticamente
```

### Esempi Creazione

```bash
# Progetto Laravel standard
./docker-dev create my-shop --type laravel --php 8.3

# WordPress
./docker-dev create blog --type wordpress --php 8.2

# Laravel fully-shared (minimo consumo RAM)
./docker-dev create api --fully-shared --php 8.3

# PHP generico con DB condiviso
./docker-dev create legacy --type php --php 7.4 --shared-db

# HTML statico
./docker-dev create landing --type html
```

## 📊 Configurazioni Supportate

### 1. Dedicated (Default)
Ogni progetto ha propri MySQL, Redis, PHP-FPM
```bash
./docker-dev create project1
```
- **RAM**: ~500MB per progetto
- **Pro**: Isolamento completo, nessuna interferenza
- **Contro**: Alto consumo RAM con molti progetti

### 2. Shared DB
MySQL e Redis condivisi, PHP dedicato
```bash
./docker-dev create project2 --shared
```
- **RAM**: ~300MB per progetto
- **Pro**: Risparmio su DB, PHP isolato
- **Contro**: Database condiviso

### 3. Fully Shared
Tutto condiviso (MySQL, Redis, PHP)
```bash
./docker-dev create project3 --fully-shared --php 8.3
```
- **RAM**: ~10-50MB per progetto (solo nginx!)
- **Pro**: Massimo risparmio (80%+), ideale per molti progetti
- **Contro**: PHP condiviso tra progetti

## 🔄 Migrazione da Vecchi Script

### Prima (script multipli)
```bash
./new-project.sh myshop --type laravel
./manage-projects.sh start myshop
./start-shared-services.sh mysql
./artisan.sh myshop migrate
```

### Ora (CLI unificato)
```bash
./docker-dev create myshop --type laravel
./docker-dev start myshop
./docker-dev shared start mysql
./docker-dev artisan myshop migrate
```

## 🔧 Sviluppo Moduli

Per aggiungere nuove funzionalità, crea un modulo in `cli/`:

```bash
# cli/mymodule.sh
#!/bin/bash

cmd_mycommand() {
    print_info "Eseguo comando..."
    # ... logica ...
}
```

Poi aggiungi il caso in `docker-dev`:
```bash
case $COMMAND in
    mycommand)
        load_module "mymodule"
        cmd_mycommand "$@"
        ;;
esac
```

## 📝 Note

- I vecchi script (`new-project.sh`, `manage-projects.sh`, etc) sono ancora funzionanti
- Il CLI usa la stessa infrastruttura Docker (proxy, shared services, templates)
- Compatibile con progetti esistenti creati con i vecchi script
- Auto-detection per PHP condiviso vs dedicato nei comandi dev

## 🎓 Tips

```bash
# Quick workflow per nuovo progetto
./docker-dev create myapp --fully-shared && \
./docker-dev start myapp && \
./docker-dev shell myapp

# Vedere log in tempo reale durante sviluppo
./docker-dev logs myapp -f

# Controllare stato generale
./docker-dev list && ./docker-dev shared status

# Cleanup
./docker-dev remove old-project
./docker-dev shared stop
```

## ⚡ Alias Consigliati

Aggiungi al tuo `~/.zshrc` o `~/.bashrc`:

```bash
alias dd='./docker-dev'
alias ddl='./docker-dev list'
alias dds='./docker-dev start'
alias ddsh='./docker-dev shell'
alias dda='./docker-dev artisan'
```

Uso:
```bash
dd list
dds myshop
ddsh myshop
dda myshop migrate
```

## 🎯 Autocompletamento (Bash/Zsh)

Per abilitare l'autocompletamento dei comandi:

```bash
# Copia lo script di completion
cp docker-dev-completion.bash ~/.docker-dev-completion.bash

# Aggiungi a ~/.bashrc o ~/.zshrc
echo 'source ~/.docker-dev-completion.bash' >> ~/.zshrc

# Ricarica shell
source ~/.zshrc
```

Ora puoi usare TAB per autocompletare:
- Comandi: `./docker-dev <TAB>`
- Progetti: `./docker-dev start <TAB>`
- Versioni PHP: `./docker-dev shared php <TAB>`
- Opzioni: `./docker-dev create myapp --<TAB>`

**Con alias:**
```bash
# Abilita completion per alias 'dd'
echo 'complete -F _docker_dev_completion dd' >> ~/.zshrc
source ~/.zshrc

# Ora funziona anche con alias
dd s<TAB>        # → dd start
dd start my<TAB> # → dd start myshop
```

