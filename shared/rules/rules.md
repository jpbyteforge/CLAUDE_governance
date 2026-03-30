---
version: 2.3
type: governance
scope: global
date: 2026-03-30
---

# Rules

Terms: Sovereign Doc (CLAUDE.md, rules/*, ADRs) > code > config > output.
       Forbidden Zone = project-defined no-write area. Fail-Closed = no rule -> blocked.
       Full taxonomy: reference/taxonomy.md

R4 Forbidden Zones
  WHEN write_operation(target)
  REQUIRE target in permitted_areas (project CLAUDE.md)
  DEFAULT BLOCK. ASK owner.
  # Derives: INV-1 + INV-3

R6 Human-in-the-Loop
  WHEN action is irreversible OR affects governance/shared state/external systems
  REQUIRE show delta + explicit confirmation + rollback option
  DEFAULT REFUSE. Present options.
  # Derives: INV-1 + INV-5

R10 Meta-Governance
  WHEN governance_rule added/modified/deprecated
  REQUIRE hierarchy maintained + referential integrity + owner review
  REQUIRE ADR for principle-level changes
  DEFAULT ESCALATE.
  # Derives: INV-2 + INV-6 + INV-7. Backstop: INV-2 governs R10 itself.

R11 Session Integrity
  WHEN session concludes (significant changes OR context saturated)
  REQUIRE /wrap (memory, staged changes, governance checks)
  DEFAULT WARN before exit.
  # Derives: INV-2 + INV-5

R12 Memory Verification
  WHEN action depends on memory naming {file, path, function, resource}
  REQUIRE verify existence NOW
  REQUIRE path_resolution_check: if memory names a path, verify it resolves from current project context
  DEFAULT if missing or unresolvable -> update/remove memory. Proceed only if verified.
  # "Memory says X exists" != "X exists". "Memory path resolves" must also be verified.

Escape: no matching rule -> ASK owner + INV-3 (fail-closed). ADR if precedent-setting.
