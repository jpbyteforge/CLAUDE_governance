---
name: verify
description: Deterministic correctness check — logic, constraints, edge cases. Use when there is a single correct answer, not competing options.
argument-hint: [optional: specific output or code to verify]
---

Use when exactness is required: technical execution, logic validation, invariant compliance, critical output.
Do NOT use for trade-offs, architecture, or decisions with multiple valid options — use /contraditorio instead.

<verify_protocol>

## When to apply

Apply when:
- There is a single correct answer (not competing valid options)
- Rules or invariants are explicitly defined
- Output correctness is verifiable, not opinionable

Do not apply to: strategic decisions, trade-offs, architecture choices, governance under uncertainty.

## Execution

1. **Identify target**: the output, code, logic, or decision to verify. Use  if provided, otherwise the last substantive output in the conversation.

2. **Run checks** — for each, state PASS or FAIL with specific evidence:

   **Logical correctness**
   - Are all steps consistent and complete?
   - Are there contradictions or gaps in reasoning?

   **Constraint compliance**
   - Does the output comply with all active rules (invariants.yaml, rules.md, project CLAUDE.md)?
   - Are forbidden zones, authority requirements, and fail-closed rules respected?

   **Edge cases**
   - What are the boundary conditions?
   - Does the output handle them correctly or explicitly scope them out?

   **Consistency**
   - Would re-execution produce the same result?
   - Are there non-deterministic dependencies?

3. **Failure modes** — list any:
   - Deterministic errors (logic bug, wrong output)
   - Critical omissions (missing required check)
   - Unverified dependencies (assumptions not confirmed)

4. **Verdict**

   PASS — output is correct within verified scope
   FAIL — output has deterministic error(s)

   If FAIL:
   - exact location of error
   - minimum correction required

5. **Confidence**

   HIGH   — all checks passed, scope fully verifiable
   MEDIUM — some dependencies unverified or scope partial
   LOW    — significant unverified assumptions

   State explicitly what remains unverified.

## Operational principles

- **Correctness over coverage**: a partial but rigorous check is better than a full but superficial one
- **No false balance**: if there is a correct answer, say so — do not introduce artificial doubt
- **Invariants take precedence**: any invariant violation is automatic FAIL, regardless of other checks
- **Failures go to incident_log**: if a governance rule or invariant is violated, log as block/INV-XXX

</verify_protocol>
