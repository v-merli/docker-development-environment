# Windows Setup (WSL2)

Guida completa per installare Docker Development Environment su Windows utilizzando WSL2.

## 🪟 Panoramica

Docker Development Environment funziona perfettamente su Windows tramite **WSL2** (Windows Subsystem for Linux 2), che offre:

- ✅ Performance native Linux
- ✅ Piena compatibilità con script bash
- ✅ Integrazione Docker Desktop
- ✅ Stesso workflow di macOS/Linux
- ✅ File system performante

## 📋 Requisiti

- **Windows 10 versione 2004+** (Build 19041+) o **Windows 11**
- **Virtualizzazione hardware abilitata** nel BIOS
- **Almeno 8GB RAM** (16GB consigliati per più progetti)
- **20GB spazio disco** libero

## 🚀 Installazione Passo-Passo

### Step 1: Installa WSL2

Apri **PowerShell** come Amministratore e esegui:

```powershell
# Installa WSL2 con Ubuntu (default)
wsl --install

# Riavvia il computer quando richiesto
```

**Dopo il riavvio**, Ubuntu si aprirà automaticamente e ti chiederà:
- Username (es: `tuo-nome`)
- Password

> 💡 **Nota**: La password non verrà visualizzata mentre digiti (è normale!)

### Step 2: Verifica WSL2

Verifica che WSL2 sia installato correttamente:

```powershell
# Da PowerShell
wsl --list --verbose
```

