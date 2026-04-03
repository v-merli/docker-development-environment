# Advanced Service Wizard - Guida d'Uso

## Panoramica

Il wizard avanzato per la configurazione dei servizi è ora completamente integrato nel TUI di PHPHarbor. Offre un'interfaccia interattiva con navigazione completa tra le domande e la possibilità di modificare le risposte date.

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
