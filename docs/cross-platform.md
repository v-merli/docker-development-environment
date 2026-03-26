# Cross-Platform Compatibility

PHPHarbor is fully compatible with macOS, Linux and Windows (via WSL2).

## OS Detection System

The main script includes a `detect_os()` function that automatically detects:

- **macOS** (`darwin`)
- **Native Linux** (`linux-gnu`)
- **WSL2** (Linux with Microsoft kernel)

## Platform Differences

### DNS (dnsmasq)

#### macOS
```bash
# Installation via Homebrew
brew install dnsmasq

# Configuration
/usr/local/etc/dnsmasq.conf
/etc/resolver/test

# Service
brew services start dnsmasq
```

#### Linux
```bash
# Installation via apt
sudo apt-get install -y dnsmasq

# Configuration
/etc/dnsmasq.d/phpharbor-test.conf
/etc/systemd/resolved.conf.d/

# Service
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq
```

### SSL (mkcert)

#### macOS
```bash
# Installation
brew install mkcert

# CA installed in
/Library/Keychains/System.keychain
```

#### Linux
```bash
# Installation from source
curl -JLO https://dl.filippo.io/mkcert/latest?for=linux/amd64
chmod +x mkcert-v*-linux-amd64
sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert

# CA installed in
~/.pki/nssdb/
/usr/local/share/ca-certificates/
```

### Shell Commands

#### sed
```bash
# macOS: requires backup extension
sed -i.bak 's/old/new/' file

# Linux: no extension
sed -i 's/old/new/' file
```

This is automatically handled by the `install.sh` script.

## Files Modified for Cross-Platform

### Core
- `phpharbor` - `detect_os()` function for OS detection
- `install.sh` - OS-specific `sed` handling

### CLI Modules
- `cli/setup.sh` - DNS setup and system checks
- `cli/ssl.sh` - mkcert installation and CA management
- `cli/create.sh` - mkcert installation suggestions

## Cross-Platform Testing

To test on Linux from macOS:

```bash
# Automatic script with Multipass
./test-linux.sh

# Manual test
multipass launch --name test-vm 22.04
multipass shell test-vm
```

## Windows Compatibility

PHPHarbor works on Windows via WSL2:

1. Install WSL2 with Ubuntu
2. Install Docker Desktop with WSL2 backend
3. Clone/install the tool inside WSL2

See [docs/windows-setup.md](windows-setup.md) for complete guide.

## Platform-Specific Commands

All commands that use platform-specific tools automatically detect the OS and adapt behavior:

- ✅ Package installation (brew vs apt-get)
- ✅ Service management (brew services vs systemctl)
- ✅ Certificate management (keychain vs NSS)
- ✅ DNS configuration (resolver vs resolved)

## Compatibility Verification

To verify everything works on your platform:

```bash
# System info
./phpharbor info

# Test setup
./phpharbor setup init

# Verify DNS (if configured)
ping test.test

# Verify SSL (if configured)
./phpharbor ssl verify
```
