# PHPHarbor - Piano di Migrazione da Bash a Go/TUI

## Stato Attuale

✅ **Completato nella fase sperimentale:**
- TUI base con Bubble Tea
- Sistema di wizard interattivo multi-step
- Integrazione con comandi bash esistenti (wrapper)
- Scrolling verticale con scrollbar
- Tabelle con lipgloss
- Router CLI/TUI in main.go
- Sistema di navigazione e command bar

## Architettura Finale

```
experiments/cli-go/
├── main.go              # Entry point, router CLI/TUI, comandi Cobra
├── tui.go               # TUI principale con Bubble Tea
├── advanced_wizard.go   # Wizard per service configuration
├── wizard.go            # Wizard per project creation
├── table.go             # Tabelle con lipgloss
├── commands/            # [DA CREARE] Package per i comandi Go
│   ├── project.go       # list, start, stop, restart, remove, logs
│   ├── create.go        # create project
│   ├── system.go        # stats, info, cleanup
│   ├── shared.go        # shared services management
│   ├── dev.go           # shell, artisan, composer, npm, mysql
│   ├── services.go      # custom services management
│   ├── ssl.go           # SSL management
│   ├── setup.go         # setup dns/proxy/init
│   ├── reset.go         # reset soft/hard/status
│   ├── update.go        # update PHPHarbor
│   └── convert.go       # convert project type
├── pkg/                 # [DA CREARE] Package condivisi
│   ├── docker/          # Docker client wrapper
│   ├── config/          # Config management
│   ├── project/         # Project types & templates
│   └── ui/              # UI components riusabili
├── go.mod
├── go.sum
└── docs/                # Documentazione
    ├── README.md
    ├── TODOS.md
    ├── BASH_INTEGRATION.md
    ├── INTEGRATION_SUMMARY.md
    ├── SCROLLING_FEATURE.md
    ├── TABLE_FEATURE.md
    ├── TUI_FEATURES.md
    ├── WIZARD_GUIDE.md
    └── MIGRATION_PLAN.md (questo file)
```

---

## Piano di Porting: Fasi e Priorità

### 📋 Fase 1: Fondamenta (PRIORITÀ ALTA)
**Obiettivo:** Sostituire i wrapper bash con implementazioni Go native per i comandi core

#### 1.1 Project Management (`cli/project.sh`)
**Status:** In corso (attualmente wrapped)
**Comandi:**
- `list` - Lista progetti
- `start <project>` - Avvia progetto
- `stop <project>` - Ferma progetto
- `restart <project>` - Riavvia progetto
- `remove <project>` - Rimuove progetto
- `logs <project> [-f]` - Mostra logs

**Tasks:**
- [ ] Creare `commands/project.go`
- [ ] Implementare lettura directory `projects/`
- [ ] Leggere `.env` per metadata progetto
- [ ] Usare Docker SDK Go per status container
- [ ] Implementare `docker-compose up/down/restart`
- [ ] Implementare streaming logs con `docker logs -f`
- [ ] Integrare nel TUI con view dedicata
- [ ] Aggiornare `listCmd` in main.go per usare Go invece di bash

**Dipendenze:**
- Docker SDK: `github.com/docker/docker`
- YAML parser: `gopkg.in/yaml.v3`

#### 1.2 System Stats (`cli/stats.sh`, `cli/system.sh`)
**Status:** Non iniziato
**Comandi:**
- `stats` - Statistiche disco
- `info` - Info sistema
- `cleanup` - Pulizia docker

**Tasks:**
- [ ] Creare `commands/system.go`
- [ ] Implementare `docker system df` in Go
- [ ] Calcolare disk usage per progetti
- [ ] Implementare `docker system prune`
- [ ] Creare view TUI con tabella statistiche
- [ ] Integrare statsTableCmd esistente

**Dipendenze:**
- Docker SDK
- Sistema file stats: `os` package

---

### 🔧 Fase 2: Gestione Progetti (PRIORITÀ ALTA)

#### 2.1 Create Project (`cli/create.sh`)
**Status:** Wrapped, da convertire
**Funzionalità:**
- Wizard interattivo per tipo progetto
- Generazione `docker-compose.yml`
- Generazione `.env`
- Setup nginx config
- Inizializzazione progetto (Laravel, WordPress, etc.)

**Tasks:**
- [ ] Creare `commands/create.go`
- [ ] Convertire logica creazione in Go
- [ ] Usare template Go per generare file
- [ ] Implementare download/setup framework (Laravel, WP)
- [ ] Integrare wizard esistente `wizard.go`
- [ ] Rimuovere dipendenza da bash script

**Dipendenze:**
- Template: `text/template`
- HTTP client per download: `net/http`

