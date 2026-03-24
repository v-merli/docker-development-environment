# Publishing Guide

Guida per pubblicare PHPHarbor su GitHub e renderlo disponibile pubblicamente.

## 📋 Pre-Pubblicazione Checklist

### 1. Repository Setup

- [ ] Crea repository GitHub: `php-harbor`
- [ ] Imposta visibilità: **Public**
- [ ] Aggiungi descrizione: "🚀 Flexible Docker development environment for Laravel, WordPress, and PHP projects with cherry-picking of shared services"
- [ ] Aggiungi topics: `docker`, `laravel`, `php`, `wordpress`, `development-environment`, `docker-compose`
- [ ] Abilita Issues
- [ ] Abilita Discussions (opzionale)

### 2. File da Verificare

Prima del push, controlla che NON ci siano:

```bash
# Verifica file sensibili
git status
git diff

# Controlla .gitignore
cat .gitignore

# Verifica permessi file eseguibili (IMPORTANTE!)
ls -lh phpharbor install.sh uninstall.sh
```

**Permessi Eseguibili** (critico per il funzionamento):
```bash
# Assicurati che questi file abbiano permessi eseguibili
chmod +x phpharbor install.sh uninstall.sh

# Git preserva i permessi eseguibili quando committa
# Verifica che siano committati correttamente
git ls-files -s phpharbor install.sh uninstall.sh
# Dovrebbe mostrare 100755 (eseguibile) non 100644 (normale)
```

**Non committare**:
- [ ] File `.env` con credenziali reali
- [ ] Certificati SSL privati
- [ ] Logs personali
- [ ] Directory `projects/` con progetti personali

