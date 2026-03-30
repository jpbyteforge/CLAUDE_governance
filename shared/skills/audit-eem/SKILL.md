---
name: audit-eem
description: Auditoria completa de qualidade do EEM. Verifica marcadores, rastreabilidade, bibliografia e contagem de palavras.
disable-model-invocation: true
---

# Auditoria EEM

Executa uma auditoria de qualidade ao Rascunho Zero do EEM. Analisa sistematicamente o documento contra os criterios de avaliacao (FAV) e as regras de rigor definidas no CLAUDE.md.

## Checklist de Verificacao

### 1. Marcadores de classificacao
- Percorrer todas as afirmacoes factuais nas seccoes 1 (Problema), 3 (Factos) e 4 (Analise)
- Cada afirmacao deve ter um marcador: `[FACTO — fonte]`, `[INFERENCIA — raciocinio]` ou `[NAO CONFIRMADO]`
- Contar: total de afirmacoes, marcadas vs. nao marcadas
- Reportar percentagem de cobertura

### 2. Rastreabilidade
- Para cada citacao no corpo do EEM, verificar a cadeia completa:
  - Documento Fonte (em `Documentos Fonte/`) → Extracao (em `Extracoes/`) → referencia no Vault ou Rascunho
- Verificar se o `Extracoes/_extraction_manifest.json` esta actualizado
- Listar citacoes sem cadeia completa

### 3. Bibliografia
- Extrair todas as referencias citadas no Rascunho Zero (autores, anos, diplomas legais)
- Verificar que cada uma existe no `Bibliografia.ris`
- Contar entradas totais no Bibliografia.ris
- Reportar citacoes em falta

### 4. Contagem de palavras
Verificar alvos por seccao:

| Seccao | Alvo | Tolerancia |
|--------|------|------------|
| 1. Problema | 200 | ±50 |
| 2. Hipoteses | 100 | ±30 |
| 3. Factos | 600 | ±100 |
| 4. Analise | 1400 | ±200 |
| 5. Conclusoes | 200 | ±50 |
| 6. Recomendacoes | 150 | ±50 |
| **TOTAL** | **~2650** | 3000±500 |

### 5. Equilibrio FAV
- Factos devem ocupar ≤25% do corpo (10% da nota)
- Analise deve ocupar ≥50% do corpo (30% da nota)
- Calcular percentagens actuais e comparar

### 6. Placeholders pendentes
- Procurar todos os marcadores: `[A COMPLETAR`, `[A REDIGIR`, `[A PREENCHER`, `[A DEFINIR`, `[A CRIAR`, `[ENT]`
- Classificar por tipo: dependente de entrevistas, dependente de orientador, pode ser feito agora

### 7. Governacao
- Ler `Vault/00 - Indice/Auditoria do EEM - Checklist de Coerencia.md`
- Verificar itens marcados vs. pendentes
- Comparar com achados anteriores em `memory/audit-content.md`

## Ficheiros a analisar
- `03 - Rascunhos/EEM - Rascunho Zero.md` — corpo principal
- `03 - Rascunhos/Matriz AEA - Indicadores e Avaliacao.md` — indicadores e pesos
- `Bibliografia.ris` — base bibliografica
- `Extracoes/_extraction_manifest.json` — manifesto de extracoes
- `Vault/00 - Indice/Auditoria do EEM - Checklist de Coerencia.md` — checklist de governacao
- `CLAUDE.md` — regras de rigor (referencia)

## Formato do Output

```markdown
# Auditoria EEM — [DATA]

## Resumo
- Marcadores: X/Y afirmacoes classificadas (Z%)
- Bibliografia: X citacoes verificadas, Y em falta
- Palavras: XXXX/2650 (XX%)
- Placeholders: X pendentes (Y dependem de entrevistas)
- Governacao: X/10 itens completos

## Achados

### [Severidade A] — Bloqueante
...

### [Severidade B] — Importante
...

### [Severidade C] — Menor
...

## Comparacao com auditoria anterior
- Achados resolvidos desde ultima auditoria
- Novos achados
- Achados persistentes
```
