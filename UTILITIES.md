# 🔧 Utilities e Estensioni PHP Incluse

Tutti i progetti includono automaticamente le seguenti utilities:

## 📦 Estensioni PHP

### Estensioni Standard Laravel
- `pdo_mysql` - Database MySQL
- `mbstring` - Gestione stringhe multibyte
- `exif` - Metadati immagini
- `pcntl` - Process control
- `bcmath` - Matematica precisione arbitraria
- `gd` - Elaborazione immagini
- `zip` - Compressione file

### Estensioni Avanzate

#### **Redis** (pecl)
- Cache e sessioni ad alte prestazioni
- Queue driver per Laravel
- Connessione: `redis://redis:6379`

**Configurazione Laravel (.env):**
```env
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

#### **Imagick** (pecl)
- Manipolazione avanzata immagini
- Supporto PDF, SVG, e oltre 200 formati
- Filtri e trasformazioni

**Esempio uso:**
```php
$image = new Imagick('input.jpg');
$image->thumbnailImage(200, 200, true);
$image->writeImage('output.jpg');
```

#### **Xdebug 3** (pecl)
- Debugging interattivo
- Code coverage per test
- Profiling prestazioni

**Configurazione inclusa:**
```ini
xdebug.mode=develop,debug,coverage
xdebug.client_host=host.docker.internal
xdebug.client_port=9003
xdebug.start_with_request=yes
```

**Setup VS Code:**
Aggiungi al `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Listen for Xdebug",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "pathMappings": {
        "/var/www/html": "${workspaceFolder}/app"
      }
    }
  ]
}
```

## 🐳 Servizi Container

### Redis
Ogni progetto ha il proprio container Redis:
```bash
# Connessione da Laravel
Host: redis
Port: 6379

# CLI Redis
./manage-projects.sh shell my-project
redis-cli -h redis

# Monitor comandi Redis
docker-compose exec redis redis-cli monitor
```

### MySQL
Container MySQL dedicato per progetto:
```bash
# Accesso via CLI
./manage-projects.sh mysql my-project

# Backup database
docker-compose exec mysql mysqldump -uroot -proot database_name > backup.sql

# Restore database
docker-compose exec -T mysql mysql -uroot -proot database_name < backup.sql
```

## 🔍 Testing con Xdebug

### Code Coverage
```bash
# Con PHPUnit
docker-compose exec app php artisan test --coverage

# Coverage HTML
docker-compose exec app php artisan test --coverage-html=coverage
```

### Profiling
```ini
# Abilita profiling in php.ini
xdebug.mode=profile
xdebug.output_dir=/tmp/xdebug
```

## ⚙️ Configurazioni Custom

### Disabilitare Xdebug (per performance)
Crea `docker-compose.override.yml`:
```yaml
services:
  app:
    environment:
      - XDEBUG_MODE=off
```

### Configurazione Redis Custom
```yaml
services:
  redis:
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
```

## 📊 Verifica Estensioni Installate

```bash
# Lista tutte le estensioni PHP
docker-compose exec app php -m

# Verifica Redis
docker-compose exec app php -r "echo extension_loaded('redis') ? 'OK' : 'NO';"

# Verifica Imagick
docker-compose exec app php -r "echo extension_loaded('imagick') ? 'OK' : 'NO';"

# Verifica Xdebug
docker-compose exec app php -v | grep Xdebug

# Info complete PHP
docker-compose exec app php -i
```

## 🎯 Best Practices

1. **Redis per Cache**: Usa Redis invece di file cache per migliori prestazioni
2. **Xdebug in Produzione**: Mai abilitare Xdebug in produzione (rallenta molto)
3. **Imagick Limits**: Configura limiti memoria per evitare crash con immagini grandi
4. **Redis Persistenza**: I dati Redis sono persistenti grazie al volume Docker

## 🔗 Connessioni da Codice

### Redis in Laravel
```php
use Illuminate\Support\Facades\Redis;

// Cache
Redis::set('key', 'value');
$value = Redis::get('key');

// Pub/Sub
Redis::publish('channel', json_encode(['event' => 'data']));

// Transactions
Redis::transaction(function ($redis) {
    $redis->incr('visits');
    $redis->incr('clicks');
});
```

### Imagick in Laravel
```php
use Intervention\Image\Facades\Image;

// Con Intervention Image (usa Imagick driver)
$img = Image::make('photo.jpg')
    ->resize(300, 200)
    ->greyscale()
    ->save('thumbnail.jpg');

// Imagick diretto
$imagick = new \Imagick('input.pdf[0]');
$imagick->setImageFormat('jpg');
$imagick->writeImage('output.jpg');
```

## 🐛 Troubleshooting

### Xdebug non si connette
```bash
# Verifica configurazione
docker-compose exec app php --ri xdebug

# Abilita log debug
xdebug.log=/tmp/xdebug.log
xdebug.log_level=7

# Verifica porta libera
lsof -i :9003
```

### Redis connection refused
```bash
# Verifica container Redis
docker-compose ps redis

# Test connessione
docker-compose exec app php artisan tinker
> Redis::connection()->ping()
```

### Imagick errori memoria
```bash
# Aumenta limiti PHP
# Crea php.ini custom e monta in docker-compose
memory_limit = 512M
```

---

Tutte queste estensioni sono pre-configurate e pronte all'uso in ogni nuovo progetto! 🚀
