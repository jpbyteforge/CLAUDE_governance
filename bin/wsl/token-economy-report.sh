#!/bin/bash
# token-economy-report.sh — Audit token economy decisions

LOG="/home/jorge/.claude/token-economy.log"

usage() {
    echo "Usage: token-economy-report [status|escalations|summary|daily]"
    echo ""
    echo "  status      — Show last 10 decisions"
    echo "  escalations — Show only escalations (tier changes)"
    echo "  summary     — Distribution of tiers used"
    echo "  daily       — Last 24h summary"
    exit 0
}

[ -z "${1:-}" ] && usage

case "$1" in
    status)
        echo "=== Last 10 Model Decisions ==="
        tail -10 "$LOG" | awk -F' \\| ' '{printf "%s | %-14s | %s\n", $1, $3, substr($4, 1, 60)}'
        ;;
    escalations)
        echo "=== Escalations (Tier Changes) ==="
        grep -v "→HAIKU→HAIKU\|→SONNET→SONNET\|→OPUS→OPUS" "$LOG" 2>/dev/null | \
        awk -F'|' '{printf "%s | %s\n", $1, $3}' || echo "(No escalations logged)"
        ;;
    summary)
        echo "=== Distribution of Tier Usage ==="
        echo ""
        echo "Final Tier Distribution:"
        awk -F'→' '{print $NF}' "$LOG" | sed 's/ .*//' | sort | uniq -c | sort -rn | \
            awk '{printf "  %-10s : %3d uses\n", $2, $1}'
        echo ""
        echo "Escalation Count:"
        awk -F'|' '$3 !~ /→[A-Z]+→[A-Z]+$|→HAIKU→HAIKU$|→SONNET→SONNET$|→OPUS→OPUS$/ {count++} END {print "  Escalations: " (count ? count : "0")}' "$LOG"
        ;;
    daily)
        echo "=== Last 24 Hours Summary ==="
        YESTERDAY=$(date -d '1 day ago' '+%Y-%m-%d')
        TODAY=$(date '+%Y-%m-%d')
        echo ""
        echo "Since $YESTERDAY:"
        grep -E "$YESTERDAY|$TODAY" "$LOG" | wc -l | awk '{print "  Total decisions: " $1}'
        echo ""
        echo "Tier distribution (last 24h):"
        grep -E "$YESTERDAY|$TODAY" "$LOG" | awk -F'→' '{print $NF}' | sed 's/ .*//' | sort | uniq -c | sort -rn | \
            awk '{printf "    %-10s : %3d\n", $2, $1}'
        ;;
    *)
        echo "Unknown command: $1"
        usage
        ;;
esac
