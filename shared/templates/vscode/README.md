# VS Code Templates

Questa directory contiene i template di configurazione per VS Code che vengono automaticamente copiati nei nuovi progetti.

## File disponibili

### launch.json
Configurazione per il debug con Xdebug 3.x

**Funzionalità:**
- Debug listener su porta 9003
- Path mapping automatico per Docker (`/var/www/html` → workspace)
- Supporto debug su file corrente
- Ottimizzato per PHPHarbor

**Come usare:**
1. In VS Code, apri il pannello "Run and Debug" (Cmd+Shift+D)
2. Seleziona "Listen for Xdebug (PHPHarbor)"
3. Premi F5 per avviare il listener
4. Nel browser aggiungi `?XDEBUG_TRIGGER=1` alla URL
5. Usa F10 per navigare riga per riga

### XDEBUG-GUIDE.md
Guida completa all'utilizzo di Xdebug con VS Code e PHPHarbor

**Contenuti:**
- Configurazione VS Code passo-passo
- Installazione estensione PHP Debug
- Come mettere breakpoint
- Controlli di debug (F5, F10, F11, ecc.)
- Troubleshooting problemi comuni
- Tutorial ed esempi pratici
- Link a risorse utili

**Nota:** Questo file viene copiato nella root del progetto (`app/XDEBUG-GUIDE.md`) per facile accesso.

## Aggiungere nuovi template

Per aggiungere nuove configurazioni VS Code:

1. Crea il file in `shared/templates/vscode/`
2. Modifica `cli/create.sh` per copiarlo durante la creazione del progetto
3. Documenta l'uso in questo README
