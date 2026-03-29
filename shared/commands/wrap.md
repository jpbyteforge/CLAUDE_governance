---
name: wrap
description: Fecha sessão — verifica integridade, regista memória e reporta pendentes
---

## 1. Verificação
- MEMORY.md ↔ ficheiros `memory/`: ponteiros bidirecionais íntegros?
- Path do projecto Claude activo existe no disco? (detecta fantasmas)
- CLAUDE.md → `rules/`: referências resolvem?
- `~/.claude/debug/` > 20 MB? `shell-snapshots/` > 50 ficheiros? Memórias > 90 dias sem edição?

Reporta quebras como `[LINK QUEBRADO] origem → destino`. Não actua — só reporta.

## 2. Pendentes
- `git status --short` nos repos tocados nesta sessão
- Tasks/todos abertos sem completar
- Planos criados mas não executados

## 3. Memória
Actualiza `memory/` e/ou `CLAUDE.md` do projecto activo. Só o que mudou.
Sem duplicar código ou git. Sem detalhe técnico excessivo.

## 4. Sumário
Lista compacta: o que foi actualizado e o que fica pendente para a próxima sessão.
