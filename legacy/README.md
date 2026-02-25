# Legacy Scripts

⚠️ **DEPRECATO** - Questi script sono mantenuti per retrocompatibilità ma saranno rimossi in futuro.

## 🔄 Usa il Nuovo CLI

Tutti questi script sono stati sostituiti dal CLI unificato `docker-dev`.

### Tabella di Migrazione

| Script Legacy | Nuovo Comando CLI |
|---------------|-------------------|
| `./legacy/new-project.sh <nome>` | `./docker-dev create <nome>` |
| `./legacy/manage-projects.sh list` | `./docker-dev list` |
| `./legacy/manage-projects.sh start <nome>` | `./docker-dev start <nome>` |
| `./legacy/manage-projects.sh stop <nome>` | `./docker-dev stop <nome>` |
| `./legacy/manage-projects.sh logs <nome>` | `./docker-dev logs <nome>` |
| `./legacy/manage-projects.sh remove <nome>` | `./docker-dev remove <nome>` |
| `./legacy/artisan.sh <nome> <cmd>` | `./docker-dev artisan <nome> <cmd>` |
| `./legacy/code-project.sh <nome>` | `./docker-dev shell <nome>` |
| `./legacy/db-connect.sh <nome>` | `./docker-dev mysql <nome>` |
| `./legacy/start-shared-services.sh mysql` | `./docker-dev shared start mysql` |
| `./legacy/start-shared-php.sh 8.3` | `./docker-dev shared php 8.3` |
| `./legacy/setup-dnsmasq.sh` | `./docker-dev setup dns` |
| `./legacy/restart-docker.sh` | _(usa Docker Desktop)_ |

## 📚 Documentazione

Leggi la documentazione completa del nuovo CLI:
- [CLI-README.md](../CLI-README.md) - Guida completa
- [MIGRATION.md](../MIGRATION.md) - Guida migrazione dettagliata

## ⏱️ Timeline di Deprecazione

- **Fase 1 (Attuale)**: Script spostati in `legacy/`, ancora funzionanti
- **Fase 2 (Prossima)**: Warning quando si usano script legacy
- **Fase 3 (Futura)**: Rimozione completa

## 🚀 Perché Migrare?

Il nuovo CLI offre:
- ✅ Un solo comando: `./docker-dev`
- ✅ Help integrato per ogni comando
- ✅ Output più pulito e colorato
- ✅ Nuove funzionalità (stats, info, shared status)
- ✅ Architettura modulare e manutenibile
- ✅ Comandi più coerenti e prevedibili

## 💡 Quick Start Migrazione

```bash
# Invece di:
cd /Users/vincenzo/docker-dev
./legacy/new-project.sh myapp
./legacy/manage-projects.sh start myapp
./legacy/artisan.sh myapp migrate

# Ora usa:
./docker-dev create myapp
./docker-dev start myapp
./docker-dev artisan myapp migrate
```

## ℹ️ Nota

I progetti esistenti creati con i vecchi script funzionano perfettamente con il nuovo CLI.
Non è necessario ricrearli!
