# Installazione

Guida completa all'installazione di Docker Development Environment.

## 📋 Requisiti

### Sistema Operativo

- ✅ **macOS** (10.15+)
- ✅ **Linux** (Ubuntu, Debian, RHEL, CentOS, ecc.)
- ✅ **Windows** (10/11 con WSL2) → **[Guida Windows completa →](windows-setup.md)**

### Obbligatori

- **Docker** (v20.10+)
  - macOS: [Docker Desktop](https://www.docker.com/products/docker-desktop)
  - Linux: [Docker Engine](https://docs.docker.com/engine/install/)
  - Verifica: `docker --version`

### Opzionali (ma consigliati)

- **mkcert** - Per certificati SSL locali HTTPS
  - macOS:
    ```bash
    brew install mkcert
    mkcert -install
    ```
  - Linux: [Installazione da GitHub](https://github.com/FiloSottile/mkcert#installation)
    ```bash
    # Debian/Ubuntu
    wget https://github.com/FiloSottile/mkcert/releases/latest/download/mkcert-v*-linux-amd64
    chmod +x mkcert-v*-linux-amd64
    sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
    mkcert -install
    ```

- **dnsmasq** - Per DNS wildcard (*.test → 127.0.0.1)
  - macOS: `brew install dnsmasq`
  - Linux: `sudo apt-get install dnsmasq` (Debian/Ubuntu)

---

## 🚀 Installazione Rapida

### Metodo 1: Script di Installazione (Consigliato)

Un solo comando per installare tutto (funziona su **macOS, Linux e Windows WSL2**):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/your-username/docker-development-environment/main/install.sh)
```

Lo script:
- ✅ Rileva automaticamente il sistema operativo (macOS/Linux/WSL2)
- ✅ Verifica prerequisiti
- ✅ Clona il repository in `~/.docker-dev-env`
- ✅ Imposta permessi eseguibili su `docker-dev`
- ✅ Crea symlink `/usr/local/bin/docker-dev`
- ✅ Configura autocompletamento bash/zsh
- ✅ Esegue setup iniziale (opzionale)

> 🪟 **Utenti Windows**: Prima di eseguire lo script, segui la **[Guida Windows/WSL2 →](windows-setup.md)** per installare WSL2 e Docker Desktop.

### Metodo 2: Installazione Manuale

```bash
# 1. Clone repository
git clone https://github.com/your-username/docker-development-environment.git ~/.docker-dev-env
cd ~/.docker-dev-env

# 2. Imposta permessi e crea symlink
chmod +x docker-dev
sudo ln -sf ~/.docker-dev-env/docker-dev /usr/local/bin/docker-dev

# 3. Autocompletamento (bash)
echo 'source ~/.docker-dev-env/docker-dev-completion.bash' >> ~/.bashrc
source ~/.bashrc

# 3. Autocompletamento (zsh)
echo 'source ~/.docker-dev-env/docker-dev-completion.bash' >> ~/.zshrc
source ~/.zshrc

# 4. Setup iniziale
docker-dev setup init
```

---

## ⚙️ Setup Iniziale

Dopo l'installazione, esegui il setup per configurare:

```bash
docker-dev setup init
```

Questo crea:
- **Directory Progetti** - Scegli dove salvare i progetti (default: `~/.docker-dev-env/projects`)
- **Nginx Reverse Proxy** - Routing automatico dei progetti
- **SSL Certificate Authority** - Certificati HTTPS locali
- **Rete Docker condivisa** - Comunicazione tra container
- **DNS locale** (opzionale) - Risoluzione *.test

### 📁 Configurazione Directory Progetti

Durante il setup ti verrà chiesto dove salvare i progetti:

```
Dove vuoi salvare i tuoi progetti Docker?

1) ~/.docker-dev-env/projects (default)
2) ~/Development/docker-projects
3) Percorso personalizzato
```

**Vantaggi directory custom:**
- ✅ Organizzazione personale (es: tutti i progetti in `~/Development`)
- ✅ Performance (usa SSD separato più veloce)
- ✅ Backup semplificato (cartella esterna al tool)
- ✅ Condivisione con altri strumenti

**Cambiare directory in seguito:**
```bash
docker-dev setup config
```

Lo script può anche **spostare automaticamente** i progetti esistenti nella nuova directory.

### 🔌 Configurazione Porte

Puoi personalizzare le porte dei servizi per evitare conflitti:

```bash
docker-dev setup ports
```

**Porte configurabili:**
- **HTTP**: Default 8080 (accesso web progetti)
- **HTTPS**: Default 8443 (accesso HTTPS progetti)
- **MySQL**: Default 3306 (MySQL condiviso)
- **Redis**: Default 6379 (Redis condiviso)

**Casi d'uso comuni:**
- Porta 8080 già occupata → Usa 8090
- Multipli ambienti Docker → Usa porte diverse per non confondere
- MySQL locale già attivo → Usa 3307 per quello condiviso

**Modifica manuale:**
Puoi anche modificare direttamente `~/.docker-dev-env/.config`:
```bash
HTTP_PORT=8090
HTTPS_PORT=8444
MYSQL_SHARED_PORT=3307
REDIS_SHARED_PORT=6380
```

Dopo la modifica, riavvia i servizi:
```bash
docker-dev setup proxy  # Riavvia proxy con nuove porte
```

---

## 🧪 Verifica Installazione

```bash
# Versione
docker-dev version

