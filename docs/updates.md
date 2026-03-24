# Sistema di Aggiornamento Automatico

PHPHarbor include un sistema di aggiornamento automatico che permette di:
- Verificare se sono disponibili nuove versioni
- Installare aggiornamenti con un comando
- Preservare tutte le configurazioni e i progetti esistenti

## Comandi Disponibili

### Verifica Aggiornamenti

Controlla se è disponibile una nuova versione su GitHub:

```bash
./phpharbor update check
```

Questo comando:
- ✅ Confronta la versione locale con l'ultima release su GitHub
- ✅ Mostra le note di rilascio (changelog)
- ✅ Offre di installare immediatamente l'aggiornamento

### Installa Aggiornamento

Installa l'ultima versione disponibile o una versione specifica:

```bash
# Installa ultima versione
./phpharbor update install

# Installa versione specifica
./phpharbor update install 1.8.0
./phpharbor update install v1.8.0

# Downgrade a versione precedente
./phpharbor update install 1.5.0
```

Il processo di aggiornamento:
1. Scarica l'ultima versione da GitHub
2. Crea backup delle configurazioni
3. Sostituisce i file di sistema
4. Ripristina configurazioni e certificati
5. Riavvia i servizi se erano in esecuzione

**Cosa viene preservato:**
- ✓ File `.config` (directory progetti, porte)
- ✓ File `proxy/.env` (configurazione proxy)
- ✓ Directory `projects/` (tutti i progetti)
- ✓ Certificati SSL in `proxy/nginx/certs/`
- ✓ Dati ACME in `proxy/nginx/acme/`
- ✓ Container e volumi Docker

**Cosa viene aggiornato:**
- ✓ Script principale `phpharbor
- ✓ Moduli CLI in `cli/`
- ✓ Template in `shared/templates/`
- ✓ Dockerfile in `shared/dockerfiles/`
- ✓ Configurazioni condivise in `shared/`
- ✓ Documentazione in `docs/`

### Elenca Versioni Disponibili

Mostra tutte le versioni pubblicate su GitHub:

```bash
./phpharbor update list
```

Output esempio:
```
Versione corrente: 2.0.0

Versioni disponibili:

  ✓ v2.0.0 - 2026-03-24 - Release 2.0.0 (installata)
    v1.9.0 - 2026-03-15 - Release 1.9.0
    v1.8.2 - 2026-03-10 - Bugfix release
    v1.8.0 - 2026-03-01 - Feature release
```

### Visualizza Changelog

Mostra le novità dell'ultima versione o di una versione specifica:

```bash
# Changelog ultima versione
./phpharbor update changelog

# Changelog versione specifica
./phpharbor update changelog 1.8.0
```

## Configurazione Repository

Dopo aver pubblicato il progetto su GitHub, configura il repository:

### Metodo 1: Variabile d'ambiente

```bash
export PHPHARBOR_GITHUB_REPO="tuo-username/pphpharbor
./phpharbor update check
```

### Metodo 2: Modifica permanente

Edita il file `cli/update.sh` e sostituisci:

```bash
GITHUB_REPO="${PHPHARBOR_GITHUB_REPO:-your-username/pphpharbor"
```

con:

```bash
GITHUB_REPO="${PHPHARBOR_GITHUB_REPO:-tuo-username/pphpharbor"
```

## Workflow di Release

Per pubblicare una nuova versione:

### 1. Aggiorna Versione

Modifica il numero di versione in `phpharbor:

```bash
VERSION="2.1.0"
```

### 2. Crea Release Package

```bash
./create-release.sh 2.1.0
```

Questo genera `releases/phpharbor-2.1.0.tar.gz`.

### 3. Crea GitHub Release

