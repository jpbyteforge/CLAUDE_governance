"""apply-model-routing-v3.py — Aplica melhorias de model routing.

Uso:
  python apply-model-routing-v3.py --dry-run
  python apply-model-routing-v3.py --apply
  python apply-model-routing-v3.py --rollback
"""
import sys, shutil, difflib
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")

HOME      = Path.home()
HOOK_FILE = HOME / ".claude" / "hooks" / "check-model-tier.py"
CLAUDE_MD = HOME / ".claude" / "CLAUDE.md"

# ── PATCH A: _SONNET block verbatim replacement ──────────────────────────────
SONNET_OLD = (
    '_SONNET = re.compile(\n'
    '    r"implementa|debug|corrig|refactor|testa|review|compar"\n'
    '    r"|analisa(?![\\s\\S]*(impacto|risco|trade|sistem))|infra|setup|configur|deploy"\n'
    '    r"|backend|frontend|api|database|schema|query|optim|perform|secure",\n'
    '    re.IGNORECASE,\n'
    ')'
)

SONNET_NEW = (
    '_SONNET = re.compile(\n'
    '    r"implementa|debug|corrig|refactor|testa|review|compar"\n'
    '    r"|analisa(?![\\s\\S]*(impacto|risco|trade|sistem))|infra|setup|configur|deploy"\n'
    '    r"|backend|frontend|api|database|schema|query|optim|perform|secure"\n'
    '    r"|cria[\\s\\S]{0,30}(plano|script|ficheiro|funcao|classe|modulo|hook|regra)"\n'
    '    r"|desenvolve|melhora[\\s\\S]{0,30}(sistem|codigo|hook|regra|classif)"\n'
    '    r"|aplica[\\s\\S]{0,30}(mudanca|altera|patch|fix|plano)"\n'
    '    r"|escreve[\\s\\S]{0,20}(codigo|code|script|funcao)"\n'
    '    r"|fecha[\\s\\S]{0,15}(sess|session)",\n'
    '    re.IGNORECASE,\n'
    ')'
)

HAIKU_FAST = (
    '_HAIKU_FAST = re.compile(\n'
    '    r"^(o que [e\\u00e9]|como funciona|qual [e\\u00e9]|quais s[a\\u00e3]o"\n'
    '    r"|lista[\\s,]|explica[\\s,]|descreve[\\s,]|resume[\\s,]|mostra[\\s,]|diz-me"\n'
    '    r"|what is|how does|show me|list |explain |describe )",\n'
    '    re.IGNORECASE,\n'
    ')\n\n\n'
)

CLASSIFY_OLD = (
    'def classify(prompt: str) -> str:\n'
    '    if _OPUS.search(prompt):\n'
    '        return "OPUS"\n'
    '    if _SONNET.search(prompt):\n'
    '        return "SONNET"\n'
    '    return "HAIKU"'
)

CLASSIFY_NEW = (
    'def classify(prompt: str) -> str:\n'
    '    # v3: fast-path HAIKU -- evita SONNET over-firing\n'
    '    if _HAIKU_FAST.match(prompt):\n'
    '        return "HAIKU"\n'
    '    if _OPUS.search(prompt):\n'
    '        return "OPUS"\n'
    '    if _SONNET.search(prompt):\n'
    '        return "SONNET"\n'
    '    return "HAIKU"'
)

# ── PATCH B: CLAUDE.md ───────────────────────────────────────────────────────
ROUTING_SECTION = (
    "\n## Model Routing\n\n"
    "When `[MODEL_TIER]` >= active model tier: execute in main thread (already optimal).\n"
    "When `[MODEL_TIER]` > active model tier AND task needs >5 tool calls OR multi-file write:\n"
    "-> Delegate to `Agent(model=<tier_model>)`. Main thread: classify + synthesize only.\n"
    "-> Pass context summary (<=5 sentences) in the subagent prompt.\n\n"
    "Routing NOT triggered for: explain, list, format, single-file read, commit, rename.\n\n"
)
QUOTA_OLD = "| Code writing | `sonnet` minimum | 1 |"
QUOTA_NEW = "| Code writing | `sonnet` minimum | 3 |"

# ── helpers ──────────────────────────────────────────────────────────────────
def read(p):
    return p.read_text(encoding="utf-8")

def show_diff(label, before, after):
    d = list(difflib.unified_diff(
        before.splitlines(keepends=True),
        after.splitlines(keepends=True),
        fromfile="a/"+label, tofile="b/"+label, n=3))
    print(f"\n--- diff {label} ---")
    print("".join(d[:150]) if d else "(sem alteracoes)")

def patch_hook(src):
    out = src
    if SONNET_OLD in out:
        out = out.replace(SONNET_OLD, SONNET_NEW, 1)
    else:
        print("WARN: bloco _SONNET nao encontrado literalmente", file=sys.stderr)
    if "_HAIKU_FAST" not in out:
        out = out.replace(CLASSIFY_OLD, HAIKU_FAST + CLASSIFY_NEW, 1)
    elif CLASSIFY_OLD in out:
        out = out.replace(CLASSIFY_OLD, CLASSIFY_NEW, 1)
    return out

def patch_md(src):
    marker = "## Context -- do not load preemptively"
    # Try exact match first, then fallback
    for m in ["## Context — do not load preemptively", marker]:
        if m in src:
            if "## Model Routing" not in src:
                src = src.replace(m, ROUTING_SECTION + m, 1)
            break
    return src.replace(QUOTA_OLD, QUOTA_NEW, 1)

def validate_py(path):
    import ast
    try:
        ast.parse(path.read_text(encoding="utf-8"))
        return True
    except SyntaxError as e:
        print(f"SYNTAX ERROR em {path}: {e}", file=sys.stderr)
        return False

# ── modes ─────────────────────────────────────────────────────────────────────
def dry_run():
    show_diff("check-model-tier.py", read(HOOK_FILE), patch_hook(read(HOOK_FILE)))
    show_diff("CLAUDE.md",           read(CLAUDE_MD),  patch_md(read(CLAUDE_MD)))
    print("\n[dry-run -- nada foi escrito]")

def apply_changes():
    errors = []
    for path, patch_fn in [(HOOK_FILE, patch_hook), (CLAUDE_MD, patch_md)]:
        src = read(path)
        new = patch_fn(src)
        if new == src:
            print(f"--  {path}  (sem alteracoes)")
            continue
        bak = path.with_suffix(path.suffix + ".bak")
        shutil.copy2(path, bak)
        path.write_text(new, encoding="utf-8")
        if path == HOOK_FILE and not validate_py(path):
            shutil.copy2(bak, path)
            errors.append(f"{path.name}: syntax error -- rolled back")
        else:
            print(f"OK  {path}  (backup: {bak.name})")
    if errors:
        [print(f"ERRO: {e}") for e in errors]; sys.exit(1)
    else:
        print("\n[apply completo]")

def rollback():
    for path in [HOOK_FILE, CLAUDE_MD]:
        bak = path.with_suffix(path.suffix + ".bak")
        if bak.exists():
            shutil.copy2(bak, path); print(f"RESTORED  {path}")
        else:
            print(f"SKIP  {bak.name}  (nao encontrado)")
    print("\n[rollback completo]")

if __name__ == "__main__":
    {"--dry-run": dry_run, "--apply": apply_changes, "--rollback": rollback}.get(
        sys.argv[1] if len(sys.argv) > 1 else "", lambda: (print(__doc__), sys.exit(1))
    )()
