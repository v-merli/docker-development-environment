# 🔄 Laravel Workers and Scheduler Management Guide

## Workers Architecture

Each Laravel project has dedicated containers for background tasks:

### 📅 Scheduler Container
**Automatically active** in all Laravel projects

```bash
# Container: {project}-scheduler
# Function: Runs php artisan schedule:run every 60 seconds
# Always active ✅
```

The scheduler container automatically executes scheduled tasks in `app/Console/Kernel.php`:

```php
protected function schedule(Schedule $schedule)
{
    $schedule->command('emails:send')->daily();
    $schedule->command('reports:generate')->hourly();
}
```

### ⚙️ Queue Worker Container
**Commented by default** - enable it if you use queues

#### How to Enable the Queue Worker

**1. Modify the project's docker-compose.yml:**

```yaml
# Uncomment this section:
  queue:
    build:
      context: ../../shared/dockerfiles
      dockerfile: php-${PHP_VERSION}.Dockerfile
      args:
        NODE_VERSION: ${NODE_VERSION:-20}
    container_name: ${PROJECT_NAME}-queue
    restart: unless-stopped
    working_dir: /var/www/projects/${PROJECT_NAME}/app  # fully-shared
    # working_dir: /var/www/html                         # dedicated
    volumes:
      - ./app:/var/www/projects/${PROJECT_NAME}/app     # fully-shared
      # - ./app:/var/www/html                            # dedicated
    networks:
      - proxy  # fully-shared
      # - backend  # dedicated
    command: php artisan queue:work --tries=3
```

**2. Restart the project:**

```bash
cd projects/{project-name}
docker compose up -d --build
```

**3. Verify it's active:**

```bash
docker ps | grep queue
```

## 📊 Fully-Shared vs Dedicated Projects

### Fully-Shared (only nginx + shared PHP)

```yaml
services:
  nginx:              # Solo web server
  scheduler:          # ✅ Scheduler sempre attivo
  # queue:            # ⚠️ Enable if needed
```

**Working Directory:** `/var/www/projects/{project-name}/app`

### Dedicated (everything local)

```yaml
services:
  app:                # Main PHP-FPM container
  nginx:              # Web server
  mysql:              # Dedicated database
  redis:              # Dedicated cache  
  scheduler:          # ✅ Scheduler always active
  # queue:            # ⚠️ Enable if needed
```

**Working Directory:** `/var/www/html`

## 🛠️ Useful Commands

### Monitor the Scheduler

```bash
# View scheduler logs
docker logs {project}-scheduler -f

# Manually run the scheduler
./phpharbor shell {project}
php artisan schedule:run
```

### Manage Queue Workers

```bash
# View queue worker logs
docker logs {project}-queue -f

# View queued jobs
./phpharbor shell {project}
php artisan queue:work --once    # Execute a single job
php artisan queue:restart        # Restart all workers
php artisan queue:failed         # List failed jobs
php artisan queue:retry 1        # Retry failed job ID 1
```

### Test Scheduler and Queue

**Test Scheduler:**

```php
// routes/console.php or app/Console/Kernel.php
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

## 🚀 Supervisor (Advanced)

For more complex configurations, you can use Supervisor in the container:

**1. Create Supervisor configuration:**

```bash
# projects/{project}/supervisor/laravel-worker.conf
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

**2. Modify docker-compose.yml:**

```yaml
queue:
  build: ...
  volumes:
    - ./app:/var/www/html
    - ./supervisor:/etc/supervisor/conf.d
  command: supervisord -n -c /etc/supervisor/supervisord.conf
```

## 📈 Scaling Workers

For projects with high queue load:

```yaml
queue:
  # ... base configuration ...
  command: php artisan queue:work --tries=3 --max-jobs=1000 --max-time=3600
  deploy:
    replicas: 3  # 3 simultaneous workers
```

Or create separate workers for different queues:

```yaml
queue-emails:
  # ... configuration ...
  command: php artisan queue:work --queue=emails --tries=3

queue-reports:
  # ... configuration ...
  command: php artisan queue:work --queue=reports --tries=5
```

## ⚠️ Important Notes

1. **Scheduler is always active** - no configuration needed
2. **Queue worker is commented** - enable it only if you use queues
3. **Fully-shared projects** mount in `/var/www/projects/{project}/app`
4. **Dedicated projects** mount in `/var/www/html`
5. **Restart containers** after changes to docker-compose.yml
6. **Persistent logs** in project's `storage/logs/`

## 🐛 Troubleshooting

### Scheduler not executing tasks

```bash
# Verify the container is active
docker ps | grep scheduler

# Check logs
docker logs {project}-scheduler -f

# Manual test
./phpharbor shell {project}
php artisan schedule:list  # List scheduled tasks
```

### Queue worker not processing jobs

```bash
# Check queue configuration
cat projects/{project}/app/.env | grep QUEUE

# Verify Redis/Database connection
./phpharbor shell {project}
php artisan queue:monitor redis:default

# Restart worker
cd projects/{project}
docker compose restart queue
```

### Jobs stuck in processing

```bash
./phpharbor shell {project}
php artisan queue:restart  # Restart all workers
php artisan queue:clear    # Clear queues (CAUTION!)
```
