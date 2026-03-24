# Configurazione Vite per Docker

Questa guida spiega come utilizzare Vite (con `npm run dev`) nei progetti Docker per il supporto HMR (Hot Module Replacement).

## Porta Vite

Tutti i template Docker sono configurati per esporre automaticamente la **porta 5173** (porta predefinita di Vite) dal container al tuo host.

### Configurazione Docker Compose

La porta è configurata nei container `app` con:

```yaml
services:
  app:
    ports:
      - "${VITE_PORT:-5173}:5173"
```

Puoi personalizzare la porta dell'host tramite la variabile d'ambiente `VITE_PORT` nel file `.env` del progetto, se necessario:

```env
VITE_PORT=5174  # Usa una porta diversa se 5173 è già occupata
```

## Configurazione Vite

Per far funzionare Vite correttamente in Docker, devi configurare il file `vite.config.ts` o `vite.config.js` del tuo progetto Laravel:

```typescript
import laravel from 'laravel-vite-plugin';
import { defineConfig } from 'vite';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
    server: {
        // Ascolta su tutte le interfacce di rete (necessario per Docker)
        host: '0.0.0.0',
        
        // Porta Vite (deve corrispondere alla porta esposta in docker-compose)
        port: 5173,
        
        // Fallisce se la porta non è disponibile
        strictPort: true,
        
        // Configurazione HMR
        hmr: {
            // Usa localhost per connettersi direttamente alla porta esposta
            // Necessario perché accedi all'app via proxy (es: myproject.test:8443)
            // ma il proxy non espone la porta 5173
            host: 'localhost',
            
            // Porta su cui il browser si connette (la porta esposta dal container)
            clientPort: 5173,
        },
        
        // Usa polling per il file watching (necessario per Docker su macOS/Windows)
        watch: {
            usePolling: true,
        },
    },
});
```

### Configurazione .env

Nel file `.env` del progetto Laravel, assicurati che `VITE_DEV_SERVER_URL` punti correttamente a `localhost`:

```env
VITE_DEV_SERVER_URL=http://localhost:5173
```

Questa variabile viene usata da Laravel (lato server PHP) per capire se Vite è in esecuzione in modalità dev. Laravel tenta di connettersi a questo URL per verificare se il dev server è attivo. Dato che Laravel e Vite girano nello stesso container (`app`), usa `localhost`.

**Nota**: Questo valore è anche il default di Laravel Vite Plugin, quindi puoi ometterlo se usi la porta 5173 standard.

### Parametri importanti:

- **`host: '0.0.0.0'`**: Permette a Vite di accettare connessioni dall'esterno del container
- **`port: 5173`**: Porta su cui Vite ascolta (deve corrispondere a docker-compose)
- **`strictPort: true`**: Previene fallback su porte diverse se 5173 è occupata
- **`hmr.host: 'localhost'`**: **IMPORTANTE!** Forza la connessione HMR a `localhost` invece che al dominio del proxy
- **`hmr.clientPort: 5173`**: La porta su cui il browser si connette (la porta esposta dal container)
- **`watch.usePolling: true`**: Necessario per Docker su macOS e Windows per rilevare i cambiamenti ai file

### Perché serve la configurazione HMR?

Senza la configurazione HMR, Vite userebbe automaticamente `window.location.hostname` per la connessione WebSocket. Ma:
- Accedi all'app via: `https://myproject.test:8443` (tramite proxy)
- Vite tenterebbe: `ws://myproject.test:5173`
- **Problema**: Il proxy non espone la porta 5173

Quindi forziamo `hmr.host: 'localhost'` per connettersi direttamente alla porta esposta dal container, bypassando il proxy.

## Utilizzo

1. Accedi alla shell del container app:
   ```bash
   ./phpharborshell myproject
   ```

2. Avvia Vite:
   ```bash
   npm run dev
   ```

3. Vite sarà accessibile su:
   - **Nel browser**: `http://myproject.test` (o `https://myproject.test:8443` per HTTPS)
   - **HMR WebSocket**: `ws://localhost:5173` (connessione diretta alla porta esposta)

4. Le modifiche ai file CSS/JS saranno ricaricate automaticamente nel browser grazie all'HMR!

## Risoluzione Problemi

### HMR non funziona

1. **Verifica che la porta sia esposta**: Controlla con `docker ps` che il container app esponga la porta 5173:
   ```bash
   docker ps --filter "name=myproject-app"
   ```
   Dovresti vedere: `0.0.0.0:5173->5173/tcp`

2. **Se la porta non è esposta**, ricrea i container (un semplice restart non basta):
   ```bash
   cd projects/myproject
   docker compose down
   docker compose up -d
   ```

3. **Controlla la console del browser**: Cerca errori WebSocket
4. **Verifica la configurazione HMR**: Usa `hmr.host: 'localhost'` e `hmr.clientPort: 5173`

### Porta 5173 già in uso

Se hai più progetti che usano Vite contemporaneamente, ogni progetto deve usare una porta diversa:

1. Aggiungi `VITE_PORT` al file `.env` del progetto con una porta diversa:
   ```env
   VITE_PORT=5174
   ```

2. Aggiorna la porta in `vite.config.ts`:
   ```typescript
   server: {
       port: 5174,
       hmr: {
           clientPort: 5174,
       },
   }
   ```

3. Ricrea i container:
   ```bash
   cd projects/myproject
   docker compose down
   docker compose up -d
   ```

4. Verifica che la nuova porta sia esposta:
   ```bash
   docker ps --filter "name=myproject-app"
   # Dovresti vedere: 0.0.0.0:5174->5174/tcp
   ```

### File watcher non funziona

Se le modifiche ai file non vengono rilevate automaticamente, assicurati di avere `watch.usePolling: true` nella configurazione Vite.

## Esempi

Vedi i file `vite.config.ts` nei progetti esistenti per esempi di configurazione funzionanti:

- `projects/fast-labels/app/vite.config.ts`
- `projects/my-spots-list/app/vite.config.ts`
