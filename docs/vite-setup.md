# Vite Configuration for Docker

This guide explains how to use Vite (with `npm run dev`) in Docker projects for HMR (Hot Module Replacement) support.

## Vite Port

All Docker templates are configured to automatically expose **port 5173** (Vite's default port) from the container to your host.

### Docker Compose Configuration

The port is configured in the `app` container with:

```yaml
services:
  app:
    ports:
      - "${VITE_PORT:-5173}:5173"
```

You can customize the host port via the `VITE_PORT` environment variable in the project's `.env` file if needed:

```env
VITE_PORT=5174  # Use a different port if 5173 is already occupied
```

## Vite Configuration

To make Vite work correctly in Docker, you need to configure your Laravel project's `vite.config.ts` or `vite.config.js` file:

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
        // Listen on all network interfaces (required for Docker)
        host: '0.0.0.0',
        
        // Vite port (must match the exposed port in docker-compose)
        port: 5173,
        
        // Fails if port is not available
        strictPort: true,
        
        // HMR configuration
        hmr: {
            // Use localhost to connect directly to exposed port
            // Necessary because you access the app via proxy (e.g., myproject.test:8443)
            // but the proxy doesn't expose port 5173
            host: 'localhost',
            
            // Port on which the browser connects (exposed container port)
            clientPort: 5173,
        },
        
        // Use polling for file watching (required for Docker on macOS/Windows)
        watch: {
            usePolling: true,
        },
    },
});
```

### .env Configuration

In the Laravel project's `.env` file, make sure `VITE_DEV_SERVER_URL` points correctly to `localhost`:

```env
VITE_DEV_SERVER_URL=http://localhost:5173
```

This variable is used by Laravel (server-side PHP) to understand if Vite is running in dev mode. Laravel attempts to connect to this URL to verify if the dev server is active. Since Laravel and Vite run in the same container (`app`), use `localhost`.

**Note**: This value is also the default of Laravel Vite Plugin, so you can omit it if you use standard port 5173.

### Important parameters:

- **`host: '0.0.0.0'`**: Allows Vite to accept connections from outside the container
- **`port: 5173`**: Port on which Vite listens (must match docker-compose)
- **`strictPort: true`**: Prevents fallback to different ports if 5173 is occupied
- **`hmr.host: 'localhost'`**: **IMPORTANT!** Forces HMR connection to `localhost` instead of proxy domain
- **`hmr.clientPort: 5173`**: Port on which the browser connects (exposed container port)
- **`watch.usePolling: true`**: Necessary for Docker on macOS and Windows to detect file changes

### Why is HMR configuration needed?

Without HMR configuration, Vite would automatically use `window.location.hostname` for the WebSocket connection. But:
- You access the app via: `https://myproject.test:8443` (through proxy)
- Vite would try: `ws://myproject.test:5173`
- **Problem**: The proxy doesn't expose port 5173

So we force `hmr.host: 'localhost'` to connect directly to the exposed container port, bypassing the proxy.

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

### HMR not working

1. **Verify port is exposed**: Check with `docker ps` that the app container exposes port 5173:
   ```bash
   docker ps --filter "name=myproject-app"
   ```
   You should see: `0.0.0.0:5173->5173/tcp`

2. **If port is not exposed**, recreate containers (a simple restart isn't enough):
   ```bash
   cd projects/myproject
   docker compose down
   docker compose up -d
   ```

3. **Check browser console**: Look for WebSocket errors
4. **Verify HMR configuration**: Use `hmr.host: 'localhost'` and `hmr.clientPort: 5173`

### Port 5173 already in use

If you have multiple projects using Vite simultaneously, each project must use a different port:

1. Add `VITE_PORT` to the project's `.env` file with a different port:
   ```env
   VITE_PORT=5174
   ```

2. Update the port in `vite.config.ts`:
   ```typescript
   server: {
       port: 5174,
       hmr: {
           clientPort: 5174,
       },
   }
   ```

3. Recreate containers:
   ```bash
   cd projects/myproject
   docker compose down
   docker compose up -d
   ```

4. Verify the new port is exposed:
   ```bash
   docker ps --filter "name=myproject-app"
   # You should see: 0.0.0.0:5174->5174/tcp
   ```

### File watcher not working

If file changes are not detected automatically, make sure you have `watch.usePolling: true` in Vite configuration.

## Examples

See the `vite.config.ts` files in existing projects for working configuration examples:

- `projects/fast-labels/app/vite.config.ts`
- `projects/my-spots-list/app/vite.config.ts`
