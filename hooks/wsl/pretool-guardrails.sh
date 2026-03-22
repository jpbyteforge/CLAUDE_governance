#!/bin/bash
# pretool-guardrails.sh — Deterministic enforcement of token economy rules
#
# 1. Blocks Bash when dedicated tools (Read/Glob/Grep/Edit/Write) suffice
# 2. Blocks Write on existing files >50 lines (forces Edit for diff efficiency)
# 3. Limits subagent spawning per session (MAX_AGENTS configurable)
#
# Fires on every PreToolUse event. Must be fast (no ollama, no network).

set -uo pipefail

# Fast-path: skip guardrails in static/doc-only projects
case "$PWD" in
    */pon|*/pon/*) exit 0 ;;
esac

INPUT=$(cat)
command -v jq &>/dev/null || exit 0

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
[ -z "$TOOL_NAME" ] && exit 0

case "$TOOL_NAME" in

    Bash)
        COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
        [ -z "$COMMAND" ] && exit 0

        # Allow complex commands (pipes, chaining, subshells)
        if echo "$COMMAND" | grep -qE '[|]|&&|[;]'; then
            exit 0
        fi

        # Extract first word of the command
        FIRST_WORD=$(echo "$COMMAND" | awk '{print $1}')

        case "$FIRST_WORD" in
            cat|head|tail)
                echo "Bloqueado: usar Read em vez de '$FIRST_WORD'." >&2
                exit 2
                ;;
            grep|rg|egrep|fgrep)
                echo "Bloqueado: usar Grep em vez de '$FIRST_WORD'." >&2
                exit 2
                ;;
            find)
                # Allow find with destructive/exec operations
                if echo "$COMMAND" | grep -qE '(-delete|-exec|xargs)'; then
                    exit 0
                fi
                echo "Bloqueado: usar Glob em vez de find." >&2
                exit 2
                ;;
            sed)
                # Only block in-place editing
                if echo "$COMMAND" | grep -qE 'sed\s+(-i|--in-place)'; then
                    echo "Bloqueado: usar Edit em vez de 'sed -i'." >&2
                    exit 2
                fi
                ;;
            awk)
                echo "Bloqueado: usar Grep ou Edit em vez de awk." >&2
                exit 2
                ;;
        esac
        ;;

    Write)
        FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
        if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
            LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null || echo 0)
            if [ "$LINE_COUNT" -gt 50 ]; then
                echo "Bloqueado: ficheiro existente com ${LINE_COUNT} linhas. Usar Edit (diff) em vez de Write (ficheiro inteiro)." >&2
                exit 2
            fi
        fi
        ;;

    Agent)
        SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
        [ -z "$SESSION_ID" ] && exit 0

        # Read-only subagents (Haiku) are unlimited — they protect the main context
        AGENT_MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // empty')
        if [ "$AGENT_MODEL" = "haiku" ]; then
            exit 0
        fi

        # Write subagents (Sonnet+) are limited per session
        MAX_WRITE_AGENTS=10
        COUNT_FILE="/tmp/claude-agents-write-${SESSION_ID}"

        COUNT=0
        [ -f "$COUNT_FILE" ] && COUNT=$(cat "$COUNT_FILE" 2>/dev/null)

        if [ "$COUNT" -ge "$MAX_WRITE_AGENTS" ]; then
            echo "Limite de subagents de escrita atingido ($COUNT/$MAX_WRITE_AGENTS). Usar subagent Haiku (read-only) ou resolver inline." >&2
            exit 2
        fi

        echo "$((COUNT + 1))" > "$COUNT_FILE"
        ;;

esac

exit 0
