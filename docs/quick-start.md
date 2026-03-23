# Quick Reference - Comandi Essenziali

## 🚀 Setup Iniziale (una volta sola)

```bash
# 1. Avvia il proxy
cd proxy && docker-compose up -d && cd ..

# 2. Configura DNS locale
./setup-dnsmasq.sh
```

## ➕ Creare Nuovo Progetto

```bash
# Laravel (default)
./new-project.sh my-shop --type laravel --php 8.3

# WordPress
./new-project.sh blog --type wordpress --php 8.2

# Progetto PHP generico
./new-project.sh api --type php --php 8.1 --no-redis

# Sito HTML statico
./new-project.sh landing --type html

# Progetto legacy
./new-project.sh old-app --type php --php 7.4 --node 18
```

## 📋 Gestione Quotidiana

```bash
# Lista progetti
./manage-projects.sh list

# Avvia/Ferma
./manage-projects.sh start nome-progetto
./manage-projects.sh stop nome-progetto

# Shell nel container
./manage-projects.sh shell nome-progetto

# Artisan
./manage-projects.sh artisan nome-progetto migrate
./manage-projects.sh artisan nome-progetto make:model Product

# Composer
./manage-projects.sh composer nome-progetto require package/name

# NPM
./manage-projects.sh npm nome-progetto install
./manage-projects.sh npm nome-progetto run build
```

## 🔧 Comandi Docker Diretti

Dentro la cartella di un progetto (`cd projects/nome-progetto`):

```bash
docker-compose ps              # Stato container
docker-compose logs -f         # Log live
docker-compose exec app bash   # Shell PHP
docker-compose restart         # Riavvia tutto
docker-compose down           # Ferma tutto
```

## 🐛 Problemi Comuni

```bash
# DNS non funziona
sudo brew services restart dnsmasq

# Ricostruire container
cd projects/nome-progetto
docker-compose up -d --build

# Reset completo proxy
cd proxy
docker-compose down -v
docker-compose up -d
```

## 📖 Accesso

- **URL:** `http://nome-progetto.test`
- **HTTPS:** `https://nome-progetto.test`
- **MySQL CLI:** `./manage-projects.sh mysql nome-progetto`
