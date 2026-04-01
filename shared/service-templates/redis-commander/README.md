# Redis Commander - Redis Web UI

Web-based interface to manage and inspect Redis data.

## What it does

- Browse Redis keys and values
- View data structures (strings, hashes, lists, sets, sorted sets)
- Edit and delete keys
- Monitor Redis commands in real-time
- Execute Redis commands from the web interface

## Access

- **Web UI**: http://localhost:8081

## Configuration

### Connect to different Redis

By default, connects to the shared Redis (or project's dedicated Redis if configured).

To connect to a specific Redis instance, edit `docker-compose.override.yml`:

```yaml
environment:
  # Connect to shared Redis 7
  - REDIS_HOSTS=local:redis-7-shared:6379
  
  # Or dedicated Redis
  - REDIS_HOSTS=local:${PROJECT_NAME}-redis:6379
  
  # Multiple Redis instances
  - REDIS_HOSTS=local:redis-7-shared:6379,cache:${PROJECT_NAME}-redis:6379
```

### Password-protected Redis

If your Redis has a password:

```yaml
environment:
  - REDIS_HOSTS=local:redis-host:6379:0:password
```

Format: `label:host:port:db_index:password`

## Use Cases

- **Debugging cache**: See what's stored in cache
- **Queue inspection**: View Laravel queue jobs
- **Session debugging**: Inspect session data
- **Performance monitoring**: See Redis memory usage
- **Data manipulation**: Manually edit/delete keys

## Features

- Real-time data browsing
- Key search and filtering
- TTL (Time To Live) inspection
- Memory usage statistics
- Pub/Sub monitoring
- Command execution

## Notes

- Port 8081 must be available (or change it in override file)
- Read-only mode available (configure in Redis Commander settings)
- Can connect to multiple Redis instances simultaneously

## Resources

- [Redis Commander GitHub](https://github.com/joeferner/redis-commander)
