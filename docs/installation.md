# Installation

Complete guide to installing PHPHarbor.

## 📋 Requirements

### Operating System

- ✅ **macOS** (10.15+)
- ✅ **Linux** (Ubuntu, Debian, RHEL, CentOS, etc.)
- ✅ **Windows** (10/11 with WSL2) → **[Complete Windows guide →](windows-setup.md)**

### Required

- **Docker** (v20.10+)
  - macOS: [Docker Desktop](https://www.docker.com/products/docker-desktop)
  - Linux: [Docker Engine](https://docs.docker.com/engine/install/)
  - Verify: `docker --version`

### Optional (but recommended)

- **mkcert** - For local HTTPS SSL certificates
  - macOS:
    ```bash
    brew install mkcert
    mkcert -install
    ```
  - Linux: [Install from GitHub](https://github.com/FiloSottile/mkcert#installation)
    ```bash
    # Debian/Ubuntu
    wget https://github.com/FiloSottile/mkcert/releases/latest/download/mkcert-v*-linux-amd64
    chmod +x mkcert-v*-linux-amd64
    sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
    mkcert -install
    ```

- **dnsmasq** - For DNS wildcard (*.test → 127.0.0.1)
  - macOS: `brew install dnsmasq`
  - Linux: `sudo apt-get install dnsmasq` (Debian/Ubuntu)

---

## 🚀 Quick Installation

### Method 1: Installation Script (Recommended)

One command to install everything (works on **macOS, Linux and Windows WSL2**):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/your-username/php-harbor/main/install.sh)
```

The script:
- ✅ Automatically detects operating system (macOS/Linux/WSL2)
- ✅ Checks prerequisites
- ✅ Clones repository to `~/.phpharbor`
- ✅ Sets executable permissions on `phpharbor`
- ✅ Creates symlink `/usr/local/bin/phpharbor`
- ✅ Configures bash/zsh autocompletion
- ✅ Runs initial setup (optional)

> 🪟 **Windows Users**: Before running the script, follow the **[Windows/WSL2 Guide →](windows-setup.md)** to install WSL2 and Docker Desktop.

### Method 2: Manual Installation

```bash
# 1. Clone repository
git clone https://github.com/your-username/php-harbor.git ~/.phpharbor
cd ~/.php-harbor

# 2. Set permissions and create symlink
chmod +x phpharbor
sudo ln -sf ~/.php-harbor/phpharbor /usr/local/bin/phpharbor

# 3. Autocompletion (bash)
echo 'source ~/.phpharbor/phpharbor-completion.bash' >> ~/.bashrc
source ~/.bashrc

# 3. Autocompletion (zsh)
echo 'source ~/.phpharbor/phpharbor-completion.bash' >> ~/.zshrc
source ~/.zshrc

# 4. Initial setup
phpharbor setup init
```

---

## ⚙️ Initial Setup

After installation, run setup to configure:

```bash
phpharbor setup init
```

This creates:
- **Projects Directory** - Choose where to save projects (default: `~/.phpharbor/projects`)
- **Nginx Reverse Proxy** - Automatic project routing
- **SSL Certificate Authority** - Local HTTPS certificates
- **Shared Docker Network** - Inter-container communication
- **Local DNS** (optional) - *.test resolution

### 📁 Projects Directory Configuration

During setup you'll be asked where to save projects:

```
Where do you want to save your Docker projects?

1) ~/.phpharbor/projects (default)
2) ~/Development/docker-projects
3) Custom path
```

**Custom directory advantages:**
- ✅ Personal organization (e.g., all projects in `~/Development`)
- ✅ Performance (use separate faster SSD)
- ✅ Simplified backup (folder external to tool)
- ✅ Sharing with other tools

**Change directory later:**
```bash
phpharbor setup config
```

The script can also **automatically move** existing projects to the new directory.

### 🔌 Port Configuration

You can customize service ports to avoid conflicts:

```bash
phpharbor setup ports
```

**Configurable ports:**
- **HTTP**: Default 8080 (web access projects)
- **HTTPS**: Default 8443 (HTTPS access projects)
- **MySQL**: Default 3306 (shared MySQL)
- **Redis**: Default 6379 (shared Redis)

**Common use cases:**
- Port 8080 already in use → Use 8090
- Multiple Docker environments → Use different ports to avoid confusion
- Local MySQL already running → Use 3307 for shared one

**Manual editing:**
You can also directly edit `~/.phpharbor/.config`:
```bash
HTTP_PORT=8090
HTTPS_PORT=8444
MYSQL_SHARED_PORT=3307
REDIS_SHARED_PORT=6380
```

After modification, restart services:
```bash
phpharbor setup proxy  # Restart proxy with new ports
```

---

## 🧪 Verify Installation

```bash
# Version
phpharbor version

