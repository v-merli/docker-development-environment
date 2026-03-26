# 🏗️ PHPHarbor Architecture

## Hybrid Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          HOST SYSTEM (macOS)                            │
│                                                                         │
│  Browser → http://shop.test                                            │
│            http://blog.test                                            │
│                         ↓                                              │
└─────────────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                         DNSMASQ (Locale)                               │
│                    *.test → 127.0.0.1                                  │
└─────────────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                    NGINX REVERSE PROXY                                  │
│                Container: nginx-proxy                                   │
│                   Porta 80:80, 443:443                                 │
│                                                                         │
│  Routing automatico basato su VIRTUAL_HOST:                            │
│  • shop.test → shop-nginx:80                                           │
│  • blog.test → blog-nginx:80                                           │
│  • api.test  → api-nginx:80                                            │
└─────────────────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────┴─────────────────┐
        ↓                                   ↓
┌──────────────────────┐         ┌──────────────────────┐
│  SHARED SERVICES     │         │   PROJECTS (N)       │
│  (Optional)          │         │                      │
│                      │         │ ┌──────────────────┐ │
│ ┌─────────────────┐ │         │ │ Project 1        │ │
│ │ mysql-shared    │ │         │ │ (shop)           │ │
│ │ MySQL 8.0       │◄────┐     │ │                  │ │
│ │ 3306:3306       │ │   │     │ │ shop-nginx:80    │ │
│ └─────────────────┘ │   │     │ │ shop-app (PHP)   │ │
│                      │   │     │ │      ↓           │ │
│ ┌─────────────────┐ │   │     │ │ ┌──────────────┐ │ │
│ │ redis-shared    │ │   └─────┼─┤ │ Shared       │ │ │
│ │ Redis:alpine    │◄────┐     │ │ │ mysql-shared │ │ │
│ │ 6379:6379       │ │   │     │ │ │ redis-shared │ │ │
│ └─────────────────┘ │   │     │ │ └──────────────┘ │ │
│                      │   │     │ └──────────────────┘ │
│ Multiple databases:  │   │     │                      │
│ • shop_db            │   │     │ ┌──────────────────┐ │
│ • blog_db            │   │     │ │ Project 2        │ │
│ • api_db             │   │     │ │ (blog)           │ │
│                      │   │     │ │                  │ │
└──────────────────────┘   │     │ │ blog-nginx:80    │ │
                           │     │ │ blog-app (PHP)   │ │
                           │     │ │      ↓           │ │
                           │     │ │ ┌──────────────┐ │ │
                           └─────┼─┤ │ Dedicated    │ │ │
                                 │ │ │ blog-mysql   │ │ │
                                 │ │ │ blog-redis   │ │ │
                                 │ │ └──────────────┘ │ │
                                 │ └──────────────────┘ │
                                 │                      │
                                 │ ┌──────────────────┐ │
                                 │ │ Project N...     │ │
                                 │ └──────────────────┘ │
                                 └──────────────────────┘
```

## Docker Networks

### `proxy` Network (bridge, external)
All containers that must be reachable from the outside:
- `nginx-proxy`
- `mysql-shared` (if used)
- `redis-shared` (if used)
- `{project}-nginx` (for each project)
- `{project}-app` (for each project)

### `backend` Network (bridge, per project)
Only for projects with dedicated services:
- `{project}-app`
- `{project}-nginx`
- `{project}-mysql`
- `{project}-redis`
- `{project}-scheduler`

## HTTP Request Flow

### With Shared Services

```
1. Browser
   ↓
2. http://shop.test
   ↓
3. dnsmasq → 127.0.0.1
   ↓
4. nginx-proxy (container)
   ↓
5. Reads Host header: shop.test
   ↓
6. Finds container with VIRTUAL_HOST=shop.test
   ↓
7. Forward → shop-nginx:80 (via proxy network)
   ↓
8. shop-nginx → FastCGI → shop-app:9000
   ↓
9. shop-app (PHP-FPM)
   |
   ├─→ mysql-shared:3306 (DB: shop_db)
   └─→ redis-shared:6379
```

### With Dedicated Services

```
1-7. [As above]
   ↓
8. shop-nginx → FastCGI → shop-app:9000
   ↓
9. shop-app (PHP-FPM)
   |
   ├─→ shop-mysql:3306 (backend network)
   └─→ shop-redis:6379 (backend network)
