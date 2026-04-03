# Rust TUI Demo Commands

## Launch TUI
```bash
cd cli-rust
./target/release/phpharbor
```

## Try these commands in the TUI:

### 1. **Interactive Create** 🎨
   ```
   create
   ```
   Questo comando ti farà delle domande interattive:
   - Project name
   - Project type (laravel/wordpress/php/html)
   - PHP version (7.3-8.3)
   - Enable MySQL? (yes/no)
   
   Puoi premere ENTER per accettare i valori di default mostrati tra `[]`

### 2. **Disk Statistics** 📊
   ```
   stats disk
   ```
   Mostra una tabella con:
   - Elenco progetti con dimensioni
   - Numero di immagini Docker
   - Numero di volumi
   - Stato (running/stopped)
   - Riepilogo servizi condivisi
   - Totale spazio utilizzato

### 3. **List projects**
   ```
   list
   ```

### 4. **Start a project**
   ```
   start myapp
   ```

### 5. **Stop a project**
   ```
   stop wordpress-blog
   ```

### 6. **Help**
   ```
   help
   ```

### 7. **Exit**
   ```
   quit
   ```
   Or press `ESC`

## Traditional CLI Mode

```bash
# Show help
./target/release/phpharbor --help

# List projects (non-interactive)
./target/release/phpharbor list

# Disk statistics with table
./target/release/phpharbor stats disk

# Create project
./target/release/phpharbor create myapp --php 8.3

# Start project
./target/release/phpharbor start myapp

# Show version
./target/release/phpharbor version
```

## New Features Demonstrated ✨

### 🎯 Interactive Prompts
Il comando `create` (senza argomenti) entra in modalità interattiva:
- Fa domande una alla volta
- Mostra i valori di default tra `[...]`
- Accetta input utente o default (premi ENTER)
- Mostra un riepilogo finale della configurazione
- Simula la creazione del progetto con feedback progressivo

**Esempio di flusso:**
```
> create
🎨 Creating a new project...

❓ Project name: myapp
  → myapp
❓ Project type (laravel/wordpress/php/html) [laravel]: 
  → laravel
❓ PHP version (7.3/7.4/8.0/8.1/8.2/8.3) [8.3]: 8.2
  → 8.2
❓ Enable MySQL? (yes/no) [yes]: 
  → yes

✓ Creating project with configuration:
  • Name: myapp
  • Type: laravel
  • PHP: 8.2
  • MySQL: yes

✓ Generating docker-compose.yml...
✓ Creating project structure...
✓ Setting up configuration...

✓ Project 'myapp' created successfully!
  → Start with: start myapp
```

### 📊 Table Rendering
Il comando `stats disk` mostra una tabella formattata con:
- Bordi box-drawing Unicode (┌─┬─┐ │ ├─┼─┤ └─┴─┘)
- Colonne allineate
- Separatori visivi
- Totali aggregati
- Sezione servizi condivisi
- Riepilogo finale

## Interface Features

✨ **TUI Highlights:**
- Full-screen terminal interface
- PHPHarbor ASCII logo at the top
- Command input area at the bottom
- Scrollable output area in the middle
- **Interactive mode** with sequential questions
- **Table rendering** with Unicode borders
- Color-coded messages:
  - 🟡 Yellow: User commands (>)
  - 🟢 Green: Success messages (✓)
  - 🔴 Red: Error messages (✗)
  - 🔵 Blue: Links/URLs (→)
  - 🟣 Magenta: Questions (❓)
  - ⚪ White: Info messages

- Cursor navigation: Left/Right arrows
- Backspace to delete
- Enter to execute (or answer questions)
- ESC to quit

## Test Workflow Example

```
1. Launch: ./target/release/phpharbor
2. Type: create
3. Answer the questions (or press ENTER for defaults)
4. Type: list
5. Type: stats disk
6. Type: start myapp
7. Press ESC to exit
```
