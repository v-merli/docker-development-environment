#!/bin/bash

# Script per creare un nuovo progetto con Docker
# Supporta: Laravel, WordPress, PHP generico, HTML statico

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directory base
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECTS_DIR="$SCRIPT_DIR/projects"
TEMPLATES_DIR="$SCRIPT_DIR/shared/templates"

# Funzioni per stampare messaggi colorati
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Funzione per mostrare l'uso
show_usage() {
    echo "Uso: $0 <nome-progetto> [opzioni]"
    echo ""
    echo "Opzioni:"
    echo "  --type <tipo>         Tipo progetto: laravel, wordpress, php, html. Default: laravel"
    echo "  --php <versione>      Versione PHP (7.3, 7.4, 8.1, 8.2, 8.3, 8.5). Default: 8.3"
    echo "  --node <versione>     Versione Node.js (18, 20, 21). Default: 20"
    echo "  --mysql <versione>    Versione MySQL (5.7, 8.0). Default: 8.0"
    echo "  --no-db               Non includere MySQL"
    echo "  --no-redis            Non includere Redis"
    echo "  --no-install          Non installare framework/CMS automaticamente"
    echo "  --help                Mostra questo messaggio"
    echo ""
    echo "Tipi di progetto:"
    echo "  laravel    - Progetto Laravel completo (PHP + MySQL + Redis)"
    echo "  wordpress  - Installazione WordPress (PHP + MySQL)"
    echo "  php        - Progetto PHP generico (PHP + MySQL + Redis opzionali)"
    echo "  html       - Sito statico HTML (solo Nginx)"
    echo ""
    echo "Esempi:"
    echo "  $0 my-shop --type laravel --php 8.3"
    echo "  $0 blog --type wordpress --php 8.2"
    echo "  $0 api --type php --php 8.1 --no-redis"
    echo "  $0 landing --type html"
}

# Valori di default
PROJECT_TYPE="laravel"
PHP_VERSION="8.3"
NODE_VERSION="20"
MYSQL_VERSION="8.0"
INCLUDE_DB=true
INCLUDE_REDIS=true
INSTALL_FRAMEWORK=true

# Parse argomenti
if [ $# -eq 0 ]; then
    print_error "Nome progetto non specificato"
    show_usage
    exit 1
fi

PROJECT_NAME=$1
shift

while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            PROJECT_TYPE="$2"
            shift 2
            ;;
        --php)
            PHP_VERSION="$2"
            shift 2
            ;;
        --node)
            NODE_VERSION="$2"
            shift 2
            ;;
        --mysql)
            MYSQL_VERSION="$2"
            shift 2
            ;;
        --no-db)
            INCLUDE_DB=false
            shift
            ;;
        --no-redis)
            INCLUDE_REDIS=false
            shift
            ;;
        --no-install)
            INSTALL_FRAMEWORK=false
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Opzione sconosciuta: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validazione versioni
if [[ ! "$PROJECT_TYPE" =~ ^(laravel|wordpress|php|html)$ ]]; then
    print_error "Tipo progetto non supportato: $PROJECT_TYPE"
    print_error "Tipi supportati: laravel, wordpress, php, html"
    exit 1
fi

if [[ "$PROJECT_TYPE" == "html" ]]; then
    PHP_VERSION=""
    NODE_VERSION=""
    INCLUDE_DB=false
    INCLUDE_REDIS=false
fi

if [[ -n "$PHP_VERSION" ]] && [[ ! "$PHP_VERSION" =~ ^(7.3|7.4|8.1|8.2|8.3|8.5)$ ]]; then
    print_error "Versione PHP non supportata: $PHP_VERSION"
    print_error "Versioni supportate: 7.3, 7.4, 8.1, 8.2, 8.3, 8.5"
    exit 1
fi

if [[ -n "$NODE_VERSION" ]] && [[ ! "$NODE_VERSION" =~ ^(18|20|21)$ ]]; then
    print_error "Versione Node.js non supportata: $NODE_VERSION"
    exit 1
fi

# Converti nome progetto in formato valido
PROJECT_SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
DOMAIN="$PROJECT_SLUG.test"
PROJECT_PATH="$PROJECTS_DIR/$PROJECT_SLUG"

