# Service Templates

Pre-configured service templates that can be easily added to PHPHarbor projects.

These templates work like **plugins** - they're ready-to-use Docker services that complement your main application.

## Available Templates

### wp-cron
**WordPress Cron Worker** - Dedicated container for WordPress cron jobs.
- Runs wp-cron.php independently
- Better performance than default WP cron
- Customizable schedule
- No exposed ports

### elasticsearch
**Search Engine** - Powerful full-text search.
- For WooCommerce advanced search
- Laravel Scout integration
- Log aggregation
- Dynamic port assignment (default: 9200)

### node-worker
**Node.js Background Service** - Run Node.js alongside PHP.
- WebSocket servers (Socket.io)
- Background job processing
- API services
- Dynamic port assignment (default: 3000)

### redis-commander
**Redis Web UI** - Visual interface for Redis data.
- Browse keys and values
- Monitor Redis in real-time
- Debug cache and sessions
- Dynamic port assignment (default: 8081)

## Dynamic Port Assignment

Templates with exposed ports automatically receive dynamic port assignments to avoid conflicts between projects.

When you add a template:
1. PHPHarbor finds an available port starting from the default
2. The port is saved to your project's `.env` file
3. The service uses the assigned port

**Example:**
- Project A adds `elasticsearch` → gets port 9200
- Project B adds `elasticsearch` → gets port 9201 (9200 already in use)

Ports are stored in `.env` as:
```bash
ELASTICSEARCH_PORT=9200
NODE_WORKER_PORT=3000
REDIS_COMMANDER_PORT=8081
```

## Usage

### List available templates

```bash
./phpharbor service templates
```

### Add a template to a project

```bash
./phpharbor service add-template <project> <template>
```

**Example:**
```bash
./phpharbor service add-template mysite wp-cron
./phpharbor service add-template myblog elasticsearch
./phpharbor service add-template myapp node-worker
```

### Remove a template

```bash
./phpharbor service remove-template <project> <template>
```

## How It Works

1. **Template Selection**: Choose from pre-configured templates
2. **Automatic Copy**: Template is copied to `docker-compose.override.yml`
3. **Auto Restart**: Project restarts with the new service
4. **Documentation**: README is copied to your project folder

## Template Structure

Each template directory contains:

```
template-name/
  ├── docker-compose.override.yml  # Service definition
  └── README.md                     # Usage instructions
```

## Creating Custom Templates

Want to create your own template?

1. Create a directory in `shared/service-templates/your-template/`
2. Add `docker-compose.override.yml` with your service definition
3. Add `README.md` with usage instructions
4. The template will automatically appear in `list-templates`

**Template Format:**

```yaml
# docker-compose.override.yml

services:
  your-service:
    image: your-image:tag
    container_name: ${PROJECT_NAME}-your-service
    # ... configuration
    networks:
      - backend
    labels:
      - phpharbor.project=phpharbor-app-${PROJECT_NAME}
      - phpharbor.template=your-template

networks:
  backend:
    external: false
```

## Multi-Template Support

You can add multiple templates to the same project:

```bash
./phpharbor add-template mysite mailhog
./phpharbor add-template mysite redis-commander
./phpharbor add-template mysite elasticsearch
```

All templates will be merged into a single `docker-compose.override.yml` file.

## Best Practices

1. **Use templates for non-standard services** - Standard services (queue, scheduler, mysql, redis) should use `add-service`
2. **Check port conflicts** - Some templates use specific ports (8025, 8081, etc.)
3. **Read the documentation** - Each template has a `SERVICE-<template>-README.md` in your project
4. **Backup before modifying** - Existing override files are backed up automatically

## Documentation

For manual customization and advanced use cases, see:
- [Custom Services Guide](../docs/custom-services.md)
- [Custom Services Examples](../docs/custom-services-examples.yml)

## Contributing

To add a new template to PHPHarbor:

1. Create your template in `shared/service-templates/`
2. Test it with `add-template`
3. Submit a pull request with your template and documentation

Popular templates contributions are welcome!
