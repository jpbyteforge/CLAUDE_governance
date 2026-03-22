---
name: contraditorio
description: Adversarial analysis / rebuttal of a prior analysis. Launches a subagent with a different model to critique conclusions, expose blind spots and identify underestimated risks.
argument-hint: [optional context]
---

Execute an adversarial rebuttal of the last relevant analysis or response in the conversation.

<contraditorio_protocol>

## When to apply

Apply rebuttal only when:
- The original analysis involves moderate or high-risk decisions
- There are non-trivial trade-offs
- The user explicitly requested `/contraditorio`

Do not apply to: formatting, boilerplate, simple factual questions, mechanical tasks.

## Execution

1. **Identify the target**: locate the most recent analysis/response in the conversation that constitutes the rebuttal target. If $ARGUMENTS contains additional context, incorporate it.

2. **Launch adversarial subagent** with a different model than the one used in the original analysis:
   - If original analysis was Haiku → subagent Sonnet
   - If original analysis was Sonnet → subagent Haiku or Opus
   - If original analysis was Opus → subagent Sonnet

3. **Subagent prompt** — use exactly this structure:

```
Act as an adversarial critic. Your function is to find flaws, not to confirm.

## Analysis to critique
{insert original analysis}

## Instructions
Identify with concrete evidence:
1. Unsupported or exaggerated conclusions
2. Ignored alternatives (at least 3)
3. Underestimated costs and risks
4. Cases where the proposal is counterproductive
5. Biases in the analysis itself (confirmation, novelty, anchoring, etc.)

Rules:
- Critique accuracy, not rhetoric. Objections must be specific and falsifiable.
- Do not be diplomatic, but each critique must have substance — no rhetorical noise.
- If the original analysis is correct on a point, say so explicitly. Do not force artificial objections.
- End with a verdict: under what conditions the original analysis is valid and under what conditions it fails.

Reply in English.
```

4. **Present result** to the user with this structure:

```
## Rebuttal

{subagent output — complete, unfiltered}

---

## Reconciliation

{synthesis in 3-5 points: where the original analysis holds, where it yields, and what changes in the final recommendation}
```

## Operational principles

- **Accuracy > aggression**: specific and falsifiable objections, not combative rhetoric
- **Do not fake independence**: acknowledge that the rebuttal shares limitations with the original analysis (same factual base, same context window)
- **Do not create false confidence**: the rebuttal covers more ground, not all ground. State explicitly what remains unverified
- **Fact-checking is separate**: the rebuttal critiques logic and framing, not data. If the analysis depends on facts, fact-checking is a separate task

</contraditorio_protocol>