#### 2.2 Development Tools (`cli/dev.sh`)
**Status:** Non iniziato
**Comandi:**
- `shell <project>` - Apri shell in container
- `artisan <project> <cmd>` - Esegui artisan
- `composer <project> <cmd>` - Esegui composer
- `npm <project> <cmd>` - Esegui npm
- `mysql <project>` - MySQL shell

**Tasks:**
- [ ] Creare `commands/dev.go`
- [ ] Implementare `docker exec -it` in Go
- [ ] Gestire input/output stream interattivi
- [ ] Creare view TUI per shell interattiva
- [ ] Passthrough stdin/stdout/stderr

**Dipendenze:**
- Docker SDK exec
- Terminal handling: `golang.org/x/term`

---

### 🔌 Fase 3: Servizi (PRIORITÀ MEDIA)

#### 3.1 Shared Services (`cli/shared.sh`)
**Status:** Non iniziato
**Comandi:**
- `shared start/stop/status/logs`
- `shared mysql` - MySQL shell
- `shared php <version>` - PHP shell

**Tasks:**
- [ ] Creare `commands/shared.go`
- [ ] Gestione servizi condivisi (MySQL, Redis, Mailpit)
- [ ] View TUI per status servizi
- [ ] Integrazione con proxy/dnsmasq

#### 3.2 Custom Services (`cli/services.sh`)
**Status:** Parziale (wizard esiste)
**Funzionalità:**
- Configurazione servizi custom (Redis, Elasticsearch, ecc.)
- Generazione docker-compose per servizi

**Tasks:**
- [ ] Creare `commands/services.go`
- [ ] Usare `advancedWizardModel` esistente
- [ ] Implementare generazione config servizi
- [ ] Integrare con progetti esistenti

---

### 🔐 Fase 4: Setup e Configurazione (PRIORITÀ MEDIA)

#### 4.1 Setup System (`cli/setup.sh`)
**Status:** Non iniziato
**Comandi:**
- `setup dns` - Setup dnsmasq
- `setup proxy` - Setup nginx proxy
- `setup init` - Inizializzazione completa

**Tasks:**
- [ ] Creare `commands/setup.go`
- [ ] Implementare check prerequisiti
- [ ] Setup dnsmasq con privilegi sudo
- [ ] Setup proxy nginx
- [ ] Wizard di prima configurazione

#### 4.2 SSL Management (`cli/ssl.sh`)
**Status:** Non iniziato
**Funzionalità:**
- Generazione CA
- Generazione certificati per progetti
- Trust CA nel sistema

**Tasks:**
- [ ] Creare `commands/ssl.go`
- [ ] Generazione certificati con Go crypto
- [ ] Trust CA (macOS Keychain, Linux ca-certificates)

**Dipendenze:**
- `crypto/x509`
- `crypto/rsa`

---

### ♻️ Fase 5: Manutenzione (PRIORITÀ BASSA)

#### 5.1 Reset System (`cli/reset.sh`)
**Status:** Non iniziato
**Comandi:**
- `reset soft` - Reset soft (mantiene volumi)
- `reset hard` - Reset completo
- `reset status` - Mostra cosa verrà rimosso

**Tasks:**
- [ ] Creare `commands/reset.go`
- [ ] Implementare cleanup Docker
- [ ] Wizard di conferma
- [ ] Dry-run mode

#### 5.2 Update PHPHarbor (`cli/update.sh`)
**Status:** Non iniziato
**Funzionalità:**
- Update da repository
- Backup prima dell'update

**Tasks:**
- [ ] Creare `commands/update.go`
- [ ] Implementare git pull/download release
- [ ] Backup automatico
- [ ] Migration automatica

#### 5.3 Convert Project (`cli/convert.sh`)
**Status:** Non iniziato
**Funzionalità:**
- Conversione tipo progetto (Laravel → WordPress, ecc.)

**Tasks:**
- [ ] Creare `commands/convert.go`
- [ ] Wizard conversione
- [ ] Backup progetto prima di convertire
- [ ] Re-generazione config

---

## Strategia di Migrazione

### Approccio Incrementale

1. **Wrapper iniziale** ✅ (COMPLETATO)
   - Tutti i comandi wrappano bash
   - Funziona subito, nessuna breaking change

2. **Sostituzione graduale** (IN CORSO)
   - Sostituire un comando alla volta
   - Testare ogni comando prima di passare al successivo
   - Mantenere bash come fallback temporaneo

3. **Refactoring** (FUTURO)
   - Estrarre logica comune in `pkg/`
   - Creare interfacce riusabili
   - Ottimizzare performance

### Ordine Consigliato

