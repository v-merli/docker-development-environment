# PHPHarbor - Unified CLI

The new unified `phpharbor` CLI replaces various individual scripts with a consistent and modular interface.

## 🎯 Advantages

- **Single command**: `./phpharbor` instead of 5+ different scripts
- **Integrated help**: `./phpharbor help` and `./phpharbor <command> --help`
- **Modularity**: Module-based architecture in `cli/`
- **Completeness**: Project management, development, shared services, setup

## 📦 Structure

```
phpharbor              # Main entrypoint
cli/
  ├── project.sh        # Project management (list, start, stop, etc)
  ├── dev.sh            # Development tools (shell, artisan, composer, etc)
  ├── shared.sh         # Shared services (mysql, redis, php)
  ├── setup.sh          # System setup (dns, proxy, init)
  ├── create.sh         # Project creation
  └── system.sh         # Info and statistics
```

## 🚀 Main Commands

### Project Management

```bash
# Create new project
./phpharbor create myshop --type laravel --php 8.3
./phpharbor create blog --fully-shared --php 8.3
./phpharbor create api --shared-db --php 8.2

# List projects
./phpharbor list

# Lifecycle management
./phpharbor start myshop
./phpharbor stop myshop
./phpharbor restart myshop
./phpharbor logs myshop
./phpharbor remove myshop
```

### Service Management

Manage optional services and templates for projects.

```bash
# Standard services (queue, scheduler, redis, mysql, mariadb)
./phpharbor service add myblog queue           # Add Laravel queue worker
./phpharbor service add myapp redis            # Add dedicated Redis
./phpharbor service remove myblog scheduler    # Remove scheduler
./phpharbor service list myblog                # List active services

# Service templates (mailhog, wp-cron, elasticsearch, etc.)
./phpharbor service templates                   # List available templates
./phpharbor service add-template myblog mailhog # Install mailhog
./phpharbor service remove-template myblog mailhog
```

**Standard services:**
- `queue` - Laravel queue worker (Laravel only)
- `scheduler` - Laravel scheduler (Laravel only)
- `redis` - Dedicated Redis cache (all types)
- `mysql` - Dedicated MySQL database (all types)
- `mariadb` - Dedicated MariaDB database (all types)

**Available templates:**
- `mailhog` - Email testing tool (Web UI + SMTP)
- `wp-cron` - WordPress cron worker
- `elasticsearch` - Search engine
- `node-worker` - Node.js background service
- `redis-commander` - Redis web UI

> See [Custom Services Guide](custom-services.md) for manual customization

### Development Tools

```bash
# Shell in PHP container
./phpharbor shell myshop

# Laravel commands
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

### Shared Services

```bash
# Start services
./phpharbor shared start              # MySQL + Redis
./phpharbor shared start mysql        # MySQL only
./phpharbor shared start redis        # Redis only
./phpharbor shared php 8.3            # Shared PHP-FPM

# Status and info
./phpharbor shared status
./phpharbor shared logs

# Shared MySQL CLI
./phpharbor shared mysql

# Stop services
./phpharbor shared stop
```

### System Setup

```bash
# Complete initial setup
./phpharbor setup init

# Setup individual components
./phpharbor setup dns        # dnsmasq for *.test
./phpharbor setup proxy      # nginx reverse proxy
```

### Information

```bash
# Docker resource statistics
./phpharbor stats

# Complete environment info
./phpharbor info

# Clean orphaned resources
./phpharbor cleanup

# Version
./phpharbor version
```

## 🎨 Project Creation Options

```bash
./phpharbor create <name> [options]

Options:
  --type <type>         laravel, wordpress, php, html (default: laravel)
  --php <version>      7.3, 7.4, 8.1, 8.2, 8.3, 8.5 (default: 8.3)
  --node <version>     18, 20, 21 (default: 20)
  --mysql <version>    5.7, 8.0 (default: 8.0)
  --no-db               Without MySQL
  --no-redis            Without Redis
  --shared-db           Shared MySQL
  --shared-redis        Shared Redis
  --shared              Shared MySQL + Redis
  --shared-php          Shared PHP
  --fully-shared        Everything shared (maximum savings)
  --no-install          Don't install framework automatically
