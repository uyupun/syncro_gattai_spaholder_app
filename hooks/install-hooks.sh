#!/bin/bash
# Script to install Git hooks for the project

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
GIT_HOOKS_DIR="$(git rev-parse --git-dir)/hooks"

echo "📦 Installing Git hooks..."

# Create hooks directory if it doesn't exist
mkdir -p "$GIT_HOOKS_DIR"

# Copy pre-commit hook
if [ -f "$HOOKS_DIR/pre-commit" ]; then
    cp "$HOOKS_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"
    chmod +x "$GIT_HOOKS_DIR/pre-commit"
    echo "✅ pre-commit hook installed"
else
    echo "❌ pre-commit hook file not found"
    exit 1
fi
