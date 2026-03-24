# Compatibilità Cross-Platform

PHPHarbor è completamente compatibile con macOS, Linux e Windows (via WSL2).

## Sistema di Rilevamento OS

Lo script principale include una funzione `detect_os()` che rileva automaticamente:

- **macOS** (`darwin`)
- **Linux** nativo (`linux-gnu`)
- **WSL2** (Linux con kernel Microsoft)

## Differenze per Piattaforma

### DNS (dnsmasq)

#### macOS
```bash
# Installazione via Homebrew
brew install dnsmasq

# Configurazione
/usr/local/etc/dnsmasq.conf
/etc/resolver/test

# Servizio
brew services start dnsmasq
```

#### Linux
```bash
# Installazione via apt
sudo apt-get install -y dnsmasq

# Configurazione
/etc/dnsmasq.d/phpharbor-test.conf
/etc/systemd/resolved.conf.d/

# Servizio
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq
```

### SSL (mkcert)

#### macOS
```bash
# Installazione
brew install mkcert

# CA installata in
/Library/Keychains/System.keychain
```

#### Linux
```bash
# Installazione da source
curl -JLO https://dl.filippo.io/mkcert/latest?for=linux/amd64
chmod +x mkcert-v*-linux-amd64
sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert

# CA installata in
~/.pki/nssdb/
/usr/local/share/ca-certificates/
```

### Comandi Shell

#### sed
```bash
# macOS: richiede estensione backup
sed -i.bak 's/old/new/' file

# Linux: nessuna estensione
sed -i 's/old/new/' file
```

Questo è gestito automaticamente dallo script `install.sh`.

## File Modificati per Cross-Platform

### Core
- `phpharbor - Funzione `detect_os()` per rilevamento OS
- `install.sh` - Gestione `sed` specifico per OS

### Moduli CLI
- `cli/setup.sh` - Setup DNS e verifiche sistema
- `cli/ssl.sh` - Installazione mkcert e gestione CA
- `cli/create.sh` - Suggerimenti installazione mkcert

## Test Cross-Platform

Per testare su Linux da macOS:

```bash
# Script automatico con Multipass
./test-linux.sh

# Test manuale
multipass launch --name test-vm 22.04
multipass shell test-vm
```

## Compatibilità Windows

PHPHarbor funziona su Windows tramite WSL2:

1. Installare WSL2 con Ubuntu
2. Installare Docker Desktop con backend WSL2
3. Clonare/installare il tool dentro WSL2

Vedi [docs/windows-setup.md](windows-setup.md) per la guida completa.

## Comandi Specifici per Piattaforma

Tutti i comandi che usano tool specifici di una piattaforma rilevano automaticamente l'OS e adattano il comportamento:

- ✅ Installazione pacchetti (brew vs apt-get)
- ✅ Gestione servizi (brew services vs systemctl)
- ✅ Gestione certificati (keychain vs NSS)
- ✅ Configurazione DNS (resolver vs resolved)

## Verifica Compatibilità

Per verificare che tutto funzioni sulla tua piattaforma:

```bash
# Info sistema
./phpharbor info

# Test setup
./phpharbor setup init

# Verifica DNS (se configurato)
ping test.test

# Verifica SSL (se configurato)
./phpharborssl verify
```
