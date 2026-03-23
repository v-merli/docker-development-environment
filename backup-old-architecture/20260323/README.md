# Backup Architettura Precedente - 23 Marzo 2026

## 📦 Contenuto

Questo backup contiene l'architettura **prima** della transizione al sistema di cherry-picking granulare.

### File inclusi:

- **`cli/`** - Script CLI originali (create.sh, dev.sh, etc.)
- **`templates/`** - Template docker-compose originali:
  - `docker-compose.yml` (standard standalone)
  - `docker-compose-shared.yml` (DB/Redis condivisi)
  - `docker-compose-php.yml` (variante PHP)
  - `docker-compose-fully-shared.yml` (tutto condiviso)
  - `docker-compose-html.yml` (siti statici)
  
- **`dockerfiles/`** - Dockerfile PHP:
  - `php-X.X.Dockerfile` - PHP + Node (per container app)
  - `php-X.X-fpm-only.Dockerfile` - PHP-FPM only (per php-shared)
  
- **`proxy-docker-compose.yml`** - Configurazione servizi condivisi nel proxy

## 🔄 Architettura precedente

### Template rigidi:
- **Standard**: tutto dedicato
- **Shared**: DB+Redis condivisi, app dedicato
- **Fully-shared**: tutto condiviso (con problematiche Vite/HMR)

### Problemi risolti nella nuova architettura:
1. ❌ Template rigidi poco flessibili
2. ❌ Fully-shared confuso (app dedicato + php-shared ridondante)
3. ❌ Nessuna possibilità di cherry-picking

## 🚀 Nuova architettura (implementata dopo questo backup)

### Sistema granulare con flag:
- `--shared-db` - Condividi MySQL
- `--shared-redis` - Condividi Redis  
- `--shared-php` - Condividi PHP-FPM (per scheduler/queue)
- Preset per comodità: `--preset shared`, `--preset fully-shared`

### Container app sempre dedicato:
- ✅ PHP + Node per development
- ✅ Vite/HMR funziona out-of-the-box
- ✅ Porta 5173 dedicata (calcolata automaticamente)

## 🔙 Rollback

Per tornare all'architettura precedente:

```bash
cd /Users/vincenzo/docker-development-environment

# Backup architettura nuova
mv cli cli-new
mv shared/templates templates-new
mv shared/dockerfiles dockerfiles-new

# Ripristino architettura vecchia
cp -r backup-old-architecture/20260323/cli .
cp -r backup-old-architecture/20260323/templates shared/
cp -r backup-old-architecture/20260323/dockerfiles shared/
cp backup-old-architecture/20260323/proxy-docker-compose.yml proxy/docker-compose.yml

# Rebuild servizi se necessario
cd proxy
docker compose --profile shared-services build php-8.3-shared php-8.4-shared
```

---

**Data backup:** 23 Marzo 2026  
**Motivo:** Transizione a architettura cherry-picking granulare