```

## Architecture Comparison

### Dedicated Architecture (Default)

```
Project 1            Project 2            Project 3
├─ nginx            ├─ nginx            ├─ nginx
├─ php-fpm          ├─ php-fpm          ├─ php-fpm
├─ mysql (400MB)    ├─ mysql (400MB)    ├─ mysql (400MB)
└─ redis (100MB)    └─ redis (100MB)    └─ redis (100MB)

Total RAM: ~1.5 GB
```

**Advantages:**
- ✅ Complete isolation
- ✅ Customized configurations
- ✅ Different MySQL versions per project

**Disadvantages:**
- ❌ High RAM consumption
- ❌ More containers to manage

### Shared Architecture

```
                    ┌─── Project 1 (nginx + php-fpm)
mysql-shared (400MB)├─── Project 2 (nginx + php-fpm)
redis-shared (100MB)├─── Project 3 (nginx + php-fpm)
                    └─── Project N...

Total RAM: ~700 MB
```

**Advantages:**
- ✅ ~70% RAM savings
- ✅ Centralized management
- ✅ Simpler backups

**Disadvantages:**
- ❌ All projects same MySQL version
- ❌ Less isolation

### Hybrid Architecture (Recommended)

```
Main PROJECT         Other Projects
├─ nginx            ┌─── Project 2 (nginx + php)
├─ php-fpm          ├─── Project 3 (nginx + php)
├─ mysql (dedicated) │
└─ redis (dedicated) └─→ mysql-shared
                        redis-shared

Total RAM: ~1 GB (vs ~1.5 GB all dedicated)
```

**Best of both worlds:**
- ✅ Critical projects: dedicated services
- ✅ Test projects: shared services
- ✅ Maximum flexibility

## Key Components

### nginxproxy/nginx-proxy
- Automatic reverse proxy
- Monitors Docker socket
- Generates dynamic configurations
- SSL termination

### nginxproxy/acme-companion
- Automatic SSL certificates
- Let's Encrypt/staging
- Automatic renewal

### App Container (PHP-FPM)
- PHP versions: 7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5
- Node.js: 18, 20, 21
- Composer, NPM preinstalled

### Nginx Container (per project)
- Specific configurations:
  - `laravel.conf`
  - `wordpress.conf`
  - `php.conf`
  - `html.conf`

## Key Environment Variables

### For Automatic Routing
```yaml
environment:
  VIRTUAL_HOST: myproject.test
  VIRTUAL_PORT: 80
  LETSENCRYPT_HOST: myproject.test
  LETSENCRYPT_EMAIL: dev@localhost
```

### For Shared Services
```yaml
environment:
  DB_HOST: mysql-shared
  DB_PORT: 3306
  REDIS_HOST: redis-shared
  REDIS_PORT: 6379
```

### For Dedicated Services
```yaml
environment:
  DB_HOST: mysql  # Service name in docker-compose
  DB_PORT: 3306
  REDIS_HOST: redis
  REDIS_PORT: 6379
```

## Volumes and Persistence

### Shared Services
```yaml
volumes:
  mysql_shared_data:
    name: mysql_shared_data  # Condiviso tra progetti
  redis_shared_data:
    name: redis_shared_data  # Condiviso tra progetti
```

### Dedicated Services
```yaml
volumes:
  mysql_data:
    driver: local  # Project-specific
  redis_data:
    driver: local  # Project-specific
```

## Exposed Ports

### Host → Container
- `8080:80` - HTTP (nginx-proxy)
- `8443:443` - HTTPS (nginx-proxy)
- `3306:3306` - Shared MySQL (optional)
- `6379:6379` - Shared Redis (optional)
- `13306-14305:3306` - Dedicated MySQL (dynamic range)

### Internal (only Docker network)
- `80` - Nginx for each project
- `9000` - PHP-FPM for each project

## Scalability

The architecture supports:
- ✅ Dozens of simultaneous projects
- ✅ Mix of project types (Laravel, WordPress, PHP, HTML)
- ✅ Different PHP versions per project
- ✅ Dedicated and shared services simultaneously

Practical limit: ~20-30 active projects (depends on available RAM)

## Security

- 🔒 Automatic SSL certificates (Let's Encrypt)
- 🔒 Isolated networks (frontend/backend)
- 🔒 Configurable database passwords
- 🔒 Non-root containers when possible

---

**Updated:** February 2026
**Version:** 2.0 (Hybrid Architecture)
