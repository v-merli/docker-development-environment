# TUI Production - Progress Tracker

**Branch:** `feature/go-tui-production`  
**Status:** 25+ commits ahead of develop  
**Last Updated:** 2026-04-03 (Setup Wizard Suspend-Resume Fix)

## ✅ Completato

### Fase 1: Project Management Commands (7/7)
- [x] `list` - Lista progetti con stato
- [x] `start [project]` - Avvia progetto/i
- [x] `stop [project]` - Ferma progetto/i
- [x] `restart [project]` - Riavvia progetto/i
- [x] `remove [project]` - Rimuovi progetto
- [x] `logs [project]` - Visualizza logs
- [x] `info [project]` - Info dettagliate progetto

### Fase 2: Development Tools (6/6)
- [x] `shell [project]` - Shell interattiva ⭐
- [x] `artisan [project] [args]` - Laravel Artisan ⭐
- [x] `composer [project] [args]` - Composer ⭐
- [x] `npm [project] [args]` - NPM ⭐
- [x] `mysql [project]` - MySQL CLI ⭐
- [x] `queue [project]` - Queue worker ⭐

_⭐ = Comando interattivo con suspend-resume pattern_

### Fase 3: Service Management (2/2)
- [x] `service` - Gestione servizi progetto (add/remove/list/templates)
- [x] `shared` - Gestione servizi condivisi (start/stop/status/logs)

### Fase 4: SSL & System (4/4)
- [x] `ssl` - SSL certificate management (setup/generate/verify/cleanup)
- [x] `setup` - System setup wizard (dns/proxy/init/config/ports)
- [x] `update` - Update management (check/install/changelog)
- [x] `reset` - Docker environment reset (soft/hard/status)

### Advanced Create Wizard (Enhanced)
- [x] **Interactive project creation wizard** con 8 step configurabili
- [x] **Visual progress bar** con indicatori per step (✓ completato, ▶ corrente, ○ futuro)
- [x] **Previous answers display** - mostra ultime 2 risposte durante la navigazione
- [x] **Automatic review mode** - entra in review dopo l'ultimo step
- [x] Navigazione avanzata (Tab/Shift+Tab, Ctrl+R review)
- [x] Validazione real-time con feedback visivo
- [x] Conversione automatica risposte → argomenti bash command
- [x] Esecuzione comando create e output nella TUI

### System Setup Wizard (NEW!)
- [x] **Interactive setup init wizard** con 4 step configurabili:
  1. Projects Directory (custom paths support)
  2. DNS Configuration (dnsmasq for *.test domains)
  3. Reverse Proxy (nginx)
  4. MailPit Email Catcher (conditional on proxy)
- [x] **All-or-Nothing Execution** - atomic setup, no partial states
- [x] **Pre-flight Checks** prima di modifiche:
  - Docker running check
  - Docker Compose check
  - Eseguiti NEL TUI prima di suspend
- [x] **Suspend-Resume Pattern** ⭐ - TUI si sospende per esecuzione bash:
  - Wizard raccoglie configurazione (4 step)
  - Review → conferma utente
  - Pre-flight checks IN TUI
  - **TUI SUSPENDS** → terminale pulito
  - Bash script esegue con pieno controllo terminale
  - **Sudo prompt VISIBILE e chiaro**
  - TUI riprende al completamento
- [x] **Just-in-Time Sudo** - password requested solo dopo review
- [x] **Secure sudo handling** - no password in memory, system prompt
- [x] **Clean UX** - no bash output corrupting TUI, no invisible prompts
- [x] Step condizionali (MailPit skip se proxy=no)
- [x] Review mode con warning pre-flight
- [x] Clear error messages e abort su qualsiasi fallimento
- [x] Visual progress bar e previous answers display

### Integrazione Bash/TUI
- [x] No args → TUI mode (`./phpharbor`)
- [x] With args → CLI mode (`./phpharbor list`)
- [x] Suspend-resume per comandi interattivi
- [x] Modal di conferma prima di uscire dalla TUI
- [x] Overlay centrato senza shift verticale

