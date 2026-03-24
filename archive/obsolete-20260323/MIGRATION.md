# Migrazione al CLI Unificato

Guida per passare dai vecchi script al nuovo sistema CLI unificato.

## 📋 Stato Attuale

### ✅ Completato
- CLI unificato `phpharbor creato e funzionante
- 5 moduli implementati (project, dev, shared, setup, system, create)
- Tutti i comandi testati e funzionanti
- Help system integrato
- Retrocompatibilità completa con progetti esistenti

### 🔄 In Transizione
I vecchi script sono ancora presenti e funzionanti:
- `new-project.sh` → `./phpharbor create`
- `manage-projects.sh` → `./phpharbor list/start/stop/etc`
- `artisan.sh` → `./phpharbor artisan`
- `start-shared-services.sh` → `./phpharbor shared`
- `setup-dnsmasq.sh` → `./phpharbor setup dns`

## 🎯 Tabella di Migrazione Comandi

| Vecchio Script | Nuovo Comando CLI | Note |
|----------------|-------------------|------|
| `./new-project.sh myapp` | `./phpharbor create myapp` | Stesse opzioni |
| `./new-project.sh myapp --shared` | `./phpharbor create myapp --shared` | Identico |
| `./new-project.sh myapp --fully-shared` | `./phpharbor create myapp --fully-shared` | Identico |
| `./manage-projects.sh list` | `./phpharbor list` | Output migliorato |
| `./manage-projects.sh start myapp` | `./phpharbor start myapp` | Identico |
| `./manage-projects.sh stop myapp` | `./phpharbor stop myapp` | Identico |
| `./manage-projects.sh logs myapp` | `./phpharbor logs myapp` | Identico |
| `./manage-projects.sh remove myapp` | `./phpharbor remove myapp` | Con conferma |
| `./artisan.sh myapp migrate` | `./phpharbor artisan myapp migrate` | Identico |
| `./code-project.sh myapp` | `./phpharbor shell myapp` | Rinominato |
| `./db-connect.sh myapp` | `./phpharbor mysql myapp` | Semplificato |
| `./start-shared-services.sh mysql` | `./phpharbor shared start mysql` | Stessa logica |
| `./start-shared-php.sh 8.3` | `./phpharbor shared php 8.3` | Semplificato |
| `./setup-dnsmasq.sh` | `./phpharbor setup dns` | Con prompt |
| - | `./phpharbor stats` | **Nuovo** |
| - | `./phpharbor info` | **Nuovo** |
| - | `./phpharbor shared status` | **Nuovo** |

## 📝 Esempi Pratici di Migrazione

### Scenario 1: Creazione Progetto Standard

**Prima:**
```bash
./new-project.sh my-shop --type laravel --php 8.3
cd projects/my-shop
docker compose ps
docker compose logs -f
```

**Ora:**
```bash
./phpharbor create my-shop --type laravel --php 8.3
./phpharbor list
./phpharbor logs my-shop
```

### Scenario 2: Sviluppo Quotidiano

**Prima:**
```bash
./manage-projects.sh start my-shop
./code-project.sh my-shop
./artisan.sh my-shop migrate
./artisan.sh my-shop make:controller UserController
```

**Ora:**
```bash
./phpharbor start my-shop
./phpharbor shell my-shop
./phpharbor artisan my-shop migrate
./phpharbor artisan my-shop make:controller UserController
```

### Scenario 3: Gestione Servizi Condivisi

**Prima:**
```bash
./start-shared-services.sh mysql
./start-shared-services.sh redis
./start-shared-php.sh 8.3
./manage-projects.sh shared-status
```

**Ora:**
```bash
./phpharbor shared start mysql
./phpharbor shared start redis
./phpharbor shared php 8.3
./phpharbor shared status
```

### Scenario 4: Setup Nuovo Ambiente

**Prima:**
```bash
./setup-dnsmasq.sh
cd proxy
docker compose up -d
cd ..
./start-shared-services.sh mysql redis
```

**Ora:**
```bash
./phpharbor setup init
# Segui i prompt interattivi
```

## 🔄 Piano di Deprecazione

### Fase 1 (Attuale) - Transizione
- ✅ CLI unificato disponibile e documentato
- ✅ Vecchi script ancora funzionanti
- ✅ Documentazione aggiornata con esempi CLI
- ℹ️ Warning agli utenti sui vecchi script (da aggiungere)

### Fase 2 (Prossimo) - Deprecazione Soft
```bash
# Aggiungere warning nei vecchi script
echo "⚠️  DEPRECATO: Usa './phpharbor create' invece di questo script"
echo "   Vecchi script saranno rimossi in futuro"
echo ""
sleep 2
# ... esegui script normale ...
```

### Fase 3 (Futuro) - Rimozione
- Spostare vecchi script in `legacy/` folder
- Creare symlink per compatibilità temporanea
- Aggiornare tutti i tutorial e documentazione

### Fase 4 (Finale) - Pulizia
- Rimuovere completamente vecchi script
- CLI come unico entrypoint

## ⚙️ Modifiche per Deprecazione Soft (Prossimo Step)

### 1. Aggiungere Warning ai Vecchi Script

```bash
# In new-project.sh, manage-projects.sh, etc
print_warning "DEPRECAZIONE: Questo script sarà rimosso in futuro"
print_info "Usa: ./phpharbor <comando> invece"
echo ""
sleep 2
```

### 2. Creare Script Wrapper

```bash
# legacy-wrapper.sh
#!/bin/bash
SCRIPT_NAME=$(basename "$0")
NEW_COMMAND=${SCRIPT_NAME%.sh}

