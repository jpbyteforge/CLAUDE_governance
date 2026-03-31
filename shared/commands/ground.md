---
name: ground
description: Source-grounded verification — verbatim accuracy, semantic fidelity, attribution traceability. Use for academic work, factual claims, and any output that must be traceable to an external source.
argument-hint: [optional: specific text or claim to verify]
---

Use when truth depends on external sources: academic writing, factual claims, citations, paraphrases.
Do NOT use for logical structure (/verify) or decision trade-offs (/contraditorio).

Rule: if it depends on a source → /ground. If it depends on logic → /verify. If it depends on choice → /contraditorio.

<ground_protocol>

## When to apply

Apply when:
- Output includes citations, quotes, or paraphrases of external sources
- Claims must be traceable to a primary or secondary source
- Semantic fidelity to the original is required (academic, legal, technical documentation)

Do not apply to: pure logical derivations, internal system decisions, architectural trade-offs.

## Execution

1. **Identify target**: the text, argument, or paragraph to verify. Use  if provided, otherwise the last substantive output in the conversation.

2. **Identify sources**: explicit list provided by user OR perform explicit retrieval step.
   If sources are not available:
   → BLOCK grounding. Do not attempt reconstruction from memory (B3).
   → Request sources from user OR perform explicit retrieval before proceeding.
   Do not proceed with memory-inferred "implicit sources" — this silently violates B3.

3. **Run checks** — for each claim in the target:

   **Claim granularity**: a claim = smallest independently falsifiable unit. Decompose compound sentences before checking. Example: "X causes Y in most cases" = 3 claims: (a) X causes Y; (b) this is causal, not correlational; (c) it holds in most cases. Each sub-claim must be classified independently.


   **Verbatim accuracy**
   - Do quotes match the source exactly?
   - Does any truncation, ellipsis, or paraphrase change meaning?
   - Flag: modified quotes presented as verbatim

   **Source attribution**
   - Is every factual claim linked to a source?
   - Classify source type: primary | secondary | inferred | unattributed
   - Flag: claims presented as sourced but unattributed

   **Semantic fidelity**
   - Does the paraphrase preserve the original meaning?
   - Any exaggeration, simplification, or distortion?
   - Flag: plausible-but-false paraphrase

   **Scope alignment**
   - Is the claim used in the same context as the source?
   - Any out-of-context citation?
   - Flag: cherry-picking or context stripping

4. **Classify each claim**:

   [SOURCE-VERIFIED]   — verbatim or faithful paraphrase with confirmed source
   [PARTIAL]           — claim is directionally correct but imprecise or partially sourced
   [MISREPRESENTED]    — claim distorts, exaggerates, or strips context from source
   [UNSUPPORTED]       — no source found or source does not support the claim

5. **Verdict**

   VALID   — all claims SOURCE-VERIFIED or PARTIAL with minor corrections
   PARTIAL — mix of verified and unsupported; specify which claims fail
   INVALID — MISREPRESENTED or UNSUPPORTED claims that materially affect the argument

   **Strict mode** (academic/legal contexts — activate when user requests or when precision is critical):
   If ANY core claim ≠ SOURCE-VERIFIED → verdict cannot be VALID.
   Core claim = any claim that, if wrong, invalidates the argument's main conclusion.
   In strict mode, PARTIAL core claims force verdict to PARTIAL minimum.

   If PARTIAL or INVALID:
   - exact location of failure
   - minimum correction to restore fidelity

6. **Traceability map** (per claim):

   claim: [text excerpt]
   source: [reference]
   quote: [exact verbatim if applicable]
   mapping: quote → claim (faithful | distorted | inferred)

7. **Confidence**

   HIGH   — sources available, checks complete, verbatim confirmed
   MEDIUM — sources available but paraphrase-only, or scope partially verified
   LOW    — sources unavailable or unverifiable; note explicitly

   State what remains unverified. Do not present LOW confidence results as conclusions.

## Operational principles

- **Source primacy**: external source overrides model memory (B3)
- **No hallucinated consensus**: if a claim cannot be sourced, classify as UNSUPPORTED — do not infer from plausibility
- **Verbatim before paraphrase**: always prefer exact quote when traceability is required
- **Grounding failures go to incident_log**: classify as type grounding_failure with severity proportional to impact

## Incident log integration

If MISREPRESENTED or UNSUPPORTED claims are found, log:

  type: grounding_failure
  severity: high (MISREPRESENTED) | medium (UNSUPPORTED)
  rule: B1 (evidence over persuasion)
  action: ground_check
  resource: [source reference]
  reason: [classification + description]
  resolution: [correction applied or flagged to user]

</ground_protocol>
