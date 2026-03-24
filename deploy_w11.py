"""Deploy CLAUDE_governance to %USERPROFILE%\\.claude\\ (Windows 11)
Usage: python deploy_w11.py [--dry-run]
"""
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent
TARGET = Path.home() / ".claude"
DRY_RUN = "--dry-run" in sys.argv


def deploy(src: Path, dst: Path) -> None:
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

# Rules
deploy(REPO / "shared" / "rules" / "manifesto-governance.md",
       TARGET / "rules" / "manifesto-governance.md")

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

print("done.")
