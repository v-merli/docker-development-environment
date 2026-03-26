# VS Code Templates

This directory contains VS Code configuration templates that are automatically copied to new projects.

## Available Files

### launch.json
Configuration for debugging with Xdebug 3.x

**Features:**
- Debug listener on port 9003
- Automatic path mapping for Docker (`/var/www/html` → workspace)
- Support for debugging current file
- Optimized for PHPHarbor

**How to use:**
1. In VS Code, open the "Run and Debug" panel (Cmd+Shift+D)
2. Select "Listen for Xdebug (PHPHarbor)"
3. Press F5 to start the listener
4. In the browser add `?XDEBUG_TRIGGER=1` to the URL
5. Use F10 to navigate line by line

### XDEBUG-GUIDE.md
Complete guide to using Xdebug with VS Code and PHPHarbor

**Contents:**
- Step-by-step VS Code configuration
- PHP Debug extension installation
- How to set breakpoints
- Debug controls (F5, F10, F11, etc.)
- Common issue troubleshooting
- Tutorials and practical examples
- Links to useful resources

**Note:** This file is copied to the project root (`app/XDEBUG-GUIDE.md`) for easy access.

## Adding New Templates

To add new VS Code configurations:

1. Create the file in `shared/templates/vscode/`
2. Modify `cli/create.sh` to copy it during project creation
3. Document its usage in this README
