# /nep-docx — Gerar ou rever DOCX segundo NEP INV 003 + IGA 2(B)

Guia Claude para gerar, rever ou corrigir documentos Word (.docx) segundo
as normas do IUM: NEP INV 003 (A3) e IGA 2(B) Anexo D.

## Hierarquia normativa

IGA 2(B) > FAV > NEP INV 003 — em caso de conflito, IGA 2(B) prevalece.

## Formatação obrigatória (NEP INV 003 + IGA 2(B))

| Elemento | Valor |
|----------|-------|
| Fonte | Times New Roman 12pt |
| Espaçamento | 1,5 linhas |
| Margem esq. | 3 cm |
| Margem dir. | 2,5 cm |
| Margem sup./inf. | 2,5 cm |
| Parágrafo | Sem espaço entre §§; 1ª linha recuada 1 cm |
| Cabeçalho/Rodapé | Distância 1,5 cm |
| Classificação | Topo E fundo de cada página |
| Paginação | Romano (pré-texto) → Árabe (corpo) → Anx X-N (anexos) |

## Estrutura do trabalho escolar IUM

```
Capa (sem nº de página)
Folha de rosto (sem nº de página)
[Classificação se aplicável]
Declaração de Honra
Agradecimentos (opcional)
Resumo (PT) + Abstract (EN)  → i, ii, ...
Índice Geral                  → iii, ...
Índice de Figuras/Tabelas
Lista de Abreviaturas
Introdução                    → 1, 2, ...
Capítulos
Conclusão
Referências Bibliográficas
Anexos                        → Anx A-1, Anx A-2, Anx B-1, ...
Apêndices                     → Apd A-1, ...
```

## Estilos Word obrigatórios

- `Heading 1` → Capítulo (TNR 12pt, bold, numerado: 1., 2., ...)
- `Heading 2` → Secção (TNR 12pt, bold, numerado: 1.1., 1.2., ...)
- `Heading 3` → Subsecção (TNR 12pt, bold itálico, numerado: 1.1.1., ...)
- Corpo de texto → Normal (TNR 12pt, 1,5 linhas)
- Notas de rodapé → TNR 10pt, espaçamento simples
- Legendas de figuras/tabelas → TNR 9pt, centrado, abaixo do elemento

## Procedimento para geração

1. Confirma o fonte de conteúdo (ficheiro .md, texto fornecido, ou ficheiro existente)
2. Identifica o projecto e o template aplicável (EEM/CPOS-M ou outro)
3. Verifica se existe `generate_docx.py` no projecto — se sim, usa-o
4. Se não existe script, usa python-docx para gerar respeitando a formatação acima
5. Valida: contagem de palavras, secções obrigatórias, paginação, classificação

## Procedimento para revisão de DOCX existente

1. Abre o ficheiro e verifica margens, fonte, espaçamento
2. Verifica paginação por secção (romano/árabe/anexo)
3. Verifica cabeçalhos e rodapés com classificação
4. Verifica referências bibliográficas (→ usar /apa-citation para cada entrada)
5. Reporta desvios com referência à norma violada (IGA 2(B) §X ou NEP INV 003 §X)

## Limites de palavras (trabalhos CPOS-M)

- EEM: 3000 ± 500 palavras no corpo (Introdução → Conclusão, excluindo referências e anexos)
- TIG/outros: verificar FAV do curso específico

## Notas

- Figuras e tabelas numeradas sequencialmente (Figura 1, Figura 2, ...)
- Tabelas com header repeat em quebras de página (python-docx: `tbl_header=True`)
- Rodapé de anexo: "Anx X-N" alinhado à direita, página relativa ao anexo
