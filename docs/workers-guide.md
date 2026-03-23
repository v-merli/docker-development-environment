# 🔄 Guida Gestione Workers e Scheduler Laravel

## Architettura Workers

Ogni progetto Laravel ha container dedicati per i task in background:

### 📅 Scheduler Container
**Automaticamente attivo** in tutti i progetti Laravel

```bash
# Container: {progetto}-scheduler
# Funzione: Esegue php artisan schedule:run ogni 60 secondi
# Sempre attivo ✅
```

Il container scheduler esegue automaticamente i task schedulati in `app/Console/Kernel.php`:

```php
protected function schedule(Schedule $schedule)
{
    $schedule->command('emails:send')->daily();
    $schedule->command('reports:generate')->hourly();
}
```

### ⚙️ Queue Worker Container
**Commentato di default** - da abilitare se usi le code

#### Come Abilitare il Queue Worker

**1. Modifica docker-compose.yml del progetto:**

```yaml
# Decommenta questa sezione:
  queue:
    build:
      context: ../../shared/dockerfiles
      dockerfile: php-${PHP_VERSION}.Dockerfile
      args:
        NODE_VERSION: ${NODE_VERSION:-20}
    container_name: ${PROJECT_NAME}-queue
    restart: unless-stopped
    working_dir: /var/www/projects/${PROJECT_NAME}/app  # fully-shared
    # working_dir: /var/www/html                         # dedicato
    volumes:
      - ./app:/var/www/projects/${PROJECT_NAME}/app     # fully-shared
      # - ./app:/var/www/html                            # dedicato
    networks:
      - proxy  # fully-shared
      # - backend  # dedicato
    command: php artisan queue:work --tries=3
```

**2. Riavvia il progetto:**

```bash
cd projects/{nome-progetto}
docker compose up -d --build
```

**3. Verifica che sia attivo:**

```bash
docker ps | grep queue
```

## 📊 Progetti Fully-Shared vs Dedicati

### Fully-Shared (solo nginx + PHP condiviso)

```yaml
services:
  nginx:              # Solo web server
  scheduler:          # ✅ Scheduler sempre attivo
  # queue:            # ⚠️ Da abilitare se necessario
```

**Working Directory:** `/var/www/projects/{nome-progetto}/app`

### Dedicati (tutto locale)

```yaml
services:
  app:                # Container PHP-FPM principale
  nginx:              # Web server
  mysql:              # Database dedicato
  redis:              # Cache dedicata  
  scheduler:          # ✅ Scheduler sempre attivo
  # queue:            # ⚠️ Da abilitare se necessario
```

**Working Directory:** `/var/www/html`

## 🛠️ Comandi Utili

### Monitorare lo Scheduler

```bash
# Visualizza log scheduler
docker logs {progetto}-scheduler -f

# Esegui manualmente il scheduler
./docker-dev shell {progetto}
php artisan schedule:run
```

### Gestire Queue Workers

```bash
# Visualizza log queue worker
docker logs {progetto}-queue -f

# Visualizza job in coda
./docker-dev shell {progetto}
php artisan queue:work --once    # Esegui un solo job
php artisan queue:restart        # Riavvia tutti i worker
php artisan queue:failed         # Lista job falliti
php artisan queue:retry 1        # Riprova job fallito ID 1
```

### Testare Scheduler e Queue

**Test Scheduler:**

```php
// routes/console.php o app/Console/Kernel.php
$schedule->call(function () {
    \Log::info('Scheduler test: ' . now());
})->everyMinute();
```

**Test Queue:**

```php
// routes/web.php
Route::get('/test-queue', function () {
    dispatch(new \App\Jobs\TestJob());
    return 'Job dispatched!';
});
```

## 🚀 Supervisor (Avanzato)

Per configurazioni più complesse, puoi usare Supervisor nel container:

**1. Crea configurazione Supervisor:**

```bash
# projects/{progetto}/supervisor/laravel-worker.conf
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan queue:work --tries=3
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/html/storage/logs/worker.log
stopwaitsecs=3600
```

**2. Modifica docker-compose.yml:**

```yaml
queue:
  build: ...
  volumes:
    - ./app:/var/www/html
    - ./supervisor:/etc/supervisor/conf.d
  command: supervisord -n -c /etc/supervisor/supervisord.conf
```

## 📈 Scaling Workers

Per progetti con alto carico di code:

```yaml
queue:
  # ... configurazione base ...
  command: php artisan queue:work --tries=3 --max-jobs=1000 --max-time=3600
  deploy:
    replicas: 3  # 3 worker simultanei
```

Oppure crea worker separati per code diverse:

```yaml
queue-emails:
  # ... configurazione ...
  command: php artisan queue:work --queue=emails --tries=3

queue-reports:
  # ... configurazione ...
  command: php artisan queue:work --queue=reports --tries=5
```

## ⚠️ Note Importanti

1. **Scheduler è sempre attivo** - non serve configurazione
2. **Queue worker è commentato** - abilitalo solo se usi le code
3. **Progetti fully-shared** montano in `/var/www/projects/{progetto}/app`
4. **Progetti dedicati** montano in `/var/www/html`
5. **Riavvia i container** dopo modifiche a docker-compose.yml
6. **Log persistenti** in `storage/logs/` del progetto

## 🐛 Troubleshooting

### Scheduler non esegue i task

```bash
# Verifica che il container sia attivo
docker ps | grep scheduler

# Controlla i log
docker logs {progetto}-scheduler -f

# Test manuale
./docker-dev shell {progetto}
php artisan schedule:list  # Lista task schedulati
```

### Queue worker non processa job

```bash
# Verifica configurazione queue
cat projects/{progetto}/app/.env | grep QUEUE

# Verifica connessione Redis/Database
./docker-dev shell {progetto}
php artisan queue:monitor redis:default

# Riavvia worker
cd projects/{progetto}
docker compose restart queue
```

### Job bloccati in elaborazione

```bash
./docker-dev shell {progetto}
php artisan queue:restart  # Riavvia tutti i worker
php artisan queue:clear    # Pulisci code (ATTENZIONE!)
```
