#!/usr/bin/env bash
# Deploy CLAUDE_governance to ~/.claude/ (WSL)
# Usage: ./deploy.sh [--dry-run]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

deploy() {
    local src="$1" dst="$2"
    if $DRY_RUN; then
        echo "[dry-run] $src → $dst"
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "deployed: $dst"
    fi
}

# Shared
deploy "$REPO_DIR/shared/CLAUDE.md"          "$TARGET/CLAUDE.example.md"
deploy "$REPO_DIR/shared/policy-limits.json" "$TARGET/policy-limits.json"

# Rules
deploy "$REPO_DIR/shared/rules/manifesto-governance.md" "$TARGET/rules/manifesto-governance.md"

# Skills
for f in "$REPO_DIR"/shared/skills/*/SKILL.md; do
    skill="$(basename "$(dirname "$f")")"
    deploy "$f" "$TARGET/skills/$skill/SKILL.md"
done

# Commands
for f in "$REPO_DIR"/shared/commands/*.md; do
    cmd="$(basename "$f" .md)"
    deploy "$f" "$TARGET/commands/$cmd.md"
done

# Hooks (WSL)
for f in "$REPO_DIR"/hooks/wsl/*; do
    deploy "$f" "$TARGET/hooks/$(basename "$f")"
done

# Settings (WSL) — deploy as examples only; never overwrite live settings
[ -f "$REPO_DIR/settings/wsl/settings.json" ]       && deploy "$REPO_DIR/settings/wsl/settings.json"       "$TARGET/settings.example.json"
[ -f "$REPO_DIR/settings/wsl/settings.local.json" ] && deploy "$REPO_DIR/settings/wsl/settings.local.json" "$TARGET/settings.local.example.json"

# Bin (WSL)
for f in "$REPO_DIR"/bin/wsl/*; do
    deploy "$f" "$TARGET/bin/$(basename "$f")"
done

echo "done."
