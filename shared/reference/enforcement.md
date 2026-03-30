---
version: 2.1
type: governance
scope: global
date: 2026-03-29
description: Bidirectional map between governance rules and their enforcement mechanisms
---

# Enforcement Map — What Is Actually Enforced

> Honesty about automation: not all rules have hooks. Convention-only rules
> depend on CLAUDE.md instructions being followed. This file closes that gap.

## Enforcement Status Legend

- **enforced**: Automated hook or settings.json blocks violations deterministically
- **partial**: Some aspects automated, others rely on convention
- **convention**: Rule exists only in CLAUDE.md/rules — no runtime check
- **project**: Enforcement exists but only in project-specific scripts

## Invariants

| Invariant | Status | Mechanism | File |
|-----------|--------|-----------|------|
| INVARIANT-1 (Regulated Autonomy) | partial | settings.json deny list blocks writes to protected paths; no check for "documentary basis" | `settings.json` |
| INVARIANT-2 (Documentary Sovereignty) | partial | settings.json denies Write to CLAUDE.md, rules/, hooks/; no hierarchy enforcement at runtime | `settings.json` |
| INVARIANT-3 (Fail-Closed) | partial | pretool-guardrails.py blocks disallowed bash commands and Write >50 lines; does not cover all ambiguity cases | `hooks/pretool-guardrails.py` |
| INVARIANT-4 (Evidence) | project | EEM: validate_project.py checks V9-V14, V20-V24; no global enforcement | project scripts |
| INVARIANT-5 (Ownership) | convention | No automated check for decision records (WHO, WHEN, WHY) | — |
| INVARIANT-6 (Proportional Change) | convention | No automated impact analysis or reversibility check | — |
| INVARIANT-7 (Evolution) | convention | No sunset clause tracking or review reminders | — |

## Rules

| Rule | Status | Mechanism | File |
|------|--------|-----------|------|
| RULE-4 (Forbidden Zones) | enforced | settings.json deny list + pretool-guardrails.py Write check | `settings.json`, `hooks/pretool-guardrails.py` |
| RULE-6 (Human-in-the-Loop) | partial | Claude Code built-in permission prompts for tool use; no "show delta" enforcement | Claude Code harness |
| RULE-10 (Meta-Governance) | partial | settings.json denies Write to rules/; no referential integrity validator | `settings.json` |
| RULE-11 (Session Integrity) | convention | /wrap skill exists but not enforced; session-end hook logs but does not validate | session-end hook |
| RULE-12 (Memory Verification) | convention | CLAUDE.md instructs verification; no pre-action filesystem check | — |
| ESCAPE (No Rule Matches) | convention | No handler for unmatched situations; relies on CLAUDE.md instruction | — |

## Model Tier Policy

| Policy | Status | Mechanism | File |
|--------|--------|-----------|------|
| Model tier recommendation | enforced | check-model-tier.py classifies prompts, suggests tier | `hooks/check-model-tier.py` |
| Subagent quota (max 10 writes) | enforced | pretool-guardrails.py tracks agent spawns in tempfile | `hooks/pretool-guardrails.py` |
| Bash tool restrictions | enforced | pretool-guardrails.py blocks cat, grep, find, sed -i, awk as first command; allows grep/head/tail/awk after pipes (filtering stdout). `tail -f`/`--follow` exempted (streaming). | `hooks/pretool-guardrails.py` |
| Subagent quota atomicity | enforced | Lock file with `O_CREAT\|O_EXCL` prevents race condition on parallel agent launches | `hooks/pretool-guardrails.py` |
| Governance version check | enforced | Runs once per session (sentinel file), not on every tool call | `hooks/pretool-guardrails.py` |

## Known Gaps (Honest Assessment)

| Gap | Severity | Notes |
|-----|----------|-------|
| FN-1: Pipe-prefix bypass | Low | `true \| grep pattern file` bypasses first-segment check; threat model is accidental misuse, not adversarial |
| No automated ADR process | Low | INVARIANT-5 requires records but no template or workflow enforced |
| No memory staleness check | Medium | RULE-12 is convention-only; stale memory can cause wrong actions |
| No epistemic marker linter (global) | Low | Only EEM has V9-V14; other projects would need their own |
| No derivation graph validator | Low | Taxonomy DAG is prose; new rules could orphan without detection |
| No sunset clause alerts | Low | INVARIANT-7 mentions sunset but no tracking mechanism exists |
| No periodic review schedule | Low | INVARIANT-7 mandates periodic review but no cadence defined; INVARIANT-2 is backstop |
| RULE-10 self-validation gap | Low | RULE-10 governs governance changes but no independent check validates RULE-10 itself; INVARIANT-2 serves as backstop |
| [INFERENCE] quality not enforced | Low | invariants.md requires premises be [FACT]/[INFERENCE] (never [UNCONFIRMED]); no linter enforces this |
