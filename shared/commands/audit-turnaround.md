---
name: audit-turnaround
description: Operational audit and project turnaround. Causal diagnosis, removal of real friction, stabilisation.
argument-hint: [project-path]
---

Operational audit of the project at $ARGUMENTS.

Formula: REFRAME → MEASURE → DIAGNOSE → INTERVENE → VALIDATE. Each phase has a gate — do not advance without passing it.

Objective: improve outputs, reduce risk, stabilise. Improvements without measurable operational impact are irrelevant.

---

PHASE 0 — REFRAME

Read CLAUDE.md, README, pyproject.toml and Makefile. Answer with facts:
1. What does the project exist for?
2. What is the output consumed by someone?
3. What happens if the system stops today?
4. Current operational baseline?

Gate: 4 concrete answers referencing real outputs.

---

PHASE 1 — MEASURE

Execute — do not infer results. Run everything independent in parallel.

**1a. System state**
- Run tests: N passed, N failed, N skipped, time
- Count output files. Check timestamps — is the system alive?
- Read last 1-3 pipeline output records

**1b. Git archaeology**
- Hotspots: `git log --format=format: --name-only | sort | uniq -c | sort -rn | head -15`
- Failure pattern: `git log --oneline --grep="fix\|bug\|crash\|broken" | head -10`

**1c. Anti-patterns** — grep in *.py excluding tests/:
- Swallowed exceptions: `except.*pass`, `except.*continue`
- Relative paths: `Path("[^/]`
- Uncertainty: `TODO|FIXME|HACK|WORKAROUND|XXX`
- Complexity: wc -l top 10 largest

**1d. Negative space** — what SHOULD exist but doesn't:
- Logging on error paths? Failure alerts? Health check? Backup/recovery?

Gate: table filled with measured data.

| Dimension | State (with evidence) |
|-----------|----------------------|
| Works | |
| Fails | |
| Fragile | |
| Non-deterministic | |
| Test coverage | N/M passed (X%) in Xs |
| Last run | [timestamp] |

---

PHASE 2 — DIAGNOSE

Classify each problem:
- **A)** Blocker — prevents value delivery
- **B)** Latent risk — safety, integrity, continuity
- **C)** Inefficiency with real cost
- **D)** Aesthetic debt — does NOT enter the plan

D causing A/B/C → reclassify with causal justification. Without file:line and quantifiable impact → not a finding, it's an opinion → remove.

Qualification: [FACT] (verified), [INFERENCE] (deduction), [UNCONFIRMED] (no direct evidence). Findings only [UNCONFIRMED] → escalate as question, do not enter plan.

Before classifying A/B, look for contrary evidence.

Format:
```
[ID] [A/B/C] Title
- File: path:line
- Root cause: 1 sentence
- Impact: what fails, who, frequency
- Evidence: [FACT/INFERENCE/UNCONFIRMED] + data
```

Calibration: ugly code that works ≠ problem. Pretty code that fails silently = problem. Ask: "does this cause loss of value, time or trust?"

Gate: zero phrases like "consider", "could", "would be good".

---

PHASE 3 — INTERVENE

Max 7 interventions, ordered by operational impact. >7 = poor prioritisation.

For each:
1. Problem it solves (ref ID)
2. Expected gain (measurable)
3. Risks introduced
4. Reversibility
5. Necessity test: "what happens if we do NOT do this?" → if "nothing" → remove

Propose concrete change (file, function, change). No total rewrites, generic abstractions or optimisations without real pressure.

Gate: each intervention passes necessity test AND has measurable gain.

---

PHASE 4 — VALIDATE (if owner approves)

1. Run tests — compare against baseline
2. Validate happy path end-to-end
3. Force expected failure — does the system react?
4. Confirm real gain vs baseline with numbers

No clear improvement → revert.

---

PHASE 5 — CLOSE

End when: system more stable (demonstrated), known risks documented, recovered value explicit. Closing decision belongs to the owner.

---

Output:

## Reframing
[4 factual answers]

## Baseline
[Filled table]

## Diagnosis
[A/B/C findings with standard format]

## Intervention Plan
[Max 7, ordered by impact]

## Current State vs Target
[Comparative table]
