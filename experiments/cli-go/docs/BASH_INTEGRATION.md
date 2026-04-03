# Integrazione Bash Scripts nel TUI

## Panoramica

Il TUI Go è ora integrato come wrapper intelligente degli script bash esistenti, permettendo di:
- Lanciare il TUI con `./phpharbor` (senza argomenti)
- Usare i comandi CLI normali con `./phpharbor create`, `./phpharbor list`, ecc.
- Eseguire gli script bash DAL TUI e vederne l'output

## Architettura

### 1. main.go - Router

```go
func main() {
    if len(os.Args) == 1 {
        // Nessun argomento → TUI
        RunTUI()
    } else {
        // Argomenti presenti → CLI normale (Cobra)
        rootCmd.Execute()
    }
}
```

### 2. TUI - Bash Executor

#### Funzione `executeBashScript()`
Esegue uno script bash e cattura l'output:
- Risolve il path relativo agli script in `cli/`
- Esegue con `bash` e passa gli argomenti
- Cattura stdout + stderr combinati
- Ritorna output come stringa

#### Funzione `executeBashCommand()`
Wrapper TUI-friendly che:
- Mappa comandi a script (`list` → `cli/project.sh list`)
- Mostra stato "executing..." mentre lo script gira
- Cattura e mostra output nella view dedicata
- Gestisce errori

### 3. Nuova View: viewCommandOutput

Mostra l'output dei comandi eseguiti con:
- Header con nome comando
- Output completo (con scrollbar se lungo)
- Indicatore successo/errore
- Suggerimento per tornare indietro

## Comandi Supportati

### Comandi Bash (eseguiti tramite script)
- `/list` → `cli/project.sh list`
- `/create <nome>` → `cli/create.sh <nome>`
- `/start <nome>` → `cli/project.sh start <nome>`
- `/stop <nome>` → `cli/project.sh stop <nome>`
- `/update` → `cli/update.sh`
- `/reset` → `cli/reset.sh`
- `/setup` → `cli/setup.sh`

### Comandi TUI Interni
- `/stats` - View statistiche (mock)
- `/table` - View tabella PHP versions
- `/service` - Wizard configurazione servizi
- `/test` - Test output lungo
- `/home` - Torna alla home
- `/help` - Mostra help
- `/quit` - Esce

## Mapping Script

```go
scriptMap := map[string]string{
    "list":    "cli/project.sh",
    "create":  "cli/create.sh",
    "start":   "cli/project.sh",  // con "start" come primo arg
    "stop":    "cli/project.sh",   // con "stop" come primo arg
    "stats":   "cli/stats.sh",
    "update":  "cli/update.sh",
    "reset":   "cli/reset.sh",
    "setup":   "cli/setup.sh",
}
```

## Path Resolution

Gli script sono cercati relativamente al binario Go:
```
experiments/cli-go/phpharbor  (binario)
    ↓
../cli/project.sh  (script)
```

Il comando viene eseguito dalla root del progetto per accedere correttamente a tutti i path.

## Esperienza Utente

### Lanciare il TUI
```bash
./phpharbor
# Si apre l'interfaccia grafica
```

### Eseguire comando dal TUI
```
┌──────────────────────────────────────┐
│ /list                             [▰]│ ← Digita comando
└──────────────────────────────────────┘

Diventa:

┌──────────────────────────────────────┐
│ 📟 Command Output                    │
├──────────────────────────────────────┤
│ $ list                               │
│                                      │
│ Available projects:                  │
│ • laravel-1 (running)                │
│ • laravel-2 (stopped)                │
│                                      │
│ Press ESC to return               [▰]│
└──────────────────────────────────────┘
```

### Usare CLI classica
```bash
./phpharbor list
# Output diretto nel terminal
```

## Vantaggi dell'Approccio

1. **Zero duplicazione**: Scripts bash esistenti riutilizzati
2. **Graduale**: CLI e TUI coesistono
3. **Flessibile**: Facile aggiungere/rimuovere comandi
4. **Manutenibile**: Single source of truth per la logica
5. **Evolutivo**: Si può migrare a Go nativo nel tempo

## Prossimi Miglioramenti

### Output Streaming (TODO)
Per comandi lunghi, implementare output in real-time:
```go
cmd := exec.Command(...)
stdout, _ := cmd.StdoutPipe()
cmd.Start()

scanner := bufio.NewScanner(stdout)
for scanner.Scan() {
    // Aggiorna TUI con nuova linea
}
```

### Comandi Interattivi (TODO)
Gestire input utente durante esecuzione:
```go
cmd.Stdin = os.Stdin  // Passa stdin al processo
```

### Progress Indicators (TODO)
Spinner o progress bar per operazioni lunghe

### Command History (TODO)
Salvare storico comandi eseguiti

### Auto-completion (TODO)
Suggerimenti intelligenti basati su context
