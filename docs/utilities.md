# 🔧 Utilities and Included PHP Extensions

All projects automatically include the following utilities:

## 📦 PHP Extensions

### Standard Laravel Extensions
- `pdo_mysql` - MySQL database
- `mbstring` - Multibyte string handling
- `exif` - Image metadata
- `pcntl` - Process control
- `bcmath` - Arbitrary precision math
- `gd` - Image processing
- `zip` - File compression

### Advanced Extensions

#### **Redis** (pecl)
- High-performance cache and sessions
- Queue driver for Laravel
- Connection: `redis://redis:6379`

**Laravel Configuration (.env):**
```env
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

#### **Imagick** (pecl)
- Advanced image manipulation
- PDF, SVG support, and over 200 formats
- Filters and transformations

**Usage example:**
```php
$image = new Imagick('input.jpg');
$image->thumbnailImage(200, 200, true);
$image->writeImage('output.jpg');
```

#### **Xdebug 3** (pecl)
- Interactive debugging
- Code coverage for tests
- Performance profiling

**Included configuration:**
```ini
xdebug.mode=develop,debug,coverage
xdebug.client_host=host.docker.internal
xdebug.client_port=9003
xdebug.start_with_request=yes
```

**VS Code Setup:**
Add to `.vscode/launch.json`:
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

## 🐳 Container Services

### Redis
Each project has its own Redis container:
```bash
# Connection from Laravel
Host: redis
Port: 6379

# Redis CLI
./phpharbor shell my-project
redis-cli -h redis

# Monitor Redis commands
docker-compose exec redis redis-cli monitor
```

### MySQL
Dedicated MySQL container per project:
```bash
# CLI access
./phpharbor mysql my-project

# Database backup
docker-compose exec mysql mysqldump -uroot -proot database_name > backup.sql

# Database restore
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
# Enable profiling in php.ini
xdebug.mode=profile
xdebug.output_dir=/tmp/xdebug
```

## ⚙️ Custom Configurations

### Disable Xdebug (for performance)
Create `docker-compose.override.yml`:
```yaml
services:
  app:
    environment:
      - XDEBUG_MODE=off
```

### Custom Redis Configuration
```yaml
services:
  redis:
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
```

## 📊 Verify Installed Extensions

```bash
# List all PHP extensions
docker-compose exec app php -m

# Verify Redis
docker-compose exec app php -r "echo extension_loaded('redis') ? 'OK' : 'NO';"

# Verify Imagick
docker-compose exec app php -r "echo extension_loaded('imagick') ? 'OK' : 'NO';"

# Verify Xdebug
docker-compose exec app php -v | grep Xdebug

# Complete PHP info
docker-compose exec app php -i
```

## 🎯 Best Practices

1. **Redis for Cache**: Use Redis instead of file cache for better performance
2. **Xdebug in Production**: Never enable Xdebug in production (significantly slows down)
3. **Imagick Limits**: Configure memory limits to avoid crashes with large images
4. **Redis Persistence**: Redis data is persistent thanks to the Docker volume

## 🔗 Connections from Code

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

// With Intervention Image (uses Imagick driver)
$img = Image::make('photo.jpg')
    ->resize(300, 200)
    ->greyscale()
    ->save('thumbnail.jpg');

// Direct Imagick
$imagick = new \Imagick('input.pdf[0]');
$imagick->setImageFormat('jpg');
$imagick->writeImage('output.jpg');
```

## 🐛 Troubleshooting

### Xdebug not connecting
```bash
# Check configuration
docker-compose exec app php --ri xdebug

# Enable debug logging
xdebug.log=/tmp/xdebug.log
xdebug.log_level=7

# Check if port is free
lsof -i :9003
```

### Redis connection refused
```bash
# Check Redis container
docker-compose ps redis

# Test connection
docker-compose exec app php artisan tinker
> Redis::connection()->ping()
```

### Imagick memory errors
```bash
# Increase PHP limits
# Create custom php.ini and mount in docker-compose
memory_limit = 512M
```

---

All these extensions are pre-configured and ready to use in every new project! 🚀