# Help
docker-dev help

# Status servizi condivisi
docker-dev shared status
```

---

## 🏃 Primo Progetto

### Modalità Interattiva

```bash
docker-dev create
```

Ti guida attraverso un menu per scegliere:
- Nome progetto
- Tipo (Laravel, WordPress, HTML statico)
- Versione PHP e Node
- Servizi dedicati o condivisi

### Modalità CLI

```bash
# Laravel completo
docker-dev create myapp --type laravel --php 8.3 --node 22

# Laravel con servizi condivisi
docker-dev create myapp --type laravel --fully-shared

# WordPress con MySQL dedicato, Redis condiviso
docker-dev create myblog --type wordpress --shared-redis

# HTML statico
docker-dev create landing --type html --shared-php
```

---

## 📦 Gestione Progetti

```bash
# Lista progetti
docker-dev project list

# Avvia progetto
docker-dev dev myapp

# Stop progetto
docker-dev project stop myapp

# Logs
docker-dev project logs myapp

# Info dettagliate
docker-dev project info myapp

# Rimuovi progetto
docker-dev project remove myapp
```

---

## 🔧 Troubleshooting

### Permessi su /usr/local/bin

Se non hai permessi per creare symlink:

```bash
# Alternativa: aggiungi al PATH
echo 'export PATH="$HOME/.docker-dev-env:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Docker Compose non trovato

Verifica versione Docker Compose:

```bash
# Plugin Compose V2 (nuovo)
docker compose version

# Standalone Compose V1 (obsoleto)
docker-compose --version
```

Docker Dev Environment supporta entrambi.

### Porta 80/443 già in uso

Se hai Apache/Nginx installato localmente:

```bash
# macOS - Stop Apache
sudo apachectl stop

# Disabilita autostart
sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null
```

### mkcert non funziona

Reinstalla CA:

```bash
mkcert -uninstall
mkcert -install
docker-dev ssl setup-ca
```

### Conflitti di porte Vite

Se hai conflitti sulla porta 5173:

```bash
# Riavvia il progetto (cerca automaticamente porta libera)
docker-dev project restart myapp

# Oppure specifica porta manuale in projects/myapp/.env
VITE_PORT=5999
```

---

## 🔄 Aggiornamento

### Script Automatico

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/your-username/docker-development-environment/main/install.sh)
```

Lo script rileva installazione esistente e propone aggiornamento.

### Manuale

```bash
cd ~/.docker-dev-env
git pull origin main
```

---

## 🗑️ Disinstallazione

### Rimuovi Tool

```bash
# Rimuovi symlink
sudo rm /usr/local/bin/docker-dev

# Rimuovi repository
rm -rf ~/.docker-dev-env

# Rimuovi autocompletamento da shell RC
# Rimuovi manualmente le righe da ~/.zshrc o ~/.bashrc
```

### Rimuovi Progetti

```bash
# Lista tutti i progetti
docker-dev project list

# Rimuovi singolarmente
docker-dev project remove PROJECT_NAME

# Oppure rimuovi manualmente
cd ~/.docker-dev-env/projects
rm -rf PROJECT_NAME
docker stop $(docker ps -q --filter "name=PROJECT_NAME")
docker rm $(docker ps -aq --filter "name=PROJECT_NAME")
```

### Rimuovi Servizi Condivisi

```bash
# Stop servizi
docker-dev shared stop

# Rimuovi container
docker stop proxy mysql-shared redis-shared proxy-php-8.3-shared
docker rm proxy mysql-shared redis-shared proxy-php-8.3-shared

# Rimuovi network
docker network rm proxy-network

# Rimuovi volumi (ATTENZIONE: perde i dati)
docker volume rm mysql-data redis-data
```

---

## 📚 Risorse

- **[README.md](README.md)** - Panoramica generale
- **[QUICK-START.md](QUICK-START.md)** - Guida rapida
- **[CLI-README.md](CLI-README.md)** - Documentazione CLI completa
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architettura tecnica
- **[SHARED-SERVICES.md](SHARED-SERVICES.md)** - Servizi condivisi
- **[SSL-SETUP.md](SSL-SETUP.md)** - Configurazione HTTPS
- **[WORKERS-GUIDE.md](WORKERS-GUIDE.md)** - Laravel workers e scheduler

---

## 💬 Supporto

- **Issues**: [GitHub Issues](https://github.com/your-username/docker-development-environment/issues)
- **Discussioni**: [GitHub Discussions](https://github.com/your-username/docker-development-environment/discussions)
- **Pull Requests**: Contributi benvenuti!

---

## 📝 Note

- L'installazione richiede circa **500MB** di spazio disco (repository + immagini Docker base)
- Il primo `docker-dev create` scarica le immagini PHP (circa 300-500MB per versione)
- I progetti risiedono in `~/.docker-dev-env/projects/PROJECT_NAME`
- Configurazioni globali in `~/.docker-dev-env/proxy/` e `~/.docker-dev-env/shared/`
