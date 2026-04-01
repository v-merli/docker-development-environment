# Custom Services Guide

PHPHarbor provides built-in commands for managing standard services (queue, scheduler, redis, mysql, mariadb). You can also:

1. **Use pre-configured templates** - Quick and easy service additions (Elasticsearch, Node.js workers, etc.)
2. **Create custom services** - Full flexibility using Docker Compose override files

## Table of Contents

- [Service Templates](#service-templates) **(Recommended)**
- [MailPit - Global Email Testing](#mailpit---global-email-testing)
- [Quick Start (Custom Services)](#quick-start-custom-services)
- [Using docker-compose.override.yml](#using-docker-composeoverrideyml)
- [Examples](#examples)
- [Managing Custom Services](#managing-custom-services)
- [Best Practices](#best-practices)

---

## Service Templates

**Recommended approach** for common services like Elasticsearch, Redis Commander, Node.js workers, etc.

Pre-configured templates that work like **plugins** - ready to use with automatic port management.

### Available Templates

```bash
./phpharbor service templates
```

- **wp-cron** - WordPress cron worker
- **elasticsearch** - Search engine (dynamic port)
- **node-worker** - Node.js background service (dynamic port)
- **redis-commander** - Redis web UI (dynamic port)

### Add a Template

```bash
./phpharbor service add-template <project> <template>
```

**Example:**
```bash
./phpharbor service add-template myblog elasticsearch
```

PHPHarbor will:
1. Find an available port (to avoid conflicts)
2. Add port variables to your `.env` file
3. Copy the template to `docker-compose.override.yml`
4. Restart the project automatically

### Dynamic Port Assignment

Templates with exposed ports receive automatic port assignment:

```bash
# First project adds elasticsearch → port 9200
# Second project adds elasticsearch → port 9201 (9200 in use)
```

Assigned ports are saved in `.env`:
```bash
ELASTICSEARCH_PORT=9200
NODE_WORKER_PORT=3000
REDIS_COMMANDER_PORT=8081
```

### Remove a Template

```bash
./phpharbor service remove-template <project> <template>
```

**Note:** Manual cleanup of `.env` port variables is recommended after removal.

---

## MailPit - Global Email Testing

MailPit is available **globally** to all projects as a dedicated PHPHarbor application.
Modern replacement for MailHog with additional features like message search and tagging.

Installed automatically during `./phpharbor setup init` and accessible via HTTPS.

### Access MailPit

- **Web UI**: https://mailpit.test:PORT
- **SMTP Server**: `mailpit:1025` (from any container)

> **Note**: Use your configured HTTPS port (default: 8443). Check your PHPHarbor configuration with `./phpharbor setup ports`.

### Configure Your Application

**Laravel** (`.env`):
```bash
MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS=noreply@yourapp.test
```

**WordPress** (`wp-config.php`):
```php
define('SMTP_HOST', 'mailpit');
define('SMTP_PORT', 1025);
```

Or use a plugin like WP Mail SMTP with these settings.

**PHP**:
```php
ini_set('SMTP', 'mailpit');
ini_set('smtp_port', 1025);
```

### Features

✅ **Secure HTTPS access** - Uses standard SSL certificate like any PHPHarbor project  
✅ **No configuration needed** - Works out of the box for all projects  
✅ **Network isolation** - SMTP accessible only from Docker containers  
✅ **Persistent** - Runs as a dedicated project, managed like any other app  
✅ **Message search** - Full-text search across all captured emails  
✅ **Tagging & filtering** - Organize and filter messages easily  
✅ **Modern interface** - Better performance and UX than MailHog  

### Managing MailPit

```bash
# Restart MailPit
cd projects/mailpit && docker-compose restart

# View logs
cd projects/mailpit && docker-compose logs -f

# Stop temporarily
cd projects/mailpit && docker-compose stop

# Start again
cd projects/mailpit && docker-compose up -d
```

---

## Quick Start (Custom Services)

### 1. Create override file

In your project directory (e.g., `projects/myproject/`), create `docker-compose.override.yml`:

```bash
cd projects/myproject
touch docker-compose.override.yml
```

### 2. Add your custom service

```yaml
services:
  my-worker:
    image: ${PROJECT_NAME}-app
    container_name: ${PROJECT_NAME}-worker
    working_dir: /var/www/html
    volumes:
      - ./app:/var/www/html
    command: php /var/www/html/bin/my-script.php
    networks:
      - backend

networks:
  backend:
    external: false
```

### 3. Restart the project

```bash
cd projects/myproject
docker-compose down
docker-compose up -d
```

Docker Compose automatically merges `docker-compose.yml` and `docker-compose.override.yml`.

---

## Using docker-compose.override.yml

### Why override.yml?

✅ **Doesn't modify base configuration** - Original `docker-compose.yml` stays intact  
✅ **Automatically loaded** - Docker Compose merges it automatically  
✅ **Survives updates** - Template updates won't overwrite your customizations  
✅ **Version controlled** - Commit it with your project  
✅ **Easy to disable** - Remove or rename the file to disable  

### Structure

```yaml
# docker-compose.override.yml

services:
  # Your custom services here
  service-name:
    image: image:tag
    container_name: ${PROJECT_NAME}-service-name
    # ... configuration

# Required: define networks used
networks:
  phpharbor-proxy:
    external: true
  backend:
    external: false
```

### Environment Variables

You can use the same variables from `.env`:

- `${PROJECT_NAME}` - Your project name
- `${PHP_VERSION}` - PHP version
- `${DB_HOST}` - Database host
- `${REDIS_HOST}` - Redis host
- Any custom variables you add to `.env`

---

## Examples

### Example 1: WordPress WP-Cron Worker

For WordPress projects, run `wp-cron.php` in a dedicated container:

```yaml
services:
  wp-cron:
    image: ${PROJECT_NAME}-app
    container_name: ${PROJECT_NAME}-wp-cron
    restart: unless-stopped
    working_dir: /var/www/html
    volumes:
      - ./app:/var/www/html
    environment:
      DB_HOST: ${DB_HOST:-}
    networks:
      - backend
      - phpharbor-proxy
    command: >
      sh -c "while true; do
        echo '[WP-Cron] Running at $(date)';
        php /var/www/html/wp-cron.php;
        sleep 300;
      done"
    labels:
      - phpharbor.project=phpharbor-app-${PROJECT_NAME}

networks:
  phpharbor-proxy:
    external: true
  backend:
    external: false
```

### Example 2: MailPit (Email Testing)

**Note**: MailPit is now available as a global system service. This example shows how it could be added per-project if needed.

Test emails locally without sending real emails:

```yaml
services:
  mailpit:
    image: axllent/mailpit:latest
    container_name: ${PROJECT_NAME}-mailpit
    restart: unless-stopped
    ports:
      - "8025:8025"  # Web UI at http://localhost:8025
      - "1025:1025"  # SMTP server
    networks:
      - backend
    labels:
      - phpharbor.project=phpharbor-app-${PROJECT_NAME}

networks:
  backend:
    external: false
```

**Usage:**
- Web UI: http://localhost:8025
- SMTP settings in your app:
  - Host: `mailpit`
  - Port: `1025`

### Example 3: Custom PHP Worker

Run a custom PHP background process:

```yaml
services:
  custom-worker:
    image: ${PROJECT_NAME}-app
    container_name: ${PROJECT_NAME}-worker
    restart: unless-stopped
    working_dir: /var/www/html
    volumes:
      - ./app:/var/www/html
    environment:
      DB_HOST: ${DB_HOST:-}
      REDIS_HOST: ${REDIS_HOST:-}
      WORKER_QUEUE: default
    networks:
      - backend
    command: php /var/www/html/bin/worker.php
    labels:
      - phpharbor.project=phpharbor-app-${PROJECT_NAME}

networks:
  backend:
    external: false
```

### Example 4: ElasticSearch

For advanced search in WooCommerce or other apps:

```yaml
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: ${PROJECT_NAME}-elasticsearch
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    volumes:
      - ../../volumes/elasticsearch/${PROJECT_NAME}:/usr/share/elasticsearch/data
    networks:
      - backend
    labels:
      - phpharbor.project=phpharbor-app-${PROJECT_NAME}

networks:
  backend:
    external: false
```

### Example 5: Node.js Service

Run a Node.js background service alongside PHP:

```yaml
services:
  node-worker:
    image: node:20-alpine
    container_name: ${PROJECT_NAME}-node-worker
    restart: unless-stopped
    working_dir: /app
    volumes:
      - ./app:/app
    command: node scripts/websocket-server.js
    environment:
      NODE_ENV: development
      PORT: 3000
    ports:
      - "3000:3000"
    networks:
      - backend
      - phpharbor-proxy
    labels:
      - phpharbor.project=phpharbor-app-${PROJECT_NAME}

networks:
  phpharbor-proxy:
    external: true
  backend:
    external: false
```

More examples in: `docs/custom-services-examples.yml`

---

## Managing Custom Services

### Start/Stop specific service

```bash
# Start a specific service
cd projects/myproject
docker-compose up -d my-worker

# Stop a specific service
docker-compose stop my-worker

# Remove a service
docker-compose rm -f my-worker
```

### View logs

```bash
# All logs
./phpharbor logs myproject

# Specific service logs
docker logs myproject-worker -f
```

### Restart a service

```bash
docker restart myproject-worker
```

### List all project containers

```bash
docker ps --filter "name=myproject"
```

---

## Best Practices

### 1. Use Project Name Variable

Always use `${PROJECT_NAME}` for container names:

```yaml
container_name: ${PROJECT_NAME}-worker  # ✅ Good
container_name: myproject-worker        # ❌ Bad - hardcoded
```

### 2. Add Labels

Add PHPHarbor labels for better management:

```yaml
labels:
  - phpharbor.project=phpharbor-app-${PROJECT_NAME}
  - phpharbor.custom=worker-name
```

### 3. Use Restart Policies

For production-like environments:

```yaml
restart: unless-stopped  # Container restarts on failure
```

### 4. Connect to Correct Networks

- **backend**: Internal communication (DB, Redis, other services)
- **phpharbor-proxy**: External access via nginx proxy

```yaml
networks:
  - backend              # Most services need this
  - phpharbor-proxy      # Only if needs external access
```

### 5. Environment Variables

Inherit from project `.env` when possible:

```yaml
environment:
  DB_HOST: ${DB_HOST:-}        # Uses .env value or empty
  REDIS_HOST: ${REDIS_HOST:-}
  CUSTOM_VAR: ${CUSTOM_VAR:-default}
```

### 6. Volume Paths

Store persistent data in PHPHarbor volumes directory:

```yaml
volumes:
  # Application code (shared with app container)
  - ./app:/var/www/html
  
  # Persistent data (survives container removal)
  - ../../volumes/custom-service/${PROJECT_NAME}:/data
```

### 7. Use Profiles for Optional Services

Make services optional with profiles:

```yaml
services:
  optional-service:
    # ... configuration
    profiles:
      - optional  # Only starts with: docker-compose --profile optional up
```

Enable in `.env`:
```bash
COMPOSE_PROFILES=app optional
```

### 8. Resource Limits (Optional)

For services that might consume too much resources:

```yaml
services:
  elasticsearch:
    # ... other config
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
```

---

## Troubleshooting

### Service not starting

Check logs:
```bash
docker logs myproject-service-name
```

### Network issues

Ensure networks are defined:
```yaml
networks:
  backend:
    external: false
  # or
  backend:
    name: myproject_backend
```

### Service cannot connect to database

Make sure the service is in the `backend` network and uses correct `DB_HOST`:

```yaml
environment:
  DB_HOST: ${DB_HOST:-}  # Inherits from .env
networks:
  - backend
```

### Changes not applied

Recreate containers:
```bash
cd projects/myproject
docker-compose down
docker-compose up -d --force-recreate
```

---

## Related Documentation

- [Standard Services (add-service/remove-service)](cli-reference.md#service-management)
- [Docker Compose Override Documentation](https://docs.docker.com/compose/extends/)
- [Examples File](custom-services-examples.yml)

---

## Need Help?

If you need a custom service but don't know how to configure it:

1. Check `docs/custom-services-examples.yml` for more examples
2. Look at the base `docker-compose.yml` in your project for structure reference
3. Consult Docker Compose documentation for advanced features
