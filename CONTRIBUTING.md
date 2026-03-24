# Contributing to Docker Development Environment

Grazie per il tuo interesse nel contribuire! Questo documento spiega il workflow di sviluppo e come contribuire al progetto.

## 📋 Tabella dei Contenuti

- [Git Workflow](#git-workflow)
- [Branch Strategy](#branch-strategy)
- [Commit Guidelines](#commit-guidelines)
- [Release Process](#release-process)
- [Development Setup](#development-setup)

## 🌳 Git Workflow

Questo progetto usa **Git Flow** semplificato con due branch principali:

### Branch Principali

#### `main` - Branch di Produzione (Congelato)
- ⭐ Contiene **solo** codice rilasciato ufficialmente
- 🏷️ Ogni commit è taggato con una versione (v1.0.0, v1.1.0, etc.)
- 🔒 **Non si lavora direttamente qui**
- ✅ Sempre stabile e pronto per essere deployato
- 📦 Da qui si generano le release GitHub

#### `develop` - Branch di Sviluppo (Vivo)
- 🚀 Branch di integrazione continua
- 💻 Qui avviene tutto il lavoro quotidiano
- 🔄 Riceve merge da feature/fix branches
- 🧪 Codice testato ma non ancora rilasciato
- 📝 Default branch per pull requests

### Branch Feature e Fix

Per ogni nuova feature o bugfix, crea un branch da `develop`:

```bash
# Feature branch
git checkout develop
git pull
git checkout -b feature/nome-feature

# Bugfix branch
git checkout develop
git pull
git checkout -b fix/nome-bug

# Hotfix urgente (da main)
git checkout main
git pull
git checkout -b hotfix/nome-fix
```

### Naming Convention

- `feature/*` - Nuove funzionalità
- `fix/*` - Bugfix normali
- `hotfix/*` - Fix urgenti su main
- `chore/*` - Manutenzione, refactoring
- `docs/*` - Documentazione

Esempi:
- `feature/add-postgres-support`
- `fix/port-conflict-detection`
- `hotfix/critical-ssl-bug`
- `docs/update-installation-guide`

## 🔄 Workflow Sviluppo Quotidiano

```bash
# 1. Parti da develop aggiornato
git checkout develop
git pull origin develop

# 2. Crea feature branch
git checkout -b feature/awesome-feature

# 3. Lavora e committa
git add .
git commit -m "feat: add awesome feature"

# 4. Push del branch
git push origin feature/awesome-feature

# 5. Apri Pull Request su GitHub (target: develop)

# 6. Dopo merge, pulisci
git checkout develop
git pull
git branch -d feature/awesome-feature
```

## 📦 Workflow Release

Quando `develop` è pronto per il rilascio:

```bash
# 1. Verifica develop
git checkout develop
git pull origin develop

# 2. Aggiorna versione in docker-dev
# Modifica: VERSION="1.1.0"
git add docker-dev
git commit -m "chore: bump version to 1.1.0"

# 3. Merge in main
git checkout main
git pull origin main
git merge develop --no-ff -m "Release v1.1.0"

# 4. Crea tag
git tag -a v1.1.0 -m "Release 1.1.0"
git push origin main v1.1.0

# 5. Genera release
./create-release.sh 1.1.0

# 6. Pubblica su GitHub releases

# 7. Torna su develop
git checkout develop
```

## 📝 Commit Guidelines

Usa [Conventional Commits](https://www.conventionalcommits.org/):

### Format
```
<type>(<scope>): <description>

[optional body]
```

### Types
- `feat:` - Nuova feature
- `fix:` - Bug fix
- `docs:` - Documentazione
- `chore:` - Manutenzione, release
- `refactor:` - Refactoring
- `test:` - Test

### Esempi
```bash
feat(ssl): add automatic certificate renewal
fix(proxy): resolve port conflict
docs: add Windows setup guide
chore: bump version to 1.2.0
```

## 🏷️ Versioning

Seguiamo [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
  │     │     │
  │     │     └─ Bug fixes (1.0.0 → 1.0.1)
  │     └─────── Nuove feature (1.0.0 → 1.1.0)
  └───────────── Breaking changes (1.0.0 → 2.0.0)
```

## 🛠️ Development Setup

```bash
# Clone e setup
git clone https://github.com/v-merli/docker-development-environment.git
cd docker-development-environment
git checkout develop
./docker-dev setup init

# Test
./docker-dev version
./test-update-system.sh
```

## 🤝 Pull Request

1. Fork il repository
2. Crea branch da `develop`
3. Committa seguendo le convenzioni
4. Testa le modifiche
5. Push e apri PR verso `develop`
6. Descrivi cosa fa la PR
7. Attendi review

---

Grazie per contribuire! 🙏
