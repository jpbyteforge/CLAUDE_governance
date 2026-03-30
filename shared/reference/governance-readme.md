# Claude Governance System v2.1

Multi-project governance for Claude Code. Rules are structured as machine-parseable
invariants and conditional rules, with human-readable intent comments.

## File Map

| File | Purpose | Changes |
|------|---------|---------|
| `rules/invariants.md` | 7 canonical premises (non-negotiable) | Rarely |
| `rules/rules.md` | 5 operational rules + escape clause (WHEN/REQUIRE/DEFAULT) | Occasionally |
| `rules/taxonomy.md` | Terms, inheritance model, governance scopes | When new concepts emerge |
| `reference/enforcement.md` | Map: what is automated (hooks) vs. convention-only | When hooks change |
| `archive/manifesto-governance-v1.md` | Archived v1.0 prose version (rollback) | Never (frozen) |

## Inheritance

```
~/.claude/rules/          GLOBAL (invariants, rules, taxonomy)
        │
        │  INHERIT (mandatory, cannot weaken)
        │  EXTEND  (can add, cannot contradict)
        │
   [portfolio/]            PORTFOLIO (optional, domain grouping)
        │
        │  SPECIALIZE (domain markers, tools)
        │  OVERRIDE   (can restrict further, never relax)
        │
  {project}/CLAUDE.md      PROJECT (identity, quality, operations)
```

Conflict: higher scope prevails. Gap: fail-closed + ask owner.

## New Project Setup

1. Copy `~/.claude/templates/project-claude.md` to project root as `CLAUDE.md`
2. Fill `[REQUIRED]` sections (identity, quality rules, forbidden zones, operations)
3. Remove `[OPTIONAL]` sections you don't need; fill those you do

## Proposing Changes

Governance changes require owner review (RULE-10). For principle-level changes,
create an ADR: context, options considered, decision, consequences.

## Enforcement

Not all rules are automated. See `enforcement.md` for honest status of each rule.
Convention-only rules depend on Claude following CLAUDE.md instructions.
