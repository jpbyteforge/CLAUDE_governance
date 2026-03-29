---
version: 2.1
type: governance
scope: global
date: 2026-03-29
description: Terms, relationships, inheritance model, and enforcement map for multi-project governance
---

# Taxonomy — Terms, Relationships, Enumerations

## Definitions

| Term | Definition | Used in |
|------|-----------|---------|
| Sovereign Document | Single source of truth. Prevails over code, config, output. | INVARIANT-2 |
| Regulated Component | Autonomous system operating under documented constraints. | INVARIANT-1 |
| Fail-Closed | No explicit rule → action blocked. Safe default. | INVARIANT-3 |
| Forbidden Zone | Directory/file where AI write is blocked. Defined per project. | RULE-4 |
| ADR | Architecture Decision Record: context, options, decision, consequences. | INVARIANT-1, INVARIANT-2, RULE-10 |
| Documentary Basis | Documented authority for an action (ADR, instruction, rule). | INVARIANT-1 |
| Governance Event | Violation or gap requiring owner attention and resolution. | INVARIANT-4 |
| Sunset Clause | Expiration condition on experimental rules. | INVARIANT-7 |
| Inheritance | How project rules derive from global rules. See §Inheritance Model. | All |
| Portfolio | Optional grouping of projects sharing domain rules (e.g., academic, engineering). | Governance Scopes |
| Enforcement Gap | Rule exists in governance but has no automated enforcement. | reference/enforcement.md |

## Epistemic Markers

| Marker | Meaning | Requirement |
|--------|---------|-------------|
| [FACT] | Verifiable claim with cited source | Source must be checkable |
| [INFERENCE] | Derived from facts | Dependency chain explicit |
| [UNCONFIRMED] | Insufficient evidence | Default state; may promote with new data |

Projects may extend with domain-specific markers (e.g., [FACTO], [A VERIFICAR]).

## Authority Hierarchy

```
sovereign_doc > operational_doc > code > output

Where:
  sovereign_doc  = CLAUDE.md, GOVERNANCE.md, rules/*, ADRs
  operational_doc = plans, task lists, memory
  code           = implementation, tests, configs
  output         = generated content, reports, analysis
```

## Action Criticality

| Level | Examples | Requires |
|-------|----------|----------|
| Reversible | Read, test locally, propose | No confirmation |
| Recoverable | Write to non-sovereign areas, commit | Confirmation + context |
| Irreversible | Delete, archive, publish, deploy | Explicit approval + rollback plan |

## Governance Scopes

| Scope | Location | Precedence |
|-------|----------|------------|
| Global | `~/.claude/rules/` | Highest — cannot be overridden |
| Portfolio | Multi-project guidance (optional) | High — extends global |
| Project | `{project}/CLAUDE.md` | Medium — extends global+portfolio |
| Session | Ephemeral (prompts, tasks) | Lowest — no governance authority |

Conflict: higher scope prevails. Lower scopes EXTEND (add rules) but cannot CONTRADICT higher.

## Actor Roles

| Role | Authority |
|------|-----------|
| Owner | Human with authority to decide governance changes |
| Agent | AI (Claude) operating under governance rules |
| Reviewer | Human tasked to validate outputs (optional, project-defined) |

## Inheritance Model

How projects derive governance from global rules:

```
INHERIT:     global.invariants → project (mandatory, cannot weaken or override)
EXTEND:      global.rules → project.rules (can ADD project-specific, cannot contradict)
SPECIALIZE:  global.markers → project.markers (can ADD domain-specific, cannot redefine global markers, e.g., [FACTO])
OVERRIDE:    project.forbidden_zones → global.defaults (can RESTRICT further, never relax)
```

Resolution:
- `conflict(global, project)` → global prevails (INVARIANT-2)
- `gap(global, project)` → INVARIANT-3 (fail-closed) + ASK owner
- `new_concept(project)` → add to project CLAUDE.md; propose to global if reusable

Onboarding: copy `~/.claude/templates/project-claude.md` → project root, fill placeholders.

## Cross-References

- `invariants.md` ↔ `rules.md`: Each rule traces to ≥1 invariant via `# intent:`
- `rules.md` ↔ `taxonomy.md`: Terms used in rules are defined here
- `~/.claude/reference/enforcement.md`: Maps rules to enforcement mechanisms and gaps
- `~/.claude/templates/project-claude.md`: Skeleton for new projects using inheritance model
- `~/.claude/archive/manifesto-governance-v1.md`: Legacy prose version (rollback)