echo ""
print_info "Creazione nuovo progetto"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Nome progetto:   $PROJECT_NAME"
echo "Tipo:            $PROJECT_TYPE"
echo "Slug:            $PROJECT_SLUG"
echo "Dominio:         $DOMAIN"
if [[ -n "$PHP_VERSION" ]]; then
    echo "PHP:             $PHP_VERSION"
    echo "Node.js:         $NODE_VERSION"
fi
if [[ "$INCLUDE_DB" == true ]]; then
    echo "MySQL:           $MYSQL_VERSION"
fi
if [[ "$INCLUDE_REDIS" == true ]]; then
    echo "Redis:           Sì"
fi
echo "Path:            $PROJECT_PATH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verifica se il progetto esiste già
if [ -d "$PROJECT_PATH" ]; then
    print_error "Il progetto '$PROJECT_SLUG' esiste già in $PROJECT_PATH"
    exit 1
fi

# Crea la struttura del progetto
print_info "Creazione struttura directory..."
mkdir -p "$PROJECT_PATH/app"

# Determina quale docker-compose usare
print_info "Copia configurazione Docker..."
case $PROJECT_TYPE in
    html)
        NGINX_CONF="html.conf"
        cp "$TEMPLATES_DIR/docker-compose-html.yml" "$PROJECT_PATH/docker-compose.yml"
        ;;
    wordpress|php)
        NGINX_CONF="${PROJECT_TYPE}.conf"
        cp "$TEMPLATES_DIR/docker-compose-php.yml" "$PROJECT_PATH/docker-compose.yml"
        ;;
    laravel)
        NGINX_CONF="laravel.conf"
        cp "$TEMPLATES_DIR/docker-compose.yml" "$PROJECT_PATH/docker-compose.yml"
        ;;
esac

# Crea file .env
print_info "Creazione file .env..."
cat > "$PROJECT_PATH/.env" << EOF
# Project Environment Configuration
PROJECT_NAME=$PROJECT_SLUG
PROJECT_TYPE=$PROJECT_TYPE
DOMAIN=$DOMAIN
LETSENCRYPT_EMAIL=dev@localhost
NGINX_CONF=$NGINX_CONF
EOF

if [[ -n "$PHP_VERSION" ]]; then
    cat >> "$PROJECT_PATH/.env" << EOF

# PHP version
PHP_VERSION=$PHP_VERSION

# Node.js version
NODE_VERSION=$NODE_VERSION
EOF
fi

if [[ "$INCLUDE_DB" == true ]]; then
    cat >> "$PROJECT_PATH/.env" << EOF

