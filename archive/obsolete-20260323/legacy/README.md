# Legacy Scripts

⚠️ **DEPRECATO** - Questi script sono mantenuti per retrocompatibilità ma saranno rimossi in futuro.

## 🔄 Usa il Nuovo CLI

Tutti questi script sono stati sostituiti dal CLI unificato `phpharbor.

### Tabella di Migrazione

| Script Legacy | Nuovo Comando CLI |
|---------------|-------------------|
| `./legacy/new-project.sh <nome>` | `./phpharbor create <nome>` |
| `./legacy/manage-projects.sh list` | `./phpharbor list` |
| `./legacy/manage-projects.sh start <nome>` | `./phpharbor start <nome>` |
| `./legacy/manage-projects.sh stop <nome>` | `./phpharbor stop <nome>` |
| `./legacy/manage-projects.sh logs <nome>` | `./phpharbor logs <nome>` |
| `./legacy/manage-projects.sh remove <nome>` | `./phpharbor remove <nome>` |
| `./legacy/artisan.sh <nome> <cmd>` | `./phpharbor artisan <nome> <cmd>` |
| `./legacy/code-project.sh <nome>` | `./phpharbor shell <nome>` |
| `./legacy/db-connect.sh <nome>` | `./phpharbor mysql <nome>` |
| `./legacy/start-shared-services.sh mysql` | `./phpharbor shared start mysql` |
| `./legacy/start-shared-php.sh 8.3` | `./phpharbor shared php 8.3` |
| `./legacy/setup-dnsmasq.sh` | `./phpharbor setup dns` |
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
- ✅ Un solo comando: `./phpharbor`
- ✅ Help integrato per ogni comando
- ✅ Output più pulito e colorato
- ✅ Nuove funzionalità (stats, info, shared status)
- ✅ Architettura modulare e manutenibile
- ✅ Comandi più coerenti e prevedibili

## 💡 Quick Start Migrazione

```bash
# Invece di:
cd /Users/vincenzo/phpharbor
./legacy/new-project.sh myapp
./legacy/manage-projects.sh start myapp
./legacy/artisan.sh myapp migrate

# Ora usa:
./phpharbor create myapp
./phpharbor start myapp
./phpharbor artisan myapp migrate
```

## ℹ️ Nota

I progetti esistenti creati con i vecchi script funzionano perfettamente con il nuovo CLI.
Non è necessario ricrearli!
