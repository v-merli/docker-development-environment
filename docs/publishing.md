# Publishing Guide

Guide for publishing PHPHarbor on GitHub and making it publicly available.

## 📋 Pre-Publication Checklist

### 1. Repository Setup

- [ ] Create GitHub repository: `php-harbor`
- [ ] Set visibility: **Public**
- [ ] Add description: "🚀 Flexible Docker development environment for Laravel, WordPress, and PHP projects with cherry-picking of shared services"
- [ ] Add topics: `docker`, `laravel`, `php`, `wordpress`, `development-environment`, `docker-compose`
- [ ] Enable Issues
- [ ] Enable Discussions (optional)

### 2. Files to Verify

Before pushing, check that there are NO:

```bash
# Check for sensitive files
git status
git diff

# Check .gitignore
cat .gitignore

# Verify executable file permissions (IMPORTANT!)
ls -lh phpharbor install.sh uninstall.sh
```

**Executable Permissions** (critical for functionality):
```bash
# Ensure these files have executable permissions
chmod +x phpharbor install.sh uninstall.sh

# Git preserves executable permissions when committing
# Verify they're committed correctly
git ls-files -s phpharbor install.sh uninstall.sh
# Should show 100755 (executable) not 100644 (normal)
```

**Do NOT commit**:
- [ ] `.env` files with real credentials
- [ ] Private SSL certificates
- [ ] Personal logs
- [ ] `projects/` directory with personal projects

**Make sure to include**:
- [x] `install.sh` and `uninstall.sh` **executable** (chmod +x)
- [x] `phpharbor` **executable** (chmod +x)
- [x] All `.md` documentation files
- [x] `.github/` templates
- [x] `LICENSE`
- [x] Appropriate `.gitignore`

### 3. Documentation

- [x] Complete README.md with overview
- [x] INSTALLATION.md with detailed guide
- [x] CONTRIBUTING.md with contributor guidelines
- [x] CLI-README.md with command documentation
- [x] QUICK-START.md with tutorial
- [x] ARCHITECTURE.md with technical details
- [x] LICENSE (MIT)

### 4. Final Testing

Before publishing, test the installer:

```bash
# Simulate installation from GitHub (use your username temporarily)
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/php-harbor/main/install.sh)

# Or test locally
./install.sh

# Verify it works
phpharbor version
phpharbor help
phpharbor create test --type laravel --php 8.3
```

---

## 🚀 Publication

### Step 1: First Push

```bash
# Add remote origin (if not already done)
git remote add origin https://github.com/YOUR-USERNAME/php-harbor.git

# Verify branch
git branch -M main

# Initial push
git push -u origin main
```

### Step 2: Create Release Package

Before creating the GitHub release, generate the clean tarball:

```bash
# Generate tarball for release v1.0.0
./create-release.sh 1.0.0

# Output: releases/phpharbor-1.0.0.tar.gz
```

The script:
- ✅ Excludes development files (archive/, .github/, legacy/, .git/)
- ✅ Creates optimized tarball for distribution
- ✅ Generates SHA256 checksum
- ✅ Shows size and contents

**Test the tarball locally:**
```bash
# Extract to temporary directory
mkdir -p /tmp/test-release
tar -xzf releases/phpharbor-1.0.0.tar.gz -C /tmp/test-release

# Verify contents
ls -la /tmp/test-release

# Test installation
cd /tmp/test-release
./install.sh  # Should fail (no GitHub release yet)
```

### Step 3: Create GitHub Release

**⚠️ IMPORTANT**: The tarball uploaded to GitHub **must** be named exactly `phpharbor.tar.gz` (without version) because the installer uses that fixed URL: `releases/latest/download/php-phpharbor.gz`

1. Go to **Releases** → **Create a new release** or use the CLI:

#### Option A: Via Web (Recommended)

