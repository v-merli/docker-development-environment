# Quick Reference - Essential Commands

## 🚀 Initial Setup (one time only)

```bash
# 1. Initialize environment
phpharbor setup init

# This will:
# - Configure projects directory
# - Start reverse proxy
# - Setup DNS (optional)
# - Configure SSL (optional)
```

## ➕ Create New Project

```bash
# Interactive mode (recommended for beginners)
phpharbor create

# Laravel (default)
phpharbor create my-shop --type laravel --php 8.3

# WordPress
phpharbor create blog --type wordpress --php 8.2

# Generic PHP project
phpharbor create api --type php --php 8.1 --no-redis

# Static HTML site
phpharbor create landing --type html

# Legacy project
phpharbor create old-app --type php --php 7.4 --node 18
```

## 📋 Daily Management

```bash
# List projects
phpharbor list

# Start/Stop
phpharbor start project-name
phpharbor stop project-name
phpharbor restart project-name

# Shell in container
phpharbor shell project-name

# Artisan
phpharbor artisan project-name migrate
phpharbor artisan project-name make:model Product

# Composer
phpharbor composer project-name require package/name

# NPM
phpharbor npm project-name install
phpharbor npm project-name run build

# MySQL CLI
phpharbor mysql project-name
```

## 🔧 Direct Docker Commands

Inside a project folder (`cd projects/project-name`):

```bash
docker-compose ps              # Container status
docker-compose logs -f         # Live logs
docker-compose exec app bash   # PHP shell
docker-compose restart         # Restart everything
docker-compose down           # Stop everything
```

## 🐛 Common Issues

```bash
# DNS not working
sudo brew services restart dnsmasq

# Rebuild containers
cd projects/project-name
docker-compose up -d --build

# Complete proxy reset
phpharbor setup proxy

# Check system status
phpharbor stats
phpharbor info project-name
```

## 📖 Access

- **URL:** `http://project-name.test`
- **HTTPS:** `https://project-name.test`
- **MySQL CLI:** `phpharbor mysql project-name`

## 🔄 Updates

```bash
# Check for updates
phpharbor update check

# Install latest version
phpharbor update install

# View changelog
phpharbor update changelog
```
