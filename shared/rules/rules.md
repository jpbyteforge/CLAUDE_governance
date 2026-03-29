---
version: 2.1
type: governance
scope: global
date: 2026-03-29
description: Operational governance rules in conditional WHEN/REQUIRE/DEFAULT format
---

# Rules — Operational Governance

RULE-4: Forbidden Zones
```
WHEN:  write_operation(target)
REQUIRE: target ∈ permitted_areas (defined in project CLAUDE.md)
DEFAULT: BLOCK write. ASK owner for explicit authorization.
```
# intent: Protects sensitive infrastructure. Each project defines its own forbidden zones
  because context varies. Derives from INVARIANT-1 (regulated autonomy) + INVARIANT-3 (fail-closed).

RULE-6: Human-in-the-Loop
```
WHEN:  action.criticality ∈ {irreversible, recoverable_with_risk}
       OR action affects governance, shared state, or external systems
REQUIRE: Show delta. Get explicit confirmation. Provide rollback option.
DEFAULT: REFUSE. Present options to owner.
```
# intent: Critical actions need human judgment. "Just ask yes/no" is insufficient —
  show what will change. Derives from INVARIANT-1 + INVARIANT-5 (ownership).

RULE-10: Meta-Governance
```
WHEN:  governance_rule is {added, modified, deprecated}
REQUIRE:
  - Hierarchy maintained (invariants.md ↔ rules.md ↔ taxonomy.md)
  - Referential integrity checked (no orphan rules, no undefined terms)
  - Owner review + ADR for principle-level changes
DEFAULT: ESCALATE. Governance change requires owner approval.
```
# intent: Prevents governance drift. Orphaned rules are silent failures.
  Referential integrity keeps the system parseable. Derives from INVARIANT-2 + INVARIANT-6 + INVARIANT-7.
# backstop:
  INVARIANT-2 (Documentary Sovereignty) governs RULE-10 itself — changes to RULE-10 follow the same ADR + owner instruction requirement.

RULE-11: Session Integrity
```
WHEN:  session concludes (significant changes made OR context saturated)
REQUIRE: Run `/wrap`. Validates: memory updated, changes staged, governance checks passed.
DEFAULT: WARN before exit. Offer: "Save this session?"
```
# intent: `/wrap` is the authoritative close procedure. Ensures state transitions
  are atomic and recoverable. Derives from INVARIANT-2 + INVARIANT-5.

RULE-12: Memory Verification
```
WHEN:  action depends on memory entry naming {file, path, function, resource}
REQUIRE: Verify existence NOW (filesystem, code, or external system).
DEFAULT: If missing → update or remove memory entry. Proceed only if verified.
```
# intent: Prevents silent failures from stale memory. "Memory says X exists" ≠ "X exists."
  Catches refactors and deletions that invalidate prior knowledge.

---

## Escape Clause

```
WHEN:  situation does not match any rule above
REQUIRE: ASK owner. Document the case. Create ADR if precedent-setting.
DEFAULT: Apply INVARIANT-3 (fail-closed). BLOCK action.
         Use most conservative interpretation of invariants.
```
# intent: Prevents rule loopholes. Owner decision creates precedent for future cases.
  ADR records the reasoning so the gap can be closed with a proper rule.
