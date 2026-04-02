# TUI Features Demo

## 🎯 Nuove Funzionalità Implementate

### 1. Wizard Interattivo Multi-Step

Un wizard completo per la creazione di progetti con:
- ✅ Navigazione avanti/indietro tra i passi
- ✅ Validazione in tempo reale
- ✅ Possibilità di modificare risposte precedenti
- ✅ Riepilogo finale

**Come usarlo:**
```bash
./phpharbor wizard
```

**Caratteristiche:**
- **Step 1**: Nome progetto (validato: minimo 3 caratteri, solo lowercase/numeri/trattini)
- **Step 2**: Tipo progetto (laravel/wordpress/php/html)
- **Step 3**: Versione PHP (8.5, 8.4, 8.3, 8.2, 8.1, 7.4)
- **Step 4**: Dominio personalizzato (opzionale)

**Controlli:**
- `Enter` - Conferma risposta e vai al passo successivo
- `↑` o `Shift+Tab` - Torna al passo precedente
- `↓` o `Tab` - Vai al passo successivo (se già risposto)
- `Esc` - Annulla wizard

### 2. Tabella Statistics (come ./phpharbor stats disk)

Visualizzazione tabellare delle statistiche di sistema.

**Come usarlo:**
```bash
./phpharbor stats-table
```

**Mostra:**
- Componenti del sistema (nginx-proxy, php-shared, mysql, redis, mailpit)
- Tipo (System, Shared Service, Project, Volume)
- Dimensione di ogni componente
- Status (running/stopped)
- Numero di container

**Esempio output:**
```
📊 PHPHarbor Disk Usage Statistics
────────────────────────────────────────────────
COMPONENT        TYPE             SIZE     STATUS    CONTAINERS
nginx-proxy      System           142 MB   running   1
php-8.5-shared   Shared Service   523 MB   running   1
mysql-8.0-shared Shared Service   456 MB   running   1
laravel-1        Project          12 MB    running   2
volumes/mysql    Volume           2.3 GB   -         -
────────────────────────────────────────────────
Total entries: 10
```

### 3. Tabella Projects

Lista completa dei progetti in formato tabella.

**Come usarlo:**
```bash
./phpharbor projects-table
```

**Mostra:**
- Nome progetto
- Tipo (Laravel, WordPress, PHP, HTML)
- Versione PHP
- Status (running/stopped)
- Dominio configurato
- Container attivi (es. 2/2)

**Esempio output:**
```
📦 PHPHarbor Projects
────────────────────────────────────────────────────────────
NAME              TYPE       PHP VERSION  STATUS    DOMAIN                 CONTAINERS
laravel-1         Laravel    8.5          running   laravel-1.test         2/2
laravel-2         Laravel    8.3          stopped   laravel-2.test         0/2
wordpress-site    WordPress  8.2          running   wordpress-site.test    2/2
────────────────────────────────────────────────────────────
Total entries: 5
```

### 4. System Overview

Riepilogo generale del sistema con sezioni organizzate.

**Come usarlo:**
```bash
./phpharbor stats-overview
```

**Mostra:**
- 🐳 Docker Resources (images, containers, volumes, networks)
- 💾 Disk Usage (per categoria e totale)
- 📦 PHPHarbor Projects (totali, running, stopped, shared services)

**Esempio output:**
```
📊 PHPHarbor System Overview

🐳 Docker Resources
  Total Images:              23
  Total Containers:          15 (8 running)
  Total Volumes:             12
  Networks:                  3

💾 Disk Usage
  Images:                    3.2 GB
  Containers:                124 MB
  Volumes:                   4.8 GB
  Build Cache:               890 MB
  Total:                     9.0 GB

📦 PHPHarbor Projects
  Total Projects:            5
  Running:                   3
  Stopped:                   2
  Shared Services:           4 running
```

## 🎨 Caratteristiche UI/UX

### Navigazione nel Wizard
- **Validazione in tempo reale**: Vedi subito se l'input è valido (✓ Valid / ✗ Error)
- **Indicatore di progresso**: "Step 1 of 4" sempre visibile
- **Modifica risposte precedenti**: Puoi tornare indietro e cambiare una risposta
- **Opzioni disponibili**: Per campi con scelta multipla, vedi tutte le opzioni disponibili
- **Help text**: Istruzioni sempre visibili in basso

### Tabelle
- **Auto-sizing**: Le colonne si adattano automaticamente al contenuto
- **Alternate row colors**: Righe alternate per migliore leggibilità
- **Bordi eleganti**: Separatori orizzontali con stile Unicode
- **Summary**: Conteggio totale elementi in basso
- **Help**: Tasti disponibili sempre visibili

### Colori e Stili
- **Cyan (#00d4ff)**: Titoli e elementi attivi
- **Purple (#874BFD)**: Bordi e decorazioni
- **Red (#FF0000)**: Errori
- **Green (#00FF00)**: Successo
- **Gray (#888888)**: Help text

## 🧪 Test Rapidi

### Test Wizard
```bash
cd /Users/vincenzo/php-harbor/cli-go
./phpharbor wizard
```

1. Digita `test-proj` per il nome
2. Premi `Enter` (dovrebbe mostrare ✓ Valid)
3. Digita `laravel` per il tipo
4. Premi `Shift+Tab` per tornare al nome
5. Modifica il nome in `my-app`
6. Completa il wizard

### Test Tabelle
```bash
# Stats disk table
./phpharbor stats-table

# Projects table
./phpharbor projects-table

# System overview
./phpharbor stats-overview
```

Premi `q` o `Esc` per uscire da qualsiasi tabella.

## 📝 Note Implementative

### Struttura File
- `wizard.go` - Wizard multi-step con validazione
- `table.go` - Rendering tabelle e overview
- `tui.go` - TUI principale (già esistente)
- `main.go` - Integrazione comandi cobra

### Componenti Bubble Tea Usati
- `textinput.Model` - Input utente
- `tea.Model` interface - Pattern MVC
- `tea.Cmd` - Comandi asincroni
- `lipgloss` - Styling avanzato

### Extensibility
Il sistema è facilmente estendibile:
- Aggiungi nuovi step al wizard modificando `newCreateProjectWizard()`
- Crea nuove tabelle con `tableModel` e dati personalizzati
- Aggiungi validazioni custom nella funzione `validate`

## 🚀 Prossimi Passi

1. **Integrazione con Docker API**: Collegare i comandi a operazioni Docker reali
2. **Live refresh**: Aggiornare tabelle in tempo reale con ticker
3. **Filtri e ricerca**: Permettere filtro e ricerca nelle tabelle
4. **Esportazione**: Salvataggio configurazioni wizard in file
5. **Temi**: Supporto per temi di colore personalizzati
