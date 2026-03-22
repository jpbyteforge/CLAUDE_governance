#!/bin/bash
# check-model-tier.sh — Deterministic model advisor (no LLM, <10ms)
# Classifies prompt complexity via pattern matching.
# Advisory only (exit 0, stdout) — injects recommendation into Claude's context.
# Claude sees the tier and advises the user if the active model is inadequate.

set -uo pipefail

INPUT=$(cat)
command -v jq &>/dev/null || exit 0

PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# Skip: empty, slash commands
[ -z "$PROMPT" ] && exit 0
[[ "$PROMPT" == /* ]] && exit 0

# --- Deterministic classification (HAIKU-FIRST bias) ---
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')
PROMPT_LEN=${#PROMPT}

# Default: HAIKU (lightweight-first philosophy)
TIER="HAIKU"

# Escalate to SONNET: medium complexity, implementation, debugging
if echo "$PROMPT_LOWER" | grep -qE '(implement|debug|fix|correct|refactor|test|review|compar|analys[ei]|infra|setup|configur|deploy|backend|frontend|api|database|schema|query|optim|perform|secure)'; then
    TIER="SONNET"
fi

# Escalate to OPUS: architecture, cross-system, governance, deep analysis
if echo "$PROMPT_LOWER" | grep -qE '(architect|multi.?system|cross.?system|refactor.*(all|global|project)|design.*(system|arch)|audit|governance|converg|migrat.*(system|project)|integrat.*(between|across|cross|multi)|depend.*(graph|circular|cycle)|trade.?off|investigat|reflect|analys[ei].*(impact|risk|trade|system|project)|evaluat.*(strateg|system|impact)|restructur|redesign|consolid.*(system|modul|project)|unif|plan.*(strateg|migrat|system)|compar.*(approach|strateg|system)|roadmap|blueprint|manifest|diagnos.*(deep|root)|tech.?debt|debt.*(tech)|complex.*(debug|analy)|principl.*(design|solid|dry|separation))'; then
    TIER="OPUS"
fi

# Model ID helper (before override)
case "$TIER" in
    HAIKU)  MODEL="claude-haiku-4-5-20251001" ;;
    SONNET) MODEL="claude-sonnet-4-6" ;;
    OPUS)   MODEL="claude-opus-4-6" ;;
esac

# Store global tier (before override)
GLOBAL_TIER="$TIER"
GLOBAL_MODEL="$MODEL"

# Apply local CLAUDE.md overrides (if exist)
RESOLVER="$HOME/.claude/hooks/resolve-model-policy.sh"
if [ -x "$RESOLVER" ]; then
    RESOLVED=$("$RESOLVER" "$TIER" "$MODEL" 2>/dev/null)
    if [ -n "$RESOLVED" ]; then
        TIER=$(echo "$RESOLVED" | cut -d'|' -f1)
        MODEL=$(echo "$RESOLVED" | cut -d'|' -f2)
    fi
fi

# Log decision to audit trail
AUDIT_LOG="$HOME/.claude/token-economy.log"
if [ -w "$(dirname "$AUDIT_LOG")" ]; then
    {
        printf '%s | %s | %s→%s | %.80s\n' \
            "$(date '+%Y-%m-%d %H:%M:%S')" \
            "MODEL_SELECT" \
            "$GLOBAL_TIER" \
            "$TIER" \
            "$PROMPT"
    } >> "$AUDIT_LOG" 2>/dev/null || true
fi

# Advisory: stdout is injected into Claude's context
echo "[MODEL_TIER] $TIER | /model $MODEL"
exit 0
