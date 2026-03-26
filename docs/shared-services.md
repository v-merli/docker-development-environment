# 🔄 Shared Services Guide

## Why Use Shared Services?

### Problem
With many active projects, each project with dedicated PHP, MySQL and Redis consumes:
- PHP-FPM: ~100-150 MB RAM
- MySQL: ~200-400 MB RAM
- Redis: ~50-100 MB RAM

**With 10 projects = ~5 GB of RAM just for services!** 😰

### Solution: Shared Services
Single shared instances of PHP, MySQL and Redis for all projects:
- Shared PHP-FPM per version: ~150 MB (all active versions: ~900 MB)
- Shared MySQL: ~400 MB (regardless of number of projects)
- Shared Redis: ~100 MB (regardless of number of projects)

**Savings: up to 90% RAM with 5+ projects!**

## Quick Start

### 1. Start Shared Services

```bash
./start-shared-services.sh
```

### 2. Create Projects with Shared Services

```bash
# Only shared DBs (MySQL + Redis)
./new-project.sh shop --shared

# Only shared MySQL
./new-project.sh blog --shared-db

# Only shared Redis
./new-project.sh api --shared-redis

# Only shared PHP (new!)
./new-project.sh test1 --shared-php --php 8.3

# Everything shared (maximum savings!)
./new-project.sh test2 --fully-shared --php 8.3
```

### 3. Create Database for Project

```bash
# Access shared MySQL
./manage-projects.sh shared-mysql

# Create database
CREATE DATABASE shop_db;
EXIT;
```

### 4. Configure Project

The project's `.env` file is already configured automatically:

```env
DB_HOST=mysql-shared
DB_PORT=3306
DB_DATABASE=shop_db
DB_USERNAME=root
DB_PASSWORD=rootpassword

REDIS_HOST=redis-shared
REDIS_PORT=6379
```

### 5. Run Migrations

```bash
./manage-projects.sh artisan shop migrate
```

## Daily Management

### Check Status

```bash
./manage-projects.sh shared-status

# Output shows:
# - Database and Cache (MySQL, Redis)
# - Shared PHP-FPM (per version)
```

### Start Specific Shared PHP

```bash
# Start PHP 8.3 shared
./manage-projects.sh shared-php 8.3

# Start PHP 8.1 shared
./manage-projects.sh shared-php 8.1
```

### View Logs

```bash
# Logs of all shared services
./manage-projects.sh shared-logs

# Specific PHP logs
./manage-projects.sh shared-php-logs 8.3
```

### Stop Services (to save RAM when not in use)

```bash
./manage-projects.sh shared-stop
```

### Restart Services

```bash
./manage-projects.sh shared-start
```

## Database Access

### Via CLI

```bash
# MySQL
./manage-projects.sh shared-mysql

# Redis
docker exec -it redis-shared redis-cli
```

### Via GUI Applications

**MySQL:**
- Host: `localhost`
- Port: `3306`
- User: `root`
- Password: `rootpassword`

**Redis:**
- Host: `localhost`
- Port: `6379`

## Best Practices

### ✅ When to Use Shared Services

#### Shared Databases (--shared, --shared-db, --shared-redis)
- Projects in local development
- You have 3+ projects active simultaneously
- Limited RAM on Mac (8-16 GB)
- Small databases (<1 GB)
- No special MySQL configurations needed

#### Shared PHP (--shared-php, --fully-shared)
- **All projects use the same PHP version**
- Simple projects without special system dependencies
- Maximum RAM savings (10+ projects with low memory)
- All Laravel/WordPress projects with same PHP version
- Test/staging environment with limited resources

### ❌ When to Use Dedicated Services

#### Dedicated Databases
- Production projects
- Need MySQL 5.7 for one project and 8.0 for another
- Very large databases or intensive queries
- Custom MySQL configurations needed
- Only 1-2 active projects

#### Dedicated PHP
- **Projects requiring different PHP versions**
- Custom PHP extensions
- Specific php.ini configurations
- Critical projects requiring isolation
- Optimal performance required

## Hybrid Architecture (Recommended)

You can mix! Example:

