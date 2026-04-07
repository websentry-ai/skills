#!/usr/bin/env bash
set -euo pipefail

# build-skill installer
# Copies agents, commands, and skills into your ~/.claude directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

echo "build-skill installer"
echo "====================="
echo ""
echo "Installing to: $CLAUDE_DIR"
echo ""

# Create directories if they don't exist
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/commands"

# Track what we install
INSTALLED=()
SKIPPED=()

install_file() {
    local src="$1"
    local dest="$2"
    local name="$3"

    if [[ -f "$dest" ]]; then
        echo "  [EXISTS] $name — $dest already exists"
        read -r -p "  Overwrite? (y/N): " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            cp "$src" "$dest"
            INSTALLED+=("$name (overwritten)")
        else
            SKIPPED+=("$name")
        fi
    else
        cp "$src" "$dest"
        INSTALLED+=("$name")
    fi
}

# Install agents
echo "Installing agents..."
for agent_file in "$SCRIPT_DIR"/agents/*.md; do
    filename="$(basename "$agent_file")"
    agent_name="${filename%.md}"
    install_file "$agent_file" "$CLAUDE_DIR/agents/$filename" "agent: $agent_name"
done

echo ""

# Install commands
echo "Installing commands..."
for cmd_file in "$SCRIPT_DIR"/commands/*.md; do
    filename="$(basename "$cmd_file")"
    cmd_name="${filename%.md}"
    install_file "$cmd_file" "$CLAUDE_DIR/commands/$filename" "command: /$cmd_name"
done

echo ""

# Summary
echo "====================="
echo "Installation complete"
echo ""

if [[ ${#INSTALLED[@]} -gt 0 ]]; then
    echo "Installed:"
    for item in "${INSTALLED[@]}"; do
        echo "  + $item"
    done
fi

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo ""
    echo "Skipped (already existed):"
    for item in "${SKIPPED[@]}"; do
        echo "  - $item"
    done
fi

echo ""
echo "Usage: In Claude Code, type /build to run the full pipeline."
echo ""
echo "Optional: If you use gstack, /build will auto-detect the /ship skill"
echo "and use it for PR creation. Otherwise, it falls back to a built-in"
echo "gh-based PR workflow."
