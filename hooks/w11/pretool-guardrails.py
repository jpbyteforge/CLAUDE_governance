"""pretool-guardrails — Deterministic enforcement of token economy rules.
No LLM. Enforces: dedicated tools over bash, Edit over Write, Sonnet+ agent quota.
"""
import sys
import json
import re
import tempfile
from pathlib import Path


def block(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(2)

_COMPLEX     = re.compile(r"[|]|&&|;")
_BASH_READ   = re.compile(r"^(cat|head|tail)\b")
_BASH_GREP   = re.compile(r"^(grep|rg|egrep|fgrep)\b")
_BASH_FIND   = re.compile(r"^find\b")
_BASH_FIND_OK = re.compile(r"-delete|-exec|xargs")
_BASH_SED    = re.compile(r"^sed\s+(-i|--in-place)\b")
_BASH_AWK    = re.compile(r"^awk\b")
_READONLY_AGENTS = {"Explore"}


def check_bash(command: str) -> None:
    command = command.strip()
    # Strip quoted strings to avoid false positives on keywords inside quotes
    try:
        stripped = re.sub(r"'[^']*'", '""', re.sub(r'"[^"]*"', '""', command))
    except Exception:
        stripped = command
    # Split on unquoted pipes, logical operators, semicolons
    segments = re.split(r'\s*(?:\|{1,2}|&&|;)\s*', stripped)
    for segment in segments:
        segment = segment.strip()
        if not segment:
            continue
        first = segment.split()[0] if segment.split() else ""
        if _BASH_READ.match(segment):
            block(f"Blocked: use Read instead of '{first}'.")
        if _BASH_GREP.match(segment):
            block(f"Blocked: use Grep instead of '{first}'.")
        if _BASH_FIND.match(segment) and not _BASH_FIND_OK.search(segment):
            block("Blocked: use Glob instead of find.")
        if _BASH_SED.match(segment):
            block("Blocked: use Edit instead of 'sed -i'.")
        if _BASH_AWK.match(segment):
            block("Blocked: use Grep or Edit instead of awk.")


def check_write(file_path: str) -> None:
    p = Path(file_path)
    if not p.exists():
        return
    try:
        with p.open(encoding="utf-8", errors="ignore") as fh:
            lines = sum(1 for _ in fh)
        if lines > 50:
            block(f"Blocked: existing file with {lines} lines. Use Edit instead of Write.")
    except Exception:
        pass


def check_agent(tool_input: dict, session_id: str) -> None:
    model         = tool_input.get("model", "")
    subagent_type = tool_input.get("subagent_type", "")
    model_l       = model.lower()

    # Haiku read-only: unlimited
    if "haiku" in model_l or subagent_type in _READONLY_AGENTS:
        return
    if not session_id:
        return

    # Opus counts double (high cost); Sonnet counts 1
    cost       = 2 if "opus" in model_l else 1
    max_write  = 10
    count_file = Path(tempfile.gettempdir()) / f"claude-agents-write-{session_id}"
    count = 0
    if count_file.exists():
        try:
            count = int(count_file.read_text().strip())
        except Exception:
            count = 0
    if count + cost > max_write:
        block(f"Insufficient write subagent quota ({count}/{max_write}, cost={cost}). Use Read/Glob/Grep directly.")
    count_file.write_text(str(count + cost))


def check_governance_version() -> None:
    """Warn if governance files in rules/ have mismatched versions."""
    rules_dir = Path.home() / ".claude" / "rules"
    if not rules_dir.exists():
        return
    versions = {}
    for f in rules_dir.glob("*.md"):
        try:
            text = f.read_text(encoding="utf-8", errors="ignore")
            for line in text.splitlines()[:10]:
                if line.startswith("version:"):
                    versions[f.name] = line.split(":", 1)[1].strip()
                    break
        except Exception:
            pass
    unique = set(versions.values())
    if len(unique) > 1:
        detail = ", ".join(f"{k}={v}" for k, v in sorted(versions.items()))
        print(f"⚠️ Governance version mismatch: {detail}", file=sys.stderr)


def main() -> None:
    try:
        data = json.loads(sys.stdin.read())
    except Exception:
        sys.exit(0)

    tool_name  = data.get("tool_name", "")
    tool_input = data.get("tool_input", {})
    session_id = data.get("session_id", "")

    if tool_name == "Bash":
        check_bash(tool_input.get("command", ""))
    elif tool_name == "Write":
        check_write(tool_input.get("file_path", ""))
    elif tool_name == "Agent":
        check_agent(tool_input, session_id)

    # Run governance integrity check on first tool call (lightweight)
    check_governance_version()

    sys.exit(0)

if __name__ == "__main__":
    main()
