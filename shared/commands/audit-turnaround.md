---
name: audit-turnaround
description: Auditoria operacional e turnaround de projectos. Diagnóstico causal, remoção de fricções reais, estabilização.
argument-hint: [path-do-projecto]
---

Auditoria operacional ao projecto em $ARGUMENTS.

Fórmula: REENQUADRAR → MEDIR → DIAGNOSTICAR → INTERVIR → VALIDAR. Cada fase tem gate — sem o passar, não avançar.

Objectivo: melhorar outputs, reduzir risco, estabilizar. Melhorias sem impacto operacional mensurável são irrelevantes.

---

FASE 0 — REENQUADRAR

Lê CLAUDE.md, README, pyproject.toml e Makefile. Responde com factos:
1. O projecto existe para quê?
2. Qual é o output consumido por alguém?
3. O que acontece se o sistema parar hoje?
4. Baseline actual de funcionamento?

Gate: 4 respostas concretas com referência a outputs reais.

---

FASE 1 — MEDIR

Executa — não inferir resultados. Correr em paralelo tudo o que for independente.

**1a. Estado do sistema**
- Correr testes: N passed, N failed, N skipped, tempo
- Contar ficheiros de output. Verificar timestamps — o sistema está vivo?
- Ler últimos 1-3 registos de output do pipeline

**1b. Arqueologia git**
- Hotspots: `git log --format=format: --name-only | sort | uniq -c | sort -rn | head -15`
- Padrão de falhas: `git log --oneline --grep="fix\|bug\|crash\|broken" | head -10`

**1c. Anti-patterns** — grep em *.py excluindo tests/:
- Excepções engolidas: `except.*pass`, `except.*continue`
- Paths relativos: `Path("[^/]`
- Incerteza: `TODO|FIXME|HACK|WORKAROUND|XXX`
- Complexidade: wc -l top 10 maiores

**1d. Espaço negativo** — o que DEVIA existir e não existe:
- Logging nos caminhos de erro? Alertas de falha? Health check? Backup/recovery?

Gate: tabela preenchida com dados medidos.

| Dimensão | Estado (com evidência) |
|----------|----------------------|
| Funciona | |
| Falha | |
| Frágil | |
| Não determinístico | |
| Cobertura de testes | N/M passed (X%) em Xs |
| Última execução | [timestamp] |

---

FASE 2 — DIAGNOSTICAR

Classifica cada problema:
- **A)** Bloqueador — impede entrega de valor
- **B)** Risco latente — segurança, integridade, continuidade
- **C)** Ineficiência com custo real
- **D)** Dívida estética — NÃO entra no plano

D que causa A/B/C → reclassifica com justificação causal. Sem ficheiro:linha e impacto quantificável → não é achado, é opinião → elimina.

Qualificação: [FACTO] (verificado), [INFERÊNCIA] (dedução), [NÃO CONFIRMADO] (sem evidência directa). Achados só [NÃO CONFIRMADO] → escalar como pergunta, não entram no plano.

Antes de classificar A/B, procurar evidência contrária.

Formato:
```
[ID] [A/B/C] Título
- Ficheiro: path:linha
- Causa raiz: 1 frase
- Impacto: o que falha, quem, frequência
- Evidência: [FACTO/INFERÊNCIA/NÃO CONFIRMADO] + dados
```

Calibração: código feio que funciona ≠ problema. Código bonito que falha em silêncio = problema. Pergunta: "causa perda de valor, tempo ou confiança?"

Gate: zero frases como "considerar", "poderia", "seria bom".

---

FASE 3 — INTERVIR

Max 7 intervenções, ordenadas por impacto operacional. >7 = má priorização.

Para cada:
1. Problema que resolve (ref ID)
2. Ganho esperado (mensurável)
3. Riscos introduzidos
4. Reversibilidade
5. Teste de necessidade: "o que acontece se NÃO fizermos isto?" → se "nada" → eliminar

Propor alteração concreta (ficheiro, função, mudança). Sem reescritas totais, abstrações genéricas ou optimizações sem pressão real.

Gate: cada intervenção passa teste de necessidade E tem ganho mensurável.

---

FASE 4 — VALIDAR (se o dono aprovar)

1. Correr testes — comparar com baseline
2. Validar happy path end-to-end
3. Forçar falha previsível — o sistema reage?
4. Confirmar ganho real vs baseline com números

Sem melhoria clara → reverter.

---

FASE 5 — ENCERRAR

Termina quando: sistema mais estável (demonstrado), riscos conhecidos, valor recuperado explícito. Decisão de encerramento é do dono.

---

Output:

## Reenquadramento
[4 respostas factuais]

## Baseline
[Tabela preenchida]

## Diagnóstico
[Achados A/B/C com formato standard]

## Plano de Intervenção
[Max 7, ordenadas por impacto]

## Estado Actual vs Alvo
[Tabela comparativa]
