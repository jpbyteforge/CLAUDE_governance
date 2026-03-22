---
name: contraditorio
description: Análise adversarial/contraditório a uma análise prévia. Lança subagent com modelo diferente para criticar conclusões, expor ângulos mortos e identificar riscos subestimados.
argument-hint: [contexto opcional]
---

Executa uma análise de contraditório à última análise ou resposta relevante na conversa.

<contraditorio_protocol>

## Quando aplicar

Aplica contraditório apenas quando:
- A análise original envolve decisões de risco moderado ou alto
- Há trade-offs não triviais
- O utilizador pediu explicitamente `/contraditorio`

Não aplicar a: formatação, boilerplate, perguntas factuais simples, tarefas mecânicas.

## Execução

1. **Identificar o alvo**: localiza a análise/resposta mais recente na conversa que constitui o alvo do contraditório. Se $ARGUMENTS contiver contexto adicional, incorpora-o.

2. **Lançar subagent adversarial** com modelo diferente do usado na análise original:
   - Se análise original foi Haiku → subagent Sonnet
   - Se análise original foi Sonnet → subagent Haiku ou Opus
   - Se análise original foi Opus → subagent Sonnet

3. **Prompt do subagent** — usar exactamente esta estrutura:

```
Actua como crítico adversarial. A tua função é encontrar falhas, não confirmar.

## Análise a criticar
{inserir análise original}

## Instruções
Identifica com evidência concreta:
1. Conclusões não suportadas ou exageradas
2. Alternativas ignoradas (pelo menos 3)
3. Custos e riscos subestimados
4. Casos onde a proposta é contraproducente
5. Vieses da própria análise (confirmação, novidade, ancoragem, etc.)

Regras:
- Critica a acuidade, não a retórica. Objecções devem ser específicas e falsificáveis.
- Não sejas diplomático, mas cada crítica deve ter substância — sem ruído retórico.
- Se a análise original está correcta num ponto, diz-o explicitamente. Não forces objecções artificiais.
- Termina com um veredicto: em que condições a análise original é válida e em que condições falha.

Responde em português (PT-PT).
```

4. **Apresentar resultado** ao utilizador com esta estrutura:

```
## Contraditório

{output do subagent — integral, sem filtrar}

---

## Reconciliação

{síntese em 3-5 pontos: onde a análise original se mantém, onde cede, e o que muda na recomendação final}
```

## Princípios operacionais

- **Acuidade > agressividade**: objecções específicas e falsificáveis, não retórica combativa
- **Não fingir independência**: reconhecer que o contraditório partilha limitações com a análise original (mesma base factual, mesma janela de contexto)
- **Não criar falsa confiança**: o contraditório cobre mais terreno, não cobre todo o terreno. Dizer explicitamente o que fica por verificar
- **Verificação factual é separada**: o contraditório critica lógica e enquadramento, não verifica dados. Se a análise depende de factos, a verificação factual é uma tarefa à parte

</contraditorio_protocol>