# MySQL configuration
MYSQL_DATABASE=${PROJECT_SLUG//-/_}_db
MYSQL_ROOT_PASSWORD=root
MYSQL_USER=${PROJECT_TYPE}
MYSQL_PASSWORD=secret
MYSQL_VERSION=$MYSQL_VERSION
EOF
fi

if [[ "$INCLUDE_REDIS" == true ]]; then
    cat >> "$PROJECT_PATH/.env" << EOF

# Redis configuration
REDIS_PORT=6379
EOF
fi

print_success "Struttura progetto creata"

# Verifica che la rete proxy esista
print_info "Verifica rete Docker proxy..."
if ! docker network inspect proxy &> /dev/null; then
    print_warning "Rete 'proxy' non trovata. Avvio del proxy..."
    cd "$SCRIPT_DIR/proxy"
    docker-compose up -d
    cd "$SCRIPT_DIR"
fi

# Avvia i container
print_info "Avvio container Docker..."
cd "$PROJECT_PATH"
docker-compose up -d --build

# Attendi che i container siano pronti
print_info "Attesa avvio container..."
sleep 5

# Installazione framework/CMS specifico
case $PROJECT_TYPE in
    laravel)
        if [ "$INSTALL_FRAMEWORK" = true ]; then
            print_info "Installazione Laravel..."
            docker-compose exec -T app composer create-project --prefer-dist laravel/laravel .
            
            print_info "Configurazione permessi..."
            docker-compose exec -T app chmod -R 775 storage bootstrap/cache
            
            if [ ! -f "$PROJECT_PATH/app/.env" ]; then
                docker-compose exec -T app cp .env.example .env
            fi
            
            print_info "Generazione chiave applicazione..."
            docker-compose exec -T app php artisan key:generate
            
            if [[ "$INCLUDE_DB" == true ]]; then
                print_info "Configurazione database..."
                docker-compose exec -T app sed -i 's/DB_HOST=.*/DB_HOST=mysql/' .env
                docker-compose exec -T app sed -i "s/DB_DATABASE=.*/DB_DATABASE=${PROJECT_SLUG//-/_}_db/" .env
                docker-compose exec -T app sed -i 's/DB_USERNAME=.*/DB_USERNAME=laravel/' .env
                docker-compose exec -T app sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=secret/' .env
            fi
            
            if [[ "$INCLUDE_REDIS" == true ]]; then
                print_info "Configurazione Redis..."
                docker-compose exec -T app sed -i 's/REDIS_HOST=.*/REDIS_HOST=redis/' .env
            fi
            
            print_success "Laravel installato con successo"
        fi
        ;;
    
    wordpress)
        if [ "$INSTALL_FRAMEWORK" = true ]; then
            print_info "Download WordPress..."
            docker-compose exec -T app curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
            docker-compose exec -T app tar -xzf /tmp/wordpress.tar.gz -C /tmp
            docker-compose exec -T app cp -r /tmp/wordpress/. /var/www/html/
            docker-compose exec -T app rm -rf /tmp/wordpress*
            
            print_info "Configurazione WordPress..."
            docker-compose exec -T app cp wp-config-sample.php wp-config.php
            docker-compose exec -T app sed -i "s/database_name_here/${PROJECT_SLUG//-/_}_db/" wp-config.php
            docker-compose exec -T app sed -i "s/username_here/wordpress/" wp-config.php
            docker-compose exec -T app sed -i "s/password_here/secret/" wp-config.php
            docker-compose exec -T app sed -i "s/localhost/mysql/" wp-config.php
            
            print_success "WordPress scaricato. Completa l'installazione su http://$DOMAIN"
        fi
        ;;
    
    html)
        print_info "Creazione index.html di esempio..."
        cat > "$PROJECT_PATH/app/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Benvenuto</title>
    <style>
        body { 
            font-family: system-ui, -apple-system, sans-serif;
            max-width: 800px;
            margin: 100px auto;
            padding: 20px;
            line-height: 1.6;
        }
        h1 { color: #333; }
        code {
            background: #f4f4f4;
            padding: 2px 6px;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <h1>🎉 Il tuo progetto è pronto!</h1>
    <p>Questo è un sito HTML statico.</p>
    <p>Modifica questo file in <code>app/index.html</code></p>
</body>
</html>
HTMLEOF
        print_success "Progetto HTML creato"
        ;;
    
    php)
        print_info "Creazione index.php di esempio..."
        cat > "$PROJECT_PATH/app/index.php" << 'PHPEOF'
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP Info</title>
    <style>
        body {
            font-family: system-ui, -apple-system, sans-serif;
            max-width: 1200px;
            margin: 20px auto;
            padding: 20px;
        }
        h1 { color: #8892BF; }
    </style>
</head>
<body>
    <h1>🎉 PHP è funzionante!</h1>
    <p><strong>Versione PHP:</strong> <?php echo phpversion(); ?></p>
    <p><strong>Sistema:</strong> <?php echo php_uname(); ?></p>
    <hr>
    <h2>Informazioni PHP Complete</h2>
    <?php phpinfo(); ?>
</body>
</html>
PHPEOF
        print_success "Progetto PHP creato"
        ;;
esac

echo ""
print_success "Progetto creato con successo!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tipo:             $PROJECT_TYPE"
echo "URL:              http://$DOMAIN"
echo "HTTPS:            https://$DOMAIN"
echo "Directory:        $PROJECT_PATH"
echo ""
echo "Comandi utili:"
echo "  cd $PROJECT_PATH"
echo "  docker-compose ps              # Stato container"
echo "  docker-compose logs -f         # Log in tempo reale"
if [[ -n "$PHP_VERSION" ]]; then
    echo "  docker-compose exec app bash   # Shell nel container PHP"
fi
echo "  docker-compose down            # Ferma i container"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

case $PROJECT_TYPE in
    laravel)
        if [ "$INSTALL_FRAMEWORK" = true ] && [ "$INCLUDE_DB" = true ]; then
            print_info "Esegui le migrazioni: docker-compose exec app php artisan migrate"
        fi
        ;;
    wordpress)
        if [ "$INSTALL_FRAMEWORK" = true ]; then
            print_info "Completa l'installazione WordPress visitando: http://$DOMAIN"
        fi
        ;;
esac

print_warning "Ricorda di configurare dnsmasq per risolvere i domini .test"
print_warning "Esegui: ./setup-dnsmasq.sh"
