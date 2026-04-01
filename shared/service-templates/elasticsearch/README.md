# ElasticSearch - Search Engine

ElasticSearch provides powerful search capabilities for your applications.

## What it does

- Full-text search engine
- Real-time indexing and searching
- Useful for WooCommerce product search
- Log aggregation and analysis

## Access

- **HTTP API**: http://localhost:9200
- **Host** (from containers): `elasticsearch:9200`

## Use Cases

### WordPress/WooCommerce

Use plugins like:
- ElasticPress
- WooCommerce ElasticSearch

### Laravel

Use Laravel Scout with ElasticSearch driver:

```bash
composer require laravel/scout
composer require matchish/laravel-scout-elasticsearch
```

Configuration in `.env`:

```env
SCOUT_DRIVER=elasticsearch
ELASTICSEARCH_HOST=elasticsearch
ELASTICSEARCH_PORT=9200
```

## Configuration

### Memory Settings

Default: 512MB RAM (`-Xms512m -Xmx512m`)

To increase, edit `docker-compose.override.yml`:

```yaml
environment:
  - "ES_JAVA_OPTS=-Xms1g -Xmx1g"  # 1GB
```

### Persistent Data

Data is stored in: `volumes/elasticsearch/<project-name>/`

## Health Check

```bash
curl http://localhost:9200
```

Expected response:
```json
{
  "name" : "...",
  "cluster_name" : "...",
  "version" : { ... }
}
```

## Notes

- Requires at least 512MB RAM
- Port 9200 must be available
- Data persists across container restarts
- For production, enable security (xpack.security.enabled=true)

## Resources

- [ElasticSearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [ElasticPress Plugin](https://wordpress.org/plugins/elasticpress/)
