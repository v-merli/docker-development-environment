#!/bin/bash

# Script per aprire un progetto in VS Code con configurazione debug corretta

if [ $# -eq 0 ]; then
    echo "Usage: ./code-project.sh <project-name>"
    echo ""
    echo "Available projects:"
    ls -1 projects/
    exit 1
fi

PROJECT_NAME=$1
PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/projects/$PROJECT_NAME"

if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Project '$PROJECT_NAME' not found in projects/"
    exit 1
fi

echo "🚀 Opening project '$PROJECT_NAME' in VS Code..."
code "$PROJECT_PATH"
