# Setup Init - Parametri da Linea di Comando

Lo script `setup init` può essere eseguito in due modalità:

## Modalità Interattiva
La modalità classica che chiede all'utente tutte le opzioni tramite prompt:

```bash
./phpharbor setup init
```

## Modalità Non-Interattiva (per TUI)
Passando tutti i parametri come argomenti della linea di comando:

```bash
./phpharbor setup init \
  --projects-choice 1 \
  --dns y \
  --proxy y \
  --mailpit y
```

### Parametri Disponibili

| Parametro | Valori | Descrizione |
|-----------|--------|-------------|
| `--path` | `<path>` | Path directory progetti (es: `./projects`, `~/Development/docker-projects`) |
| `--dns` | `y`, `n` | Configurare dnsmasq per *.test |
| `--proxy` | `y`, `n` | Avviare reverse proxy |
| `--mailpit` | `y`, `n` | Installare MailPit email testing tool |

### Esempi

**Setup completo automatico:**
```bash
./phpharbor setup init --path ./projects --dns y --proxy y --mailpit y
```

**Setup minimo (solo directory progetti):**
```bash
./phpharbor setup init --path ./projects --dns n --proxy n
```

**Setup con path personalizzato:**
```bash
./phpharbor setup init \
  --path "$HOME/MyProjects" \
  --dns y \
  --proxy y \
  --mailpit n
```

## Uso dal TUI (Go)

Dal codice Go del TUI, lo script viene chiamato tramite la funzione `BuildSetupCommand()` in `tui/setup_wizard.go`:

```go
func (m setupWizardModel) BuildSetupCommand() *exec.Cmd {
    // Costruisce il comando con i parametri raccolti dal wizard
    args := []string{bashScriptPath, "setup", "init"}
    
    // Converti la scelta dell'utente in un path reale
    var projectsPath string
    switch dir {
    case "./projects":
        projectsPath = "./projects"
    case "~/Development/docker-projects":
        projectsPath = "~/Development/docker-projects"
    default:
        // Path personalizzato - espandi ~ se necessario
        projectsPath = expandedPath
    }
    
    // Aggiungi il path dei progetti
    args = append(args, "--path", projectsPath)
    
    // Aggiungi configurazioni DNS, proxy e mailpit
    args = append(args, "--dns", dnsChoice)
    args = append(args, "--proxy", proxyChoice)
    args = append(args, "--mailpit", mailpitChoice)
    
    cmd := exec.Command("bash", args...)
    cmd.Stdin = os.Stdin   // Permette prompt sudo interattivi
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr
    
    return cmd
}
```

### Vantaggi dell'Approccio con Parametri CLI

1. **Esplicito e Trasparente**: I parametri sono visibili nella linea di comando
2. **Debuggabile**: Facile vedere esattamente cosa viene eseguito
3. **Testabile**: Si può testare lo script manualmente con gli stessi parametri
4. **Compatibile**: Funziona sia da TUI che da linea di comando manuale
5. **Standard**: Usa convenzioni comuni degli script bash

## Note

- Se un parametro non viene fornito, lo script userà il comportamento interattivo per quel parametro
- Questo permette di mixare parametri e input interattivo se necessario
- La retrocompatibilità con l'uso completamente interattivo è mantenuta