```bash
# Main project: all dedicated
./new-project.sh main-app --mysql 8.0

# Secondary projects: only shared DBs
./new-project.sh test1 --shared --php 8.3
./new-project.sh test2 --shared --php 8.1

# Lightweight projects: all shared
./new-project.sh demo1 --fully-shared --php 8.3
./new-project.sh demo2 --fully-shared --php 8.3
./new-project.sh demo3 --fully-shared --php 8.3
```

**RAM Consumption:**
- main-app: ~500 MB (all dedicated)
- test1: ~250 MB (dedicated PHP, shared DBs)
- test2: ~250 MB (dedicated PHP, shared DBs)
- demo1-3: ~30 MB (only Nginx, rest shared)
- **Total: ~1.1 GB** vs **~3 GB** if all dedicated

### Optimal Strategy

1. **Production/critical projects**: all dedicated
2. **Active development projects**: shared DBs, dedicated PHP (for different versions)
3. **Demo/test projects**: all shared (maximum savings)

## Troubleshooting

### Shared services won't start

```bash
# Verify proxy is active
docker ps | grep nginx-proxy

# If not active
cd proxy
docker-compose up -d

# Then start services
docker-compose --profile shared-services up -d
```

### Connection error from container

Verify the project is on the `proxy` network:

```bash
docker inspect <container-name> | grep proxy
```

### Database not found

```bash
# List databases
./manage-projects.sh shared-mysql
SHOW DATABASES;

# Create if missing
CREATE DATABASE myproject_db;
```

## Migration from Dedicated to Shared

### 1. Export Database

```bash
cd projects/myproject
docker-compose exec mysql mysqldump -uroot -proot myproject_db > backup.sql
```

### 2. Stop and Remove Dedicated Containers

```bash
docker-compose down -v
```

### 3. Modify docker-compose.yml

Use template `shared/templates/docker-compose-shared.yml`

### 4. Update .env

```env
DB_HOST=mysql-shared
MYSQL_ROOT_PASSWORD=rootpassword
```

### 5. Import Database

```bash
# Create database
./manage-projects.sh shared-mysql
CREATE DATABASE myproject_db;
EXIT;

# Import
cat backup.sql | docker exec -i mysql-shared mysql -uroot -prootpassword myproject_db
```

### 6. Restart Project

```bash
docker-compose up -d
```

## FAQ

**Q: Can I use different MySQL versions with shared services?**
A: No, all projects will share the same version (MySQL 8.0 by default).

**Q: Can I use different PHP versions with --fully-shared?**
A: No, with --fully-shared all projects must use the same PHP version. Use --shared (only DBs) if you need different PHP versions.

**Q: How does shared PHP work technically?**
A: A PHP-FPM container mounts the complete `projects/` folder. Each project's Nginx points to `php-X.X-shared:9000` instead of having its own PHP container.

**Q: Are databases isolated?**
A: Yes, each project has its own separate database on the same MySQL server.

**Q: What happens if I stop shared services?**
A: All projects using shared services will stop working.

**Q: Can I mix projects with dedicated and shared services?**
A: Yes! It's the recommended approach to optimize resources.

**Q: Can I have PHP 8.3 shared and PHP 8.1 shared simultaneously?**
A: Yes! You can start multiple shared PHP versions. Each version is a separate container.

```bash
./manage-projects.sh shared-php 8.3
./manage-projects.sh shared-php 8.1
./new-project.sh project1 --shared-php --php 8.3
./new-project.sh project2 --shared-php --php 8.1
```

**Q: How do I backup shared databases?**
A: 
```bash
docker exec mysql-shared mysqldump -uroot -prootpassword --all-databases > backup.sql
```

**Q: Does Redis support multiple databases?**
A: Yes, Redis has 16 databases (0-15). You can assign a different number per project in the `.env` file:
```env
REDIS_DB=1  # project 1
REDIS_DB=2  # project 2
```

## Resource Monitoring

```bash
# View memory consumption of all containers
docker stats

# Only shared services
docker stats mysql-shared redis-shared
```

---

**💡 Tip:** Start with shared services. If a project becomes complex, switch to dedicated easily!
