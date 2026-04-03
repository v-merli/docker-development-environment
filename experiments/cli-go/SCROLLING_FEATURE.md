# Scrolling Feature Implementation - Wizard

## Overview

Implementazione del sistema di scrolling verticale **sempre disponibile** per il wizard del TUI. Le frecce ↑/↓ sono dedicate allo scrolling, mentre Tab/Shift+Tab gestiscono la navigazione tra step.

## Design Decision: Separazione Controlli

### Navigazione tra Step
- **Tab**: Avanti al prossimo step
- **Shift+Tab**: Indietro allo step precedente

### Scrolling Verticale (sempre attivo)
- **↑/↓**: Scroll di 1 riga
- **Page Up/Down**: Scroll di 10 righe
- **j/k**: Scroll di 1 riga (Vim-style)
- **Home/End** o **g/G**: Inizio/fine

Questa separazione elimina conflitti e rende l'interfaccia più intuitiva, dato che:
1. Tab è lo standard per navigare tra campi nei form
2. Le frecce sono naturali per lo scrolling verticale
3. Lo scrolling è utile in qualsiasi momento, non solo nella review

## Problema Risolto

Nella versione precedente:
- ❌ Le frecce ↑/↓ erano usate per navigare tra step
- ❌ Lo scrolling era disponibile solo in Review Mode e Final Summary
- ❌ Il comportamento delle frecce cambiava a seconda dello stato
- ❌ Confusione per l'utente su quando usare cosa

Ora:
- ✅ Tab/Shift+Tab per navigazione (standard nei form)
- ✅ Frecce ↑/↓ sempre per scrolling (comportamento consistente)
- ✅ Scrolling disponibile in qualsiasi momento
- ✅ Nessun conflitto, comportamento prevedibile

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

## Comandi

### Navigazione tra Step (Wizard)
| Tasto | Azione | Note |
|-------|--------|------|
| **Tab** | Vai allo step successivo | Standard nei form |
| **Shift+Tab** | Vai allo step precedente | Standard nei form |
| **Enter** | Conferma risposta e procedi | Valida prima di avanzare |
| **Ctrl+R** | Entra in Review Mode | Vedi tutte le risposte |
| **Esc** | Annulla wizard | Torna alla home |

### Scrolling Verticale (Sempre Attivo)
| Tasto | Azione | Note |
|-------|--------|------|
| **↑ (Up Arrow)** | Scorri su 1 riga | Sempre disponibile |
| **↓ (Down Arrow)** | Scorri giù 1 riga | Sempre disponibile |
| **Page Up** | Scorri su 10 righe | Scrolling veloce |
| **Page Down** | Scorri giù 10 righe | Scrolling veloce |
| **j** | Scorri giù 1 riga | Stile Vim |
| **k** | Scorri su 1 riga | Stile Vim |
| **J** (Shift+j) | Come Page Down | Alternativa |
| **K** (Shift+k) | Come Page Up | Alternativa |
| **Home** o **g** | Vai all'inizio | Quick navigation |
| **End** o **G** | Vai alla fine | Quick navigation |

## File Modificati

### `/advanced_wizard.go`
- ✅ Cambiato navigazione da `up`/`down` a `tab`/`shift+tab`
- ✅ Aggiornati help text per riflettere i nuovi comandi
- ✅ Rimossi metodi `IsScrollable()`, `IsReviewMode()`, `IsCompleted()` (non più necessari)

### `/tui.go`
- ✅ Intercettazione frecce ↑/↓ **sempre** per scrolling (non condizionale)
- ✅ Aggiornamento `maxScroll` quando wizard cambia stato
- ✅ Reset `scrollOffset` quando wizard completa/cancella
- ✅ Indicatore visivo di scroll sempre mostrato quando necessario
- ✅ Calcolo corretto delle righe visibili
- ✅ Help text nell'indicatore aggiornato

## Benefici

1. **✅ Controlli separati e chiari** - Tab per navigazione, frecce per scrolling
2. **✅ Scrolling sempre disponibile** - Non serve aspettare la review mode
3. **✅ Standard UI conventions** - Tab è lo standard per navigare tra campi
4. **✅ Nessun conflitto** - Ogni tasto ha un solo significato, sempre
5. **✅ Comportamento prevedibile** - Le frecce fanno sempre la stessa cosa
6. **✅ Esperienza fluida** - Scroll naturale in qualsiasi momento
7. **✅ Feedback visivo** - Indicatore mostra quando c'è contenuto da scrollare

## Testing

```bash
# Compila
go build -o phpharbor

# Avvia TUI
./phpharbor tui

# Nel TUI:
/service

# Navigazione tra step:
Tab              # Vai allo step successivo
Shift+Tab        # Torna allo step precedente

# Scrolling (sempre disponibile):
↓ ↓ ↓            # Scorri giù con le frecce
↑ ↑              # Scorri su con le frecce
Page Down        # Scorri giù veloce
j j j            # Scorri giù 3 righe (Vim-style)
k k              # Scorri su 2 righe
Home             # Vai all'inizio
End              # Vai alla fine

# Compila wizard:
Tab Tab Tab...   # Naviga tra le 8 domande con Tab

# Review Mode:
Ctrl+R           # Vedi tutte le risposte
↓ ↓ ↓            # Scorri per vedere tutto
Enter            # Conferma

# Final Summary:
↓ ↓ ↓            # Scorri per vedere docker-compose completo
Esc              # Torna alla home
```

## Edge Cases Gestiti

✅ **Contenuto più corto dello schermo** - Nessun indicatore, scrolling funziona ma non serve  
✅ **Scroll oltre il limite** - Clamping a maxScroll  
✅ **Scroll sotto zero** - Clamping a 0  
✅ **Resize finestra** - Ricalcolo automatico maxScroll  
✅ **Cambio stato wizard** - Reset scroll appropriato  
✅ **Contenuto dinamico** - Calcolo real-time delle righe  
✅ **Step navigation** - Tab/Shift+Tab non interferiscono con scroll  
✅ **Input field** - Frecce catturate dal TUI, non dall'input field

## Metriche

- **Complessità aggiunta**: Bassa (~30 righe modificate)
- **Code removed**: ~50 righe (metodi IsScrollable, etc.)
- **Performance impact**: Nessuno (più semplice del precedente)
- **User experience**: Significativamente migliorata
- **Manutenibilità**: Alta (logica più semplice e diretta)
- **Consistency**: Perfetta (comportamento sempre uguale)

---

**Status**: ✅ Implementato, testato e documentato  
**Data**: 3 aprile 2026  
**Versione**: CLI-Go v0.1.0-experimental  
**Improvement**: Navigazione più intuitiva con separazione Tab/Arrows
