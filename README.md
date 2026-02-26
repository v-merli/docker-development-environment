# 🚀 Docker Development Environment per Laravel

> **✨ NEW: CLI Unificato v2.0!** Usa `./docker-dev` per tutti i comandi. Gli script legacy sono in `legacy/`.  
> Leggi la [Guida CLI](CLI-README.md) per iniziare.

Ambiente di sviluppo Docker completo per gestire più progetti con:
- 🎯 **Tipi progetto multipli** (Laravel, WordPress, PHP generico, HTML statico)
- 🐘 **Versioni PHP selezionabili** (7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5) - dedicato o condiviso
- 📦 **Versioni Node.js selezionabili** (18, 20, 21)
- 🗄️ **MySQL** (5.7, 8.0) - dedicato o condiviso
- 🔴 **Redis** - dedicato o condiviso
- 🌐 **Nginx reverse proxy** con routing automatico
- 🔒 **Certificati SSL automatici** (Let's Encrypt/self-signed)
- 🔌 **DNS locale** con dnsmasq per domini `.test`
- 💾 **Architettura ibrida** - PHP, MySQL, Redis dedicati o condivisi

## ⚡ Quick Start (CLI v2.0)

```bash
# Setup iniziale
./docker-dev setup init

# Crea un progetto Laravel con massimo risparmio risorse
./docker-dev create myapp --fully-shared --php 8.3

# Gestisci progetti
./docker-dev list
./docker-dev start myapp
./docker-dev logs myapp
./docker-dev shell myapp

# Sviluppo Laravel
./docker-dev artisan myapp migrate
./docker-dev composer myapp require laravel/sanctum
```

📖 **Documentazione**:
- **[Guida CLI Completa](CLI-README.md)** - Tutti i comandi disponibili
- **[Gestione Workers e Scheduler](WORKERS-GUIDE.md)** - Laravel scheduler, queue workers, supervisor
- **[Certificati SSL Locali](SSL-SETUP.md)** - Setup certificati per HTTPS locale
- **[Architettura Sistema](ARCHITECTURE.md)** - Dettagli tecnici architettura Docker

## 📋 Indice

- [Requisiti](#requisiti)
- [Installazione](#installazione)
- [Architettura](#architettura)
- [Utilizzo](#utilizzo)
- [Gestione Progetti](#gestione-progetti)
- [Servizi Condivisi](#servizi-condivisi)
- [Struttura Directory](#struttura-directory)
- [Troubleshooting](#troubleshooting)

## 🔧 Requisiti

- **macOS** (testato su macOS)
- **Docker Desktop** installato e in esecuzione
- **Homebrew** (per installare dnsmasq)

## 📥 Installazione

### Setup Completo Automatico

Il modo più veloce per iniziare:

```bash
./docker-dev setup init
```

Questo comando interattivo:
1. Verifica Docker e Docker Compose
2. Configura dnsmasq per domini `.test` (opzionale)
3. Avvia il reverse proxy nginx
4. Verifica mkcert per certificati SSL locali

### Setup Manuale

Se preferisci configurare manualmente:

#### 1. Avvia il Proxy

```bash
./docker-dev setup proxy
```

Questo creerà la rete Docker `proxy` e avvierà nginx-proxy con acme-companion per i certificati SSL.

#### 2. Configura DNS Locale (Opzionale)

```bash
./docker-dev setup dns
```

Installa e configura dnsmasq per far funzionare i domini `*.test`.

Lo script:
- Installa dnsmasq via Homebrew
- Configura la risoluzione di tutti i domini `*.test` a `127.0.0.1`
- Avvia il servizio dnsmasq

**Verifica:** Dopo l'installazione, prova:
```bash
ping test.test
# Dovrebbe rispondere da 127.0.0.1
```

#### 3. (Opzionale) Avvia i Servizi Condivisi

Se prevedi di usare servizi condivisi per risparmiare RAM:

```bash
./docker-dev shared start
```

### Quick Start - Crea il tuo primo progetto

```bash
# Progetto Laravel con servizi dedicati
./docker-dev create myshop --type laravel

# Progetto con tutto condiviso (massimo risparmio)
./docker-dev create myapp --fully-shared --php 8.3

# Progetto con DB condiviso, PHP dedicato
./docker-dev create myapi --shared-db --php 8.2

# Accedi al progetto
open http://myshop.test
```

## 🏗️ Architettura

Questa soluzione implementa un'**architettura ibrida** che offre flessibilità tra prestazioni e consumo risorse:

**📖 [Documentazione Completa Architettura →](ARCHITECTURE.md)**

### Componenti Principali

#### 1. **Nginx Reverse Proxy** (centrale)
- Container unico che ascolta sulle porte `8080` (HTTP) e `8443` (HTTPS)
- Monitora i container Docker tramite `/var/run/docker.sock`
- Routing automatico basato su `VIRTUAL_HOST` (es. `myproject.test` → container `myproject-nginx`)
- Gestione certificati SSL con ACME companion

#### 2. **Servizi per Progetto**
Ogni progetto può avere:
- **PHP-FPM**: container dedicato con versione specifica (7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5)
- **Nginx**: container dedicato con configurazione specifica (Laravel/WordPress/PHP/HTML)
- **Scheduler**: container sempre attivo per Laravel task scheduler (`php artisan schedule:run`)
- **Queue Worker**: container opzionale per Laravel queue processing (Redis/Database)

> 📖 **[Guida completa workers →](WORKERS-GUIDE.md)** - Scheduler, queue workers, supervisor

#### 3. **Servizi Database: Dedicati o Condivisi**
Puoi scegliere tra:

**🔹 Servizi Dedicati** (default):
- Ogni progetto ha il proprio MySQL e Redis
- ✅ Isolamento completo
- ✅ Configurazioni personalizzate
- ❌ Consumo RAM elevato con molti progetti (~500MB per progetto)

**🔹 Servizi Condivisi** (opzionale):
- MySQL e Redis condivisi tra tutti i progetti
- ✅ Risparmio significativo di RAM (~4GB → 400MB con 10 progetti)
- ✅ Database separati per progetto (stesso server MySQL)
- ✅ Backup centralizzato più semplice
- ⚠️ Tutti i progetti condividono versione MySQL/Redis

### Flusso di una Richiesta

```
Browser → http://myproject.test
         ↓
127.0.0.1 (dnsmasq risolve *.test)
         ↓
nginx-proxy container
         ↓
Legge Host: myproject.test
         ↓
Routing via rete Docker "proxy"
         ↓
Container myproject-nginx:80
         ↓
FastCGI → myproject-app (PHP-FPM)
         ↓
Connessione a MySQL/Redis (dedicato o condiviso)
```

## 🎯 Utilizzo

### Creare un Nuovo Progetto

#### Con Servizi Dedicati (default)

```bash
# Progetto Laravel (default - PHP 8.3, Node 20, MySQL 8.0)
./docker-dev create my-shop

# WordPress
./docker-dev create blog --type wordpress --php 8.2

# Progetto PHP generico
./docker-dev create api --type php --php 8.1

# Sito HTML statico (solo Nginx)
./docker-dev create landing --type html

# Personalizza tutto
./docker-dev create ecommerce --type laravel --php 8.3 --node 20 --mysql 8.0

# Senza database o Redis
./docker-dev create simple --type php --php 8.2 --no-db --no-redis

# Legacy PHP 7.4
./docker-dev create old-project --type php --php 7.4
```

#### Con Servizi Condivisi (risparmio risorse)

```bash
# Usa tutti i servizi condivisi (MySQL + Redis)
./docker-dev create project1 --shared

# Solo MySQL condiviso, Redis dedicato
./docker-dev create project2 --shared-db

# Solo Redis condiviso, MySQL dedicato
./docker-dev create project3 --shared-redis

# Solo PHP condiviso (MySQL e Redis dedicati)
./docker-dev create project4 --shared-php

# Tutto condiviso (massimo risparmio RAM!)
./docker-dev create project5 --fully-shared

# Esempio completo con tipo specifico
./docker-dev create shop --type laravel --php 8.3 --fully-shared
```

**💡 Quando usare servizi condivisi?**
- ✅ Hai 3+ progetti contemporaneamente attivi
- ✅ RAM limitata sul tuo Mac
- ✅ Progetti in sviluppo che non richiedono configurazioni MySQL particolari
- ✅ **PHP condiviso**: massimo risparmio, ma tutti i progetti usano la stessa versione PHP
- ❌ Progetti di produzione o che richiedono versioni MySQL/PHP diverse
- ❌ **PHP condiviso**: se i progetti necessitano versioni PHP diverse

Il progetto sarà accessibile a:
- **HTTP:** `http://nome-progetto.test`
- **HTTPS:** `https://nome-progetto.test` (certificato auto-firmato in locale)

### Gestire i Progetti

```bash
# Lista tutti i progetti
./docker-dev list

# Avvia un progetto
./docker-dev start my-shop

# Ferma un progetto
./docker-dev stop my-shop

# Riavvia un progetto
./docker-dev restart my-shop

# Visualizza i log
./docker-dev logs my-shop

# Rimuovi un progetto
./docker-dev remove my-shop
```

### Strumenti di Sviluppo

```bash
# Apri shell nel container PHP
./docker-dev shell my-shop

# Esegui comandi Artisan
./docker-dev artisan my-shop migrate
./docker-dev artisan my-shop make:controller UserController

# Esegui comandi Composer
./docker-dev composer my-shop require laravel/sanctum

# Esegui comandi NPM
./docker-dev npm my-shop install
./docker-dev npm my-shop run dev

# Accedi a MySQL del progetto
./docker-dev mysql my-shop
```

## 🔄 Servizi Condivisi

I servizi condivisi (MySQL e Redis) consentono a più progetti di condividere la stessa istanza del database, riducendo significativamente il consumo di RAM.

**📖 [Guida Completa ai Servizi Condivisi →](SHARED-SERVICES.md)**

### Avvio Rapido

```bash
# Avvia servizi condivisi (MySQL + Redis)
./docker-dev shared start

# Crea progetto con servizi condivisi
./docker-dev create myproject --shared

# Crea progetto fully-shared (massimo risparmio)
./docker-dev create myproject --fully-shared --php 8.3
```

### Gestione Servizi Condivisi

```bash
# Avvia tutti i servizi condivisi (MySQL + Redis)
./docker-dev shared start

# Avvia singolo servizio
./docker-dev shared start mysql
./docker-dev shared start redis

# Avvia PHP condiviso (versione specifica)
./docker-dev shared php 8.3

# Ferma i servizi condivisi
./docker-dev shared stop

# Mostra lo stato dei servizi condivisi
./docker-dev shared status

# Mostra i log dei servizi condivisi
./docker-dev shared logs

# Accedi a MySQL condiviso
./docker-dev shared mysql
```

### Informazioni di Connessione

**MySQL Condiviso:**
- **Host:** `localhost` (dall'host) o `mysql-shared` (da container)
- **Porta:** `3306`
- **User:** `root`
- **Password:** `rootpassword`

**Redis Condiviso:**
- **Host:** `localhost` (dall'host) o `redis-shared` (da container)
- **Porta:** `6379`

**PHP-FPM Condiviso:**
- **Container:** `php-X.X-shared` (es. `php-8.3-shared`)
- **Percorsi:** `/var/www/projects/<progetto>/app`

### Creare Database per Progetti

I progetti con servizi condivisi devono creare il loro database:

```bash
# Accedi a MySQL condiviso
./docker-dev shared mysql

# Crea database per il progetto
CREATE DATABASE myproject_db;
GRANT ALL PRIVILEGES ON myproject_db.* TO 'root'@'%';
FLUSH PRIVILEGES;
EXIT;

# Esegui migration dal progetto
./docker-dev artisan myproject migrate
```

### Confronto Consumo Risorse

| Configurazione | 1 Progetto | 5 Progetti | 10 Progetti |
|----------------|------------|------------|-------------|
| **Tutti Dedicati** | ~500 MB | ~2.5 GB | ~5 GB |
| **DB Condivisi** | ~350 MB | ~1.75 GB | ~3.5 GB |
| **Tutto Condiviso** | ~50 MB | ~250 MB | ~500 MB |
| **Risparmio (fully-shared)** | - | **90%** | **90%** |

*Nota: Con --fully-shared, ogni progetto ha solo Nginx (~10MB), tutto il resto è condiviso*

## 📁 Struttura Directory

```
docker-dev/
├── docker-dev                     # 🆕 CLI unificato (entrypoint principale)
│
├── cli/                           # 🆕 Moduli CLI
│   ├── project.sh                # Gestione progetti
│   ├── dev.sh                    # Strumenti sviluppo
│   ├── shared.sh                 # Servizi condivisi
│   ├── setup.sh                  # Setup sistema
│   ├── create.sh                 # Creazione progetti
│   └── system.sh                 # Info e statistiche
│
├── legacy/                        # ⚠️ Script deprecati (retrocompatibilità)
│   ├── README.md                 # Guida migrazione
│   ├── new-project.sh
│   ├── manage-projects.sh
│   └── ...                       # Altri script legacy
│
├── proxy/                         # Nginx reverse proxy + servizi condivisi
│   ├── docker-compose.yml        # Proxy + MySQL/Redis/PHP condivisi
│   ├── nginx/
│   │   ├── certs/                # Certificati SSL
│   │   ├── vhost.d/              # Configurazioni vhost
│   │   └── acme/                 # Let's Encrypt config
│   └── generate-cert.sh
│
├── projects/                      # Tutti i progetti
│   ├── my-shop/                  # Progetto Laravel
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   └── app/                  # Codice Laravel
│   ├── blog/                     # Progetto WordPress
│   │   └── ...
│   └── landing/                  # Sito HTML statico
│       └── ...
│
├── shared/                        # Risorse condivise
│   ├── dockerfiles/              # Dockerfile per versioni PHP
│   │   ├── php-7.3.Dockerfile
│   │   ├── php-7.4.Dockerfile
│   │   ├── php-8.1.Dockerfile
│   │   ├── php-8.2.Dockerfile
│   │   ├── php-8.3.Dockerfile
│   │   └── php-8.5.Dockerfile
│   ├── nginx/                    # Configurazioni nginx
│   │   ├── laravel.conf         # Laravel
│   │   ├── laravel-shared.conf  # Laravel PHP condiviso
│   │   ├── wordpress.conf       # WordPress
│   │   ├── php.conf             # PHP generico
│   │   └── html.conf            # HTML statico
│   ├── templates/                # Template per nuovi progetti
│   │   ├── docker-compose.yml              # Dedicato completo
│   │   ├── docker-compose-shared.yml       # DB/Redis condivisi
│   │   ├── docker-compose-fully-shared.yml # Tutto condiviso
│   │   ├── docker-compose-php.yml          # PHP generico
│   │   └── docker-compose-html.yml         # HTML statico
│   └── dnsmasq/
│       └── dnsmasq.conf
│
├── 📄 Documentazione
│   ├── README.md                 # Questo file
│   ├── CLI-README.md             # 🆕 Guida CLI completa
│   ├── MIGRATION.md              # 🆕 Guida migrazione script
│   ├── ARCHITECTURE.md           # Architettura dettagliata
│   ├── SHARED-SERVICES.md        # Servizi condivisi
│   ├── QUICK-START.md            # Quick start
│   └── UTILITIES.md              # Utility varie
```

### 🔄 Cambiamenti Recenti (v2.0)

- ✅ **CLI Unificato**: Un solo comando `./docker-dev` per tutto
- ✅ **Struttura Modulare**: Codice organizzato in `cli/`  
- ✅ **Script Legacy**: Spostati in `legacy/` ma ancora funzionanti
- ✅ **Documentazione**: Aggiunta CLI-README e MIGRATION guide

## 🎯 Tipi di Progetto Supportati

### Laravel
Progetto Laravel completo con:
- Container PHP-FPM con tutte le estensioni
- MySQL per il database
- Redis per cache/queue/sessioni
- Nginx configurato per Laravel
- Composer e Node.js pre-installati

### WordPress
Installazione WordPress pronta all'uso:
- Container PHP-FPM ottimizzato per WordPress
- MySQL per il database
- Nginx configurato per WordPress
- Download automatico WordPress (opzionale)

### PHP Generico
Per progetti PHP custom:
- Container PHP-FPM con tutte le estensioni
- MySQL opzionale
- Redis opzionale
- Nginx con configurazione PHP standard

### HTML Statico
Per siti statici senza PHP:
- Solo container Nginx
- Nessun PHP, MySQL o Redis
- Massima leggerezza e velocità
- Ideale per landing page, documentazione, etc.

##  │   └── .env.example
│   └── dnsmasq/
│       └── dnsmasq.conf
│
├── new-project.sh                 # Script creazione progetti
├── manage-projects.sh             # Script gestione progetti
├── setup-dnsmasq.sh              # Script setup DNS
└── README.md                      # Questa guida
```

## 🐘 Versioni PHP Disponibili

Ogni progetto può usare una versione diversa di PHP:

- **PHP 7.3** - Legacy (EOL)
- **PHP 7.4** - Legacy (EOL)
- **PHP 8.1** - Stabile
- **PHP 8.2** - Stabile e performante
- **PHP 8.3** - LTS (default)
- **PHP 8.5** - Ultima versione

Estensioni incluse:
- pdo_mysql, mbstring, exif, pcntl, bcmath, gd, zip
- redis, imagick, xdebug
- Composer pre-installato

**Nota:** PHP 7.3 e 7.4 usano Xdebug 2.x, le altre versioni usano Xdebug 3.x

## 📦 Versioni Node.js Disponibili

- **Node.js 18** - LTS
- **Node.js 20** - LTS (default)
- **Node.js 21** - Ultima versione

## 🗄️ Database

Ogni progetto ha il proprio container MySQL isolato. Le credenziali di default sono configurabili nel file `.env` del progetto:

```env
MYSQL_DATABASE=my_shop_db
MYSQL_ROOT_PASSWORD=root
MYSQL_USER=laravel
MYSQL_PASSWORD=secret
```

### Accesso al Database

**Da Laravel:**
```env
DB_HOST=mysql
DB_DATABASE=my_shop_db
DB_USERNAME=laravel
DB_PASSWORD=secret
```

**Da terminale:**
```bash
./docker-dev mysql my-shop
```

**Da client esterno** (es. TablePlus):
```
Host: 127.0.0.1
Port: [esegui: docker compose port mysql 3306 nel progetto]
User: root
Password: root
```

## 🔒 Certificati SSL

### Sviluppo Locale

I certificati SSL vengono **generati automaticamente** durante la creazione del progetto utilizzando **mkcert**.

**Setup iniziale (solo la prima volta):**
```bash
./docker-dev ssl setup
```

Questo installerà la CA locale nel keychain del tuo sistema. **Dovrai riavviare il browser** dopo l'installazione.

**I certificati vengono generati automaticamente** quando crei un nuovo progetto:
```bash
./docker-dev create myproject
# Il certificato SSL viene generato e installato automaticamente
```

**Comandi utili:**
```bash
# Verifica configurazione SSL
./docker-dev ssl verify

# Genera certificato per dominio specifico
./docker-dev ssl generate myapp.test

# Reinstalla CA (se necessario)
./docker-dev ssl install
```

**Se il browser mostra avvisi di sicurezza:**

Consulta la [guida completa SSL](SSL-SETUP.md) oppure:

1. **Riavvia tutti i browser** (fondamentale!)
2. Apri **Accesso Portachiavi** > cerca "mkcert"
3. Doppio clic > espandi "Fidati" > seleziona "Fidati sempre" per SSL
4. Riavvia il browser

### Produzione

Per domini pubblici, acme-companion richiederà automaticamente certificati Let's Encrypt validi.

## 🛠️ Comandi Docker Utili

### Dentro la directory di un progetto:

```bash
# Stato dei container
docker-compose ps

# Log in tempo reale
docker-compose logs -f

# Ricostruire le immagini
docker-compose up -d --build

# Fermare i container
docker-compose down

# Fermare e rimuovere i volumi (ATTENZIONE: elimina il database)
docker-compose down -v

# Eseguire comandi nel container PHP
docker-compose exec app php -v
docker-compose exec app composer --version
docker-compose exec app node --version
docker-compose exec app npm --version
```

## 🔍 Troubleshooting

### Il dominio .test non si risolve

1. Verifica che dnsmasq sia in esecuzione:
   ```bash
   sudo brew services list
   ```

2. Riavvia dnsmasq:
   ```bash
   sudo brew services restart dnsmasq
   ```

3. Verifica la configurazione resolver:
   ```bash
   cat /etc/resolver/test
   # Dovrebbe mostrare: nameserver 127.0.0.1
   ```

4. Test manuale:
   ```bash
   dig @127.0.0.1 test.test
   ```

### I container non si avviano

1. Verifica che Docker sia in esecuzione
2. Controlla i log:
   ```bash
   cd projects/my-shop
   docker-compose logs
   ```

3. Verifica che la rete proxy esista:
   ```bash
   docker network ls | grep proxy
   ```

4. Se manca, avvia il proxy:
   ```bash
   cd proxy
   docker-compose up -d
   ```

### Errore "port is already allocated"

Se hai già servizi su porta 80/443:

**Opzione 1:** Ferma i servizi in conflitto (es. nginx, apache locali)

**Opzione 2:** Modifica le porte in `proxy/docker-compose.yml`:
```yaml
ports:
  - "80:80"     # Porte standard
  - "443:443"   # Porte standard
```

Poi accedi con: `http://my-shop.test`

### Laravel: permessi di scrittura

Se Laravel non riesce a scrivere in `storage/` o `bootstrap/cache/`:

```bash
cd projects/my-shop
docker-compose exec app chmod -R 775 storage bootstrap/cache
docker-compose exec app chown -R www-data:www-data storage bootstrap/cache
```

### Database connection refused

1. Verifica che il container MySQL sia avviato:
   ```bash
   docker-compose ps mysql
   ```

2. Controlla che Laravel usi `DB_HOST=mysql` (non `localhost` o `127.0.0.1`)

3. Aspetta che MySQL sia completamente avviato (può richiedere 10-15 secondi al primo avvio)

### Cancellare tutto e ricominciare

```bash
# Ferma tutti i container
cd projects/my-shop
docker-compose down -v

cd ../../proxy
docker-compose down -v

# Rimuovi la rete
docker network rm proxy

# Riavvia il proxy
docker-compose up -d

# Riavvia il progetto
cd ../projects/my-shop
docker-compose up -d
```

## 📚 Risorse Utili

- [Docker Documentation](https://docs.docker.com/)
- [Laravel Documentation](https://laravel.com/docs)
- [nginx-proxy GitHub](https://github.com/nginx-proxy/nginx-proxy)
- [acme-companion GitHub](https://github.com/nginx-proxy/acme-companion)

## 🤝 Best Practices

1. **Un progetto = un container set:** Ogni progetto ha i propri container isolati
2. **Versioni esplicite:** Specifica sempre le versioni PHP/Node quando crei un progetto
3. **Backup database:** I dati MySQL sono in volumi Docker. Fai backup regolari:
   ```bash
   docker-compose exec mysql mysqldump -uroot -proot database_name > backup.sql
   ```
4. **Aggiorna le immagini:** Periodicamente ricostruisci le immagini per avere gli ultimi aggiornamenti:
   ```bash
   docker-compose build --no-cache
   ```

## 📝 Note

- I certificati SSL in sviluppo locale sono auto-firmati
- dnsmasq risolve TUTTI i domini `.test` a localhost
- Ogni progetto ha un proprio network Docker isolato per sicurezza
- Il proxy condivide la rete `proxy` con tutti i progetti

---

**Creato con ❤️ per lo sviluppo Laravel su Docker**
