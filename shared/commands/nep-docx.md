# /nep-docx — Generate or revise DOCX according to NEP INV 003 + IGA 2(B)

Guide for Claude to generate, revise or correct Word (.docx) documents according to
IUM standards: NEP INV 003 (A3) and IGA 2(B) Annex D.

## Normative hierarchy

IGA 2(B) > FAV > NEP INV 003 — in case of conflict, IGA 2(B) prevails.

## Mandatory formatting (NEP INV 003 + IGA 2(B))

| Element | Value |
|---------|-------|
| Font | Times New Roman 12pt |
| Spacing | 1.5 lines |
| Left margin | 3 cm |
| Right margin | 2.5 cm |
| Top/bottom margin | 2.5 cm |
| Paragraph | No space between paragraphs; 1st line indented 1 cm |
| Header/Footer | Distance 1.5 cm |
| Classification | Top AND bottom of each page |
| Pagination | Roman (pre-text) → Arabic (body) → Anx X-N (annexes) |

## IUM academic paper structure

```
Cover page (no page number)
Title page (no page number)
[Classification if applicable]
Declaration of Honour
Acknowledgements (optional)
Abstract (PT) + Abstract (EN)  → i, ii, ...
Table of Contents               → iii, ...
List of Figures/Tables
List of Abbreviations
Introduction                    → 1, 2, ...
Chapters
Conclusion
References
Annexes                         → Anx A-1, Anx A-2, Anx B-1, ...
Appendices                      → Apd A-1, ...
```

## Mandatory Word styles

- `Heading 1` → Chapter (TNR 12pt, bold, numbered: 1., 2., ...)
- `Heading 2` → Section (TNR 12pt, bold, numbered: 1.1., 1.2., ...)
- `Heading 3` → Subsection (TNR 12pt, bold italic, numbered: 1.1.1., ...)
- Body text → Normal (TNR 12pt, 1.5 lines)
- Footnotes → TNR 10pt, single spacing
- Figure/table captions → TNR 9pt, centred, below the element

## Generation procedure

1. Confirm the content source (.md file, provided text, or existing file)
2. Identify the project and applicable template (EEM/CPOS-M or other)
3. Check if `generate_docx.py` exists in the project — if so, use it
4. If no script exists, use python-docx to generate respecting the formatting above
5. Validate: word count, mandatory sections, pagination, classification

## DOCX revision procedure

1. Open the file and check margins, font, spacing
2. Check pagination by section (roman/arabic/annex)
3. Check headers and footers with classification
4. Check bibliographic references (→ use /apa-citation for each entry)
5. Report deviations with reference to the violated standard (IGA 2(B) §X or NEP INV 003 §X)

## Word limits (CPOS-M papers)

- EEM: 3000 ± 500 words in body (Introduction → Conclusion, excluding references and annexes)
- TIG/other: check course-specific FAV

## Notes

- Figures and tables numbered sequentially (Figure 1, Figure 2, ...)
- Tables with header repeat on page breaks (python-docx: `tbl_header=True`)
- Annex footer: "Anx X-N" right-aligned, page relative to the annex