```
1. project.go     (list, start, stop)      ← Core functionality
2. system.go      (stats, info)            ← User-facing
3. create.go      (create project)         ← High value
4. dev.go         (shell, artisan)         ← Developer tools
5. shared.go      (shared services)        ← Infrastructure
6. services.go    (custom services)        ← Advanced
7. setup.go       (setup system)           ← One-time use
8. ssl.go         (SSL management)         ← One-time use
9. reset.go       (reset)                  ← Maintenance
10. update.go     (update PHPHarbor)       ← Maintenance
11. convert.go    (convert project)        ← Rarely used
```

---

## Metriche di Successo

### Obiettivi Misurabili

- **Performance:** Comandi Go devono essere ≥ velocità bash (o più veloci)
- **Codice:** Riduzione linee di codice totali del 30%
- **Manutenibilità:** Copertura test ≥ 70%
- **UX:** Zero breaking changes per l'utente
- **Binary size:** ≤ 15MB (attualmente ~6MB)

### Test Coverage

- [ ] Unit tests per ogni comando
- [ ] Integration tests per workflow completi
- [ ] E2E tests per TUI
- [ ] CI/CD pipeline

---

## Risorse e Dipendenze

### Librerie Go Necessarie

```go
// Core
github.com/spf13/cobra            // CLI framework ✅
github.com/charmbracelet/bubbletea // TUI ✅
github.com/charmbracelet/lipgloss  // Styling ✅

// Docker
github.com/docker/docker          // Docker SDK
github.com/docker/go-connections  // Docker connections

// File & Config
gopkg.in/yaml.v3                  // YAML parsing
github.com/spf13/viper            // Config management

// Templates
text/template                      // Go templates (stdlib)

// Crypto (SSL)
crypto/x509                        // Certificates (stdlib)
crypto/rsa                         // RSA keys (stdlib)

// Utility
github.com/fatih/color            // Colors ✅
github.com/AlecAivazis/survey/v2  // Prompts ✅
```

### Documentazione

- Docker SDK Go: https://docs.docker.com/engine/api/sdk/
- Bubble Tea: https://github.com/charmbracelet/bubbletea
- Cobra: https://github.com/spf13/cobra

---

## Timeline Stimata

### Sprint Breakdown (2-week sprints)

**Sprint 1-2:** Fase 1 (Fondamenta)
- project.go implementation
- system.go implementation
- Tests

**Sprint 3-4:** Fase 2 (Gestione Progetti)
- create.go implementation
- dev.go implementation
- Interactive shell handling

**Sprint 5:** Fase 3 (Servizi)
- shared.go implementation
- services.go integration

**Sprint 6:** Fase 4 (Setup)
- setup.go implementation
- ssl.go implementation

**Sprint 7:** Fase 5 (Manutenzione)
- reset.go, update.go, convert.go
- Final cleanup

**Sprint 8:** Testing & Release
- Integration tests
- Documentation
- Release v2.0.0-go

**Totale stimato:** 16 settimane (~4 mesi)

---

## Checklist Pre-Release

- [ ] Tutti i comandi bash sostituiti
- [ ] Test coverage ≥ 70%
- [ ] Documentazione completa
- [ ] Migration guide per utenti
- [ ] Backward compatibility verificata
- [ ] Performance benchmarks
- [ ] Release notes
- [ ] Binary per macOS/Linux/Windows

---

## Note di Implementazione

### Best Practices

1. **Errori:** Usare `fmt.Errorf` con wrapping
2. **Logging:** Implementare logger strutturato (zerolog?)
3. **Config:** Centralizzare in `pkg/config`
4. **Docker:** Riusare client Docker (singleton)
5. **Testing:** Mock Docker interactions
6. **TUI:** Separare business logic da UI rendering

### Anti-Patterns da Evitare

- ❌ Chiamare bash da Go (eccetto fase transitoria)
- ❌ Hardcode percorsi assoluti
- ❌ Ignorare errori
- ❌ Usare `os.Exit()` fuori da main
- ❌ Global state mutable

---

## Prossimi Step Immediati

1. ✅ Pulizia repository
2. ✅ Creazione docs/
3. ✅ Piano di migrazione
4. ⏭️ Creare branch `feat/go-rewrite`
5. ⏭️ Setup struttura `commands/` e `pkg/`
6. ⏭️ Implementare `commands/project.go` (primo comando)
7. ⏭️ Scrivere test per `project.list()`
8. ⏭️ Aggiornare main.go per usare Go invece di bash wrapper

---

**Versione:** 1.0  
**Data:** 3 Aprile 2026  
**Autore:** PHPHarbor Development Team  
**Status:** 📋 PIANIFICAZIONE
