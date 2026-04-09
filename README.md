# CLAUDE_governance

Cross-platform governance configuration for [Claude Code](https://claude.ai/claude-code) — deterministic hooks, model tier management, token economy guardrails, and operational audit skills.

Works on **WSL/Linux** (bash) and **Windows 11** (Python 3.13 native).

## What this is

A single source of truth for governing Claude Code behavior across machines and operating systems. Instead of managing separate configs per platform, this repo holds everything in one place and deploys to the right locations.

**Core principles** (codified in [invariants.md](shared/rules/invariants.md) + [invariants.yaml](shared/rules/invariants.yaml); v1 prose in [archive/manifesto-governance.md](shared/archive/manifesto-governance.md)):
- AI is a regulated component, not an autonomous agent (INV-1)
- Documentary sovereignty: sovereign docs > code > config > output (INV-2)
- Fail-closed on ambiguity — unknown rule = BLOCK (INV-3)
- Evidence over persuasion: claims marked [FACT] / [INFERENCE] / [UNCONFIRMED] (INV-4)
- Human ownership of every artifact; no self-elevation (INV-5)
- Proportional change + periodic review with sunset clauses (INV-6, INV-7)

## Structure

```
shared/                     # OS-agnostic — deployed to both platforms
├── CLAUDE.md               # User-level protocol (tier response, tools, subagents)
├── policy-limits.json      # Session-level quotas
├── sunset-clauses.json     # Experimental-rule expiry tracker (INV-7)
├── .manifest.json          # Declarative deploy contract (shared/ → ~/.claude/)
├── rules/                  # L0 — auto-loaded, sovereign
│   ├── invariants.md       # 7 canonical premises (prose + intent)
│   ├── invariants.yaml     # Machine-readable structure + severity
│   └── rules.md            # Operational rules (WHEN/REQUIRE/DEFAULT)
├── reference/              # L1 — loaded on demand
│   ├── taxonomy.md         # Terms, inheritance model, scopes
│   ├── enforcement.md      # Map: rule → hook (enforced | partial | convention)
│   └── governance-readme.md
├── archive/                # L3 — frozen, rollback-only
│   ├── manifesto-governance.md     # v1 prose manifesto
│   └── manifesto-governance-v1.md
├── templates/              # L2 — project bootstrap
│   ├── project-claude.md
│   └── claudeignore-template
├── commands/               # On-demand skills (loaded when invoked)
│   ├── boot.md             # Session start — hydrate + orient
│   ├── wrap.md             # Session close — integrity + incident summary
│   ├── verify.md           # Deterministic correctness check
│   ├── ground.md           # Source-grounded verification (verbatim + attribution)
│   ├── contraditorio.md    # Adversarial rebuttal (cross-model)
│   └── audit-turnaround.md # Operational audit protocol
├── skills/
│   ├── neon-postgres/      # Neon Serverless Postgres guide
│   ├── extract-pdf/        # Document extraction → markdown
│   └── audit-eem/          # EEM quality audit
└── scripts/
    ├── playwright-init.js
    └── sync-playwright-profile.sh

hooks/                      # Platform-specific enforcement
├── wsl/                    # Bash
│   ├── check-model-tier.sh
│   ├── resolve-model-policy.sh
│   ├── pretool-guardrails.sh
│   ├── session-start-model.sh
│   └── session-end.sh
└── w11/                    # Python 3.13 (zero WSL dependency)
    ├── check-model-tier.py
    ├── pretool-guardrails.py
    └── session-end.py

settings/                   # Platform-specific Claude Code config (examples)
├── wsl/settings.example.json
└── w11/settings.example.json

bin/                        # Utility scripts
├── wsl/token-economy-report.sh
└── w11/token-economy-report.py

tools/                      # Developer tooling
├── verify_audit.py         # Hash-chain integrity check for incident_log
└── create_wsl_task.ps1

incident_log.jsonl          # Append-only governance event log (hash-chained)
incident_log.schema.json    # Entry schema (block | warn | override | drift | grounding_failure)
```

## Hooks

### check-model-tier (UserPromptSubmit)
Classifies prompt complexity and recommends the appropriate model tier. Deterministic regex matching — no LLM, <10ms. Supports local overrides via `## Model Policy` in project CLAUDE.md files.

| Tier | Model | When |
|------|-------|------|
| HAIKU | `claude-haiku-4-5-20251001` | Questions, formatting, commits, boilerplate |
| SONNET | `claude-sonnet-4-6` | Implementation, debug, refactor, review |
| OPUS | `claude-opus-4-6` | Multi-system architecture, governance, trade-offs |

### pretool-guardrails (PreToolUse)
Enforces token economy rules before each tool call:
- **Dedicated tools over Bash**: blocks `cat`/`head`/`tail`→Read, `grep`/`rg`→Grep, `find`→Glob, `sed -i`→Edit, `awk`→Edit/Read (first segment only; post-pipe filtering is allowed)
- **Edit over Write**: existing files >50 lines must use Edit (sends diff, not full file)
- **Subagent quota**: max 10 write-subagents per session, atomic via `O_CREAT|O_EXCL` lock
- **Governance version check**: once per session (sentinel file), not per tool call

### session-end (SessionEnd)
Logs session close events and emits summary counters into `incident_log.jsonl`. Advisory — does not block.

See [shared/reference/enforcement.md](shared/reference/enforcement.md) for the full rule → mechanism map and known gaps.

## Commands

On-demand skills loaded only when invoked (zero token cost at baseline):

| Command | Purpose |
|---------|---------|
| `/boot` | Session start — hydrate minimum context, verify L0 files, report inherited state from last `/wrap` |
| `/wrap` | Session close — integrity check, invariant coverage, incident summary, deploy drift, pendentes |
| `/verify` | Deterministic correctness check (logic, constraints, edge cases). Single correct answer required. |
| `/ground` | Source-grounded verification — verbatim accuracy, semantic fidelity, attribution. For academic/factual claims. |
| `/contraditorio` | Adversarial rebuttal via cross-model subagent. Medium+ impact, medium+ irreversibility only. |
| `/audit-turnaround` | Operational audit: REFRAME → MEASURE → DIAGNOSE → INTERVENE → VALIDATE. |

Routing rule: source-dependent → `/ground`; logic-dependent → `/verify`; choice-dependent → `/contraditorio`.

## Deploy

Deploys are manifest-driven ([shared/.manifest.json](shared/.manifest.json)) — a single declarative contract maps `shared/` → live `~/.claude/`, including tombstones for removed files and reverse-sync entries for files edited live.

**WSL/Linux:**
```bash
./deploy.sh            # Deploy to ~/.claude/
./deploy.sh --dry-run  # Preview without copying
```

**Windows 11:**
```cmd
python deploy_w11.py              # Deploy to %USERPROFILE%\.claude\
python deploy_w11.py --dry-run    # Preview
python deploy_w11.py --verify     # Compare live vs manifest; exit 1 on drift
python deploy_w11.py --reverse    # Pull live edits back into shared/ (reverse_sync only)
```

`--verify` is the pre-push gate: `/wrap` runs it and flags drift before the owner pushes.

## Governance model

```
L0  rules/         invariants.md · invariants.yaml · rules.md   (sovereign, auto-loaded)
       │  INHERIT (mandatory, cannot weaken)
L1  reference/     taxonomy.md · enforcement.md · governance-readme.md
       │  EXTEND (can add, cannot contradict)
L2  templates/     project-claude.md · claudeignore-template
       │  SPECIALIZE (domain markers, tools)
      project/CLAUDE.md   (identity, quality rules, forbidden zones)
L3  archive/       manifesto-governance.md · manifesto-governance-v1.md   (frozen)
```

Conflict resolution: higher scope prevails. Gap: fail-closed + ask owner (INV-3).
Rule changes at principle level require an ADR (R10 / INV-6).

## Audit trail

Every governance event (block, warn, override, drift, grounding_failure) is appended to [incident_log.jsonl](incident_log.jsonl) as a hash-chained record ([schema](incident_log.schema.json)). Integrity is verifiable with [tools/verify_audit.py](tools/verify_audit.py). `/wrap` aggregates the session slice and flags invariant violations before closing.

## Token economy

Every design decision optimizes for minimal context window usage:
- L0 rules/ auto-load; L1 reference/, L2 templates/, L3 archive/ load on demand
- Commands and skills are zero-cost until invoked (`disable-model-invocation` where applicable)
- Dedicated-tool enforcement: Grep/Glob/Read/Edit over Bash equivalents to avoid full-file transfers
- Edit over Write on files >50 lines (diff, not full payload)
- `bin/token-economy-report` measures actual baseline per platform

## License

MIT — see [LICENSE](LICENSE).
