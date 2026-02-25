# 🔄 Guida ai Servizi Condivisi

## Perché Usare Servizi Condivisi?

### Problema
Con molti progetti attivi, ogni progetto con PHP, MySQL e Redis dedicati consuma:
- PHP-FPM: ~100-150 MB RAM
- MySQL: ~200-400 MB RAM
- Redis: ~50-100 MB RAM

**Con 10 progetti = ~5 GB di RAM solo per i servizi!** 😰

### Soluzione: Servizi Condivisi
Singole istanze condivise di PHP, MySQL e Redis per tutti i progetti:
- PHP-FPM condiviso per versione: ~150 MB (tutte le versioni attive: ~900 MB)
- MySQL condiviso: ~400 MB (indipendentemente dal numero di progetti)
- Redis condiviso: ~100 MB (indipendentemente dal numero di progetti)

**Risparmio: fino al 90% di RAM con 5+ progetti!**

## Quick Start

### 1. Avvia i Servizi Condivisi

```bash
./start-shared-services.sh
```

### 2. Crea Progetti con Servizi Condivisi

```bash
# Solo DB condivisi (MySQL + Redis)
./new-project.sh shop --shared

# Solo MySQL condiviso
./new-project.sh blog --shared-db

# Solo Redis condiviso
./new-project.sh api --shared-redis

# Solo PHP condiviso (nuovo!)
./new-project.sh test1 --shared-php --php 8.3

# Tutto condiviso (massimo risparmio!)
./new-project.sh test2 --fully-shared --php 8.3
```

### 3. Crea il Database per il Progetto

```bash
# Accedi a MySQL condiviso
./manage-projects.sh shared-mysql

# Crea il database
CREATE DATABASE shop_db;
EXIT;
```

### 4. Configura il Progetto

Il file `.env` del progetto è già configurato automaticamente:

```env
DB_HOST=mysql-shared
DB_PORT=3306
DB_DATABASE=shop_db
DB_USERNAME=root
DB_PASSWORD=rootpassword

REDIS_HOST=redis-shared
REDIS_PORT=6379
```

### 5. Esegui le Migration

```bash
./manage-projects.sh artisan shop migrate
```

## Gestione Quotidiana

### Controllare lo Stato

```bash
./manage-projects.sh shared-status

# Output mostra:
# - Database e Cache (MySQL, Redis)
# - PHP-FPM Condivisi (per versione)
```

### Avviare PHP Condiviso Specifico

```bash
# Avvia PHP 8.3 condiviso
./manage-projects.sh shared-php 8.3

# Avvia PHP 8.1 condiviso
./manage-projects.sh shared-php 8.1
```

### Vedere i Log

```bash
# Log di tutti i servizi condivisi
./manage-projects.sh shared-logs

# Log di PHP specifico
./manage-projects.sh shared-php-logs 8.3
```

### Fermare i Servizi (per risparmiare RAM quando non in uso)

```bash
./manage-projects.sh shared-stop
```

### Riavviare i Servizi

```bash
./manage-projects.sh shared-start
```

## Accesso ai Database

### Via CLI

```bash
# MySQL
./manage-projects.sh shared-mysql

# Redis
docker exec -it redis-shared redis-cli
```

### Via Applicazioni GUI

**MySQL:**
- Host: `localhost`
- Port: `3306`
- User: `root`
- Password: `rootpassword`

**Redis:**
- Host: `localhost`
- Port: `6379`

## Best Practices

### ✅ Quando Usare Servizi Condivisi

#### Database Condivisi (--shared, --shared-db, --shared-redis)
- Progetti in sviluppo locale
- Hai 3+ progetti contemporaneamente attivi
- RAM limitata sul Mac (8-16 GB)
- Database di piccole dimensioni (<1 GB)
- Non servono configurazioni MySQL particolari

#### PHP Condiviso (--shared-php, --fully-shared)
- **Tutti i progetti usano la stessa versione PHP**
- Progetti semplici senza dipendenze di sistema particolari
- Massimo risparmio RAM (10+ progetti con poca memoria)
- Tutti i progetti Laravel/WordPress con stessa versione PHP
- Ambiente di test/staging con risorse limitate

### ❌ Quando Usare Servizi Dedicati

#### Database Dedicati
- Progetti di produzione
- Serve MySQL 5.7 per un progetto e 8.0 per un altro
- Database molto grandi o query intensive
- Configurazioni MySQL custom necessarie
- Solo 1-2 progetti attivi

#### PHP Dedicato
- **Progetti che richiedono versioni PHP diverse**
- Estensioni PHP personalizzate
- Configurazioni php.ini specifiche
- Progetti critici che richiedono isolamento
- Performance ottimali richieste

## Architettura Ibrida (Consigliata)

Puoi mescolare! Esempio:

