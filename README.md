# � PHPHarbor

Ambiente di sviluppo Docker flessibile per Laravel, WordPress, PHP e HTML con servizi dedicati o condivisi.

## 📦 Installazione One-Line

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/v-merli/php-harbor/main/install.sh)
```

> 🪟 **Windows**: Usa [WSL2](docs/windows-setup.md) | 🐧 **Linux/macOS**: Funziona direttamente

## ⚡ Quick Start

```bash
# Setup iniziale
phpharbor setup init

# Crea progetto (modalità interattiva)
phpharbor create

# Oppure CLI diretta
phpharbor create myapp --type laravel --php 8.3

# Avvia sviluppo
phpharbor dev myapp

# Accedi al sito
open https://myapp.test
```

> 💡 **Directory Progetti**: Durante il setup, scegli dove salvare i progetti (default: `~/.docker-dev-env/projects`). Puoi cambiarla in seguito con `phpharbor setup config`

## ✨ Features

- 🎯 Multi-progetto (Laravel, WordPress, HTML, PHP)
- 🐘 PHP multi-versione (7.3 → 8.5)
- 💾 Cherry-pick servizi condivisi (risparmio RAM)
- 🔒 HTTPS automatico con certificati locali
- 🌐 DNS wildcard `*.test` locale
- 🎨 CLI interattivo o modalità comando

## 📚 Documentazione

**Per iniziare:**
- 📖 [Installazione completa](docs/installation.md)
- 🚀 [Tutorial Quick Start](docs/quick-start.md)
- 💻 [Riferimento CLI](docs/cli-reference.md)

**Guide tecniche:**
- ⚙️ [Architettura sistema](docs/architecture.md)
- 🔧 [Servizi condivisi](docs/shared-services.md)
- 🔐 [Setup SSL/HTTPS](docs/ssl-setup.md)
- ⚡ [Vite HMR in Docker](docs/vite-setup.md)
- 👷 [Laravel Workers/Scheduler](docs/workers-guide.md)

📂 **[Vedi tutta la documentazione →](docs/)**

## 🔧 Requisiti

- **Docker**:
  - macOS: Docker Desktop
  - Linux: Docker Engine
  - Windows: Docker Desktop + WSL2
- Git
- mkcert (opzionale, per HTTPS)
- dnsmasq (opzionale, per DNS *.test)

> 💡 **Compatibilità**: macOS, Linux, Windows (via WSL2) → **[Setup Windows](docs/windows-setup.md)**

## 🎯 Esempi d'Uso

```bash
# Laravel con tutto dedicato (max performance)
phpharbor create shop --type laravel --php 8.3

# Laravel con tutto condiviso (min RAM)
phpharbor create api --type laravel --fully-shared

# WordPress con MySQL condiviso
phpharbor create blog --type wordpress --shared-db

# HTML statico con PHP condiviso
phpharbor create landing --type html --shared-php

# Gestione
phpharbor project list
phpharbor project logs shop
phpharbor project artisan shop migrate
phpharbor project composer shop require package

# Servizi
phpharbor shared status
phpharbor shared php 8.3
```

## 🏗️ Architettura

**Reverse Proxy** → routing automatico dei domini  
**Servizi dedicati** → container per progetto (max isolamento)  
**Servizi condivisi** → MySQL/Redis/PHP condivisi tra progetti (min RAM)

Scegli il mix ideale per ogni progetto.

📖 **[Documentazione Completa Architettura →](docs/architecture.md)**

## 🤝 Contribuisci

Leggi [CONTRIBUTING.md](CONTRIBUTING.md) per le linee guida.

## 📝 Licenza

[MIT License](LICENSE) - Copyright 2026

## 💬 Supporto

- 📖 [Documentazione completa](docs/)
- 🐛 [Report bug](https://github.com/your-username/docker-development-environment/issues)
- 💡 [Richiedi feature](https://github.com/your-username/docker-development-environment/issues/new)
- 💬 [Discussioni](https://github.com/your-username/docker-development-environment/discussions)

---

**Made with ❤️ for developers who love Docker**
