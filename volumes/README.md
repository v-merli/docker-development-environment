# PHPHarbor Volumes

Questa directory contiene tutti i volumi Docker di PHPHarbor, organizzati per tipologia.

## Struttura

```
volumes/
├── mysql/          # Volumi MySQL (shared e dedicated)
├── mariadb/        # Volumi MariaDB (shared e dedicated)
├── redis/          # Volumi Redis (shared e dedicated)
└── other/          # Altri volumi (es. PostgreSQL, MongoDB, ecc.)
```

## Volumi Condivisi (Shared Services)

I servizi condivisi hanno volumi nella seguente struttura:

- **MySQL**: `mysql/mysql-{version}-shared/` (es. `mysql/mysql-8.0-shared/`)
- **MariaDB**: `mariadb/mariadb-{version}-shared/` (es. `mariadb/mariadb-11.4-shared/`)
- **Redis**: `redis/redis-{version}-shared/` (es. `redis/redis-7-shared/`)

## Volumi Dedicati (Progetti)

Ogni progetto ha i propri volumi organizzati per nome progetto:

- **MySQL**: `mysql/{project-name}/`
- **MariaDB**: `mariadb/{project-name}/`
- **Redis**: `redis/{project-name}/`

## Backup e Migrazione

### Backup di un database

```bash
# MySQL/MariaDB
docker exec mysql-8.0-shared mysqldump -u root -prootpassword dbname > backup.sql

# Redis
docker exec redis-7-shared redis-cli --rdb /data/dump.rdb
```

### Migrazione da Named Volumes

Se hai volumi esistenti da migrare, puoi usare:

```bash
# Esempio per MySQL 8.0 shared
docker run --rm -v mysql_8_0_shared_data:/from -v $(pwd)/volumes/mysql/mysql-8.0-shared:/to alpine sh -c "cd /from && cp -av . /to"
```

## Note

- I dati dei volumi sono esclusi dal controllo versione (vedi `.gitignore`)
- Assicurati di avere backup regolari dei database di produzione
- I volumi locali sono specifici per macchina (non condivisi tra team)
