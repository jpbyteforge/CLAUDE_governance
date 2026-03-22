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
    if _COMPLEX.search(command):
        return
    first = command.split()[0] if command.split() else ""
    if _BASH_READ.match(command):
        block(f"Bloqueado: usar Read em vez de '{first}'.")
    if _BASH_GREP.match(command):
        block(f"Bloqueado: usar Grep em vez de '{first}'.")
    if _BASH_FIND.match(command) and not _BASH_FIND_OK.search(command):
        block("Bloqueado: usar Glob em vez de find.")
    if _BASH_SED.match(command):
        block("Bloqueado: usar Edit em vez de 'sed -i'.")
    if _BASH_AWK.match(command):
        block("Bloqueado: usar Grep ou Edit em vez de awk.")


def check_write(file_path: str) -> None:
    p = Path(file_path)
    if not p.exists():
        return
    try:
        with p.open(encoding="utf-8", errors="ignore") as fh:
            lines = sum(1 for _ in fh)
        if lines > 50:
            block(f"Bloqueado: ficheiro existente com {lines} linhas. Usar Edit em vez de Write.")
    except Exception:
        pass


def check_agent(tool_input: dict, session_id: str) -> None:
    model         = tool_input.get("model", "")
    subagent_type = tool_input.get("subagent_type", "")
    model_l       = model.lower()

    # Haiku read-only: ilimitado
    if "haiku" in model_l or subagent_type in _READONLY_AGENTS:
        return
    if not session_id:
        return

    # Opus conta duplo (custo elevado); Sonnet conta 1
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
        block(f"Quota de subagents write insuficiente ({count}/{max_write}, custo={cost}). Usar Read/Glob/Grep directos.")
    count_file.write_text(str(count + cost))


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

    sys.exit(0)

if __name__ == "__main__":
    main()
