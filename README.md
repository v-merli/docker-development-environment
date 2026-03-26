# � PHPHarbor

Flexible Docker development environment for Laravel, WordPress, PHP, and HTML with dedicated or shared services.

## 📦 One-Line Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/v-merli/php-harbor/main/install.sh)
```

> 🪟 **Windows**: Use [WSL2](docs/windows-setup.md) | 🐧 **Linux/macOS**: Works directly

## ⚡ Quick Start

```bash
# Initial setup
phpharbor setup init

# Create project (interactive mode)
phpharbor create

# Or direct CLI
phpharbor create myapp --type laravel --php 8.3

# Start development
phpharbor dev myapp

# Access site
open https://myapp.test
```

> 💡 **Projects Directory**: During setup, choose where to save projects (default: `~/.phpharbor/projects`). You can change it later with `phpharbor setup config`

## ✨ Features

- 🎯 Multi-project (Laravel, WordPress, HTML, PHP)
- 🐘 Multi-version PHP (7.3 → 8.5)
- 💾 Cherry-pick shared services (RAM savings)
- 🔒 Automatic HTTPS with local certificates
- 🌐 Local wildcard DNS `*.test`
- 🎨 Interactive CLI or command mode

## 📚 Documentation

**Getting started:**
- 📖 [Complete installation](docs/installation.md)
- 🚀 [Quick Start tutorial](docs/quick-start.md)
- 💻 [CLI reference](docs/cli-reference.md)

**Technical guides:**
- ⚙️ [System architecture](docs/architecture.md)
- 🔧 [Shared services](docs/shared-services.md)
- 🔐 [SSL/HTTPS setup](docs/ssl-setup.md)
- ⚡ [Vite HMR in Docker](docs/vite-setup.md)
- 👷 [Laravel Workers/Scheduler](docs/workers-guide.md)

📂 **[View all documentation →](docs/)**

## 🔧 Requirements

- **Docker**:
  - macOS: Docker Desktop
  - Linux: Docker Engine
  - Windows: Docker Desktop + WSL2
- Git
- mkcert (optional, for HTTPS)
- dnsmasq (optional, for DNS *.test)

> 💡 **Compatibility**: macOS, Linux, Windows (via WSL2) → **[Windows Setup](docs/windows-setup.md)**

## 🎯 Usage Examples

```bash
# Laravel with all dedicated (max performance)
phpharbor create shop --type laravel --php 8.3

# Laravel with all shared (min RAM)
phpharbor create api --type laravel --fully-shared

# WordPress with shared MySQL
phpharbor create blog --type wordpress --shared-db

# Static HTML with shared PHP
phpharbor create landing --type html --shared-php

# Management
phpharbor project list
phpharbor project logs shop
phpharbor project artisan shop migrate
phpharbor project composer shop require package

# Services
phpharbor shared status
phpharbor shared php 8.3
```

## 🏗️ Architecture

**Reverse Proxy** → automatic domain routing  
**Dedicated services** → container per project (max isolation)  
**Shared services** → MySQL/Redis/PHP shared between projects (min RAM)

Choose the ideal mix for each project.

📖 **[Complete Architecture Documentation →](docs/architecture.md)**

## 🔧 Maintenance

### Reset Docker Environment

PHPHarbor includes integrated reset commands to clean up the Docker environment:

```bash
# Interactive mode (recommended)
./phpharbor reset

# Quick soft reset (keep data)
./phpharbor reset soft

# Hard reset (WARNING: deletes all data!)
./phpharbor reset hard

# Show current status
./phpharbor reset status
```

**Soft Reset:**
- Removes all PHPHarbor containers
- Keeps volumes and data (databases preserved)
- Useful for troubleshooting container issues

**Hard Reset:**
- Removes all containers AND volumes
- ⚠️ **DELETES ALL DATABASE DATA** in shared services
- Use when you want a completely fresh start

### Uninstall

To completely remove PHPHarbor:

```bash
./uninstall.sh
```

This will:
- Remove all containers and volumes
- Delete the installation directory
- Remove the `phpharbor` command
- Keep your projects directory safe

## 🤝 Contribute

Read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📝 License

[MIT License](LICENSE) - Copyright 2026

## 💬 Support

- 📖 [Complete documentation](docs/)
- 🐛 [Report bugs](https://github.com/your-username/php-harbor/issues)
- 💡 [Request features](https://github.com/your-username/php-harbor/issues/new)
- 💬 [Discussions](https://github.com/your-username/php-harbor/discussions)

---

**Made with ❤️ for developers who love Docker**