```bash
# Via GitHub CLI
gh release create v2.1.0 \
  releases/phpharbor-2.1.0.tar.gz#php-phpharbor.gz \
  --title "Release 2.1.0" \
  --notes "Changelog..."

# Oppure manualmente su GitHub:
# 1. Vai su https://github.com/username/repo/releases/new
# 2. Tag: v2.1.0
# 3. Title: Release 2.1.0
# 4. Upload: phpharbor-2.1.0.tar.gz rinominato in php-phpharbor.gz
# 5. Pubblica
```

### 4. Test Aggiornamento

```bash
# Su un'installazione esistente
./phpharbor update check
./phpharbor update install
```

## API GitHub

Il sistema usa GitHub Releases API:

```bash
# Endpoint usato
https://api.github.com/repos/username/repo/releases/latest

# Download tarball
https://github.com/username/repo/releases/latest/download/phpharbor.tar.gz
```

**Nota:** L'API di GitHub ha rate limit:
- 60 richieste/ora per IP non autenticati
- 5000 richieste/ora per utenti autenticati

## Sicurezza

### Verifiche durante l'aggiornamento

1. **Controllo connessione**: Verifica che GitHub sia raggiungibile
2. **Validazione versione**: Controlla che la release esista
3. **Conferma utente**: Richiede conferma prima di procedere
4. **Backup automatico**: Salva configurazioni prima dell'aggiornamento
5. **Rollback manuale**: In caso di problemi, ripristina dal backup

### In caso di problemi

Se l'aggiornamento fallisce:

```bash
# Le configurazioni sono in una directory temporanea
# Il percorso viene mostrato durante l'aggiornamento

# Ripristino manuale
cp /tmp/backup-XXXX/.config .
cp /tmp/backup-XXXX/.env proxy/

# Oppure re-installa da zero
curl -fsSL https://raw.githubusercontent.com/username/repo/main/install.sh | bash
```

## Aggiornamenti Automatici Futuri

Possibili miglioramenti:

### Check automatico all'avvio

Aggiungi in `phpharbor:

```bash
# Check aggiornamenti ogni 7 giorni
check_updates_periodically() {
    local last_check_file="$SCRIPT_DIR/.last_update_check"
    if [ ! -f "$last_check_file" ] || [ $(( $(date +%s) - $(stat -f %m "$last_check_file" 2>/dev/null || echo 0) )) -gt 604800 ]; then
        print_info "Verifico aggiornamenti..."
        update_check_silent
        touch "$last_check_file"
    fi
}
```

### Notifiche desktop

Su macOS:

```bash
osascript -e 'display notification "Nuova versione disponibile!" with title "Docker Dev Env"'
```

Su Linux:

```bash
notify-send "Docker Dev Env" "Nuova versione disponibile!"
```

## Testing

Test completo del sistema update:

```bash
# 1. Simula versione vecchia
sed -i.bak 's/VERSION=".*"/VERSION="1.0.0"/' phpharbor

# 2. Verifica check
./phpharbor update check

# 3. Verifica changelog
./phpharbor update changelog

# 4. Test install (se hai una release)
./phpharbor update install

# 5. Verifica versione aggiornata
./phpharbor version
```

## FAQ

### L'aggiornamento cancella i miei progetti?

No. I progetti in `projects/` sono completamente preservati. Anche se hai progetti in una directory personalizzata (configurata con `setup config`), quella directory non viene toccata.

### Devo riavviare i container?

No. I container rimangono in esecuzione. L'aggiornamento riguarda solo gli script e i file di configurazione.

### Posso fare downgrade a una versione precedente?

Sì, ma manualmente:

```bash
# Download versione specifica
curl -fsSL https://github.com/username/repo/releases/download/v2.0.0/phpharbor.tar.gz | tar -xz
```

### L'aggiornamento funziona offline?

No. Serve connessione internet per scaricare da GitHub.

## Link Utili

- GitHub Releases: `https://github.com/username/repo/releases`
- API GitHub: `https://docs.github.com/en/rest/releases`
- Semantic Versioning: `https://semver.org`
