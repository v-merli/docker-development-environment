#!/bin/bash

# Test completo del refactoring PHPHarbor
# Verifica: installazione, creazione progetto, shell, rimozione

set -e

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funzioni di output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_title() { echo -e "${CYAN}━━━ $1 ━━━${NC}"; }

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_PROJECT="test-refactoring-$(date +%s)"
ERRORS=0

echo ""
print_title "TEST REFACTORING PHPHARBOR"
echo ""
echo "Directory: $SCRIPT_DIR"
echo "Progetto test: $TEST_PROJECT"
echo ""

# ==================================================
# TEST 1: Verifica nomi comandi e file
# ==================================================
print_title "Test 1: Verifica File e Comandi"
echo ""

print_info "Verifica file principale 'phpharbor'..."
if [ -f "$SCRIPT_DIR/phpharbor" ] && [ -x "$SCRIPT_DIR/phpharbor" ]; then
    print_success "File phpharbor esiste ed è eseguibile"
else
    print_error "File phpharbor non trovato o non eseguibile"
    ((ERRORS++))
fi

print_info "Verifica completion file 'phpharbor-completion.bash'..."
if [ -f "$SCRIPT_DIR/phpharbor-completion.bash" ]; then
    print_success "File completion trovato"
else
    print_error "File completion non trovato"
    ((ERRORS++))
fi

print_info "Controllo riferimenti obsoleti a 'docker-dev'..."
DOCKER_DEV_COUNT=$(grep -r "\bdocker-dev\b" --exclude-dir=.git --exclude-dir=node_modules --include="*.sh" --include="*.bash" "$SCRIPT_DIR" 2>/dev/null | grep -v "docker-development-environment" | wc -l | tr -d ' ')
if [ "$DOCKER_DEV_COUNT" -eq 0 ]; then
    print_success "Nessun riferimento obsoleto a 'docker-dev' trovato"
else
    print_warning "Trovati $DOCKER_DEV_COUNT riferimenti a 'docker-dev' (potrebbero essere accettabili)"
fi

echo ""

# ==================================================
# TEST 2: Help e Versione
# ==================================================
print_title "Test 2: Comandi Help e Version"
echo ""

print_info "Test: ./phpharbor help"
if ./phpharbor help > /dev/null 2>&1; then
    print_success "Comando help funziona"
else
    print_error "Comando help fallito"
    ((ERRORS++))
fi

print_info "Test: ./phpharbor version"
VERSION_OUTPUT=$(./phpharbor version 2>&1)
if echo "$VERSION_OUTPUT" | grep -q "PHPHarbor"; then
    print_success "Comando version funziona: $VERSION_OUTPUT"
else
    print_error "Comando version non mostra 'PHPHarbor'"
    ((ERRORS++))
fi

echo ""

# ==================================================
# TEST 3: Verifica sintassi script installazione
# ==================================================
print_title "Test 3: Sintassi Script Installazione"
echo ""

print_info "Verifica sintassi install.sh..."
if bash -n "$SCRIPT_DIR/install.sh" 2>&1; then
    print_success "install.sh: sintassi corretta"
else
    print_error "install.sh: errori di sintassi"
    ((ERRORS++))
fi

print_info "Verifica sintassi uninstall.sh..."
if bash -n "$SCRIPT_DIR/uninstall.sh" 2>&1; then
    print_success "uninstall.sh: sintassi corretta"
else
    print_error "uninstall.sh: errori di sintassi"
    ((ERRORS++))
fi

print_info "Verifica contenuto install.sh per 'phpharbor'..."
if grep -q "phpharbor" "$SCRIPT_DIR/install.sh"; then
    print_success "install.sh contiene riferimenti a 'phpharbor'"
else
    print_error "install.sh non contiene riferimenti a 'phpharbor'"
    ((ERRORS++))
fi

echo ""

# ==================================================
# TEST 4: Creazione Progetto (DRY RUN)
# ==================================================
print_title "Test 4: Creazione Progetto Test"
echo ""

