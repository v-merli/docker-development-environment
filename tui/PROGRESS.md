# TUI Production - Progress Tracker

**Branch:** `feature/go-tui-production`  
**Status:** 20+ commits ahead of develop  
**Last Updated:** 2026-04-03 (Fase 3 completata)

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

## 🚧 Prossimi Step

### Fase 4: SSL & System (0/4)
- [ ] `ssl [project]` - SSL setup
- [ ] `setup` - Initial setup wizard
- [ ] `system prune` - Cleanup Docker resources
- [ ] `update` - Update php-harbor

### Fase 5: Testing & Release (0/5)
- [ ] Test completo tutti i comandi
- [ ] Test su diversi terminali
- [ ] Update README.md
- [ ] Merge in develop
- [ ] Release notes

## 📊 Metriche

- **Commits:** 20+ (da develop)
- **Files changed:** 3 main files (tui.go, main.go, phpharbor)
- **Lines of Go code:** ~1,800
- **Binary size:** 4.8 MB
- **Commands implemented:** 15/19

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

## 🎯 Prossima Sessione

**Fase 3 completata!** ✅

Iniziare con **Fase 4: SSL & System**. Questi comandi sono più complessi:
- `ssl` richiede interazione con certificati e configurazione nginx
- `setup` è un wizard interattivo per il setup iniziale
- `system prune` è più semplice (cleanup Docker)
- `update` gestisce gli aggiornamenti di php-harbor

Stima tempo: 45-60 minuti per completare Fase 4.
