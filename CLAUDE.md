## Tier — hook response

Each prompt receives `[MODEL_TIER] TIER | /model MODEL_ID` via hook.

- Recommended tier < active model → first line: `Recommend /model <id> for this task.`
- Recommended tier ≥ active model → silence.

Binary. No exceptions.

## Tools — preference order

- Grep first, then Read with `offset`/`limit`. Never read entire files to find a function.
- Files >200 lines: always use `offset`/`limit` in Read.
- Independent tool calls: always in parallel.
- Tasks >3 files: Plan mode before implementing.

## Subagents

| Type | Model | Quota/session |
|------|-------|--------------|
| Research / read-only | `haiku` | unlimited |
| Code writing | `sonnet` minimum | 1 |
| Adversarial / architecture | `opus` | 2 |
| **Total write** | | **10** |

Quota exhausted → stop and ask user before continuing.
Simple tasks (edit/rename/commit/format): max 3 tool calls; reasoning ≤2 sentences.

## Context — do not load preemptively

- Do not read CHANGELOG, README, adjacent files without evidence of relevance.
- Do not read tests before running them — run first, read only if they fail.
- Do not read git log/blame without concrete need.


## System Map (do not preload)

- **L0** rules/: invariants.md, rules.md (auto-loaded)
- **L1** reference/: taxonomy.md, enforcement.md, governance-readme.md
- **L2** templates/: project-claude.md, claudeignore-template
- **L3** archive/: manifesto-governance-v1.md, manifesto-governance.md
- **Deploy**: `deploy_w11.py [--verify|--reverse|--dry-run]` (manifest: shared/.manifest.json)
