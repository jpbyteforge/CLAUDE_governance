---
inherits: global.invariants
version: 1.0
date: <!-- YYYY-MM-DD -->
owner: <!-- Human owner name -->
portfolio: <!-- academic | engineering | personal | (omit if none) -->
---

# CLAUDE.md — <!-- Project Name -->

> Governance: 3 layers. Inherits global invariants from `~/.claude/rules/invariants.md`.
> Project rules below EXTEND global rules — they cannot contradict them.

---

## LAYER 1 — IDENTITY [REQUIRED]

<!-- What is this project? One paragraph. Include:
     - Purpose / research question / product goal
     - Key constraints (deadlines, stakeholders, regulations)
     - Success criteria (measurable if possible)
-->

**Purpose**: <!-- ... -->

**Deadline**: <!-- ... or "ongoing" -->

**Success criteria**: <!-- ... -->

---

## LAYER 2 — QUALITY RULES [REQUIRED]

### Project Invariants (specialize global INVARIANT-4, INVARIANT-5)

<!-- Add project-specific invariants that SPECIALIZE global ones.
     Format: INVARIANT-Na where N = global invariant number, a = local suffix.
     Example for academic project:

**INVARIANT-4a: Epistemic Marking**
```
∀ claim ∈ body: claim.marker ∈ {[FACT], [INFERENCE], [UNCONFIRMED]}
```
# intent: ...
-->

### Project Rules (EXTEND global rules)

<!-- Add project-specific rules in WHEN/REQUIRE/DEFAULT format.
     These must not contradict global rules.
     Example:

**RULE-PROJ-1: Validation Before Commit**
```
WHEN:  changes to source files
REQUIRE: run validation script → all checks PASS
DEFAULT: BLOCK commit until PASS.
```
# intent: ...
-->

### Forbidden Zones [REQUIRED]

<!-- Define project-specific forbidden zones (OVERRIDE: can restrict, never relax).
     These are in ADDITION to global settings.json deny list.
-->

```
forbidden:
  - <!-- path/to/sovereign/doc -->
  - <!-- path/to/protected/config -->
permitted:
  - <!-- everything else in project root -->
```

---

## LAYER 3 — OPERATIONS [REQUIRED]

**State tracking**: <!-- e.g., TASK.md, MEMORY.md, validation scripts -->

**Workflow**:
```
Start:   <!-- e.g., validate → update state → begin work -->
Edit:    <!-- e.g., validate after each change -->
Close:   <!-- e.g., validate → commit + push -->
```

<!-- [OPTIONAL] Technical gotchas, encoding issues, tool versions -->

<!-- [OPTIONAL] Custom epistemic markers beyond global [FACT]/[INFERENCE]/[UNCONFIRMED] -->

<!-- [OPTIONAL] References to project-specific governance docs (e.g., GOVERNANCE.md) -->

---

## References

- **Global rules**: `~/.claude/rules/` (invariants, rules, taxonomy)
- **Enforcement map**: `~/.claude/reference/enforcement.md`
- **Escape**: situation not covered → ASK owner + INVARIANT-3 (fail-closed)

---
<!-- v1.0 — created from template. Update version on significant governance changes. -->
