"""
verify_audit.py — Hash-chain integrity checker for incident_log.jsonl

Usage:
    python verify_audit.py [--log PATH] [--seal]

Options:
    --log PATH   Path to incident_log.jsonl (default: ../.claude/incident_log.jsonl)
    --seal       Rewrite log with sequence + previous_hash populated on all entries

Hash convention:
    previous_hash = SHA-256 of the raw JSON string of the previous entry (as stored).
    First entry: previous_hash = "genesis"
    Legacy entries without previous_hash: treated as opaque blobs; hash computed from raw line.
"""

import hashlib
import json
import sys
from pathlib import Path

DEFAULT_LOG = Path(__file__).parent.parent / "incident_log.jsonl"


def _sha256(s: str) -> str:
    return hashlib.sha256(s.encode()).hexdigest()


def load_lines(path: Path) -> list[str]:
    return [line for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def verify_integrity(path: Path) -> bool:
    lines = load_lines(path)
    if not lines:
        print("Log is empty.")
        return True

    ok = True
    prev_hash = "genesis"
    for i, raw in enumerate(lines, start=1):
        try:
            entry = json.loads(raw)
        except json.JSONDecodeError as e:
            print(f"  [FAIL] line {i}: invalid JSON — {e}")
            ok = False
            continue

        recorded = entry.get("previous_hash")
        if recorded is None:
            # Legacy entry — skip chain check, update rolling hash
            prev_hash = _sha256(raw)
            print(f"  [SKIP] line {i}: no previous_hash (legacy entry) — hash computed for chain")
            continue

        if recorded != prev_hash:
            print(f"  [FAIL] line {i}: chain broken — expected {prev_hash[:16]}... got {recorded[:16]}...")
            ok = False
        else:
            seq = entry.get("sequence", "?")
            print(f"  [OK]   line {i} (seq={seq}): chain valid")

        prev_hash = _sha256(raw)

    return ok


def seal(path: Path) -> None:
    """Rewrite log populating sequence and previous_hash on every entry."""
    lines = load_lines(path)
    sealed: list[str] = []
    prev_hash = "genesis"

    for i, raw in enumerate(lines, start=1):
        entry = json.loads(raw)
        entry["sequence"] = i
        entry["previous_hash"] = prev_hash
        # Canonical serialisation for hashing (no trailing spaces, sorted keys for stability)
        canonical = json.dumps(entry, separators=(",", ":"), ensure_ascii=False)
        sealed.append(canonical)
        prev_hash = _sha256(canonical)

    path.write_text("\n".join(sealed) + "\n", encoding="utf-8")
    print(f"Sealed {len(sealed)} entries. Final hash: {prev_hash[:16]}...")


def main() -> None:
    args = sys.argv[1:]
    log_path = DEFAULT_LOG
    do_seal = False

    i = 0
    while i < len(args):
        if args[i] == "--log" and i + 1 < len(args):
            log_path = Path(args[i + 1])
            i += 2
        elif args[i] == "--seal":
            do_seal = True
            i += 1
        else:
            i += 1

    if not log_path.exists():
        print(f"Log not found: {log_path}")
        sys.exit(1)

    if do_seal:
        seal(log_path)
    else:
        print(f"Verifying: {log_path}")
        ok = verify_integrity(log_path)
        sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