```bash
# Progetto principale: tutto dedicato
./new-project.sh main-app --mysql 8.0

# Progetti secondari: solo DB condivisi
./new-project.sh test1 --shared --php 8.3
./new-project.sh test2 --shared --php 8.1

# Progetti leggeri: tutto condiviso
./new-project.sh demo1 --fully-shared --php 8.3
./new-project.sh demo2 --fully-shared --php 8.3
./new-project.sh demo3 --fully-shared --php 8.3
```

**Consumo RAM:**
- main-app: ~500 MB (tutto dedicato)
- test1: ~250 MB (PHP dedicato, DB condivisi)
- test2: ~250 MB (PHP dedicato, DB condivisi)
- demo1-3: ~30 MB (solo Nginx, resto condiviso)
- **Totale: ~1.1 GB** vs **~3 GB** se tutti dedicati

### Strategia Ottimale

1. **Progetti produzione/critici**: tutto dedicato
2. **Progetti sviluppo attivo**: DB condivisi, PHP dedicato (per versioni diverse)
3. **Progetti demo/test**: tutto condiviso (massimo risparmio)

## Troubleshooting

### I servizi condivisi non partono

```bash
# Verifica che il proxy sia attivo
docker ps | grep nginx-proxy

# Se non è attivo
cd proxy
docker-compose up -d

# Poi avvia i servizi
docker-compose --profile shared-services up -d
```

### Errore di connessione da container

Verifica che il progetto sia sulla rete `proxy`:

```bash
docker inspect <container-name> | grep proxy
```

### Database non trovato

```bash
# Lista database
./manage-projects.sh shared-mysql
SHOW DATABASES;

# Crea se mancante
CREATE DATABASE myproject_db;
```

## Migrazione da Dedicato a Condiviso

### 1. Esporta il Database

```bash
cd projects/myproject
docker-compose exec mysql mysqldump -uroot -proot myproject_db > backup.sql
```

### 2. Ferma e Rimuovi Container Dedicati

```bash
docker-compose down -v
```

### 3. Modifica docker-compose.yml

Usa il template `shared/templates/docker-compose-shared.yml`

### 4. Aggiorna .env

```env
DB_HOST=mysql-shared
MYSQL_ROOT_PASSWORD=rootpassword
```

### 5. Importa il Database

```bash
# Crea database
./manage-projects.sh shared-mysql
CREATE DATABASE myproject_db;
EXIT;

# Importa
cat backup.sql | docker exec -i mysql-shared mysql -uroot -prootpassword myproject_db
```

### 6. Riavvia il Progetto

```bash
docker-compose up -d
```

## FAQ

**Q: Posso usare versioni MySQL diverse con servizi condivisi?**
A: No, tutti i progetti condivideranno la stessa versione (MySQL 8.0 di default).

**Q: Posso usare versioni PHP diverse con --fully-shared?**
A: No, con --fully-shared tutti i progetti devono usare la stessa versione PHP. Usa --shared (solo DB) se hai bisogno di versioni PHP diverse.

**Q: Come funziona il PHP condiviso tecnicamente?**
A: Un container PHP-FPM monta la cartella `projects/` completa. Nginx di ogni progetto punta a `php-X.X-shared:9000` invece di avere il proprio container PHP.

**Q: I database sono isolati?**
A: Sì, ogni progetto ha il suo database separato nello stesso server MySQL.

**Q: Cosa succede se fermo i servizi condivisi?**
A: Tutti i progetti che usano servizi condivisi smetteranno di funzionare.

**Q: Posso mixare progetti con servizi dedicati e condivisi?**
A: Sì! È l'approccio consigliato per ottimizzare le risorse.

**Q: Posso avere PHP 8.3 condiviso e PHP 8.1 condiviso contemporaneamente?**
A: Sì! Puoi avviare multiple versioni PHP condivise. Ogni versione è un container separato.

```bash
./manage-projects.sh shared-php 8.3
./manage-projects.sh shared-php 8.1
./new-project.sh project1 --shared-php --php 8.3
./new-project.sh project2 --shared-php --php 8.1
```

**Q: Come faccio backup dei database condivisi?**
A: 
```bash
docker exec mysql-shared mysqldump -uroot -prootpassword --all-databases > backup.sql
```

**Q: Redis supporta database multipli?**
A: Sì, Redis ha 16 database (0-15). Puoi assegnare un numero diverso per progetto nel file `.env`:
```env
REDIS_DB=1  # progetto 1
REDIS_DB=2  # progetto 2
```

## Monitoraggio Risorse

```bash
# Vedi consumo memoria di tutti i container
docker stats

# Solo servizi condivisi
docker stats mysql-shared redis-shared
```

---

**💡 Tip:** Inizia con servizi condivisi. Se un progetto diventa complesso, passa a dedicati facilmente!