Output atteso:
```
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

Se vedi `VERSION 1`, aggiorna a WSL2:
```powershell
wsl --set-version Ubuntu 2
```

### Step 3: Installa Docker Desktop

1. **Download**: [Docker Desktop per Windows](https://www.docker.com/products/docker-desktop)

2. **Installa** il file scaricato

3. **Abilita integrazione WSL2**:
   - Apri Docker Desktop
   - Vai in **Settings** (⚙️)
   - **Resources** → **WSL Integration**
   - ✅ Abilita "Enable integration with my default WSL distro"
   - ✅ Abilita "Ubuntu"
   - Click **Apply & Restart**

4. **Verifica** da Ubuntu:
   ```bash
   wsl
   docker --version
   docker compose version
   ```

### Step 4: Installa Docker Dev Environment

Apri **Ubuntu** (dal menu Start) e esegui:

```bash
# Installa con un solo comando
bash <(curl -fsSL https://raw.githubusercontent.com/your-username/docker-development-environment/main/install.sh)
```

Lo script:
- ✅ Rileva automaticamente che sei su WSL2
- ✅ Verifica Docker e prerequisiti
- ✅ Installa e configura tutto

### Step 5: Primo Progetto

```bash
# Setup iniziale
docker-dev setup init

# Crea progetto
docker-dev create myapp --type laravel --php 8.3

# Accedi al progetto
# Da Windows: http://myapp.test
# Oppure usa l'IP WSL
```

---

## 🔧 Configurazione Ottimale

### File System: Usa WSL2, Non Windows

**❌ NON fare questo:**
```bash
cd /mnt/c/Users/TuoNome/Projects  # File system Windows (LENTO!)
```

**✅ Fai questo:**
```bash
cd ~/projects  # File system WSL2 (VELOCE!)
```

**Perché?**
- `/mnt/c/` accede ai file Windows → **10-100x più lento**
- `~` (home WSL) usa file system nativo Linux → **performance ottimali**

### Accedere ai File WSL da Windows

I file WSL sono accessibili da Esplora File Windows:

```
\\wsl$\Ubuntu\home\tuo-username\.docker-dev-env\projects
```

Oppure da terminale Ubuntu:
```bash
explorer.exe .
```

Questo apre la cartella corrente in Esplora File Windows!

### Editor: VS Code con WSL Extension

**Setup consigliato:**

1. Installa **VS Code** su Windows
2. Installa l'estensione **WSL** (Microsoft)
3. Da Ubuntu, apri il progetto:
   ```bash
   cd ~/.docker-dev-env/projects/myapp
   code .
   ```

VS Code si aprirà su Windows ma **lavorerà direttamente su WSL2** (performance native).

---

## 🌐 DNS e Accesso Progetti

### Opzione 1: File hosts (Manuale)

Aggiungi al file `C:\Windows\System32\drivers\etc\hosts` (come Amministratore):

```
127.0.0.1  myapp.test
127.0.0.1  blog.test
127.0.0.1  shop.test
```

### Opzione 2: Accesso via IP

Trova l'IP di WSL:
```bash
# Da Ubuntu
hostname -I
```

Accedi via IP: `http://172.x.x.x:8080`

### Opzione 3: Porta Forward (Automatico con Docker Desktop)

Docker Desktop inoltra automaticamente le porte, quindi:
- `http://localhost:8080` → funziona direttamente!

---

## 🐛 Troubleshooting

### "Docker command not found"

**Soluzione**: Docker Desktop non integrato con WSL2

1. Apri Docker Desktop
2. Settings → Resources → WSL Integration
3. ✅ Abilita Ubuntu
4. Riavvia Ubuntu: `wsl --shutdown` poi riapri

### "Cannot connect to Docker daemon"

**Soluzione**: Docker Desktop non in esecuzione

1. Avvia Docker Desktop su Windows
2. Attendi che sia completamente avviato (icona Docker nella system tray)
3. Riprova in Ubuntu

### Performance Lente

**Causa**: Stai usando file su `/mnt/c/` (Windows)

**Soluzione**: Sposta tutto in WSL2
```bash
# Clona/sposta progetti in home WSL
cd ~
git clone ...
```

### Port già in uso (8080, 8443)

**Soluzione 1**: Ferma altri servizi Windows che usano quelle porte

**Soluzione 2**: Cambia porte proxy
```bash
# Modifica proxy/docker-compose.yml
# Cambia 8080:80 in 8090:80
# Cambia 8443:443 in 8444:443
```

### WSL2 usa troppa RAM

**Soluzione**: Limita memoria WSL2

Crea `C:\Users\TuoNome\.wslconfig`:
```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
```

Riavvia WSL:
```powershell
wsl --shutdown
```

### Certificati SSL non fidati

Su Windows, devi installare la CA di mkcert:

```bash
# In Ubuntu
mkcert -install

# Copia il certificato CA su Windows
cp "$(mkcert -CAROOT)/rootCA.pem" /mnt/c/Users/TuoNome/Desktop/

# Su Windows, double-click rootCA.pem
# Installa in "Autorità di certificazione radice attendibili"
```

---

## 💡 Tips & Tricks

### Alias Utili

Aggiungi a `~/.bashrc` in Ubuntu:

```bash
# Apri file/cartelle in Windows
alias open='explorer.exe'

# Shortcut docker-dev
alias dd='docker-dev'
alias ddl='docker-dev project list'
alias ddc='docker-dev create'
```

### Terminal Windows Moderno

Usa **Windows Terminal** invece di cmd/PowerShell tradizionale:

1. Installa da Microsoft Store
2. Ubuntu sarà integrato nel menu dropdown
3. Supporta tabs, temi, font custom

### Backup Progetti

I progetti in WSL2 non sono automaticamente backuppati da Windows Backup!

```bash
# Backup progetti
tar -czf ~/projects-backup.tar.gz ~/.docker-dev-env/projects

# Copia su Windows
cp ~/projects-backup.tar.gz /mnt/c/Users/TuoNome/Backup/
```

### Network tra Windows e WSL2

Puoi collegarti da Windows ai servizi WSL:

```bash
# Trova IP WSL
ip addr show eth0 | grep inet

# Da browser Windows: http://172.x.x.x:PORT
```

E viceversa:
```bash
# Da Ubuntu, accedi a servizi Windows su localhost
curl http://localhost:PORT
```

---

## 🔄 Aggiornamento

Per aggiornare Docker Dev Environment:

```bash
# Riesegui l'installer (rileva installazione esistente)
bash <(curl -fsSL https://raw.githubusercontent.com/your-username/docker-development-environment/main/install.sh)

# Oppure manualmente
cd ~/.docker-dev-env
git pull origin main
```

---

## 📊 Confronto Performance

| Scenario | Windows Native | WSL2 |
|----------|----------------|------|
| Docker build | - | ⚡⚡⚡ Veloce |
| File I/O | - | ⚡⚡⚡ Nativo |
| Composer install | - | ⚡⚡⚡ Ottimale |
| Vite HMR | - | ⚡⚡⚡ Reattivo |
| Laravel Artisan | - | ⚡⚡⚡ Istantaneo |

**Conclusione**: WSL2 offre performance quasi identiche a Linux nativo!

---

## 🆘 Supporto

**Problemi specifici Windows/WSL2?**
- [GitHub Issues](https://github.com/your-username/docker-development-environment/issues)
- Tag: `windows` o `wsl2`

**Risorse WSL2:**
- [Documentazione WSL2](https://docs.microsoft.com/windows/wsl/)
- [Docker Desktop WSL2](https://docs.docker.com/desktop/windows/wsl/)

---

## ✅ Checklist Post-Installazione

- [ ] WSL2 installato e aggiornato
- [ ] Docker Desktop in esecuzione e integrato
- [ ] docker-dev installato e funzionante
- [ ] Primo progetto creato con successo
- [ ] Progetti salvati in `~` (non in `/mnt/c/`)
- [ ] VS Code con WSL extension configurato
- [ ] Certificati SSL installati (opzionale)
- [ ] File hosts configurato (opzionale)

**Tutto OK? Buon sviluppo! 🚀**
