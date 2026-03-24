# PHPHarbor - CLI Unificato

Il nuovo CLI unificato `phpharbor` sostituisce i vari script individuali con un'interfaccia coerente e modulare.

## 🎯 Vantaggi

- **Un solo comando**: `./phpharbor` invece di 5+ script diversi
- **Help integrato**: `./phpharbor help` e `./phpharbor <comando> --help`
- **Modularità**: Architettura a moduli in `cli/`
- **Completezza**: Gestione progetti, sviluppo, servizi condivisi, setup

## 📦 Struttura

```
phpharbor              # Entrypoint principale
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
./phpharbor create myshop --type laravel --php 8.3
./phpharbor create blog --fully-shared --php 8.3
./phpharbor create api --shared-db --php 8.2

# Elencare progetti
./phpharbor list

# Gestione lifecycle
./phpharbor start myshop
./phpharbor stop myshop
./phpharbor restart myshop
./phpharbor logs myshop
./phpharbor remove myshop
```

### Strumenti Sviluppo

```bash
# Shell nel container PHP
./phpharbor shell myshop

# Comandi Laravel
./phpharbor artisan myshop migrate
./phpharbor artisan myshop make:controller UserController

# Composer
./phpharbor composer myshop require laravel/sanctum
./phpharbor composer myshop update

# NPM
./phpharbor npm myshop install
./phpharbor npm myshop run dev

# MySQL CLI
./phpharbor mysql myshop
```

### Servizi Condivisi

```bash
# Avviare servizi
./phpharbor shared start              # MySQL + Redis
./phpharbor shared start mysql        # Solo MySQL
./phpharbor shared start redis        # Solo Redis
./phpharbor shared php 8.3            # PHP-FPM condiviso

# Stato e info
./phpharbor shared status
./phpharbor shared logs

# MySQL CLI condiviso
./phpharbor shared mysql

# Fermare servizi
./phpharbor shared stop
```

### Setup Sistema

```bash
# Setup iniziale completo
./phpharbor setup init

# Setup componenti individuali
./phpharbor setup dns        # dnsmasq per *.test
./phpharbor setup proxy      # nginx reverse proxy
```

### Informazioni

```bash
# Statistiche risorse Docker
./phpharbor stats

# Info ambiente completo
./phpharbor info

# Versione
./phpharbor version
```

## 🎨 Opzioni Creazione Progetto

```bash
./phpharbor create <nome> [opzioni]

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
./phpharbor create my-shop --type laravel --php 8.3

# WordPress
./phpharbor create blog --type wordpress --php 8.2

# Laravel fully-shared (minimo consumo RAM)
./phpharbor create api --fully-shared --php 8.3

# PHP generico con DB condiviso
./phpharbor create legacy --type php --php 7.4 --shared-db

# HTML statico
./phpharbor create landing --type html
```

## 📊 Configurazioni Supportate

### 1. Dedicated (Default)
Ogni progetto ha propri MySQL, Redis, PHP-FPM
```bash
./phpharbor create project1
```
- **RAM**: ~500MB per progetto
- **Pro**: Isolamento completo, nessuna interferenza
- **Contro**: Alto consumo RAM con molti progetti

### 2. Shared DB
MySQL e Redis condivisi, PHP dedicato
```bash
./phpharbor create project2 --shared
```
- **RAM**: ~300MB per progetto
- **Pro**: Risparmio su DB, PHP isolato
- **Contro**: Database condiviso

### 3. Fully Shared
Tutto condiviso (MySQL, Redis, PHP)
```bash
./phpharbor create project3 --fully-shared --php 8.3
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
./phpharbor create myshop --type laravel
./phpharbor start myshop
./phpharbor shared start mysql
./phpharbor artisan myshop migrate
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

Poi aggiungi il caso in `phpharbor`:
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
./phpharbor create myapp --fully-shared && \
./phpharbor start myapp && \
./phpharbor shell myapp

# Vedere log in tempo reale durante sviluppo
./phpharbor logs myapp -f

# Controllare stato generale
./phpharbor list && ./phpharbor shared status

# Cleanup
./phpharbor remove old-project
./phpharbor shared stop
```

## ⚡ Alias Consigliati

Aggiungi al tuo `~/.zshrc` o `~/.bashrc`:

```bash
alias dd='./phpharbor'
alias ddl='./phpharbor list'
alias dds='./phpharbor start'
alias ddsh='./phpharbor shell'
alias dda='./phpharbor artisan'
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
cp phpharbor-completion.bash ~/.phpharbor-completion.bash

# Aggiungi a ~/.bashrc o ~/.zshrc
echo 'source ~/.phpharbor-completion.bash' >> ~/.zshrc

# Ricarica shell
source ~/.zshrc
```

Ora puoi usare TAB per autocompletare:
- Comandi: `./phpharbor <TAB>`
- Progetti: `./phpharbor start <TAB>`
- Versioni PHP: `./phpharbor shared php <TAB>`
- Opzioni: `./phpharbor create myapp --<TAB>`

**Con alias:**
```bash
# Abilita completion per alias 'dd'
echo 'complete -F _docker_dev_completion dd' >> ~/.zshrc
source ~/.zshrc

# Ora funziona anche con alias
dd s<TAB>        # → dd start
dd start my<TAB> # → dd start myshop
```

