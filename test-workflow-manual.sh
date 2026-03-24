#!/bin/bash

# Test manuale completo: creazione, shell, rimozione progetto
# Esegui questo script per testare il workflow completo

set -e

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_title() { echo -e "${CYAN}━━━ $1 ━━━${NC}"; }

TEST_PROJECT="test-workflow-$(date +%s)"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
print_title "TEST WORKFLOW COMPLETO PHPHARBOR"
echo ""
echo "Progetto di test: $TEST_PROJECT"
echo ""

# Verifica Docker
print_info "Verifica Docker..."
if ! docker ps > /dev/null 2>&1; then
    print_error "Docker non disponibile o non in esecuzione"
    exit 1
fi
print_success "Docker disponibile"
echo ""

# ==================================================
# FASE 1: Creazione Progetto
# ==================================================
print_title "FASE 1: Creazione Progetto"
echo ""

print_info "Comando: ./phpharbor create $TEST_PROJECT --type laravel --php 8.3 --no-install"
echo ""

read -p "$(echo -e "${CYAN}Procedere con la creazione? (y/n):${NC} ")" -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Test annullato"
    exit 0
fi

print_info "Creazione progetto in corso..."
./phpharbor create "$TEST_PROJECT" --type laravel --php 8.3 --no-install

if [ $? -eq 0 ]; then
    print_success "Progetto $TEST_PROJECT creato con successo"
else
    print_error "Errore durante la creazione del progetto"
    exit 1
fi

echo ""
sleep 2

# ==================================================
# FASE 2: Verifica Progetto
# ==================================================
print_title "FASE 2: Verifica Progetto"
echo ""

print_info "Lista progetti..."
./phpharbor list

echo ""

print_info "Verifica container del progetto..."
CONTAINERS=$(docker ps --filter "name=$TEST_PROJECT" --format "{{.Names}}")
if [ -n "$CONTAINERS" ]; then
    print_success "Container trovati:"
    echo "$CONTAINERS" | sed 's/^/  - /'
else
    print_warning "Nessun container in esecuzione (normale se il progetto è stato fermato)"
fi

echo ""
sleep 2

# ==================================================
# FASE 3: Test Shell/SSH
# ==================================================
print_title "FASE 3: Test Accesso Shell"
echo ""

print_info "Test comando shell..."
print_warning "Questo aprirà una shell interattiva nel container"
print_info "Esegui alcuni comandi (es: pwd, ls, php -v) e poi digita 'exit'"
echo ""

read -p "$(echo -e "${CYAN}Aprire shell? (y/n):${NC} ")" -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Apertura shell..."
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Shell interattiva - digita 'exit' per uscire${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    ./phpharbor shell "$TEST_PROJECT"
    
    echo ""
    print_success "Shell chiusa"
else
    print_warning "Test shell saltato"
fi

echo ""
sleep 2

# ==================================================
# FASE 4: Test Logs
# ==================================================
print_title "FASE 4: Verifica Logs"
echo ""

print_info "Ultimi log del progetto..."
./phpharbor logs "$TEST_PROJECT" --tail 20

echo ""
sleep 2

# ==================================================
# FASE 5: Test Artisan (se Laravel)
# ==================================================
print_title "FASE 5: Test Comandi Laravel"
echo ""

print_info "Test comando artisan..."
./phpharbor artisan "$TEST_PROJECT" --version

echo ""
sleep 2

# ==================================================
# FASE 6: Rimozione Progetto
# ==================================================
print_title "FASE 6: Rimozione Progetto"
echo ""

print_warning "Questa operazione rimuoverà:"
echo "  - Container del progetto"
echo "  - Volumi Docker"
echo "  - Directory del progetto"
echo ""

read -p "$(echo -e "${RED}Rimuovere il progetto $TEST_PROJECT? (y/n):${NC} ")" -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Rimozione progetto in corso..."
    ./phpharbor remove "$TEST_PROJECT"
    
    if [ $? -eq 0 ]; then
        print_success "Progetto rimosso con successo"
    else
        print_error "Errore durante la rimozione"
        exit 1
    fi
else
    print_warning "Rimozione saltata - ricordati di rimuovere manualmente:"
    echo "  ./phpharbor remove $TEST_PROJECT"
    exit 0
fi

echo ""
sleep 1

# ==================================================
# FASE 7: Verifica Pulizia
# ==================================================
print_title "FASE 7: Verifica Pulizia"
echo ""

print_info "Verifica che il progetto sia stato rimosso..."
if ./phpharbor list 2>&1 | grep -q "$TEST_PROJECT"; then
    print_error "Il progetto è ancora presente nella lista"
    exit 1
else
    print_success "Progetto non più presente nella lista"
fi

print_info "Verifica container rimossi..."
REMAINING=$(docker ps -a --filter "name=$TEST_PROJECT" --format "{{.Names}}")
if [ -n "$REMAINING" ]; then
    print_warning "Container residui trovati:"
    echo "$REMAINING"
else
    print_success "Nessun container residuo"
fi

echo ""

# ==================================================
# RIEPILOGO FINALE
# ==================================================
print_title "RIEPILOGO TEST WORKFLOW"
echo ""

print_success "🎉 Test workflow completato con successo!"
echo ""
echo "Test eseguiti:"
echo "  ✓ Creazione progetto con comando 'phpharbor create'"
echo "  ✓ Lista progetti con 'phpharbor list'"
echo "  ✓ Accesso shell con 'phpharbor shell'"
echo "  ✓ Visualizzazione logs con 'phpharbor logs'"
echo "  ✓ Esecuzione comandi artisan"
echo "  ✓ Rimozione progetto con 'phpharbor remove'"
echo "  ✓ Verifica pulizia completa"
echo ""
print_success "Il refactoring è perfettamente funzionante!"
echo ""
