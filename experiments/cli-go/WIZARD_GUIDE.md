# Advanced Service Wizard - Guida d'Uso

## Panoramica

Il wizard avanzato per la configurazione dei servizi è **completamente integrato graficamente** nel TUI di PHPHarbor. Mantiene il layout standard dell'applicazione (header, content area, command bar, status bar) mentre offre un'interfaccia interattiva con navigazione completa tra le domande.

## Integrazione Grafica

### Layout Consistente

Quando lanci il wizard, l'interfaccia mantiene:

```
╔════════════════════════════════════════════════╗
║  PHPHarbor Header (sempre visibile)           ║  ← Logo e versione
╠════════════════════════════════════════════════╣
║                                                ║
║  🔧 SERVICE CONFIGURATION WIZARD               ║
║  ✓ 1  ▶ 2  ○ 3  ○ 4 ...                       ║  ← Wizard content
║                                                ║
║  Step 2 of 8                                   ║
║  Previous answers: ...                         ║
║  [Current question and input field]            ║
║                                                ║
╠════════════════════════════════════════════════╣
║ ⊗ Command input disabled during wizard        ║  ← Command bar (disabilitata)
╠════════════════════════════════════════════════╣
║ 🔧 Service Configuration Wizard Active        ║  ← Status bar (wizard status)
╚════════════════════════════════════════════════╝
```

### Differenze con la Versione Precedente

#### ❌ Prima (Standalone)
- Il wizard sostituiva **tutta** l'interfaccia
- Nessun header/logo visibile
- Nessuna command bar
- Nessuna status bar
- Layout completamente diverso dal resto del TUI

#### ✅ Ora (Integrato)
- **Header sempre visibile** con logo PHPHarbor
- **Command bar presente** (ma disabilitata visivamente)
- **Status bar attiva** con messaggi del wizard
- **Layout consistente** con il resto dell'applicazione
- **Transizione fluida** tra viste

## Come Accedere al Wizard

### Opzione 1: Tramite il TUI
```bash
./phpharbor tui
```

Una volta nel TUI, digita:
```
/service
```
oppure
```
/wizard
```

### Caratteristiche Principali

#### ✨ Navigazione Completa
- **↑/Shift+Tab**: Torna alla domanda precedente
- **↓/Tab**: Vai alla domanda successiva (se valida)
- **Enter**: Conferma la risposta e vai avanti
- **Ctrl+R**: Attiva la modalità di revisione per vedere tutte le risposte
- **Esc**: Annulla e torna al menu principale

#### 📊 Indicatori di Progresso
- Barra di progresso visuale che mostra:
  - **✓** Domande completate (verde)
  - **▶** Domanda corrente (evidenziata)
  - **○** Domande future (grigio)

#### ✅ Validazione in Tempo Reale
- **✓ Valid**: Feedback immediato per risposte valide
- **✗ Error**: Messaggi di errore chiari quando la risposta non è valida
- Validazione automatica prima di procedere

#### 🔄 Modalità Revisione
Premi **Ctrl+R** in qualsiasi momento per:
- Vedere tutte le risposte date finora
- Confermare la configurazione finale
- Tornare indietro per modificare (premendo Esc)

## Domande del Wizard

Il wizard guida attraverso 8 passaggi per configurare un servizio personalizzato:

1. **Service Type** - Tipo di servizio (redis, elasticsearch, rabbitmq, postgres, mongodb)
2. **Service Name** - Nome univoco per l'istanza del servizio
3. **Version** - Versione da utilizzare
4. **External Port** - Porta per esporre il servizio (opzionale)
5. **Persistent Data** - Se persistere i dati (yes/no)
6. **Memory Limit** - Limite di memoria in MB (128-8192)
7. **Auto Start** - Avvio automatico con PHPHarbor (yes/no)
8. **Notes** - Note opzionali sul servizio

## Esempio di Utilizzo

```bash
# Avvia il TUI
./phpharbor tui

# Nel TUI, digita:
/service

# Rispondi alle domande:
Service Type: redis
Service Name: my-redis
Version: 7.2
External Port: 6379
Persistent Data: yes
Memory Limit: 512
Auto Start: yes
Notes: Redis cache per l'applicazione

# Premi Ctrl+R per rivedere tutto
# Premi Enter per confermare
```

## Output Generato

Al completamento, il wizard genera:
- **Riepilogo della configurazione**: Tutti i parametri configurati
- **Snippet docker-compose.yml**: Pronto per essere integrato nel setup
- **Istruzioni next steps**: Come procedere con l'integrazione

## Vantaggi Rispetto al Comando Standalone