**Assicurati di includere**:
- [x] `install.sh` e `uninstall.sh` **eseguibili** (chmod +x)
- [x] `phpharbor **eseguibile** (chmod +x)
- [x] Tutti i file `.md` di documentazione
- [x] Template `.github/`
- [x] `LICENSE`
- [x] `.gitignore` appropriato

### 3. Documentazione

- [x] README.md completo con overview
- [x] INSTALLATION.md con guida dettagliata
- [x] CONTRIBUTING.md con linee guida contributori
- [x] CLI-README.md con documentazione comandi
- [x] QUICK-START.md con tutorial
- [x] ARCHITECTURE.md con dettagli tecnici
- [x] LICENSE (MIT)

### 4. Testing Finale

Prima di pubblicare, testa l'installatore:

```bash
# Simula installazione da GitHub (usa il tuo username temporaneamente)
bash <(curl -fsSL https://raw.githubusercontent.com/TUO-USERNAME/php-harbor/main/install.sh)

# Oppure testa localmente
./install.sh

# Verifica che funzioni
phpharbor version
phpharbor help
phpharbor create test --type laravel --php 8.3
```

---

## 🚀 Pubblicazione

### Step 1: Primo Push

```bash
# Aggiungi remote origin (se non già fatto)
git remote add origin https://github.com/TUO-USERNAME/php-harbor.git

# Verifica branch
git branch -M main

# Push iniziale
git push -u origin main
```

### Step 2: Crea Release Package

Prima di creare la release su GitHub, genera il tarball pulito:

```bash
# Genera tarball per release v1.0.0
./create-release.sh 1.0.0

# Output: releases/phpharbor-1.0.0.tar.gz
```

Lo script:
- ✅ Esclude file di sviluppo (archive/, .github/, legacy/, .git/)
- ✅ Crea tarball ottimizzato per distribuzione
- ✅ Genera checksum SHA256
- ✅ Mostra dimensione e contenuto

**Testa il tarball localmente:**
```bash
# Estrai in directory temporanea
mkdir -p /tmp/test-release
tar -xzf releases/phpharbor-1.0.0.tar.gz -C /tmp/test-release

# Verifica contenuto
ls -la /tmp/test-release

# Testa installazione
cd /tmp/test-release
./install.sh  # Dovrebbe fallire (nessuna release su GitHub ancora)
```

### Step 3: Crea GitHub Release

**⚠️ IMPORTANTE**: Il tarball caricato su GitHub **deve** chiamarsi esattamente `phpharbor.tar.gz` (senza versione) perché l'installer usa quell'URL fisso: `releases/latest/download/php-phpharbor.gz`

1. Vai su **Releases** → **Create a new release** o usa la CLI:

#### Opzione A: Via Web (Consigliata)

1. Vai su: `https://github.com/TUO-USERNAME/php-harbor/releases/new`
2. Tag: `v1.0.0`
3. Target: `main` branch
4. Title: `🚀 v1.0.0 - Initial Release`
5. Description: (vedi template sotto)
6. **📎 Attach binaries**: Drag & drop `releases/phpharbor-1.0.0.tar.gz`
7. **⚠️ CRITICO**: Dopo il caricamento, clicca sulla matita (✏️) e rinomina il file in: `phpharbor.tar.gz`
   - ❌ Errore: `phpharbor-1.0.0.tar.gz`
   - ✅ Corretto: `phpharbor.tar.gz`
8. ✅ Set as latest release
9. **Publish release**

#### Opzione B: Via GitHub CLI

```bash
# Installa gh CLI se non presente
brew install gh  # macOS
# oppure: https://cli.github.com/

# Autenticati
gh auth login

# Crea release e carica tarball
gh release create v1.0.0 \
  releases/phpharbor-1.0.0.tar.gz#php-phpharbor.gz \
  --title "🚀 v1.0.0 - Initial Release" \
  --notes-file RELEASE_NOTES.md
```

**Template Description:**

```markdown
## 🎉 First Public Release

PHPHarbor è ora disponibile pubblicamente!

### ✨ Features

- 🎯 Supporto Laravel, WordPress, HTML statico, PHP generico
- 🐘 PHP multi-versione (7.3 - 8.5)
- 💾 Cherry-picking servizi condivisi (MySQL, Redis, PHP-FPM)
- 🌐 Nginx reverse proxy con SSL automatico
- 🎨 Modalità interattiva per creazione progetti
- ⚡ CLI completo con autocompletamento bash/zsh

### 📦 Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TUO-USERNAME/php-harbor/main/install.sh)
```

### 📚 Documentation

- [Installation Guide](INSTALLATION.md)
- [Quick Start](QUICK-START.md)
- [CLI Documentation](CLI-README.md)
- [Contributing](CONTRIBUTING.md)

### 🙏 Contributors

Thanks to all who contributed to this initial release!
```

5. **Publish release**

### Step 4: Verifica Installazione Pubblica

Testa che l'installer funzioni da GitHub:

```bash
# Su una macchina pulita o VM
bash <(curl -fsSL https://raw.githubusercontent.com/TUO-USERNAME/php-harbor/main/install.sh)
```

---

## 📣 Promozione

### Social Media

Condividi il progetto su:
- Twitter/X
- Reddit (r/laravel, r/docker, r/php)
- Dev.to
- LinkedIn

**Post template**:
```
🚀 Just released PHPHarbor v1.0!

Flexible Docker setup for Laravel/WordPress/PHP with:
✅ Cherry-pick shared services (save RAM)
✅ Multi-version PHP (7.3-8.5)
✅ Interactive project creation
✅ One-line installation

https://github.com/TUO-USERNAME/php-harbor

#Laravel #Docker #PHP #DevOps
```

### Laravel Community

- Laravel News (submit tip)
- Laravel.io forum
- Laracasts forum

### SEO

Aggiungi al README:
- Status badges (build, license, version)
- GIF/video demo
- FAQ section
- Comparison con altri tool

---

## 🔄 Manutenzione

### Branch Strategy

```
main          - Stable release
develop       - Development branch
feature/*     - Feature branches
hotfix/*      - Quick fixes
```

### Release Workflow

1. Sviluppa in `feature/` branches
2. Merge in `develop`
3. Test completi su `develop`
4. Merge in `main` per release
5. Tag release `vX.Y.Z`
6. Update changelog

### Issue Management

**Labels da creare**:
- `bug` - Qualcosa non funziona
- `enhancement` - Nuova feature
- `documentation` - Miglioramenti doc
- `good first issue` - Facili per newcomers
- `help wanted` - Serve aiuto
- `question` - Domande
- `wontfix` - Non sarà risolto
- `duplicate` - Issue duplicata

---

## 📊 Analytics (Opzionale)

Traccia l'utilizzo con:

**GitHub Insights**:
- Stars, forks, watchers
- Traffic (clones, visitors)
- Popular content

**Optional Analytics**:
- Google Analytics su docs (se usi GitHub Pages)
- Download counter per releases

---

## 🎯 Roadmap Futura

Aggiungi un `ROADMAP.md` con piani futuri:

**v1.1**:
- Supporto Linux
- Dashboard web
- Auto-update

**v2.0**:
- Kubernetes support
- Multi-database (PostgreSQL, MongoDB)
- GUI application

---

## ✅ Final Checklist

Prima di annunciare pubblicamente:

- [ ] Repository pubblico su GitHub
- [ ] Release v1.0.0 creata
- [ ] Installer testato da GitHub raw
- [ ] Documentazione completa e accurata
- [ ] README con screenshot/demo
- [ ] CONTRIBUTING.md per nuovi contributori
- [ ] Issue templates funzionanti
- [ ] URL aggiornati con username corretto
- [ ] LICENSE file presente
- [ ] .gitignore appropriato

**🎉 Sei pronto per pubblicare!**
