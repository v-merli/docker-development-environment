# Scrolling Feature Implementation - Wizard

## Overview

Implementazione del sistema di scrolling verticale per il wizard del TUI quando il contenuto supera lo spazio disponibile.

## Problema Risolto

Quando il wizard entra in **Review Mode** (Ctrl+R) o mostra il **Final Summary**, il contenuto può essere più alto dell'area visibile, rendendo impossibile vedere tutte le informazioni.

## Soluzione Implementata

### 1. Deteczione Stato Scrollable

Aggiunto metodo nel wizard per identificare quando lo scrolling è necessario:

```go
// IsScrollable returns true if the wizard is in a state where content might need scrolling
func (m advancedWizardModel) IsScrollable() bool {
    return m.reviewMode || m.completed
}
```

### 2. Intercettazione Tasti a Livello TUI

Il TUI intercetta i tasti di scrolling **solo** quando il wizard è in modalità scrollable:

```go
if m.wizard.IsScrollable() {
    switch keyMsg.String() {
    case "pgup", "K":
        m.scrollOffset -= 10  // Scroll up
    case "pgdown", "J":
        m.scrollOffset += 10  // Scroll down
    case "k":
        m.scrollOffset--      // Scroll up 1 line
    case "j":
        m.scrollOffset++      // Scroll down 1 line
    case "home", "g":
        m.scrollOffset = 0    // Go to top
    case "end", "G":
        m.scrollOffset = m.maxScroll  // Go to bottom
    }
}
```

### 3. Indicatore Visivo

Quando il contenuto è scrollable, viene mostrato un indicatore:

```go
if totalLines > visibleLines && m.wizard.IsScrollable() {
    scrollInfo := fmt.Sprintf("\n\n%s Scroll: %d-%d of %d lines (PgUp/PgDn or j/k)",
        newHintStyle.Render("↕"),
        startLine+1,
        endLine,
        totalLines)
    visibleContent += scrollInfo
}
```

**Esempio output:**
```
↕ Scroll: 11-30 of 45 lines (PgUp/PgDn or j/k)
```

### 4. Help Text Aggiornati

Gli help text del wizard ora includono riferimenti allo scrolling:

- **Review Mode**: "Enter: Confirm & Create | Esc: Go Back & Edit | PgUp/PgDn: Scroll"
- **Final Summary**: "Press ESC to return to home (PgUp/PgDn to scroll)"

## Comandi di Scrolling

| Tasto | Azione | Note |
|-------|--------|------|
| **Page Up** | Scorri su 10 righe | Scrolling veloce |
| **Page Down** | Scorri giù 10 righe | Scrolling veloce |
| **j** | Scorri giù 1 riga | Stile Vim |
| **k** | Scorri su 1 riga | Stile Vim |
| **J** (Shift+j) | Come Page Down | Alternativa |
| **K** (Shift+k) | Come Page Up | Alternativa |
| **Home** o **g** | Vai all'inizio | Quick navigation |
| **End** o **G** | Vai alla fine | Quick navigation |

## Quando è Attivo

Lo scrolling è disponibile SOLO in queste modalità del wizard:

1. **Review Mode** (attivata con Ctrl+R)
   - Mostra tutte le domande e risposte
   - Permette di rivedere la configurazione completa

2. **Final Summary** (dopo conferma)
   - Mostra riepilogo configurazione
   - Mostra docker-compose.yml generato
   - Mostra next steps

## Perché Non Nelle Altre Modalità?

Durante la **navigazione normale** tra gli step:
- Le frecce ↑/↓ sono usate per navigare tra domande
- Il contenuto di un singolo step è generalmente breve
- Non c'è conflitto di tasti

Questo design evita conflitti e mantiene l'usabilità ottimale.

## File Modificati

### `/advanced_wizard.go`
- ✅ Aggiunto `IsScrollable()` method
- ✅ Aggiunto `IsReviewMode()` method  
- ✅ Aggiunto `IsCompleted()` method
- ✅ Aggiornati help text in `renderReviewForTUI()`
- ✅ Aggiornati help text in `renderFinalSummaryForTUI()`

### `/tui.go`
- ✅ Intercettazione tasti scrolling quando `wizard.IsScrollable()`
- ✅ Aggiornamento `maxScroll` quando wizard cambia stato
- ✅ Reset `scrollOffset` quando wizard completa/cancella
- ✅ Indicatore visivo di scroll in `renderContent()` per viewServiceWizard
- ✅ Calcolo corretto delle righe visibili

## Benefici

1. **✅ Non perdere informazioni** - Tutto il contenuto è accessibile
2. **✅ Navigazione intuitiva** - Comandi standard (PgUp/PgDn) + Vim-style (j/k)
3. **✅ Feedback visivo** - Indicatore mostra posizione e comandi
4. **✅ Nessun conflitto** - Scrolling solo quando appropriato
5. **✅ Esperienza fluida** - Integrato nel flusso naturale del wizard

## Testing

```bash
# Compila
go build -o phpharbor

# Avvia TUI
./phpharbor tui

# Nel TUI:
/service

# Compila 8 domande, poi:
Ctrl+R         # Entra in review mode

# Prova scrolling:
Page Down      # Scorri giù
j              # Scorri giù 1 riga
k              # Scorri su 1 riga
Page Up        # Scorri su
Home           # Vai all'inizio
End            # Vai alla fine

# Completa wizard:
Enter          # Conferma

# Nella summary finale:
Page Down      # Scorri per vedere docker-compose.yml completo
```

## Edge Cases Gestiti

✅ **Contenuto più corto dello schermo** - Nessun indicatore, nessun scrolling
✅ **Scroll oltre il limite** - Clamping a maxScroll
✅ **Scroll sotto zero** - Clamping a 0
✅ **Resize finestra** - Ricalcolo automatico maxScroll
✅ **Cambio stato wizard** - Reset scroll appropriato
✅ **Contenuto dinamico** - Calcolo real-time delle righe

## Metriche

- **Complessità aggiunta**: Bassa (~50 righe di codice)
- **Performance impact**: Trascurabile (calcolo semplice)
- **User experience**: Significativamente migliorata
- **Manutenibilità**: Alta (logica ben separata)

---

**Status**: ✅ Implementato e testato
**Data**: 3 aprile 2026
**Versione**: CLI-Go v0.1.0-experimental
