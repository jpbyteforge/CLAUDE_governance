"""pretool-guardrails — Deterministic enforcement of token economy rules.
No LLM. Enforces: dedicated tools over bash, Edit over Write, Sonnet+ agent quota.
"""
import sys
import json
import os
import re
import tempfile
import time
from pathlib import Path


def block(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(2)

_COMPLEX      = re.compile(r"[|]|&&|;")
_BASH_READ    = re.compile(r"^(cat|head|tail)\b")
_TAIL_FOLLOW  = re.compile(r"^tail\s+(-\S*f\S*|--follow)\b")
_BASH_GREP    = re.compile(r"^(grep|rg|egrep|fgrep)\b")
_BASH_FIND    = re.compile(r"^find\b")
_BASH_FIND_OK = re.compile(r"-delete|-exec|xargs")
_BASH_SED     = re.compile(r"^sed\s+(-i|--in-place)\b")
_BASH_AWK     = re.compile(r"^awk\b")
_READONLY_AGENTS = {"Explore"}


def check_bash(command: str) -> None:
    command = command.strip()
    # P2: Strip quoted strings — handles \" escapes inside double-quotes
    try:
        if len(command) > 4000:
            stripped = command
        else:
            stripped = re.sub(r"'[^']*'", "''",
                        re.sub(r'"(?:[^"\\]|\\.)*"', '""', command))
    except Exception:
        stripped = command
    # Split on unquoted pipes, logical operators, semicolons
    segments = re.split(r'\s*(?:\|{1,2}|&&|;)\s*', stripped)
    # P1: Enforce read/grep/awk only on first segment (i==0).
    # After a pipe these filter stdout — legitimate, no tool equivalent.
    # find and sed -i always operate on files, enforced at every position.
    # Known gap (FN-1): `true | grep pattern file` bypasses the check.
    for i, segment in enumerate(segments):
        segment = segment.strip()
        if not segment:
            continue
        first = segment.split()[0] if segment.split() else ""
        if i == 0:
            # P3: Allow tail -f / tail --follow (streaming, no Read equivalent)
            if _BASH_READ.match(segment) and not _TAIL_FOLLOW.match(segment):
                block(f"Blocked: use Read instead of '{first}'.")
            if _BASH_GREP.match(segment):
                block(f"Blocked: use Grep instead of '{first}'.")
            if _BASH_AWK.match(segment):
                block("Blocked: use Grep or Edit instead of awk.")
        if _BASH_FIND.match(segment) and not _BASH_FIND_OK.search(segment):
            block("Blocked: use Glob instead of find.")
        if _BASH_SED.match(segment):
            block("Blocked: use Edit instead of 'sed -i'.")


def check_write(file_path: str) -> None:
    # P7: Early-exit at threshold instead of reading entire file
    p = Path(file_path)
    if not p.exists():
        return
    THRESHOLD = 50
    try:
        with p.open(encoding="utf-8", errors="ignore") as fh:
            for i, _ in enumerate(fh, 1):
                if i > THRESHOLD:
                    block(f"Blocked: existing file exceeds {THRESHOLD} lines. Use Edit instead of Write.")
    except Exception:
        pass


def _acquire_lock(lock_path: Path, timeout: float = 2.0) -> int:
    """Acquire an exclusive lock file atomically. Returns fd or -1."""
    deadline = time.monotonic() + timeout
    while True:
        try:
            fd = os.open(str(lock_path), os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            # Write PID for stale-lock detection
            os.write(fd, str(os.getpid()).encode())
            return fd
        except FileExistsError:
            # Check if holding process is still alive
            try:
                pid = int(lock_path.read_text().strip())
                os.kill(pid, 0)
            except (ValueError, OSError, PermissionError):
                # Process dead or PID unreadable — stale lock
                try:
                    lock_path.unlink()
                except OSError:
                    pass
                continue
            if time.monotonic() > deadline:
                return -1  # fail open on timeout
            time.sleep(0.05)


def _release_lock(lock_path: Path, fd: int) -> None:
    if fd >= 0:
        os.close(fd)
    try:
        lock_path.unlink()
    except OSError:
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
    # P5: Atomic lock to prevent race condition on parallel agent launches
    lock_path  = count_file.with_suffix(".lock")
    fd = _acquire_lock(lock_path)
    try:
        count = 0
        if count_file.exists():
            try:
                count = int(count_file.read_text().strip())
            except Exception:
                count = 0
        if count + cost > max_write:
            block(f"Insufficient write subagent quota ({count}/{max_write}, cost={cost}). Use Read/Glob/Grep directly.")
        count_file.write_text(str(count + cost))
    finally:
        _release_lock(lock_path, fd)


def check_governance_version(session_id: str) -> None:
    """Warn if governance files in rules/ have mismatched versions.
    P6: Runs at most once per session via sentinel file."""
    if not session_id:
        return
    sentinel = Path(tempfile.gettempdir()) / f"claude-gov-checked-{session_id}"
    if sentinel.exists():
        return
    rules_dir = Path.home() / ".claude" / "rules"
    if not rules_dir.exists():
        try:
            sentinel.touch()
        except Exception:
            pass
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
        print(f"Governance version mismatch: {detail}", file=sys.stderr)
    try:
        sentinel.touch()
    except Exception:
        pass




def check_push(command: str) -> None:
    """Advisory pre-push checks. Warns to stderr, never blocks (exits 0)."""
    import subprocess
    if not re.search(r'\bgit\s+push\b', command):
        return
    warnings = []
    try:
        result = subprocess.run(
            ["git", "ls-files"], capture_output=True, text=True, timeout=5
        )
        sensitive = [
            line for line in result.stdout.splitlines()
            if re.search(r'(?i)(config\.json|secret|credentials|\.env\b|api[-_]?key)', line)
        ]
        if sensitive:
            warnings.append(f"Sensitive files tracked: {', '.join(sensitive)}")
    except Exception:
        pass
    deploy_script = Path.home() / ".claude" / "deploy_w11.py"
    if deploy_script.exists():
        try:
            result = subprocess.run(
                ["python", str(deploy_script), "--verify"],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode != 0:
                warnings.append("Deploy drift detected - run deploy_w11.py --verify before push")
        except Exception:
            pass
    if warnings:
        print("[push-advisory]", file=sys.stderr)
        for w in warnings:
            print(f"  WARN: {w}", file=sys.stderr)

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
        check_push(tool_input.get("command", ""))
    elif tool_name == "Write":
        check_write(tool_input.get("file_path", ""))
    elif tool_name == "Agent":
        check_agent(tool_input, session_id)

    # P6: Run governance integrity check once per session
    check_governance_version(session_id)

    sys.exit(0)

if __name__ == "__main__":
    main()
