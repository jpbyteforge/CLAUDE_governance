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
    r"implement|debug|fix|correct|refactor|test|review|compar"
    r"|analys[ei](?![\s\S]*(impact|risk|trade|system))|infra|setup|configur|deploy"
    r"|backend|frontend|api|database|schema|query|optim|perform|secure",
    re.IGNORECASE,
)
_OPUS = re.compile(
    r"architect|multi.?system|cross.?system"
    r"|refactor[\s\S]*(all|global|project)|design[\s\S]*(system|arch)"
    r"|audit|governance|converg|migrat[\s\S]*(system|project)"
    r"|integrat[\s\S]*(between|across|cross|multi)|depend[\s\S]*(graph|circular|cycle)"
    r"|trade.?off|investigat|reflect"
    r"|analys[ei][\s\S]*(impact|risk|trade|system|project)"
    r"|evaluat[\s\S]*(strateg|system|impact)|restructur|redesign"
    r"|consolid[\s\S]*(system|modul|project)|unif"
    r"|plan[\s\S]*(strateg|migrat|system)"
    r"|compar[\s\S]*(approach|strateg|system)"
    r"|roadmap|blueprint|manifest"
    r"|diagnos[\s\S]*(deep|root)"
    r"|tech.?debt|debt[\s\S]*(tech)"
    r"|complex[\s\S]*(debug|analy)"
    r"|principl[\s\S]*(design|solid|dry|separation)",
    re.IGNORECASE,
)


def classify(prompt: str) -> str:
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
