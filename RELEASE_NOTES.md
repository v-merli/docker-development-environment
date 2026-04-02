## 🎉 PHPHarbor v1.0.0

First public release of PHPHarbor!

### ✨ Main Features

- 🎯 **Multi-project**: Laravel, WordPress, static HTML, generic PHP
- 🐘 **Multi-version PHP**: 7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5 (dedicated or shared)
- 📦 **Selectable Node.js**: 18, 20, 21
- 🗄️ **MySQL**: 5.7, 8.0, 8.4 (dedicated or shared)
- 🔴 **Redis**: 7, 6 (dedicated or shared)
- 🌐 **Nginx reverse proxy**: Automatic routing with SSL
- 🔒 **Automatic SSL certificates**: Let's Encrypt + self-signed
- 🔌 **Local DNS**: dnsmasq for `*.test` domains
- 💾 **Services cherry-picking**: RAM savings up to 90%
- 🎨 **Interactive mode**: Guided menu for project creation
- ⚡ **Complete CLI**: bash/zsh autocompletion

### 🌐 Supported Platforms

- ✅ macOS (10.15+)
- ✅ Linux (Ubuntu, Debian, RHEL, CentOS)
- ✅ Windows (10/11 via WSL2)

### 📦 Installation

One command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/v-merli/php-harbor/main/install.sh)
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
# Initial setup
phpharbor setup init

# Create project (interactive)
phpharbor create

# Or direct CLI
phpharbor create myapp --type laravel --php 8.3

# Start development
phpharbor dev myapp

# Access
open https://myapp.test
```

### 🔧 Requirements

- Docker Desktop (macOS/Windows) or Docker Engine (Linux)
- Git (only for development, not required for installation)
- mkcert (optional, for HTTPS)
- dnsmasq (optional, for wildcard DNS)

### 🐛 Known Issues

None at the moment.

### 🙏 Contributors

Thanks to all contributors who made this release possible!

### 📝 Checksums

```
SHA256: 5804e38169e36e29deef5f332a7629ce3811003284fad66463c097f5a5e5e32d
```

---

**Happy coding! 🚀**
