#!/usr/bin/env bash
set -eo pipefail

# skills installer
# Copies agents and commands into your ~/.claude directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
FORCE=false

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --force|-y) FORCE=true ;;
        --help|-h)
            echo "Usage: ./install.sh [--force|-y]"
            echo "  --force, -y   Overwrite existing files without prompting"
            exit 0
            ;;
    esac
done

echo "skills installer"
echo "================"
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
        if [[ "$FORCE" == "true" ]]; then
            cp "$src" "$dest"
            INSTALLED+=("$name (overwritten)")
        else
            echo "  [EXISTS] $name — $dest already exists"
            read -r -p "  Overwrite? (y/N): " answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                cp "$src" "$dest"
                INSTALLED+=("$name (overwritten)")
            else
                SKIPPED+=("$name")
            fi
        fi
    else
        cp "$src" "$dest"
        INSTALLED+=("$name")
    fi
}

# Install agents
echo "Installing agents..."
for agent_file in "$SCRIPT_DIR"/agents/*.md; do
    [[ -f "$agent_file" ]] || continue
    filename="$(basename "$agent_file")"
    agent_name="${filename%.md}"
    install_file "$agent_file" "$CLAUDE_DIR/agents/$filename" "agent: $agent_name"
done

echo ""

# Install commands (recursive — subdirectories namespace child commands, e.g.
# commands/ux-laws-review/trust-and-honesty.md → /ux-laws-review:trust-and-honesty)
echo "Installing commands..."
while IFS= read -r cmd_file; do
    rel_path="${cmd_file#$SCRIPT_DIR/commands/}"
    dest="$CLAUDE_DIR/commands/$rel_path"
    mkdir -p "$(dirname "$dest")"
    cmd_name="${rel_path%.md}"
    cmd_name="${cmd_name//\//:}"
    install_file "$cmd_file" "$dest" "command: /$cmd_name"
done < <(find "$SCRIPT_DIR/commands" -type f -name '*.md')

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
echo "Usage:"
echo "  /council <spec>  — multi-lens review before you write code"
echo "  /build <task>    — full plan/build/test/review/ship pipeline"
echo ""
echo "Optional: If you use gstack, /build will auto-detect the /ship skill"
echo "and use it for PR creation. Otherwise, it falls back to a built-in"
echo "gh-based PR workflow."
