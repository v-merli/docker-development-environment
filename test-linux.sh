#!/bin/bash
# Script per testare Docker Development Environment su Linux tramite Multipass

set -e

VM_NAME="docker-dev-test"
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

echo ""
echo "========================================"
echo "  Test Docker Dev Environment su Linux"
echo "========================================"
echo ""

# ==================================================
# Step 1: Crea VM Ubuntu
# ==================================================
print_info "Creazione VM Ubuntu..."
echo ""

if multipass list | grep -q "$VM_NAME"; then
    print_warning "VM '$VM_NAME' già esistente"
    read -p "Vuoi ricrearla? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Eliminazione VM esistente..."
        multipass delete "$VM_NAME"
        multipass purge
    else
        print_info "Uso VM esistente"
    fi
fi

if ! multipass list | grep -q "$VM_NAME"; then
    print_info "Lancio nuova VM Ubuntu (22.04 LTS)..."
    print_info "Configurazione: 2 CPU, 4GB RAM, 20GB Disco"
    multipass launch --name "$VM_NAME" --cpus 2 --memory 4G --disk 20G 22.04
    print_success "VM creata!"
fi

echo ""

# ==================================================
# Step 2: Installa Docker nella VM
# ==================================================
print_info "Installazione Docker nella VM..."
echo ""

multipass exec "$VM_NAME" -- bash -c '
set -e

echo "📦 Aggiornamento sistema..."
sudo apt-get update -qq

echo "📦 Installazione dipendenze..."
sudo apt-get install -y -qq \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git

echo "🐳 Installazione Docker..."
# Aggiungi Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Aggiungi repository Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installa Docker
sudo apt-get update -qq
sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Aggiungi utente al gruppo docker
sudo usermod -aG docker ubuntu

echo "✓ Docker installato"
'

print_success "Docker installato nella VM!"
echo ""

# ==================================================
# Step 3: Copia il progetto nella VM
# ==================================================
print_info "Trasferimento progetto nella VM..."
echo ""

# Crea archivio temporaneo escludendo file non necessari
TEMP_TAR="/tmp/docker-dev-env-test.tar.gz"
tar -czf "$TEMP_TAR" \
    --exclude='archive' \
    --exclude='.git' \
    --exclude='legacy' \
    --exclude='projects/*' \
    --exclude='proxy/nginx/certs/*' \
    --exclude='releases' \
    --exclude='.DS_Store' \
    --exclude='*.log' \
    -C "$(dirname "$0")" \
    .

# Copia nella VM
multipass transfer "$TEMP_TAR" "$VM_NAME:/home/ubuntu/docker-dev-env.tar.gz"
rm "$TEMP_TAR"

# Estrai nella VM
multipass exec "$VM_NAME" -- bash -c '
cd /home/ubuntu
mkdir -p docker-dev-env
tar -xzf docker-dev-env.tar.gz -C docker-dev-env
rm docker-dev-env.tar.gz
'

print_success "Progetto trasferito!"
echo ""

# ==================================================
# Step 4: Test dello script principale
# ==================================================
print_info "Test del tool docker-dev..."
echo ""

multipass exec "$VM_NAME" -- bash -c '
cd /home/ubuntu/docker-dev-env

echo "=========================================="
echo "TEST 1: Verifica esecuzione script"
echo "=========================================="
./docker-dev --version

echo ""
echo "=========================================="
echo "TEST 2: Info sistema"
echo "=========================================="
./docker-dev info

echo ""
echo "=========================================="
echo "TEST 3: Setup iniziale"
echo "=========================================="
# Setup automatico con valori default
echo "1" | ./docker-dev setup config

echo ""
echo "=========================================="
echo "TEST 4: Verifica configurazione"
echo "=========================================="
cat .config 2>/dev/null || echo "File .config non trovato"

echo ""
echo "=========================================="
echo "TEST 5: Avvio proxy"
echo "=========================================="
./docker-dev setup proxy

echo ""
echo "=========================================="
echo "TEST 6: Verifica container"
echo "=========================================="
docker ps

echo ""
echo "=========================================="
echo "TEST 7: Info completo"
echo "=========================================="
./docker-dev info
'

print_success "Test completati!"
echo ""

# ==================================================
# Riepilogo
# ==================================================
echo ""
echo "========================================"
echo "  📊 Riepilogo"
echo "========================================"
echo ""
print_success "VM Linux creata e configurata"
print_success "Docker installato e funzionante"
print_success "Docker Dev Environment testato"
echo ""
print_info "Per accedere alla VM:"
echo "  multipass shell $VM_NAME"
echo ""
print_info "Per fermare la VM:"
echo "  multipass stop $VM_NAME"
echo ""
print_info "Per eliminare la VM:"
echo "  multipass delete $VM_NAME"
echo "  multipass purge"
echo ""
print_info "Per vedere i logs della VM:"
echo "  multipass exec $VM_NAME -- docker logs nginx-proxy"
echo ""
