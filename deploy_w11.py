"""Deploy CLAUDE_governance to %USERPROFILE%\\.claude\\ (Windows 11)
Usage: python deploy_w11.py [--dry-run | --verify]
  --dry-run   Show what would be deployed without changing anything
  --verify    Compare repo source vs live target, report drift
"""
import filecmp
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent
TARGET = Path.home() / ".claude"
DRY_RUN = "--dry-run" in sys.argv
VERIFY = "--verify" in sys.argv

_drift = []


def deploy(src: Path, dst: Path) -> None:
    if VERIFY:
        if not dst.exists():
            _drift.append(f"[MISSING]  {dst}  (source: {src})")
        elif not filecmp.cmp(src, dst, shallow=False):
            _drift.append(f"[CHANGED]  {dst}  (differs from {src})")
        return
    if DRY_RUN:
        print(f"[dry-run] {src} -> {dst}")
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    print(f"deployed: {dst}")


# Shared
deploy(REPO / "shared" / "CLAUDE.md", TARGET / "CLAUDE.example.md")
_policy = REPO / "shared" / "policy-limits.json"
if _policy.exists():
    deploy(_policy, TARGET / "policy-limits.json")

# Rules (v2.2: invariants + rules + inline glossary; manifestos in archive/)
for f in (REPO / "shared" / "rules").glob("*.md"):
    deploy(f, TARGET / "rules" / f.name)

# Reference (on-demand, not auto-loaded)
for f in (REPO / "shared" / "reference").glob("*.md"):
    deploy(f, TARGET / "reference" / f.name)

# Archive (rollback only)
for f in (REPO / "shared" / "archive").glob("*.md"):
    deploy(f, TARGET / "archive" / f.name)

# Templates
for f in (REPO / "shared" / "templates").glob("*"):
    deploy(f, TARGET / "templates" / f.name)

# Skills
for f in (REPO / "shared" / "skills").rglob("SKILL.md"):
    skill = f.parent.name
    deploy(f, TARGET / "skills" / skill / "SKILL.md")

# Commands
for f in (REPO / "shared" / "commands").glob("*.md"):
    deploy(f, TARGET / "commands" / f.name)

# Hooks (W11)
for f in (REPO / "hooks" / "w11").glob("*"):
    deploy(f, TARGET / "hooks" / f.name)

# Settings (W11) — deploy as example only; never overwrite live settings.json
deploy(REPO / "settings" / "w11" / "settings.example.json", TARGET / "settings.example.json")

# Stop hook
deploy(REPO / "hooks" / "w11" / "session-end.py", TARGET / "hooks" / "session-end.py")

# Bin (W11)
for f in (REPO / "bin" / "w11").glob("*"):
    deploy(f, TARGET / "bin" / f.name)

if VERIFY:
    if _drift:
        print(f"DRIFT DETECTED — {len(_drift)} file(s):")
        for d in _drift:
            print(f"  {d}")
        sys.exit(1)
    else:
        print("OK — no drift between repo and live.")
        sys.exit(0)

print("done.")
