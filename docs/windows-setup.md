# Windows Setup (WSL2)

Complete guide to install PHPHarbor on Windows using WSL2.

## 🪟 Overview

PHPHarbor works perfectly on Windows via **WSL2** (Windows Subsystem for Linux 2), which offers:

- ✅ Native Linux performance
- ✅ Full bash script compatibility
- ✅ Docker Desktop integration
- ✅ Same workflow as macOS/Linux
- ✅ High-performance file system

## 📋 Requirements

- **Windows 10 version 2004+** (Build 19041+) or **Windows 11**
- **Hardware virtualization enabled** in BIOS
- **At least 8GB RAM** (16GB recommended for multiple projects)
- **20GB free disk space**

## 🚀 Step-by-Step Installation

### Step 1: Install WSL2

Open **PowerShell** as Administrator and run:

```powershell
# Install WSL2 with Ubuntu (default)
wsl --install

# Restart computer when prompted
```

**After reboot**, Ubuntu will open automatically and ask you for:
- Username (e.g.: `your-name`)
- Password

> 💡 **Note**: Password won't be displayed while typing (this is normal!)

### Step 2: Verify WSL2

Verify that WSL2 is installed correctly:

```powershell
# From PowerShell
wsl --list --verbose
```

Expected output:
```
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

If you see `VERSION 1`, upgrade to WSL2:
```powershell
wsl --set-version Ubuntu 2
```

### Step 3: Install Docker Desktop

1. **Download**: [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)

2. **Install** the downloaded file

3. **Enable WSL2 integration**:
   - Open Docker Desktop
   - Go to **Settings** (⚙️)
   - **Resources** → **WSL Integration**
   - ✅ Enable "Enable integration with my default WSL distro"
   - ✅ Enable "Ubuntu"
   - Click **Apply & Restart**

4. **Verify** from Ubuntu:
   ```bash
   wsl
   docker --version
   docker compose version
   ```

### Step 4: Install PHPHarbor

Open **Ubuntu** (from Start menu) and run:

```bash
# Install with a single command
bash <(curl -fsSL https://raw.githubusercontent.com/your-username/php-harbor/main/install.sh)
```

The script:
- ✅ Automatically detects you're on WSL2
- ✅ Verifies Docker and prerequisites
- ✅ Installs and configures everything

### Step 5: First Project

```bash
# Initial setup
phpharbor setup init

# Create project
phpharbor create myapp --type laravel --php 8.3

# Access the project
# From Windows: http://myapp.test
# Or use WSL IP
```

---

## 🔧 Optimal Configuration

### File System: Use WSL2, Not Windows

**❌ DON'T do this:**
```bash
cd /mnt/c/Users/YourName/Projects  # Windows file system (SLOW!)
```

**✅ Do this:**
```bash
cd ~/projects  # WSL2 file system (FAST!)
```

**Why?**
- `/mnt/c/` accesses Windows files → **10-100x slower**
- `~` (WSL home) uses native Linux file system → **optimal performance**

### Access WSL Files from Windows

WSL files are accessible from Windows File Explorer:

```
\\wsl$\Ubuntu\home\your-username\.phpharbor\projects
```

Or from Ubuntu terminal:
```bash
explorer.exe .
```

This opens the current folder in Windows File Explorer!

### Editor: VS Code with WSL Extension

**Recommended setup:**

1. Install **VS Code** on Windows
2. Install the **WSL** extension (Microsoft)
3. From Ubuntu, open the project:
   ```bash
   cd ~/.phpharbor/projects/myapp
   code .
   ```

VS Code will open on Windows but **work directly on WSL2** (native performance).

---

## 🌐 DNS and Project Access

### Option 1: hosts File (Manual)

Add to `C:\Windows\System32\drivers\etc\hosts` (as Administrator):

```
127.0.0.1  myapp.test
127.0.0.1  blog.test
127.0.0.1  shop.test
```

### Option 2: Access via IP

Find WSL IP:
```bash
# From Ubuntu
hostname -I
```

Access via IP: `http://172.x.x.x:8080`

### Option 3: Port Forward (Automatic with Docker Desktop)

Docker Desktop automatically forwards ports, so:
- `http://localhost:8080` → works directly!

---

## 🐛 Troubleshooting

### "Docker command not found"

**Solution**: Docker Desktop not integrated with WSL2

1. Open Docker Desktop
2. Settings → Resources → WSL Integration
3. ✅ Enable Ubuntu
4. Restart Ubuntu: `wsl --shutdown` then reopen

### "Cannot connect to Docker daemon"

**Solution**: Docker Desktop not running

1. Start Docker Desktop on Windows
2. Wait until it's fully started (Docker icon in system tray)
3. Retry in Ubuntu

### Slow Performance

**Cause**: You're using files on `/mnt/c/` (Windows)

**Solution**: Move everything to WSL2
```bash
# Clone/move projects to WSL home
cd ~
git clone ...
```

### Port already in use (8080, 8443)

**Solution 1**: Stop other Windows services using those ports

**Solution 2**: Change proxy ports
```bash
# Modify proxy/docker-compose.yml
# Change 8080:80 to 8090:80
# Change 8443:443 to 8444:443
```

### WSL2 uses too much RAM

**Solution**: Limit WSL2 memory

Create `C:\Users\YouName\.wslconfig`:
```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
```

Restart WSL:
```powershell
wsl --shutdown
```

### SSL certificates not trusted

On Windows, you need to install the mkcert CA:

```bash
# In Ubuntu
mkcert -install

# Copy CA certificate to Windows
cp "$(mkcert -CAROOT)/rootCA.pem" /mnt/c/Users/YourName/Desktop/

# On Windows, double-click rootCA.pem
# Install in "Trusted Root Certification Authorities"
```

---

## 💡 Tips & Tricks

### Useful Aliases

Add to `~/.bashrc` in Ubuntu:

```bash
# Open files/folders in Windows
alias open='explorer.exe'

# phpharbor shortcuts
alias dd='phpharbor'
alias ddl='phpharbor project list'
alias ddc='phpharbor create'
```

### Modern Windows Terminal

Use **Windows Terminal** instead of traditional cmd/PowerShell:

1. Install from Microsoft Store
2. Ubuntu will be integrated in the dropdown menu
3. Supports tabs, themes, custom fonts

### Project Backup

Projects in WSL2 are not automatically backed up by Windows Backup!

```bash
# Backup projects
tar -czf ~/projects-backup.tar.gz ~/.phpharbor/projects

# Copy to Windows
cp ~/projects-backup.tar.gz /mnt/c/Users/YourName/Backup/
```

### Network between Windows and WSL2

You can connect from Windows to WSL services:

```bash
# Find WSL IP
ip addr show eth0 | grep inet

# From Windows browser: http://172.x.x.x:PORT
```

And vice versa:
```bash
# From Ubuntu, access Windows services on localhost
curl http://localhost:PORT
```

---

## 🔄 Update

To update PHPHarbor:

```bash
# Re-run the installer (detects existing installation)
bash <(curl -fsSL https://raw.githubusercontent.com/your-username/php-harbor/main/install.sh)

# Or manually
cd ~/.phpharbor
git pull origin main
```

---

## 📊 Performance Comparison

| Scenario | Windows Native | WSL2 |
|----------|----------------|------|
| Docker build | - | ⚡⚡⚡ Fast |
| File I/O | - | ⚡⚡⚡ Native |
| Composer install | - | ⚡⚡⚡ Optimal |
| Vite HMR | - | ⚡⚡⚡ Responsive |
| Laravel Artisan | - | ⚡⚡⚡ Instant |

**Conclusion**: WSL2 offers nearly identical performance to native Linux!

---

## 🆘 Support

**Windows/WSL2 specific issues?**
- [GitHub Issues](https://github.com/your-username/php-harbor/issues)
- Tag: `windows` or `wsl2`

**WSL2 Resources:**
- [WSL2 Documentation](https://docs.microsoft.com/windows/wsl/)
- [Docker Desktop WSL2](https://docs.docker.com/desktop/windows/wsl/)

---

## ✅ Post-Installation Checklist

- [ ] WSL2 installed and updated
- [ ] Docker Desktop running and integrated
- [ ] phpharbor installed and working
- [ ] First project created successfully
- [ ] Projects saved in `~` (not in `/mnt/c/`)
- [ ] VS Code with WSL extension configured
- [ ] SSL certificates installed (optional)
- [ ] hosts file configured (optional)

**All OK? Happy coding! 🚀**
