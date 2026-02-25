# Migrazione al CLI Unificato

Guida per passare dai vecchi script al nuovo sistema CLI unificato.

## 📋 Stato Attuale

### ✅ Completato
- CLI unificato `docker-dev` creato e funzionante
- 5 moduli implementati (project, dev, shared, setup, system, create)
- Tutti i comandi testati e funzionanti
- Help system integrato
- Retrocompatibilità completa con progetti esistenti

### 🔄 In Transizione
I vecchi script sono ancora presenti e funzionanti:
- `new-project.sh` → `./docker-dev create`
- `manage-projects.sh` → `./docker-dev list/start/stop/etc`
- `artisan.sh` → `./docker-dev artisan`
- `start-shared-services.sh` → `./docker-dev shared`
- `setup-dnsmasq.sh` → `./docker-dev setup dns`

## 🎯 Tabella di Migrazione Comandi

| Vecchio Script | Nuovo Comando CLI | Note |
|----------------|-------------------|------|
| `./new-project.sh myapp` | `./docker-dev create myapp` | Stesse opzioni |
| `./new-project.sh myapp --shared` | `./docker-dev create myapp --shared` | Identico |
| `./new-project.sh myapp --fully-shared` | `./docker-dev create myapp --fully-shared` | Identico |
| `./manage-projects.sh list` | `./docker-dev list` | Output migliorato |
| `./manage-projects.sh start myapp` | `./docker-dev start myapp` | Identico |
| `./manage-projects.sh stop myapp` | `./docker-dev stop myapp` | Identico |
| `./manage-projects.sh logs myapp` | `./docker-dev logs myapp` | Identico |
| `./manage-projects.sh remove myapp` | `./docker-dev remove myapp` | Con conferma |
| `./artisan.sh myapp migrate` | `./docker-dev artisan myapp migrate` | Identico |
| `./code-project.sh myapp` | `./docker-dev shell myapp` | Rinominato |
| `./db-connect.sh myapp` | `./docker-dev mysql myapp` | Semplificato |
| `./start-shared-services.sh mysql` | `./docker-dev shared start mysql` | Stessa logica |
| `./start-shared-php.sh 8.3` | `./docker-dev shared php 8.3` | Semplificato |
| `./setup-dnsmasq.sh` | `./docker-dev setup dns` | Con prompt |
| - | `./docker-dev stats` | **Nuovo** |
| - | `./docker-dev info` | **Nuovo** |
| - | `./docker-dev shared status` | **Nuovo** |

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
./docker-dev create my-shop --type laravel --php 8.3
./docker-dev list
./docker-dev logs my-shop
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
./docker-dev start my-shop
./docker-dev shell my-shop
./docker-dev artisan my-shop migrate
./docker-dev artisan my-shop make:controller UserController
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
./docker-dev shared start mysql
./docker-dev shared start redis
./docker-dev shared php 8.3
./docker-dev shared status
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
./docker-dev setup init
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
echo "⚠️  DEPRECATO: Usa './docker-dev create' invece di questo script"
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
print_info "Usa: ./docker-dev <comando> invece"
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
echo "   Usa: ./docker-dev $NEW_COMMAND"
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
./docker-dev create myapp
./docker-dev start myapp
./docker-dev shell myapp
\`\`\`

Vedi [CLI-README.md](CLI-README.md) per documentazione completa.
```

## 📊 Benefici della Migrazione

### Per l'Utente
- ✅ Un solo comando da ricordare: `./docker-dev`
- ✅ Help integrato: `./docker-dev help`
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

**Se stai iniziando ora**: Usa solo `./docker-dev`, ignora gli altri script.

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
2. Leggi `./docker-dev help`
3. Controlla esempi in CLI-README.md
4. Confronta comando vecchio vs nuovo in questa guida

## ✅ Checklist Migrazione Personale

- [ ] Leggi CLI-README.md
- [ ] Prova `./docker-dev help`
- [ ] Crea un progetto test: `./docker-dev create test-cli`
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