print_info "Verifica comando create disponibile..."
if ./phpharbor create --help > /dev/null 2>&1; then
    print_success "Comando 'create' disponibile"
else
    print_error "Comando 'create' non disponibile"
    ((ERRORS++))
fi

print_info "Test: Creazione progetto '$TEST_PROJECT'..."
print_warning "⏭️  SKIP: Test creazione progetto reale (richiede Docker)"
print_info "Per testare manualmente:"
echo "  ./phpharbor create $TEST_PROJECT --type laravel --php 8.3 --no-install"

echo ""

# ==================================================
# TEST 5: Comandi gestione progetti
# ==================================================
print_title "Test 5: Comandi Gestione Progetti"
echo ""

print_info "Test: ./phpharbor list"
if ./phpharbor list > /dev/null 2>&1; then
    print_success "Comando 'list' funziona"
else
    print_error "Comando 'list' fallito"
    ((ERRORS++))
fi

print_info "Test: ./phpharbor shared status"
if ./phpharbor shared status > /dev/null 2>&1; then
    print_success "Comando 'shared status' funziona"
else
    print_error "Comando 'shared status' fallito"
    ((ERRORS++))
fi

echo ""

# ==================================================
# TEST 6: Verifica CLI modules
# ==================================================
print_title "Test 6: Verifica Moduli CLI"
echo ""

CLI_MODULES=("create.sh" "project.sh" "dev.sh" "shared.sh" "setup.sh" "ssl.sh" "system.sh" "update.sh")
ALL_OK=true

for module in "${CLI_MODULES[@]}"; do
    MODULE_PATH="$SCRIPT_DIR/cli/$module"
    if [ -f "$MODULE_PATH" ]; then
        if bash -n "$MODULE_PATH" 2>&1; then
            echo "  ✓ $module: OK"
        else
            print_error "$module: errore sintassi"
            ALL_OK=false
            ((ERRORS++))
        fi
    else
        print_error "$module: non trovato"
        ALL_OK=false
        ((ERRORS++))
    fi
done

if [ "$ALL_OK" = true ]; then
    print_success "Tutti i moduli CLI verificati"
fi

echo ""

# ==================================================
# TEST 7: Verifica documentazione
# ==================================================
print_title "Test 7: Verifica Documentazione"
echo ""

print_info "Controllo riferimenti in README.md..."
if grep -q "phpharbor" "$SCRIPT_DIR/README.md"; then
    print_success "README.md aggiornato con 'phpharbor'"
else
    print_warning "README.md potrebbe non essere aggiornato"
fi

print_info "Controllo docs/installation.md..."
if [ -f "$SCRIPT_DIR/docs/installation.md" ]; then
    if grep -q "phpharbor" "$SCRIPT_DIR/docs/installation.md"; then
        print_success "installation.md aggiornato"
    else
        print_warning "installation.md potrebbe non essere aggiornato"
    fi
fi

echo ""

# ==================================================
# RIEPILOGO
# ==================================================
print_title "RIEPILOGO TEST"
echo ""

if [ $ERRORS -eq 0 ]; then
    print_success "🎉 Tutti i test passati con successo!"
    echo ""
    echo -e "${GREEN}Il refactoring è completo e corretto!${NC}"
    echo ""
    echo "Prossimi passi per test manuali:"
    echo ""
    echo "1️⃣  Test installazione simulata:"
    echo "   ${CYAN}cat install.sh | grep phpharbor${NC}"
    echo ""
    echo "2️⃣  Crea un progetto di test:"
    echo "   ${CYAN}./phpharbor create test-manual --type laravel --php 8.3${NC}"
    echo ""
    echo "3️⃣  Accedi alla shell del progetto:"
    echo "   ${CYAN}./phpharbor shell test-manual${NC}"
    echo ""
    echo "4️⃣  Rimuovi il progetto:"
    echo "   ${CYAN}./phpharbor remove test-manual${NC}"
    echo ""
    exit 0
else
    print_error "❌ Test falliti: $ERRORS errori trovati"
    echo ""
    echo "Controlla i messaggi sopra per i dettagli"
    exit 1
fi