# Help
phpharbor help

# Shared services status
phpharbor shared status
```

---

## 🏃 First Project

### Interactive Mode

```bash
phpharbor create
```

Guides you through a menu to choose:
- Project name
- Type (Laravel, WordPress, static HTML)
- PHP and Node version
- Dedicated or shared services

### CLI Mode

```bash
# Complete Laravel
phpharbor create myapp --type laravel --php 8.3 --node 22

# Laravel with shared services
phpharbor create myapp --type laravel --fully-shared

# WordPress with dedicated MySQL, shared Redis
phpharbor create myblog --type wordpress --shared-redis

# Static HTML
phpharbor create landing --type html --shared-php
```

---

## 📦 Project Management

```bash
# List projects
phpharbor project list

# Start project
phpharbor dev myapp

# Stop project
phpharbor project stop myapp

# Logs
phpharbor project logs myapp

# Detailed info
phpharbor project info myapp

# Remove project
phpharbor project remove myapp
```

---

## 🔧 Troubleshooting

### Permissions on /usr/local/bin

If you don't have permissions to create symlink:

```bash
# Alternative: add to PATH
echo 'export PATH="$HOME/.phpharbor:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Docker Compose not found

Check Docker Compose version:

```bash
# Compose V2 plugin (new)
docker compose version

# Standalone Compose V1 (obsolete)
docker-compose --version
```

PHPHarbor supports both.

### Port 80/443 already in use

If you have Apache/Nginx installed locally:

```bash
# macOS - Stop Apache
sudo apachectl stop

# Disable autostart
sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null
```

### mkcert not working

Reinstall CA:

```bash
mkcert -uninstall
mkcert -install
phpharbor ssl setup-ca
```

### Vite port conflicts

If you have conflicts on port 5173:

```bash
# Restart project (automatically searches for free port)
phpharbor project restart myapp

# Or specify manual port in projects/myapp/.env
VITE_PORT=5999
```

---

## 🔄 Update

### Automatic Script

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/your-username/php-harbor/main/install.sh)
```

The script detects existing installation and proposes update.

### Manual

```bash
cd ~/.phpharbor
git pull origin main
```

---

## 🗑️ Uninstallation

### Remove Tool

```bash
# Remove symlink
sudo rm /usr/local/bin/phpharbor

# Remove repository
rm -rf ~/.phpharbor

# Remove autocompletion from shell RC
# Manually remove lines from ~/.zshrc or ~/.bashrc
```

### Remove Projects

```bash
# List all projects
phpharbor project list

# Remove individually
phpharbor project remove PROJECT_NAME

# Or remove manually
cd ~/.phpharbor/projects
rm -rf PROJECT_NAME
docker stop $(docker ps -q --filter "name=PROJECT_NAME")
docker rm $(docker ps -aq --filter "name=PROJECT_NAME")
```

### Remove Shared Services

```bash
# Stop services
phpharbor shared stop

# Remove containers
docker stop proxy mysql-shared redis-shared proxy-php-8.3-shared
docker rm proxy mysql-shared redis-shared proxy-php-8.3-shared

# Remove network
docker network rm proxy-network

# Remove volumes (WARNING: loses data)
docker volume rm mysql-data redis-data
```

---

## 📚 Resources

- **[README.md](README.md)** - General overview
- **[QUICK-START.md](QUICK-START.md)** - Quick guide
- **[CLI-README.md](CLI-README.md)** - Complete CLI documentation
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical architecture
- **[SHARED-SERVICES.md](SHARED-SERVICES.md)** - Shared services
- **[SSL-SETUP.md](SSL-SETUP.md)** - HTTPS configuration
- **[WORKERS-GUIDE.md](WORKERS-GUIDE.md)** - Laravel workers and scheduler

---

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/your-username/php-harbor/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/php-harbor/discussions)
- **Pull Requests**: Contributions welcome!

---

## 📝 Notes

- Installation requires approximately **500MB** disk space (repository + base Docker images)
- The first `phpharbor create` downloads PHP images (approximately 300-500MB per version)
- Projects reside in `~/.phpharbor/projects/PROJECT_NAME`
- Global configurations in `~/.phpharbor/proxy/` and `~/.php-phpharbor/shared/`
