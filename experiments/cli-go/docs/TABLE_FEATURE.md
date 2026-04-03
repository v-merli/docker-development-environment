# Tabelle Lipgloss nel TUI

## Panoramica

Il comando `/table` dimostra l'uso delle **tabelle lipgloss** per visualizzare dati in formato tabellare elegante all'interno del TUI di PHPHarbor.

## Come Accedere

Nel TUI, digita:
```
/table
```

oppure

```
/data
```

## Caratteristiche della Tabella

### 🎨 Styling Avanzato

- **Header colorato**: Sfondo viola (#874BFD) con testo bianco in grassetto
- **Righe alternate**: Sfondo grigio scuro (#1a1a1a) per migliorare la leggibilità
- **Colori semantici**: 
  - 🟢 Verde (#00FF88) per stati attivi e JIT abilitato
  - 🔵 Blu (#00AAFF) per versioni in security-only
  - 🟠 Arancione (#FFAA00) per versioni beta/dev
  - 🔴 Rosso (#FF4444) per versioni EOL/legacy
  - ⚫ Grigio (#666666) per funzionalità mancanti

### 📊 Contenuto Mock

La tabella mostra le versioni PHP disponibili con:
- **Version**: Numero versione (PHP 7.3 - 8.5)
- **Status**: Stato del supporto (Active, Security, EOL, Beta, Dev)
- **JIT**: Supporto JIT compiler (Yes/No)
- **Performance**: Valutazione prestazioni (⭐ 1-5+)
- **Common Use**: Caso d'uso tipico

### 🏗️ Implementazione Tecnica

#### Stili Principali

```go
headerCellStyle := lipgloss.NewStyle().
    Bold(true).
    Foreground(lipgloss.Color("#FFFFFF")).
    Background(lipgloss.Color("#874BFD")).
    Padding(0, 2).
    Align(lipgloss.Center)

altRowStyle := lipgloss.NewStyle().
    Background(lipgloss.Color("#1a1a1a")).
    Padding(0, 2)
```

#### Costruzione della Tabella

1. **Definizione colonne**: Larghezze fisse per ogni colonna
2. **Header row**: Creata con `lipgloss.JoinHorizontal`
3. **Data rows**: Iterate e stilizzate con colori condizionali
4. **Assemblaggio**: `lipgloss.JoinVertical` per unire tutte le righe
5. **Bordo finale**: `lipgloss.RoundedBorder()` con colore personalizzato

```go
// Header
headerRow := lipgloss.JoinHorizontal(lipgloss.Top,
    headerCellStyle.Width(colVersion).Render("Version"),
    headerCellStyle.Width(colStatus).Render("Status"),
    // ... altre colonne
)

// Tutte le righe unite verticalmente
table := lipgloss.JoinVertical(lipgloss.Left, rows...)

// Aggiunta bordo
tableStyle := lipgloss.NewStyle().
    Border(lipgloss.RoundedBorder()).
    BorderForeground(lipgloss.Color("#874BFD")).
    Padding(1, 2)
```

### 🔄 Scrolling

Come per tutte le altre view del TUI:
- **↑/↓**: Scorri su/giù di 1 riga
- **Fn+↑/Fn+↓** (Mac): Scroll più veloce
- **ESC**: Torna indietro

## Estensibilità

Questa implementazione può essere facilmente estesa per mostrare:
- Container attivi con statistiche (CPU, memoria, stato)
- Progetti con dettagli (PHP version, porta, status)
- Servizi custom configurati
- Log di sistema con timestamp
- Qualsiasi dato strutturato che beneficia dalla visualizzazione tabellare

## Vantaggi Rispetto a stringhe.Builder

### ❌ Approccio Tradizionale (strings.Builder)
```go
b.WriteString(fmt.Sprintf("  %-10s  %-12s  %-8s\n", "PHP 8.3", "Active", "Yes"))
```

**Svantaggi**:
- Allineamento manuale difficile
- Nessun colore semantico automatico
- Calcolo larghezze complesso
- Difficile manutenzione

### ✅ Approccio Lipgloss
```go
row := lipgloss.JoinHorizontal(lipgloss.Top,
    cellStyle.Width(10).Render("PHP 8.3"),
    statusStyle.Width(12).Render("Active"),
    jitStyle.Width(8).Render("Yes"),
)
```

**Vantaggi**:
- ✨ Allineamento automatico perfetto
- 🎨 Styling dichiarativo e componibile
- 📏 Gestione larghezze semplificata
- 🔧 Facile da mantenere e estendere
- 🌈 Colori e stili per cella/riga

## Note di Implementazione

- **Colonne fisse**: Le larghezze sono hardcoded per semplicità. Per dati dinamici si può calcolare la larghezza massima.
- **Dati mock**: I dati PHP sono hardcoded. In produzione verrebbero da Docker/filesystem.
- **Performance**: Per tabelle molto lunghe (100+ righe), considera la virtualizzazione o il lazy loading.

## Comandi Correlati

- `/list` - Lista progetti (formato lista semplice)
- `/stats` - Statistiche sistema (formato chiave-valore)
- `/service` - Wizard servizi (form interattivo)
- `/table` - **Dati tabulari (tabella lipgloss)** ← Nuovo!
