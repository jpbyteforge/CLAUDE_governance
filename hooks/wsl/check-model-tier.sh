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
if echo "$PROMPT_LOWER" | grep -qE '(implementa|debug|corrig|refactor|testa|review|compar|analisa[^.*impacto]|infra|setup|configur|deploy|backend|frontend|api|database|schema|query|optim|perform|secure)'; then
    TIER="SONNET"
fi

# Escalate to OPUS: architecture, cross-system, governance, deep analysis
if echo "$PROMPT_LOWER" | grep -qE '(arquitetura|arquitectura|architect|multi.?sistem|cross.?system|refactor.*(todo|tudo|all|global|projet)|design.*(system|arqui)|audit[ao]?[r ]|governa[çn]|converg|migra.*(sistema|system|project)|integra.*(entre|across|cross|multi)|depend.*(graph|circular|cycle)|trade.?off|investig|reflete|refle[cxs]|analisa.*(impacto|risco|trade|sistem|project)|avalia.*(estrateg|sistem|impacto)|reestrutur|redesign|consolid.*(sistem|modul|projet)|unific|planei?a.*(estrateg|migra|sistem)|compara.*(abordagen|approach|estrateg|sistem)|roadmap|blueprint|manifest|diagn[oó]stic.*(profund|deep|root)|d[ií]vid.*(t[eé]cnic|tech)|debt.*(t[eé]cnic|tech)|complex.*(debug|analy)|pr[ií]ncip.*(design|solid|dry|separation))'; then
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
