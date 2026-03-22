"""token-economy-report — Audit token economy decisions.

Usage:
  python token-economy-report.py status       Last 10 decisions
  python token-economy-report.py escalations  Only tier changes
  python token-economy-report.py summary      Distribution of tiers
  python token-economy-report.py daily        Last 24h summary
"""
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
from collections import Counter
from datetime import datetime, timedelta
from pathlib import Path

LOG = Path.home() / ".claude" / "token-economy.log"


def read_lines() -> list[str]:
    if not LOG.exists():
        print(f"Log não encontrado: {LOG}")
        sys.exit(1)
    return LOG.read_text(encoding="utf-8", errors="ignore").splitlines()


def parse(line: str) -> tuple[str, str, str] | None:
    """Return (ts, transition, prompt) or None."""
    parts = [p.strip() for p in line.split("|")]
    if len(parts) < 4 or parts[1] != "MODEL_SELECT":
        return None
    return parts[0], parts[2], parts[3]


def _split_transition(transition: str) -> list[str]:
    """Handle both '->' (Windows) and '→' (WSL) separators."""
    sep = "→" if "→" in transition else "->"
    return [p.strip() for p in transition.split(sep)]


def final_tier(transition: str) -> str:
    return _split_transition(transition)[-1]


def is_escalation(transition: str) -> bool:
    parts = _split_transition(transition)
    return len(parts) == 2 and parts[0] != parts[1]


def cmd_status() -> None:
    lines = read_lines()[-10:]
    print("=== Last 10 Model Decisions ===")
    for line in lines:
        r = parse(line)
        if r:
            ts, transition, prompt = r
            print(f"{ts} | {transition:<20} | {prompt[:60]}")


def cmd_escalations() -> None:
    print("=== Escalations (Tier Changes) ===")
    found = False
    for line in read_lines():
        r = parse(line)
        if r and is_escalation(r[1]):
            print(f"{r[0]} | {r[1]}")
            found = True
    if not found:
        print("(sem escalações registadas)")


def cmd_summary() -> None:
    print("=== Distribution of Tier Usage ===\n")
    records = [parse(l) for l in read_lines()]
    records = [r for r in records if r]

    tiers = Counter(final_tier(r[1]) for r in records)
    escalations = sum(1 for r in records if is_escalation(r[1]))

    print("Final Tier Distribution:")
    for tier, count in sorted(tiers.items(), key=lambda x: -x[1]):
        print(f"  {tier:<10}: {count:>4} uses")
    print(f"\n  Escalações: {escalations}")


def cmd_daily() -> None:
    cutoff = datetime.now() - timedelta(days=1)
    print(f"=== Last 24 Hours (since {cutoff.strftime('%Y-%m-%d %H:%M')}) ===\n")

    recent = []
    for line in read_lines():
        r = parse(line)
        if not r:
            continue
        try:
            ts = datetime.strptime(r[0], "%Y-%m-%d %H:%M:%S")
            if ts >= cutoff:
                recent.append(r)
        except ValueError:
            pass

    tiers = Counter(final_tier(r[1]) for r in recent)
    print(f"  Total decisões: {len(recent)}\n")
    print("  Tier distribution:")
    for tier, count in sorted(tiers.items(), key=lambda x: -x[1]):
        print(f"    {tier:<10}: {count:>4}")


COMMANDS = {
    "status":      cmd_status,
    "escalations": cmd_escalations,
    "summary":     cmd_summary,
    "daily":       cmd_daily,
}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(__doc__)
        sys.exit(0)
    COMMANDS[sys.argv[1]]()
