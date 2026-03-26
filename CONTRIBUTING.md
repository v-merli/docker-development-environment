# Contributing to PHPHarbor

Thank you for your interest in contributing! This document explains the development workflow and how to contribute to the project.

## 📋 Table of Contents

- [Git Workflow](#git-workflow)
- [Branch Strategy](#branch-strategy)
- [Commit Guidelines](#commit-guidelines)
- [Release Process](#release-process)
- [Development Setup](#development-setup)

## 🌳 Git Workflow

This project uses simplified **Git Flow** with two main branches:

### Main Branches

#### `main` - Production Branch (Frozen)
- ⭐ Contains **only** officially released code
- 🏷️ Every commit is tagged with a version (v1.0.0, v1.1.0, etc.)
- 🔒 **Never work directly here**
- ✅ Always stable and ready to be deployed
- 📦 GitHub releases are generated from here

#### `develop` - Development Branch (Active)
- 🚀 Continuous integration branch
- 💻 All daily work happens here
- 🔄 Receives merges from feature/fix branches
- 🧪 Tested code but not yet released
- 📝 Default branch for pull requests

### Feature and Fix Branches

For each new feature or bugfix, create a branch from `develop`:

```bash
# Feature branch
git checkout develop
git pull
git checkout -b feature/nome-feature

# Bugfix branch
git checkout develop
git pull
git checkout -b fix/nome-bug

# Urgent hotfix (from main)
git checkout main
git pull
git checkout -b hotfix/fix-name
```

### Naming Convention

- `feature/*` - New features
- `fix/*` - Regular bugfixes
- `hotfix/*` - Urgent fixes on main
- `chore/*` - Maintenance, refactoring
- `docs/*` - Documentation

Examples:
- `feature/add-postgres-support`
- `fix/port-conflict-detection`
- `hotfix/critical-ssl-bug`
- `docs/update-installation-guide`

## 🔄 Daily Development Workflow

```bash
# 1. Start from updated develop
git checkout develop
git pull origin develop

# 2. Create feature branch
git checkout -b feature/awesome-feature

# 3. Work and commit
git add .
git commit -m "feat: add awesome feature"

# 4. Push branch
git push origin feature/awesome-feature

# 5. Open Pull Request on GitHub (target: develop)

# 6. After merge, clean up
git checkout develop
git pull
git branch -d feature/awesome-feature
```

## 📦 Release Workflow

When `develop` is ready for release:

```bash
# 1. Verify develop
git checkout develop
git pull origin develop

# 2. Update version in phpharbor
# Modify: VERSION="1.1.0"
git add phpharbor
git commit -m "chore: bump version to 1.1.0"

# 3. Merge into main
git checkout main
git pull origin main
git merge develop --no-ff -m "Release v1.1.0"

# 4. Create tag
git tag -a v1.1.0 -m "Release 1.1.0"
git push origin main v1.1.0

# 5. Generate release
./create-release.sh 1.1.0

# 6. Publish on GitHub releases

# 7. Return to develop
git checkout develop
```

## 📝 Commit Guidelines

Use [Conventional Commits](https://www.conventionalcommits.org/):

### Format
```
<type>(<scope>): <description>

[optional body]
```

### Types
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `chore:` - Maintenance, release
- `refactor:` - Refactoring
- `test:` - Tests

### Examples
```bash
feat(ssl): add automatic certificate renewal
fix(proxy): resolve port conflict
docs: add Windows setup guide
chore: bump version to 1.2.0
```

## 🏷️ Versioning

We follow [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
  │     │     │
  │     │     └─ Bug fixes (1.0.0 → 1.0.1)
  │     └─────── New features (1.0.0 → 1.1.0)
  └───────────── Breaking changes (1.0.0 → 2.0.0)
```

## 🛠️ Development Setup

```bash
# Clone e setup
git clone https://github.com/v-merli/php-harbor.git
cd php-harbor
git checkout develop
./phpharbor setup init

# Test
./phpharbor version
./test-update-system.sh
```

## 🤝 Pull Request

1. Fork the repository
2. Create branch from `develop`
3. Commit following conventions
4. Test your changes
5. Push and open PR to `develop`
6. Describe what the PR does
7. Wait for review

---

Thank you for contributing! 🙏