### Prima (Standalone)
❌ Comando separato dal TUI
❌ Esperienza disgiunta
❌ Necessità di uscire e rientrare

### Ora (Integrato)
✅ Completamente integrato nel TUI
✅ Navigazione fluida tra le viste
✅ Ritorno automatico al menu principale
✅ Esperienza utente coerente
✅ Stessa interfaccia per tutto

## Caratteristiche Avanzate

### Navigazione tra Domande
Il wizard mantiene le risposte precedenti, quindi puoi:
- Tornare indietro con ↑
- Modificare una risposta
- Procedere di nuovo con ↓

### Suggerimenti Contestuali
Per le domande con opzioni predefinite, vengono mostrate:
- Lista delle opzioni disponibili
- Valori predefiniti
- Descrizioni dettagliate

### Feedback Visivo Chiaro
- **Bordi colorati**: Indicano lo stato (normale, errore, successo)
- **Icone emotive**: Facilitano la comprensione (✓, ✗, ▶)
- **Colori semantici**: Verde per successo, rosso per errori, blu per info

## Tips & Tricks

💡 **Risparmia tempo**: Usa Tab per navigare rapidamente se hai già compilato una risposta valida

💡 **Rivedi prima di confermare**: Premi Ctrl+R per vedere tutto prima di finalizzare

💡 **Correggi errori facilmente**: Torna indietro con ↑ invece di ricominciare da capo

💡 **Opzioni predefinite**: Molti campi hanno valori di default ragionevoli

## Integrazione nel Workflow

Il wizard si integra perfettamente nel workflow del TUI:

```
TUI Home → /service → Wizard → Configurazione → Ritorno Home
     ↑________________________________________________↓
```

Dalla home puoi:
- Vedere i progetti (`/list`)
- Vedere le statistiche (`/stats`)
- Configurare servizi (`/service`)
- Creare progetti (`/create`)

Tutto senza uscire dall'interfaccia!

## Prossimi Sviluppi

Possibili miglioramenti futuri:
- [ ] Salvataggio automatico delle configurazioni
- [ ] Template di servizi predefiniti
- [ ] Validazione con check reale su porte disponibili
- [ ] Preview del docker-compose.yml durante la configurazione
- [ ] Storia delle configurazioni precedenti
- [ ] Export diretto nel progetto selezionato

---

**Nota**: Questo wizard è parte dell'esperimento CLI-Go per PHPHarbor e dimostra come creare interfacce interattive sofisticate con navigazione completa e gestione dello stato.

## Implementazione Tecnica

### Architettura dell'Integrazione

Il wizard è integrato nel TUI attraverso un **sistema a doppio rendering**:

#### 1. Modalità Standalone (`View()`)
- Usata quando il wizard viene lanciato come comando separato
- Renderizza con border esterno e header colorato
- Layout completo e indipendente

#### 2. Modalità Integrata (`RenderForTUI()`)
- Usata quando il wizard è parte del TUI
- **Nessun border esterno** - si adatta all'area del contenuto
- **Header compatto** - testo semplice invece di box colorato
- **Dimensionamento dinamico** - si adatta all'altezza disponibile

### File Modificati

#### `advanced_wizard.go`
```go
// Nuova funzione per rendering integrato
func (m advancedWizardModel) RenderForTUI() string {
    // Renderizza senza border esterno
    // Header compatto
    // Si integra nell'area del contenuto
}
```

#### `tui.go`
```go
// Vista non sostituita più completamente
func (m tuiModel) View() string {
    // Header sempre presente
    // Content area con wizard integrato
    // Command bar sempre visibile (ma disabilitata)
    // Status bar sempre visibile
}

// Rendering del contenuto
func (m tuiModel) renderContent(height int) string {
    case viewServiceWizard:
        if m.wizard != nil {
            return m.wizard.RenderForTUI() // ← Usa versione integrata
        }
}
```

### Gestione dello Stato

- **`wizardActive`**: Flag che indica se il wizard è in esecuzione
- **Command bar disabilitata**: Input non processato durante wizard
- **Status bar dinamica**: Mostra "Wizard Active" invece dello stato normale
- **Delegazione eventi**: Tutti gli input vengono passati al wizard

### Benefici dell'Approccio

✅ **Consistenza UX**: Stessa interfaccia per tutte le viste
✅ **Orientamento utente**: Logo sempre visibile = contesto chiaro
✅ **Status feedback**: Status bar fornisce info costanti
✅ **Esperienza professionale**: Layout pulito e coerente
✅ **Manutenibilità**: Separazione tra rendering standalone e integrato

---

**Versione**: Integrazione grafica completata il 3 aprile 2026
