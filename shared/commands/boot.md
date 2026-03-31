---
name: boot
description: Inicio de sessao — hydrate minimo + orientacao + risco imediato
---

## 1. Contexto activo

* CLAUDE.md carregado: verificar auto-load
* rules/ resolve: invariants.md, invariants.yaml, rules.md → OK | MISSING

Se qualquer ficheiro L0 em falta: reportar antes de continuar.

## 2. Estado herdado (ultimo /wrap)

Fonte unica (precedencia):
  1. memory/project_governance_v2.md (session outcome persistido)
  2. fallback: ultimo bloco em incident_log.jsonl



  pending:          [lista compacta do ultimo wrap]
  mode_next_session: [modo definido]

Se nao houver wrap anterior: NONE — sessao fresh.

## 3. Governacao — quick check

Verificar incident_log.jsonl (ultimas entradas):

  ultimo wrap: violations? → NO | YES (destacar)
  Se incident_log vazio: assumir baseline limpo (0/0/0/0)
  block:    N
  warn:     N
  override: N
  drift:    N

Se block > 0 ou override > 0 desde ultimo wrap:
→ ATENCAO: destacar antes de continuar

## 4. Working focus

  tarefa_activa: [se explicitada pelo utilizador] | NONE — aguardar instrucao
  pendente_prioritario: [critical/high do ultimo wrap, se existir]

## 5. Principios activos (resumo operacional)

  A3 fail-closed:     unknown rule = BLOCK
  A1 authority:       action requires documented basis
  A4 no self-elevation
  B3 verify-before-act: memory reference → check existence first

(Nao listar tudo — apenas os 4 invariantes operacionais)

## 6. Ready state

  status: READY

  proxima_accao:
  - continuar pendente mais prioritario (se existir)
  - aguardar instrucao (se NONE)

---
Notas de design:
- Nao fazer scan completo de memory/ (C1 lazy loading)
- Nao ler docs sem evidencia de relevancia
- Nao planear — apenas posicionar
- sessao = desde este boot ate proximo /wrap