echo "⚠️  $SCRIPT_NAME è deprecato"
echo "   Usa: ./phpharbor $NEW_COMMAND"
echo ""
read -p "Continuo con il vecchio script? [s/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    exit 1
fi

# Esegui script originale
exec ./legacy/$SCRIPT_NAME "$@"
```

### 3. Aggiornare README Principale

Aggiungere sezione in cima:
```markdown
## ⚡ Quick Start (Nuovo CLI)

Usa il nuovo CLI unificato:
\`\`\`bash
./phpharbor create myapp
./phpharbor start myapp
./phpharbor shell myapp
\`\`\`

Vedi [CLI-README.md](CLI-README.md) per documentazione completa.
```

## 📊 Benefici della Migrazione

### Per l'Utente
- ✅ Un solo comando da ricordare: `./phpharbor`
- ✅ Help integrato: `./phpharbor help`
- ✅ Comandi più coerenti e predicibili
- ✅ Meno file nella root del progetto
- ✅ Autocompletamento più facile (un solo script)

### Per il Maintainer
- ✅ Codice modulare in `cli/`
- ✅ Più facile aggiungere nuove funzionalità
- ✅ Testing più semplice (moduli isolati)
- ✅ Manutenzione centralizzata
- ✅ Versioning del CLI (v2.0.0)

## 🎯 Raccomandazione per gli Utenti

**Se stai iniziando ora**: Usa solo `./phpharbor`, ignora gli altri script.

**Se hai progetti esistenti**: 
1. Continua a usare i vecchi script per ora
2. Prova il nuovo CLI per nuovi progetti
3. Migra gradualmente quando ti senti comodo

**Per team**: 
1. Aggiorna documentazione con nuovi comandi CLI
2. Training session sul nuovo sistema
3. Stabilisci timeline per migrazione completa

## 📚 Risorse

- [CLI-README.md](CLI-README.md) - Documentazione completa CLI
- [README.md](README.md) - Documentazione generale
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architettura sistema
- [SHARED-SERVICES.md](SHARED-SERVICES.md) - Servizi condivisi

## 🆘 Supporto

Se incontri problemi durante la migrazione:
1. I vecchi script funzionano ancora
2. Leggi `./phpharbor help`
3. Controlla esempi in CLI-README.md
4. Confronta comando vecchio vs nuovo in questa guida

## ✅ Checklist Migrazione Personale

- [ ] Leggi CLI-README.md
- [ ] Prova `./phpharbor help`
- [ ] Crea un progetto test: `./phpharbor create test-cli`
- [ ] Prova comandi base: list, start, stop, logs
- [ ] Prova comandi dev: shell, artisan
- [ ] Configura alias (opzionale)
- [ ] Aggiorna script personali se esistenti
- [ ] Migrare progetti esistenti (opzionale, funzionano già)

## 🚀 Prossimi Sviluppi

- [ ] Bash completion per autocompletamento
- [ ] Più comandi info per progetti individuali
- [ ] Export/import configurazioni progetti
- [ ] Health check automatici
- [ ] Backup/restore database
- [ ] Template personalizzati utente
- [ ] Plugin system per estensioni

