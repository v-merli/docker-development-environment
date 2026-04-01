# Node.js Worker

Background Node.js service for WebSocket servers, queue processing, real-time features, etc.

## What it does

- Runs a Node.js application alongside your PHP app
- Perfect for WebSocket servers, real-time features
- Can handle background jobs, queue processing
- Express servers, Socket.io, etc.

## Configuration

### Default Script

By default, runs `node server.js` from `app/` directory.

### Change the script

Edit `docker-compose.override.yml`:

```yaml
command: node scripts/websocket-server.js
# or
command: npm start
# or
command: sh -c "npm install && npm run dev"
```

### Install dependencies

The `app/` directory is mounted, so:

1. Create your `package.json` in `app/`
2. Install dependencies inside the container:

```bash
docker exec -it <project-name>-node-worker npm install
```

Or use a startup script:

```yaml
command: sh -c "npm install && node server.js"
```

## Example: Socket.io Server

Create `app/server.js`:

```javascript
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

server.listen(3000, () => {
  console.log('WebSocket server running on port 3000');
});
```

Create `app/package.json`:

```json
{
  "name": "node-worker",
  "dependencies": {
    "express": "^4.18.0",
    "socket.io": "^4.6.0"
  }
}
```

## Access

- From host: `http://localhost:3000`
- From other containers: `http://node-worker:3000`

## Environment Variables

Add custom environment variables in `docker-compose.override.yml`:

```yaml
environment:
  NODE_ENV: production
  PORT: 3000
  DATABASE_URL: mysql://user:pass@mysql/dbname
  REDIS_URL: redis://redis:6379
```

## View Logs

```bash
docker logs <project-name>-node-worker -f
```

## Notes

- Port 3000 must be available (or change it)
- Node modules are installed inside the container
- Great for Laravel Echo Server, Socket.io, etc.
