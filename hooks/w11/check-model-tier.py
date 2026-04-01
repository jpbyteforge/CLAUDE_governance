"""check-model-tier — Deterministic model tier advisor.
No LLM, <10ms. Advisory only: injects [MODEL_TIER] into Claude's context.
"""
import sys
import json
import re
from datetime import datetime
from pathlib import Path

TIER_RANK  = {"HAIKU": 1, "SONNET": 2, "OPUS": 3}
TIER_MODEL = {
    "HAIKU":  "claude-haiku-4-5-20251001",
    "SONNET": "claude-sonnet-4-6",
    "OPUS":   "claude-opus-4-6",
}

_SONNET = re.compile(
    r"implementa|debug|corrig|refactor|testa|review|compar"
    r"|analisa(?![\s\S]*(impacto|risco|trade|sistem))|infra|setup|configur|deploy"
    r"|backend|frontend|api|database|schema|query|optim|perform|secure"
    r"|cria[\s\S]{0,30}(plano|script|ficheiro|funcao|classe|modulo|hook|regra)"
    r"|desenvolve|melhora[\s\S]{0,30}(sistem|codigo|hook|regra|classif)"
    r"|aplica[\s\S]{0,30}(mudanca|altera|patch|fix|plano)"
    r"|escreve[\s\S]{0,20}(codigo|code|script|funcao)"
    r"|fecha[\s\S]{0,15}(sess|session)",
    re.IGNORECASE,
)
_OPUS = re.compile(
    r"arquitetura|arquitectura|architect|multi.?sistem|cross.?system"
    r"|refactor[\s\S]*(todo|tudo|all|global|projet)|design[\s\S]*(system|arqui)"
    r"|audit[ao]?[r ]|governa(?:[çn]|\b)|converg|migra[\s\S]*(sistema|system|project)"
    r"|integra[\s\S]*(entre|across|cross|multi)|depend[\s\S]*(graph|circular|cycle)"
    r"|trade.?off|investig|reflete|refle[cxs]"
    r"|analisa[\s\S]*(impacto|risco|trade|sistem|project)"
    r"|avalia[\s\S]*(estrateg|sistem|impacto)|reestrutur|redesign"
    r"|consolid[\s\S]*(sistem|modul|projet)|unific"
    r"|planei?a[\s\S]*(estrateg|migra|sistem)"
    r"|compara[\s\S]*(abordagen|approach|estrateg|sistem)"
    r"|roadmap|blueprint|manifest"
    r"|diagn[oó]stic[\s\S]*(profund|deep|root)"
    r"|d[ií]vid[\s\S]*(t[eé]cnic|tech)|debt[\s\S]*(t[eé]cnic|tech)"
    r"|complex[\s\S]*(debug|analy)"
    r"|pr[ií]ncip[\s\S]*(design|solid|dry|separation)",
    re.IGNORECASE,
)


_HAIKU_FAST = re.compile(
    r"^(o que [e\u00e9]|como funciona|qual [e\u00e9]|quais s[a\u00e3]o"
    r"|lista[\s,]|explica[\s,]|descreve[\s,]|resume[\s,]|mostra[\s,]|diz-me"
    r"|what is|how does|show me|list |explain |describe )",
    re.IGNORECASE,
)


def classify(prompt: str) -> str:
    # v3: fast-path HAIKU -- evita SONNET over-firing
    if _HAIKU_FAST.match(prompt):
        return "HAIKU"
    if _OPUS.search(prompt):
        return "OPUS"
    if _SONNET.search(prompt):
        return "SONNET"
    return "HAIKU"


def apply_local_policy(tier: str) -> str:
    """Walk up from CWD looking for a CLAUDE.md with ## Model Policy overrides."""
    d = Path.cwd()
    for _ in range(5):
        candidate = d / "CLAUDE.md"
        if candidate.exists():
            text = candidate.read_text(encoding="utf-8", errors="ignore")
            section = re.search(r"(?ms)^## Model Policy\r?\n(.*?)(?=^## |\Z)", text)
            if section:
                policy = section.group(1).lower()
                rank = TIER_RANK[tier]
                for t in ("opus", "sonnet", "haiku"):
                    if re.search(rf"min.*tier.*{t}", policy):
                        min_rank = TIER_RANK[t.upper()]
                        if rank < min_rank:
                            tier = t.upper()
                            rank = min_rank
                        break  # stop at first min tier match
                for t in ("haiku", "sonnet", "opus"):
                    if re.search(rf"max.*tier.*{t}", policy):
                        if rank > TIER_RANK[t.upper()]:
                            tier = t.upper()
                        break  # stop at first max tier match
            break
        parent = d.parent
        if parent == d:
            break
        d = parent
    return tier


def log(global_tier: str, final_tier: str, prompt: str) -> None:
    try:
        log_path = Path.home() / ".claude" / "token-economy.log"
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        entry = f"{ts} | MODEL_SELECT | {global_tier}->{final_tier} | {prompt[:80]}\n"
        with log_path.open("a", encoding="utf-8") as f:
            f.write(entry)
    except Exception:
        pass


def main() -> None:
    try:
        data = json.loads(sys.stdin.read())
    except Exception:
        sys.exit(0)

    prompt = data.get("prompt", "")
    if not prompt or prompt.startswith("/"):
        sys.exit(0)

    global_tier = classify(prompt)
    final_tier  = apply_local_policy(global_tier)
    final_model = TIER_MODEL[final_tier]

    log(global_tier, final_tier, prompt)
    print(f"[MODEL_TIER] {final_tier} | /model {final_model}")
    sys.exit(0)


if __name__ == "__main__":
    main()
