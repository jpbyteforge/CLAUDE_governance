# CLAUDE_governance

Cross-platform governance configuration for [Claude Code](https://claude.ai/claude-code) — deterministic hooks, model tier management, token economy guardrails, and operational audit skills.

Works on **WSL/Linux** (bash) and **Windows 11** (Python 3.13 native).

## What this is

A single source of truth for governing Claude Code behavior across machines and operating systems. Instead of managing separate configs per platform, this repo holds everything in one place and deploys to the right locations.

**Core principles** (from the [governance manifesto](shared/rules/manifesto-governance.md)):
- AI is a regulated component, not an autonomous agent
- Documents are law — deterministic checks before AI action
- Fail-closed on ambiguity
- Human-in-the-loop for critical actions
- Minimum context, maximum results

## Structure

```
shared/                     # OS-agnostic — deployed to both platforms
├── CLAUDE.md               # User-level governance (model tiers, token economy)
├── policy-limits.json      # Session-level quotas
├── rules/                  # Auto-loaded governance rules
│   └── manifesto-governance.md
├── commands/               # On-demand skills (loaded when invoked)
│   ├── audit-turnaround.md # Operational audit protocol
│   ├── contraditorio.md    # Adversarial analysis
│   ├── apa-citation.md     # APA 7th ed formatting
│   └── nep-docx.md         # DOCX generation per IUM norms
└── skills/
    └── neon-postgres/      # Neon Serverless Postgres guide

hooks/                      # Platform-specific enforcement
├── wsl/                    # Bash scripts
│   ├── check-model-tier.sh
│   ├── resolve-model-policy.sh
│   ├── pretool-guardrails.sh
│   └── session-start-model.sh
└── w11/                    # Python 3.13 (zero WSL dependency)
    ├── check-model-tier.py
    └── pretool-guardrails.py

settings/                   # Platform-specific Claude Code config
├── wsl/
└── w11/

bin/                        # Utility scripts
├── wsl/token-economy-report.sh
└── w11/token-economy-report.py
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
- **Dedicated tools over Bash**: blocks `cat`→Read, `grep`→Grep, `find`→Glob, `sed -i`→Edit
- **Edit over Write**: existing files >50 lines must use Edit (sends diff, not full file)
- **Subagent quota**: max 10 write-subagents per session

## Deploy

**WSL/Linux:**
```bash
./deploy.sh            # Deploy to ~/.claude/
./deploy.sh --dry-run  # Preview without copying
```

**Windows 11:**
```cmd
python deploy_w11.py            # Deploy to %USERPROFILE%\.claude\
python deploy_w11.py --dry-run
```

Both scripts copy shared files to `~/.claude/` and platform-specific files from the appropriate subdirectory.

## Governance model

```
manifesto (doctrine, read-only)
  └→ protocol (projet-governance/CLAUDE.md)
       └→ portfolio (projects/CLAUDE.md)
            └→ project ({proj}/CLAUDE.md)
```

Each level can restrict but not relax the level above. The manifesto principles are distilled into [manifesto-governance.md](shared/rules/manifesto-governance.md) — a 34-line Claude-optimized rules file that auto-loads in every session, replacing the full 189-line manifesto.

## Token economy

Every design decision optimizes for minimal context window usage:
- Governance baseline: **~1,930 tokens** per session (down from ~4,400)
- Manifesto: 189 lines → 34 lines (-82%)
- Protocol: 96 lines → 48 lines (-50%)
- Skills load on-demand only

## License

MIT — see [LICENSE](LICENSE).
