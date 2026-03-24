# 🏗️ Architettura PHPHarbor

## Panoramica Architettura Ibrida

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
│  SERVIZI CONDIVISI   │         │   PROGETTI (N)       │
│  (Opzionali)         │         │                      │
│                      │         │ ┌──────────────────┐ │
│ ┌─────────────────┐ │         │ │ Progetto 1       │ │
│ │ mysql-shared    │ │         │ │ (shop)           │ │
│ │ MySQL 8.0       │◄────┐     │ │                  │ │
│ │ 3306:3306       │ │   │     │ │ shop-nginx:80    │ │
│ └─────────────────┘ │   │     │ │ shop-app (PHP)   │ │
│                      │   │     │ │      ↓           │ │
│ ┌─────────────────┐ │   │     │ │ ┌──────────────┐ │ │
│ │ redis-shared    │ │   └─────┼─┤ │ Condivisi    │ │ │
│ │ Redis:alpine    │◄────┐     │ │ │ mysql-shared │ │ │
│ │ 6379:6379       │ │   │     │ │ │ redis-shared │ │ │
│ └─────────────────┘ │   │     │ │ └──────────────┘ │ │
│                      │   │     │ └──────────────────┘ │
│ Database multipli:   │   │     │                      │
│ • shop_db            │   │     │ ┌──────────────────┐ │
│ • blog_db            │   │     │ │ Progetto 2       │ │
│ • api_db             │   │     │ │ (blog)           │ │
│                      │   │     │ │                  │ │
└──────────────────────┘   │     │ │ blog-nginx:80    │ │
                           │     │ │ blog-app (PHP)   │ │
                           │     │ │      ↓           │ │
                           │     │ │ ┌──────────────┐ │ │
                           └─────┼─┤ │ Dedicati     │ │ │
                                 │ │ │ blog-mysql   │ │ │
                                 │ │ │ blog-redis   │ │ │
                                 │ │ └──────────────┘ │ │
                                 │ └──────────────────┘ │
                                 │                      │
                                 │ ┌──────────────────┐ │
                                 │ │ Progetto N...    │ │
                                 │ └──────────────────┘ │
                                 └──────────────────────┘
```

## Reti Docker

### Rete `proxy` (bridge, esterna)
Tutti i container che devono essere raggiungibili dall'esterno:
- `nginx-proxy`
- `mysql-shared` (se usato)
- `redis-shared` (se usato)
- `{progetto}-nginx` (per ogni progetto)
- `{progetto}-app` (per ogni progetto)

### Rete `backend` (bridge, per progetto)
Solo per progetti con servizi dedicati:
- `{progetto}-app`
- `{progetto}-nginx`
- `{progetto}-mysql`
- `{progetto}-redis`
- `{progetto}-scheduler`

## Flusso di una Richiesta HTTP

### Con Servizi Condivisi

```
1. Browser
   ↓
2. http://shop.test
   ↓
3. dnsmasq → 127.0.0.1
   ↓
4. nginx-proxy (container)
   ↓
5. Legge header Host: shop.test
   ↓
6. Trova container con VIRTUAL_HOST=shop.test
   ↓
7. Forward → shop-nginx:80 (via rete proxy)
   ↓
8. shop-nginx → FastCGI → shop-app:9000
   ↓
9. shop-app (PHP-FPM)
   |
   ├─→ mysql-shared:3306 (DB: shop_db)
   └─→ redis-shared:6379
```

### Con Servizi Dedicati

```
1-7. [Come sopra]
   ↓
8. shop-nginx → FastCGI → shop-app:9000
   ↓
9. shop-app (PHP-FPM)
   |
   ├─→ shop-mysql:3306 (rete backend)
   └─→ shop-redis:6379 (rete backend)
```

## Confronto Architetture

### Architettura Dedicata (Default)

```
Progetto 1           Progetto 2           Progetto 3
├─ nginx            ├─ nginx            ├─ nginx
├─ php-fpm          ├─ php-fpm          ├─ php-fpm
├─ mysql (400MB)    ├─ mysql (400MB)    ├─ mysql (400MB)
└─ redis (100MB)    └─ redis (100MB)    └─ redis (100MB)

