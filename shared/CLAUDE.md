## Tier — resposta ao hook

Cada prompt recebe `[MODEL_TIER] TIER | /model MODEL_ID` via hook.

- Tier recomendado < modelo activo → primeira linha: `Recomendo /model <id> para esta tarefa.`
- Tier recomendado ≥ modelo activo → silêncio.

Binário. Sem excepções.

## Ferramentas — ordem de preferência

- Grep primeiro, depois Read com `offset`/`limit`. Nunca ler ficheiros inteiros para encontrar uma função.
- Ficheiros >200 linhas: sempre `offset`/`limit` no Read.
- Tool calls independentes: sempre em paralelo.
- Tarefas >3 ficheiros: Plan mode antes de implementar.

## Subagents

| Tipo | Modelo | Quota/sessão |
|------|--------|-------------|
| Pesquisa / read-only | `haiku` | ilimitado |
| Escrita de código | `sonnet` mínimo | 1 |
| Contraditório / arquitectura | `opus` | 2 |
| **Total write** | | **10** |

## Contexto — não carregar preventivamente

- Não ler CHANGELOG, README, ficheiros adjacentes sem evidência de relevância.
- Não ler testes antes de os correr — correr primeiro, ler só se falharem.
- Não ler git log/blame sem necessidade concreta.
