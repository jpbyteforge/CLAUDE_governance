---
name: wrap
description: Fecha sessao — verifica integridade, regista memoria e reporta pendentes
---

## 1. Verificacao estrutural
- MEMORY.md ↔ ficheiros `memory/`: ponteiros bidirecionais integros?
- Path do projecto Claude activo existe no disco? (detecta fantasmas)
- CLAUDE.md → `rules/`: referencias resolvem? (invariants.md, invariants.yaml, rules.md)

Reporta quebras como `[LINK QUEBRADO] origem → destino`. Nao actua — so reporta.

## 2. Invariants check
Verificar explicitamente cada invariant desta sessao:

  INV-001 no_write_outside_workspace → OK | VIOLATION
  INV-002 no_self_permission_escalation → OK | VIOLATION
  INV-003 authority_basis → OK | VIOLATION

  coverage: N/3
  violations: N

Se violations > 0: registar em incident_log.jsonl com campo invariant preenchido.

## 3. Incident summary (sessao)
Agregar eventos do incident_log desta sessao:

  block: N
  warn: N
  override: N
  drift: N

  top_rules: (top 3, ordem desc por frequencia)
  - REGRA: N

Input directo para mini-E2. Se todos zero: OK.
(sessao = eventos desde ultimo /wrap)

## 4. Deploy drift
- Executar `python ~/.claude/deploy_w11.py --verify` e reportar resultado
- Se drift > 0: sugerir `python deploy_w11.py --reverse` para ficheiros em reverse_sync
- Advisory — nao bloqueia /wrap

## 5. Pendentes (classificados)
- `git status --short` nos repos tocados nesta sessao (incluindo `~/.claude/`)
- Tasks/todos abertos sem completar
- Planos criados mas nao executados

Classificar por severidade:

  critical: accoes bloqueantes para proxima sessao
  high:     pendentes com impacto real se nao resolvidos
  medium:   desejaveis mas nao urgentes
  low:      informativos

## 6. Memoria
Actualiza `memory/` e/ou `CLAUDE.md` do projecto activo. So o que mudou.
Sem duplicar codigo ou git. Sem detalhe tecnico excessivo.

## 7. Higiene operacional (nao-bloqueante)
Informativo — nao afecta governacao:
- `~/.claude/debug/` > 20 MB?
- `shell-snapshots/` > 50 ficheiros?
- Memorias > 90 dias sem edicao?

## 8. Session outcome
Estruturado (nao narrativo):

  completed: [lista compacta]
  pending:   [lista compacta]
  mode_next_session: [instrucao para proxima sessao]

Mini-E2 trigger: quando incident_log atingir 20-50 eventos.
