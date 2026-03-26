# Automatic Update System

PHPHarbor includes an automatic update system that allows you to:
- Check if new versions are available
- Install updates with a single command
- Preserve all existing configurations and projects

## Available Commands

### Check for Updates

Check if a new version is available on GitHub:

```bash
./phpharbor update check
```

This command:
- ✅ Compares local version with the latest release on GitHub
- ✅ Shows release notes (changelog)
- ✅ Offers to install the update immediately

### Install Update

Install the latest available version or a specific version:

```bash
# Install latest version
./phpharbor update install

# Install specific version
./phpharbor update install 1.8.0
./phpharbor update install v1.8.0

# Downgrade to previous version
./phpharbor update install 1.5.0
```

The update process:
1. Downloads the latest version from GitHub
2. Creates backups of configurations
3. Replaces system files
4. Restores configurations and certificates
5. Restarts services if they were running

**What is preserved:**
- ✓ `.config` file (project directories, ports)
- ✓ `proxy/.env` file (proxy configuration)
- ✓ `projects/` directory (all projects)
- ✓ SSL certificates in `proxy/nginx/certs/`
- ✓ ACME data in `proxy/nginx/acme/`
- ✓ Docker containers and volumes

**What is updated:**
- ✓ Main `phpharbor` script
- ✓ CLI modules in `cli/`
- ✓ Templates in `shared/templates/`
- ✓ Dockerfiles in `shared/dockerfiles/`
- ✓ Shared configurations in `shared/`
- ✓ Documentation in `docs/`

### Elenca Versioni Disponibili

Mostra tutte le versioni pubblicate su GitHub:

```bash
./phpharbor update list
```

Example output:
```
Current version: 2.0.0

Available versions:

  ✓ v2.0.0 - 2026-03-24 - Release 2.0.0 (installed)
    v1.9.0 - 2026-03-15 - Release 1.9.0
    v1.8.2 - 2026-03-10 - Bugfix release
    v1.8.0 - 2026-03-01 - Feature release
```

### View Changelog

Show what's new in the latest version or a specific version:

```bash
# Latest version changelog
./phpharbor update changelog

# Specific version changelog
./phpharbor update changelog 1.8.0
```

## Repository Configuration

After publishing the project on GitHub, configure the repository:

### Method 1: Environment variable

```bash
export PHPHARBOR_GITHUB_REPO="tuo-username/pphpharbor
./phpharbor update check
```

### Metodo 2: Modifica permanente

Edita il file `cli/update.sh` e sostituisci:

```bash
GITHUB_REPO="${PHPHARBOR_GITHUB_REPO:-your-username/pphpharbor"
```

con:

```bash
GITHUB_REPO="${PHPHARBOR_GITHUB_REPO:-tuo-username/pphpharbor"
```

## Release Workflow

To publish a new version:

### 1. Update Version

Modify the version number in `phpharbor`:

```bash
VERSION="2.1.0"
```

### 2. Create Release Package

```bash
./create-release.sh 2.1.0
```

This generates `releases/phpharbor-2.1.0.tar.gz`.

### 3. Create GitHub Release

```bash
# Via GitHub CLI
gh release create v2.1.0 \
  releases/phpharbor-2.1.0.tar.gz#php-phpharbor.gz \
  --title "Release 2.1.0" \
  --notes "Changelog..."

# Or manually on GitHub:
# 1. Go to https://github.com/username/repo/releases/new
# 2. Tag: v2.1.0
# 3. Title: Release 2.1.0
# 4. Upload: phpharbor-2.1.0.tar.gz renamed to php-phpharbor.gz
# 5. Publish
```

### 4. Test Update

```bash
# On an existing installation
./phpharbor update check
./phpharbor update install
```

## GitHub API

The system uses the GitHub Releases API:

```bash
# Used endpoint
https://api.github.com/repos/username/repo/releases/latest

# Download tarball
https://github.com/username/repo/releases/latest/download/phpharbor.tar.gz
```

**Note:** GitHub API has rate limits:
- 60 requests/hour for unauthenticated IPs
- 5000 requests/hour for authenticated users

## Security

### Checks during update

1. **Connection check**: Verifies GitHub is reachable
2. **Version validation**: Checks that the release exists
3. **User confirmation**: Requires confirmation before proceeding
4. **Automatic backup**: Saves configurations before update
5. **Manual rollback**: In case of problems, restore from backup

### If there are problems

If the update fails:

```bash
# Configurations are in a temporary directory
# The path is shown during the update

# Manual restore
cp /tmp/backup-XXXX/.config .
cp /tmp/backup-XXXX/.env proxy/

# Or reinstall from scratch
curl -fsSL https://raw.githubusercontent.com/username/repo/main/install.sh | bash
```

## Future Automatic Updates

Possible improvements:

### Automatic check at startup

Add to `phpharbor`:

```bash
# Check updates every 7 days
check_updates_periodically() {
    local last_check_file="$SCRIPT_DIR/.last_update_check"
    if [ ! -f "$last_check_file" ] || [ $(( $(date +%s) - $(stat -f %m "$last_check_file" 2>/dev/null || echo 0) )) -gt 604800 ]; then
        print_info "Checking for updates..."
        update_check_silent
        touch "$last_check_file"
    fi
}
```

### Desktop notifications

On macOS:

```bash
osascript -e 'display notification "New version available!" with title "PHPHarbor"'
```

On Linux:

```bash
notify-send "PHPHarbor" "New version available!"
```

## Testing

Complete test of the update system:

```bash
# 1. Simulate old version
sed -i.bak 's/VERSION=".*"/VERSION="1.0.0"/' phpharbor

# 2. Verify check
./phpharbor update check

# 3. Verify changelog
./phpharbor update changelog

# 4. Test install (if you have a release)
./phpharbor update install

# 5. Verify updated version
./phpharbor version
```

## FAQ

### Will the update delete my projects?

No. Projects in `projects/` are completely preserved. Even if you have projects in a custom directory (configured with `setup config`), that directory is not touched.

### Do I need to restart the containers?

No. Containers remain running. The update only affects scripts and configuration files.

### Can I downgrade to a previous version?

Yes, but manually:

```bash
# Download specific version
curl -fsSL https://github.com/username/repo/releases/download/v2.0.0/phpharbor.tar.gz | tar -xz
```

### Does the update work offline?

No. Internet connection is required to download from GitHub.

## Useful Links

- GitHub Releases: `https://github.com/username/repo/releases`
- GitHub API: `https://docs.github.com/en/rest/releases`
- Semantic Versioning: `https://semver.org`