1. Go to: `https://github.com/YOUR-USERNAME/php-harbor/releases/new`
2. Tag: `v1.0.0`
3. Target: `main` branch
4. Title: `🚀 v1.0.0 - Initial Release`
5. Description: (see template below)
6. **📎 Attach binaries**: Drag & drop `releases/phpharbor-1.0.0.tar.gz`
7. **⚠️ CRITICAL**: After upload, click the pencil (✏️) and rename the file to: `phpharbor.tar.gz`
   - ❌ Wrong: `phpharbor-1.0.0.tar.gz`
   - ✅ Correct: `phpharbor.tar.gz`
8. ✅ Set as latest release
9. **Publish release**

#### Option B: Via GitHub CLI

```bash
# Install gh CLI if not present
brew install gh  # macOS
# or: https://cli.github.com/

# Authenticate
gh auth login

# Create release and upload tarball
gh release create v1.0.0 \
  releases/phpharbor-1.0.0.tar.gz#php-phpharbor.gz \
  --title "🚀 v1.0.0 - Initial Release" \
  --notes-file RELEASE_NOTES.md
```

**Template Description:**

```markdown
## 🎉 First Public Release

PHPHarbor is now publicly available!

### ✨ Features

- 🎯 Laravel, WordPress, static HTML, generic PHP support
- 🐘 Multi-version PHP (7.3 - 8.5)
- 💾 Cherry-picking of shared services (MySQL, Redis, PHP-FPM)
- 🌐 Nginx reverse proxy with automatic SSL
- 🎨 Interactive mode for project creation
- ⚡ Complete CLI with bash/zsh autocompletion

### 📦 Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/php-harbor/main/install.sh)
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

### Step 4: Verify Public Installation

Test that the installer works from GitHub:

```bash
# On a clean machine or VM
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/php-harbor/main/install.sh)
```

---

## 📣 Promotion

### Social Media

Share the project on:
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

https://github.com/YOUR-USERNAME/php-harbor

#Laravel #Docker #PHP #DevOps
```

### Laravel Community

- Laravel News (submit tip)
- Laravel.io forum
- Laracasts forum

### SEO

Add to README:
- Status badges (build, license, version)
- GIF/video demo
- FAQ section
- Comparison with other tools

---

## 🔄 Maintenance

### Branch Strategy

```
main          - Stable release
develop       - Development branch
feature/*     - Feature branches
hotfix/*      - Quick fixes
```

### Release Workflow

1. Develop in `feature/` branches
2. Merge into `develop`
3. Complete testing on `develop`
4. Merge into `main` for release
5. Tag release `vX.Y.Z`
6. Update changelog

### Issue Management

**Labels to create**:
- `bug` - Something isn't working
- `enhancement` - New feature
- `documentation` - Documentation improvements
- `good first issue` - Easy for newcomers
- `help wanted` - Help needed
- `question` - Questions
- `wontfix` - Won't be fixed
- `duplicate` - Duplicate issue

---

## 📊 Analytics (Optional)

Track usage with:

**GitHub Insights**:
- Stars, forks, watchers
- Traffic (clones, visitors)
- Popular content

**Optional Analytics**:
- Google Analytics on docs (if using GitHub Pages)
- Download counter for releases

---

## 🎯 Future Roadmap

Add a `ROADMAP.md` with future plans:

**v1.1**:
- Linux support
- Web dashboard
- Auto-update

**v2.0**:
- Kubernetes support
- Multi-database (PostgreSQL, MongoDB)
- GUI application

---

## ✅ Final Checklist

Before announcing publicly:

- [ ] Public repository on GitHub
- [ ] Release v1.0.0 created
- [ ] Installer tested from GitHub raw
- [ ] Complete and accurate documentation
- [ ] README with screenshot/demo
- [ ] CONTRIBUTING.md for new contributors
- [ ] Working issue templates
- [ ] URLs updated with correct username
- [ ] LICENSE file present
- [ ] Appropriate .gitignore

**🎉 You're ready to publish!**
