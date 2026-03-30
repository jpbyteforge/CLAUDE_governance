"""Deploy CLAUDE_governance to %USERPROFILE%\\.claude\\ (Windows 11)

Usage: python deploy_w11.py [--deploy | --verify | --reverse] [--dry-run] [--force]

Modes:
  (default)   Deploy shared/ -> live/ per manifest
  --verify    Compare live vs manifest, report drift (exit 1 if drift)
  --reverse   Sync live -> shared/ for reverse_sync entries in manifest
  --dry-run   Preview any mode without writing
  --force     Skip confirmation on --reverse
"""
import json
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent
TARGET = Path.home() / ".claude"
MANIFEST_PATH = REPO / "shared" / ".manifest.json"

DRY_RUN = "--dry-run" in sys.argv
VERIFY = "--verify" in sys.argv
REVERSE = "--reverse" in sys.argv
FORCE = "--force" in sys.argv

_drift = []
_actions = []


# -- Helpers ------------------------------------------------------------------

def _is_text(path: Path, text_extensions: list) -> bool:
    if path.suffix.lower() in text_extensions:
        return True
    # Extensionless files: check if they look like text (no null bytes in first 8KB)
    if not path.suffix and path.exists():
        try:
            return b"\x00" not in path.read_bytes()[:8192]
        except Exception:
            pass
    return False


def _content_equal(src: Path, dst: Path, text_exts: list) -> bool:
    """Compare files; normalize CRLF for text files."""
    try:
        s = src.read_bytes()
        d = dst.read_bytes()
        if _is_text(src, text_exts):
            s = s.replace(b"\r\n", b"\n")
            d = d.replace(b"\r\n", b"\n")
        return s == d
    except Exception:
        return False