```

### Creation Examples

```bash
# Standard Laravel project
./phpharbor create my-shop --type laravel --php 8.3

# WordPress
./phpharbor create blog --type wordpress --php 8.2

# Laravel fully-shared (minimum RAM consumption)
./phpharbor create api --fully-shared --php 8.3

# Generic PHP with shared DB
./phpharbor create legacy --type php --php 7.4 --shared-db

# Static HTML
./phpharbor create landing --type html
```

## 📊 Supported Configurations

### 1. Dedicated (Default)
Each project has its own MySQL, Redis, PHP-FPM
```bash
./phpharbor create project1
```
- **RAM**: ~500MB per project
- **Pros**: Complete isolation, no interference
- **Cons**: High RAM consumption with many projects

### 2. Shared DB
Shared MySQL and Redis, dedicated PHP
```bash
./phpharbor create project2 --shared
```
- **RAM**: ~300MB per project
- **Pros**: DB savings, isolated PHP
- **Cons**: Shared database

### 3. Fully Shared
Everything shared (MySQL, Redis, PHP)
```bash
./phpharbor create project3 --fully-shared --php 8.3
```
- **RAM**: ~10-50MB per project (nginx only!)
- **Pros**: Maximum savings (80%+), ideal for many projects
- **Cons**: PHP shared between projects

## 🔄 Migration from Old Scripts

### Before (multiple scripts)
```bash
./new-project.sh myshop --type laravel
./manage-projects.sh start myshop
./start-shared-services.sh mysql
./artisan.sh myshop migrate
```

### Now (unified CLI)
```bash
./phpharbor create myshop --type laravel
./phpharbor start myshop
./phpharbor shared start mysql
./phpharbor artisan myshop migrate
```

## 🔧 Module Development

To add new functionality, create a module in `cli/`:

```bash
# cli/mymodule.sh
#!/bin/bash

cmd_mycommand() {
    print_info "Running command..."
    # ... logic ...
}
```

Then add the case in `phpharbor`:
```bash
case $COMMAND in
    mycommand)
        load_module "mymodule"
        cmd_mycommand "$@"
        ;;
esac
```

## 📝 Notes

- The old scripts (`new-project.sh`, `manage-projects.sh`, etc) are still functional
- The CLI uses the same Docker infrastructure (proxy, shared services, templates)
- Compatible with existing projects created with old scripts
- Auto-detection for shared vs dedicated PHP in dev commands

## 🎓 Tips

```bash
# Quick workflow for new project
./phpharbor create myapp --fully-shared && \
./phpharbor start myapp && \
./phpharbor shell myapp

# View logs in real-time during development
./phpharbor logs myapp -f

# Check general status
./phpharbor list && ./phpharbor shared status

# Cleanup
./phpharbor remove old-project
./phpharbor shared stop
```

## ⚡ Recommended Aliases

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
alias dd='./phpharbor'
alias ddl='./phpharbor list'
alias dds='./phpharbor start'
alias ddsh='./phpharbor shell'
alias dda='./phpharbor artisan'
```

Usage:
```bash
dd list
dds myshop
ddsh myshop
dda myshop migrate
```

## 🎯 Autocompletion (Bash/Zsh)

To enable command autocompletion:

```bash
# Copy completion script
cp phpharbor-completion.bash ~/.phpharbor-completion.bash

# Add to ~/.bashrc or ~/.zshrc
echo 'source ~/.phpharbor-completion.bash' >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

Now you can use TAB to autocomplete:
- Commands: `./phpharbor <TAB>`
- Projects: `./phpharbor start <TAB>`
- PHP versions: `./phpharbor shared php <TAB>`
- Options: `./phpharbor create myapp --<TAB>`

**With aliases:**
```bash
# Enable completion for 'dd' alias
echo 'complete -F _docker_dev_completion dd' >> ~/.zshrc
source ~/.zshrc

# Now works with alias too
dd s<TAB>        # → dd start
dd start my<TAB> # → dd start myshop
```

