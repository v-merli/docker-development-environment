## 🎉 PHPHarbor v1.0.0

Prima release pubblica di PHPHarbor!

### ✨ Features Principali

- 🎯 **Multi-progetto**: Laravel, WordPress, HTML statico, PHP generico
- 🐘 **PHP multi-versione**: 7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5 (dedicato o condiviso)
- 📦 **Node.js selezionabile**: 18, 20, 21
- 🗄️ **MySQL**: 5.7, 8.0 (dedicato o condiviso)
- 🔴 **Redis**: Dedicato o condiviso
- 🌐 **Nginx reverse proxy**: Routing automatico con SSL
- 🔒 **Certificati SSL automatici**: Let's Encrypt + self-signed
- 🔌 **DNS locale**: dnsmasq per domini `*.test`
- 💾 **Cherry-picking servizi**: Risparmio RAM fino al 90%
- 🎨 **Modalità interattiva**: Menu guidato per creazione progetti
- ⚡ **CLI completo**: bash/zsh autocompletamento

### 🌐 Piattaforme Supportate

- ✅ macOS (10.15+)
- ✅ Linux (Ubuntu, Debian, RHEL, CentOS)
- ✅ Windows (10/11 via WSL2)

### 📦 Installazione

Un solo comando:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/your-username/php-harbor/main/install.sh)
```

### 📚 Documentazione

- 📖 [Installation Guide](docs/installation.md)
- 🚀 [Quick Start](docs/quick-start.md)
- 💻 [CLI Reference](docs/cli-reference.md)
- 🪟 [Windows Setup](docs/windows-setup.md)
- ⚙️ [Architecture](docs/architecture.md)
- 🤝 [Contributing](CONTRIBUTING.md)

### 🎯 Quick Start

```bash
# Setup iniziale
phpharbor setup init

# Crea progetto (interattivo)
phpharbor create

# Oppure CLI diretta
phpharbor create myapp --type laravel --php 8.3

# Avvia sviluppo
phpharbor dev myapp

# Accedi
open https://myapp.test
```

### 📊 Performance

| Configurazione | 5 progetti | Risparmio |
|----------------|------------|-----------|
| Tutti dedicati | ~2.5 GB RAM | - |
| Fully-shared   | ~250 MB RAM | **90%** |

### 🔧 Requisiti

- Docker Desktop (macOS/Windows) o Docker Engine (Linux)
- Git (solo per sviluppo, non richiesto per installazione)
- mkcert (opzionale, per HTTPS)
- dnsmasq (opzionale, per DNS wildcard)

### 🐛 Known Issues

Nessuno al momento.

### 🙏 Contributors

Grazie a tutti i contributori che hanno reso possibile questa release!

### 📝 Checksums

```
SHA256: [verrà generato da create-release.sh]
```

---

**Buon sviluppo! 🚀**