def _normalize_write(src: Path, dst: Path, text_exts: list) -> None:
    """Copy src to dst, normalizing line endings for text files to LF."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    if _is_text(src, text_exts):
        data = src.read_bytes().replace(b"\r\n", b"\n")
        dst.write_bytes(data)
    else:
        shutil.copy2(src, dst)


def _load_manifest() -> dict:
    if not MANIFEST_PATH.exists():
        print(f"WARNING: manifest not found at {MANIFEST_PATH}", file=sys.stderr)
        print("Falling back to legacy hardcoded mappings.", file=sys.stderr)
        return {}
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def _resolve_mapping(mapping: dict) -> list:
    """Resolve a single mapping entry to (src, dst) pairs."""
    pairs = []
    src_pattern = mapping["src"]
    dst_pattern = mapping["dst"]

    if mapping.get("rglob"):
        base = REPO / src_pattern.split("*")[0].rstrip("/")
        glob_part = src_pattern.split("*", 1)[1].lstrip("*/")
        if base.exists():
            for f in base.rglob(glob_part if glob_part else "*"):
                if f.is_file():
                    skill = f.parent.name
                    pairs.append((f, TARGET / dst_pattern / skill / f.name))
    elif mapping.get("glob"):
        base = REPO / str(Path(src_pattern).parent)
        pattern = Path(src_pattern).name
        if base.exists():
            for f in base.glob(pattern):
                if f.is_file():
                    pairs.append((f, TARGET / dst_pattern / f.name))
    else:
        src = REPO / src_pattern
        if src.exists() or not mapping.get("optional"):
            pairs.append((src, TARGET / dst_pattern))
    return pairs


# -- Modes --------------------------------------------------------------------

def do_deploy(manifest: dict) -> None:
    text_exts = manifest.get("text_extensions", [".md", ".py", ".json", ".sh"])

    # Deploy mappings
    for mapping in manifest.get("mappings", []):
        for src, dst in _resolve_mapping(mapping):
            if not src.exists():
                if not mapping.get("optional"):
                    print(f"WARNING: source missing: {src}")
                continue
            if DRY_RUN:
                print(f"[dry-run] {src} -> {dst}")
            else:
                _normalize_write(src, dst, text_exts)
                print(f"deployed: {dst}")

    # Remove tombstones
    for ts in manifest.get("tombstones", []):
        ts_path = TARGET / ts
        if ts_path.exists():
            if DRY_RUN:
                print(f"[dry-run] remove orphan: {ts_path}")
            else:
                ts_path.unlink()
                print(f"removed orphan: {ts_path}")


def do_verify(manifest: dict) -> None:
    text_exts = manifest.get("text_extensions", [".md", ".py", ".json", ".sh"])

    for mapping in manifest.get("mappings", []):
        for src, dst in _resolve_mapping(mapping):
            if not src.exists():
                if not mapping.get("optional"):
                    _drift.append(f"[SRC-MISS] {src}")
                continue
            if not dst.exists():
                _drift.append(f"[MISSING]  {dst}  (source: {src})")
            elif not _content_equal(src, dst, text_exts):
                _drift.append(f"[CHANGED]  {dst}  (differs from {src})")

    # Check tombstones
    for ts in manifest.get("tombstones", []):
        ts_path = TARGET / ts
        if ts_path.exists():
            _drift.append(f"[ORPHAN]   {ts_path}  (should not exist - moved in v2.2)")


def do_reverse(manifest: dict) -> None:
    text_exts = manifest.get("text_extensions", [".md", ".py", ".json", ".sh"])
    entries = manifest.get("reverse_sync", [])
    if not entries:
        print("No reverse_sync entries in manifest.")
        return

    changes = []
    for entry in entries:
        live_path = TARGET / entry["live"]
        src_path = REPO / entry["src"]
        if not live_path.exists():
            print(f"  skip (live missing): {live_path}")
            continue
        if src_path.exists() and _content_equal(live_path, src_path, text_exts):
            continue  # already in sync
        changes.append((live_path, src_path))

    if not changes:
        print("Reverse sync: all files already in sync.")
        return

    print(f"Reverse sync: {len(changes)} file(s) to update:")
    for live, src in changes:
        print(f"  {live} -> {src}")

    if not DRY_RUN:
        if not FORCE:
            resp = input("Proceed? [y/N] ").strip().lower()
            if resp != "y":
                print("Aborted.")
                sys.exit(0)
        for live, src in changes:
            _normalize_write(live, src, text_exts)
            print(f"  synced: {src}")


# -- Legacy fallback ---------------------------------------------------------

def _legacy_deploy() -> None:
    """Fallback when manifest is missing. Deprecated."""

    def deploy(src: Path, dst: Path) -> None:
        if VERIFY:
            if not dst.exists():
                _drift.append(f"[MISSING]  {dst}  (source: {src})")
            elif src.read_bytes().replace(b"\r\n", b"\n") != dst.read_bytes().replace(b"\r\n", b"\n"):
                _drift.append(f"[CHANGED]  {dst}  (differs from {src})")
            return
        if DRY_RUN:
            print(f"[dry-run] {src} -> {dst}")
            return
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        print(f"deployed: {dst}")

    deploy(REPO / "shared" / "CLAUDE.md", TARGET / "CLAUDE.example.md")
    _policy = REPO / "shared" / "policy-limits.json"
    if _policy.exists():
        deploy(_policy, TARGET / "policy-limits.json")
    for d in ["rules", "reference", "archive", "templates", "commands"]:
        p = REPO / "shared" / d
        if p.exists():
            pat = "*.md" if d != "templates" else "*"
            for f in p.glob(pat):
                deploy(f, TARGET / d / f.name)
    for f in (REPO / "shared" / "skills").rglob("SKILL.md"):
        deploy(f, TARGET / "skills" / f.parent.name / "SKILL.md")
    for f in (REPO / "hooks" / "w11").glob("*"):
        deploy(f, TARGET / "hooks" / f.name)
    deploy(REPO / "settings" / "w11" / "settings.example.json", TARGET / "settings.example.json")
    for f in (REPO / "bin" / "w11").glob("*"):
        deploy(f, TARGET / "bin" / f.name)


# -- Main --------------------------------------------------------------------

manifest = _load_manifest()

if not manifest:
    _legacy_deploy()
elif REVERSE:
    do_reverse(manifest)
elif VERIFY:
    do_verify(manifest)
else:
    do_deploy(manifest)

if VERIFY:
    if _drift:
        print(f"DRIFT DETECTED - {len(_drift)} file(s):")
        for d in _drift:
            print(f"  {d}")
        sys.exit(1)
    else:
        print("OK - no drift between repo and live.")
        sys.exit(0)

if not VERIFY and not REVERSE:
    print("done.")