### Bug Fix
- [x] Path resolution per progetti (2 bugs)
- [x] Modal scroll causing logo cutoff
- [x] Terminal detection issues (risolto con suspend-resume)
- [x] Modal overlay vertical alignment
- [x] Setup wizard sudo prompt invisibility (fix con suspend-resume pattern)

## ⚠️ Known Issues / TODO

### Setup Init Script Enhancement
**Status:** Posticipato  
**Issue:** Lo script bash `cli/setup.sh` (funzione `setup_init()`) attualmente ripropone le domande anche se il wizard Go ha già raccolto la configurazione tramite variabili d'ambiente.

**Variabili d'ambiente passate dal wizard:**
```bash
PHPHARBOR_PROJECTS_DIR=<path>     # Directory progetti
PHPHARBOR_SETUP_DNS=1             # Se abilitare DNS (assente = no)
PHPHARBOR_SETUP_PROXY=1           # Se abilitare proxy (assente = no)
PHPHARBOR_SETUP_MAILPIT=1         # Se abilitare MailPit (assente = no)
```

**Soluzione richiesta:**
Modificare `cli/setup.sh` → `setup_init()` per:
1. Controllare se le variabili d'ambiente sono settate
2. Se presenti → usare quelle (modalità non-interattiva)
3. Se assenti → fare domande interattive (backward compatibility)

**Esempio logica:**
```bash
# Invece di ask sempre:
read -p "Configure dnsmasq for *.test? [y/N]" -n 1 -r

# Fare:
if [ -n "$PHPHARBOR_SETUP_DNS" ]; then
    # Usa valore da wizard
    setup_dns
else
    # Chiedi all'utente
    read -p "Configure dnsmasq for *.test? [y/N]" -n 1 -r
    [[ $REPLY =~ ^[Yy]$ ]] && setup_dns
fi
```

**Priorità:** Media (wizard funziona già, ma ripete domande)

## 🚧 Prossimi Step

### Fase 5: Testing & Polish (0/5)
- [ ] Test completo tutti i comandi
- [ ] Test su diversi terminali
- [ ] Update README.md
- [ ] Merge in develop
- [ ] Release notes

## 📊 Metriche

- **Commits:** 25+ (da develop)
- **Files changed:** 5 main files (tui.go, create_wizard.go, setup_wizard.go, wizard_shared.go, main.go)
- **Lines of Go code:** ~2,650
- **Binary size:** ~5.0 MB
- **Commands implemented:** 19/19 ✅ (100% CORE COMMANDS)
- **Wizards:** 2 (create + setup init, 12 total steps)
- **Interactive commands with suspend-resume:** 8 (shell, mysql, artisan, composer, npm, queue, create wizard, setup wizard)

## 🔧 Setup dall'Altro PC

```bash
# 1. Pull del branch
git checkout feature/go-tui-production
git pull origin feature/go-tui-production

# 2. Build
cd tui && go build -o phpharbor .

# 3. Test rapido
cd .. && ./tui/phpharbor
```

## 📝 Note Tecniche Importanti

### Pattern Comandi Interattivi
I comandi marcati con ⭐ usano questo pattern:

```go
// In handleCommand()
case "shell", "mysql":
    m.waitingForInteractiveConfirm = true
    m.pendingInteractiveCommand = command
    m.pendingInteractiveArgs = args
    m.view = viewInteractiveConfirm
    return m, nil
```

### Modal Overlay (lipgloss.Place)
```go
// Early return in View() per evitare logo cutoff
if m.view == viewInteractiveConfirm {
    modal := m.renderInteractiveConfirmModal()
    return lipgloss.Place(m.width, m.height, Center, Center, modal, ...)
}
```

### calculateMaxScroll Fix
```go
// Ritorna 0 per modal (non scrollabile)
if m.view == viewInteractiveConfirm {
    return 0
}
```

### Setup Wizard Suspend-Resume Pattern
Il setup wizard usa il pattern suspend-resume per esecuzione bash pulita:

