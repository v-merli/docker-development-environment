# Archive: File Obsoleti

**Data archiviazione:** 23 Marzo 2026  
**Motivo:** Migrazione completata al template unificato con cherry-picking

## Contenuto

### 📁 legacy/
Script originali rimpiazzati dal CLI unificato (`./phpharbor):
- `artisan.sh`, `code-project.sh`, `db-connect.sh`
- `manage-projects.sh`, `new-project.sh`, `new-project-fixed.sh`
- `restart-docker.sh`, `setup-dnsmasq.sh`
- `start-shared-php.sh`, `start-shared-services.sh`

**Sostituito da:** `./phpharbor con moduli in `cli/`

### 📁 backup-old-architecture/
Backup completo creato prima della migrazione al template unificato (20260323)

### 📁 old-templates/
Template Docker Compose obsoleti sostituiti dal sistema unificato:
- `docker-compose.yml` - Template standard originale
- `docker-compose-shared.yml` - Template con servizi condivisi
- `docker-compose-fully-shared.yml` - Template completamente condiviso
- `docker-compose-php.yml` - Template per progetti PHP generici
- `.env.example` - Vecchio esempio di configurazione

**Sostituito da:** 
- `docker-compose-unified.yml` - Template unificato con profili
- `.env-unified.example` - Configurazione completa con cherry-picking

### 📄 Documentazione
- `CONSOLIDATION-COMPLETE.md` - Documento di completamento migrazione CLI
- `MIGRATION.md` - Guida di migrazione agli script nuovi

## Sistema Attuale

### Template Attivi
- ✅ `docker-compose-unified.yml` - Template con profili e cherry-picking
- ✅ `docker-compose-html.yml` - Template per progetti HTML statici
- ✅ `.env-unified.example` - Template environment completo

### CLI Unificato
```bash
./phpharbor create <nome> [--shared-db] [--shared-redis] [--shared-php]
./phpharbor create <nome> [--shared | --fully-shared]
```

### Flag Disponibili
- `--shared-db` - MySQL condiviso
- `--shared-redis` - Redis condiviso
- `--shared-php` - Scheduler/Queue usano PHP condiviso
- `--shared` - Preset: DB + Redis condivisi
- `--fully-shared` - Preset: DB + Redis + PHP condivisi

## Note
Questi file sono mantenuti come riferimento storico e possono essere rimossi definitivamente se non più necessari.
