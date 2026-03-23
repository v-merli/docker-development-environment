# Contributing

Grazie per l'interesse nel contribuire a Docker Development Environment! 🎉

## 🤝 Come Contribuire

Accettiamo contributi di ogni tipo:
- 🐛 **Bug reports** - Segnala problemi o comportamenti inattesi
- ✨ **Feature requests** - Suggerisci nuove funzionalità
- 📝 **Documentazione** - Migliora guide e README
- 💻 **Codice** - Fix bug, implementa features, ottimizza

## 📋 Linee Guida

### Prima di Iniziare

1. **Cerca issue esistenti** - Qualcun altro potrebbe già lavorarci
2. **Apri una issue** - Discuti l'idea prima di codificare
3. **Fork il repository** - Lavora sul tuo fork

### Setup Ambiente di Sviluppo

```bash
# Clone del tuo fork
git clone https://github.com/tuo-username/docker-development-environment.git
cd docker-development-environment

# Aggiungi upstream
git remote add upstream https://github.com/original-username/docker-development-environment.git

# Crea branch per feature/fix
git checkout -b feature/nome-feature
```

### Testing

Prima di inviare una PR, testa:

```bash
# Testa creazione progetto
./docker-dev create test-project --type laravel --php 8.3

# Testa con servizi condivisi
./docker-dev create test-shared --fully-shared

# Testa tutti i comandi
./docker-dev project list
./docker-dev project info test-project
./docker-dev shared status
./docker-dev project remove test-project
```

**Checklist di test**:
- [ ] Creazione progetto Laravel con DB dedicato
- [ ] Creazione progetto con servizi condivisi
- [ ] Comandi project (start, stop, logs, shell)
- [ ] Comandi shared (start, stop, status)
- [ ] SSL funzionante (https://test-project.test)
- [ ] Vite HMR funzionante
- [ ] Laravel artisan/composer
- [ ] Remove progetto completo

### Stile Codice

**Bash Scripts**:
```bash
# Usa set -e per fail-fast
set -e

# Funzioni con nomi descrittivi
function do_something() {
    local var="value"
    # ...
}

# Commenti per sezioni
# ==================================================
# SEZIONE IMPORTANTE
# ==================================================

# Quote sempre le variabili
echo "$VAR"
[ -d "$DIR" ]

# Usa colori per output
print_success "Operazione completata"
print_error "Errore critico"
```

**Docker Compose**:
```yaml
# Indentazione 2 spazi
services:
  app:
    # Usa variabili .env
    image: ${PROJECT_NAME}-app
    
    # Commenti per sezioni complesse
    environment:
      # Laravel specifico
      - DB_HOST=mysql
```

### Commit Messages

Usa [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add WordPress support
fix: resolve port conflict in vite
docs: update installation guide
refactor: simplify project creation logic
test: add integration tests for shared services
```

Esempi:
- `feat(cli): add interactive mode for project creation`
- `fix(docker): resolve PHP memory limit issue`
- `docs(readme): add troubleshooting section`

### Pull Request

1. **Aggiorna il tuo fork**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Pusha le modifiche**:
   ```bash
   git push origin feature/nome-feature
   ```

3. **Apri PR su GitHub**:
   - Titolo chiaro (es: "Add WordPress multisite support")
   - Descrizione dettagliata delle modifiche
   - Link all'issue di riferimento
   - Screenshot/logs se pertinenti

4. **Checklist PR**:
   - [ ] Codice testato localmente
   - [ ] Documentazione aggiornata
   - [ ] Commit messages seguono convenzioni
   - [ ] Nessun file inutile committato (logs, .env, ecc)
   - [ ] Funziona con tutte le versioni PHP supportate

## 🏗️ Struttura Progetto

```
docker-development-environment/
├── docker-dev              # Entry point principale
├── docker-dev-completion.bash  # Autocompletamento bash/zsh
├── install.sh              # Script installazione
├── uninstall.sh            # Script disinstallazione
│
├── cli/                    # Moduli CLI
│   ├── create.sh          # Creazione progetti
│   ├── project.sh         # Gestione progetti
│   ├── dev.sh             # Dev commands (artisan, composer)
│   ├── shared.sh          # Servizi condivisi
│   ├── ssl.sh             # SSL/certificati
│   ├── setup.sh           # Setup iniziale
│   └── system.sh          # System utilities
│
├── shared/                 # Configurazioni condivise
│   ├── dockerfiles/       # PHP Dockerfiles (dev + fpm-only)
│   ├── nginx/             # Nginx configs (Laravel, WordPress, HTML)
│   ├── supervisor/        # Supervisor configs (workers)
│   └── templates/         # Docker Compose templates
│       └── docker-compose-unified.yml  # Template unificato con profiles
│
├── proxy/                  # Nginx reverse proxy
│   ├── docker-compose.yml
│   ├── setup-ssl-ca.sh
│   └── nginx/
│
└── projects/               # Progetti creati
    └── [project-name]/
```

## 🎯 Aree di Contribuzione

### Facile (Good First Issue)

- Migliorare documentazione
- Aggiungere esempi in QUICK-START.md
- Fix typos
- Aggiungere test per edge cases
- Migliorare output colorato/formattazione

### Medio

- Aggiungere supporto nuovi framework (Symfony, CodeIgniter)
- Migliorare gestione errori
- Ottimizzare performance build
- Aggiungere validazione input

### Avanzato

- Supporto multi-OS (Linux, Windows WSL)
- Orchestrazione complessa (Kubernetes)
- Dashboard web per gestione progetti
- Auto-update mechanism
- Backup/restore automatico

## 🐛 Segnalazione Bug

Apri una [issue](https://github.com/your-username/docker-development-environment/issues/new) includendo:

**Informazioni Sistema**:
```bash
# Output di questi comandi
docker --version
docker compose version
sw_vers  # macOS
./docker-dev version
```

**Descrizione Bug**:
- Cosa ti aspettavi
- Cosa è successo invece
- Steps per riprodurre

**Logs**:
```bash
# Logs progetto
./docker-dev project logs project-name

# Logs servizi condivisi
docker logs proxy
docker logs mysql-shared
```

## 📖 Documentazione

Se modifichi funzionalità, aggiorna:
- README.md - Overview generale
- CLI-README.md - Documentazione comandi
- INSTALLATION.md - Guida installazione
- File specifici (WORKERS-GUIDE.md, SSL-SETUP.md, ecc)

## 🔍 Code Review

Le PR sono reviewate per:
- **Funzionalità** - Fa quello che dice?
- **Testing** - È stato testato adeguatamente?
- **Stile** - Segue le convenzioni?
- **Documentazione** - È documentato?
- **Breaking Changes** - Rompe codice esistente?

## 📜 Licenza

Contribuendo, accetti che il tuo codice sia rilasciato sotto la stessa licenza del progetto (probabilmente MIT).

## 💬 Domande?

- Apri una [Discussion](https://github.com/your-username/docker-development-environment/discussions)
- Commenta su issue esistenti
- Contatta i maintainer

## 🙏 Riconoscimenti

Tutti i contributori sono listati in:
- GitHub Contributors page
- Releases notes
- Hall of Fame (coming soon!)

---

**Grazie per aver contribuito! Together we make development easier for everyone.** 🚀