```go
// In tui.go - Wizard completion handler
if wm.WasCompleted() {
    // 1. Pre-flight checks IN TUI (Docker, Docker Compose)
    preflightOutput, err := wm.ExecuteSetup()
    if err != nil {
        // Abort on failure, show error, return to home
        return m, nil
    }
    
    // 2. Build command with env vars from wizard answers
    cmd := wm.BuildSetupCommand()
    
    // 3. Suspend TUI and execute bash with full terminal control
    return m, tea.ExecProcess(cmd, func(err error) tea.Msg {
        return setupWizardFinishedMsg{err: err}
    })
}

// In setup_wizard.go - Build command
func (m setupWizardModel) BuildSetupCommand() *exec.Cmd {
    cmd := exec.Command("bash", bashScriptPath, "setup", "init")
    
    // CRITICAL: Direct terminal I/O for sudo prompts
    cmd.Stdin = os.Stdin
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr
    
    // Pass wizard answers via environment variables
    env := os.Environ()
    if dir, ok := m.answers["projects_dir"]; ok {
        env = append(env, fmt.Sprintf("PHPHARBOR_PROJECTS_DIR=%s", dir))
    }
    if dns, ok := m.answers["dns_enable"]; ok && dns == "yes" {
        env = append(env, "PHPHARBOR_SETUP_DNS=1")
    }
    // ... other env vars
    cmd.Env = env
    
    return cmd
}
```

**Flusso completo:**
1. Wizard raccoglie configurazione (4 step)
2. Review → utente conferma
3. Pre-flight checks eseguiti NEL TUI (Docker, Docker Compose)
4. Se checks falliscono → ABORT, mostra errore, torna a home
5. **TUI SI SOSPENDE** (schermo pulito, terminale libero)
6. Bash script esegue con pieno controllo del terminale
7. Sudo prompt è **VISIBILE e CHIARO** (no TUI in background)
8. Output bash è **LEGGIBILE** (no corruzione visuale)
9. **TUI RIPRENDE** al completamento, mostra risultato

**Vantaggi:**
- ✅ Sudo prompt perfettamente visibile
- ✅ Nessuna corruzione del TUI da output bash
- ✅ Errori mostrati chiaramente nel terminale
- ✅ UX pulita e professionale
- ✅ Stesso pattern di shell/mysql/altri comandi interattivi

### Advanced Create Wizard Architecture
Il wizard create è stato potenziato con 8 step configurabili:

```go
// Struttura wizard step
type wizardStep struct {
    id          string                 // Identificatore unico
    title       string                 // Titolo visualizzato
    description string                 // Descrizione del campo
    input       textinput.Model        // Input utente
    options     []string               // Opzioni disponibili
    validate    func(string) error     // Funzione di validazione
}

// Build command arguments da risposte wizard
func (m createWizardModel) BuildCreateCommand() []string {
    args := []string{}
    // Logica condizionale basata su risposte:
    // - Skip Node.js se non Laravel
    // - Skip PHP version se HTML
    // - Database version solo se dedicated
    // - Costruisce --type, --php, --node, --mysql/--mariadb, --redis, --ssl
    return args
}
```

**Features wizard:**
- Navigazione Tab/Shift+Tab tra step
- Review mode (Ctrl+R) per rivedere risposte
- Validazione real-time con feedback visivo ✓/✗
- Display opzioni disponibili per ogni campo
- Esecuzione automatica comando create al completamento

## 🎯 Prossima Sessione

**Fase 4 completata!** ✅ **TUTTI I COMANDI CORE IMPLEMENTATI!** 🎉

**Fase 5: Testing & Polish** è l'ultima fase prima del merge:
- Test completo di tutti i comandi in scenari reali
- Test su diversi terminali (iTerm2, Terminal.app, Alacritty, etc.)
- Verifica compatibilità cross-platform
- Update della documentazione (README.md, docs/)
- Preparazione per il merge in develop
- Release notes per il changelog

Stima tempo: 1-2 ore per testing completo e documentazione.