Totale RAM: ~1.5 GB
```

**Vantaggi:**
- ✅ Isolamento completo
- ✅ Configurazioni personalizzate
- ✅ Versioni MySQL diverse per progetto

**Svantaggi:**
- ❌ Alto consumo RAM
- ❌ Più container da gestire

### Architettura Condivisa

```
                    ┌─── Progetto 1 (nginx + php-fpm)
mysql-shared (400MB)├─── Progetto 2 (nginx + php-fpm)
redis-shared (100MB)├─── Progetto 3 (nginx + php-fpm)
                    └─── Progetto N...

Totale RAM: ~700 MB
```

**Vantaggi:**
- ✅ Risparmio RAM ~70%
- ✅ Gestione centralizzata
- ✅ Backup più semplici

**Svantaggi:**
- ❌ Tutti i progetti stessa versione MySQL
- ❌ Meno isolamento

### Architettura Ibrida (Consigliata)

```
Progetto MAIN        Altri Progetti
├─ nginx            ┌─── Progetto 2 (nginx + php)
├─ php-fpm          ├─── Progetto 3 (nginx + php)
├─ mysql (dedicato) │
└─ redis (dedicato) └─→ mysql-shared
                        redis-shared

Totale RAM: ~1 GB (vs ~1.5 GB tutti dedicati)
```

**Best of both worlds:**
- ✅ Progetti critici: servizi dedicati
- ✅ Progetti test: servizi condivisi
- ✅ Flessibilità massima

## Componenti Chiave

### nginxproxy/nginx-proxy
- Reverse proxy automatico
- Monitora Docker socket
- Genera configurazioni dinamiche
- SSL termination

### nginxproxy/acme-companion
- Certificati SSL automatici
- Let's Encrypt/staging
- Rinnovo automatico

### Container App (PHP-FPM)
- Versioni PHP: 7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5
- Node.js: 18, 20, 21
- Composer, NPM preinstallati

### Container Nginx (per progetto)
- Configurazioni specifiche:
  - `laravel.conf`
  - `wordpress.conf`
  - `php.conf`
  - `html.conf`

## Variabili d'Ambiente Chiave

### Per Routing Automatico
```yaml
environment:
  VIRTUAL_HOST: myproject.test
  VIRTUAL_PORT: 80
  LETSENCRYPT_HOST: myproject.test
  LETSENCRYPT_EMAIL: dev@localhost
```

### Per Servizi Condivisi
```yaml
environment:
  DB_HOST: mysql-shared
  DB_PORT: 3306
  REDIS_HOST: redis-shared
  REDIS_PORT: 6379
```

### Per Servizi Dedicati
```yaml
environment:
  DB_HOST: mysql  # Nome servizio nel docker-compose
  DB_PORT: 3306
  REDIS_HOST: redis
  REDIS_PORT: 6379
```

## Volumi e Persistenza

### Servizi Condivisi
```yaml
volumes:
  mysql_shared_data:
    name: mysql_shared_data  # Condiviso tra progetti
  redis_shared_data:
    name: redis_shared_data  # Condiviso tra progetti
```

### Servizi Dedicati
```yaml
volumes:
  mysql_data:
    driver: local  # Specifico del progetto
  redis_data:
    driver: local  # Specifico del progetto
```

## Porte Esposte

### Host → Container
- `8080:80` - HTTP (nginx-proxy)
- `8443:443` - HTTPS (nginx-proxy)
- `3306:3306` - MySQL condiviso (opzionale)
- `6379:6379` - Redis condiviso (opzionale)
- `13306-14305:3306` - MySQL dedicati (range dinamico)

### Interne (solo Docker network)
- `80` - Nginx per ogni progetto
- `9000` - PHP-FPM per ogni progetto

## Scalabilità

L'architettura supporta:
- ✅ Decine di progetti simultanei
- ✅ Mix di tipi progetto (Laravel, WordPress, PHP, HTML)
- ✅ Versioni PHP diverse per progetto
- ✅ Servizi dedicati e condivisi contemporaneamente

Limite pratico: ~20-30 progetti attivi (dipende da RAM disponibile)

## Sicurezza

- 🔒 Certificati SSL automatici (Let's Encrypt)
- 🔒 Reti isolate (frontend/backend)
- 🔒 Password database configurabili
- 🔒 Container non-root quando possibile

---

**Aggiornato:** Febbraio 2026
**Versione:** 2.0 (Architettura Ibrida)
