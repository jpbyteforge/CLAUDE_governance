---
name: extract-pdf
description: Extrai texto de um PDF/DOCX/PPTX, cria markdown na pasta Extracoes e actualiza o manifesto.
disable-model-invocation: true
---

# Extracao de Documento Fonte

Extrai texto de um documento e cria ficheiro markdown na pasta `Extracoes/`.

## Argumentos
- **Caminho do ficheiro** (obrigatorio): caminho relativo ou absoluto do documento a extrair
- Se nao fornecido, perguntar ao utilizador

## Workflow

### 1. Identificar tipo de documento
- `.pdf` → verificar se tem texto extraivel (testar com PyMuPDF)
  - Se ≥100 caracteres por pagina → extracao de texto
  - Se <100 caracteres → OCR (documento digitalizado)
- `.docx` → extracao de texto com python-docx
- `.pptx` → extracao de texto com python-pptx
- `.xlsx` → extracao de tabelas com openpyxl

### 2. Extrair conteudo

**Para PDF com texto ou DOCX/PPTX/XLSX:**
```bash
"C:\Users\jorge\AppData\Local\Programs\Python\Python313\python.exe" "Scripts/extract_all.py" "<caminho_do_ficheiro>"
```

**Para PDF digitalizado (OCR):**
```bash
"C:\Users\jorge\AppData\Local\Programs\Python\Python313\python.exe" "Scripts/extract_ocr.py" "<caminho_do_ficheiro>" --lang por+eng
```

### 3. Verificar resultado
- Confirmar que o ficheiro .md foi criado em `Extracoes/`
- Verificar que o `_extraction_manifest.json` foi actualizado
- Reportar: nome do ficheiro, metodo, numero de paginas, caracteres extraidos

### 4. (Opcional) Criar nota no Vault
- Perguntar ao utilizador se deseja criar uma nota curada no Vault
- Se sim, identificar a pasta correcta do Vault (01-08) com base no conteudo
- Criar nota com frontmatter YAML (title, tags, source, category, date_created, status)

## Recursos disponiveis

| Recurso | Localizacao |
|---------|-------------|
| Python 3.13 | `C:\Users\jorge\AppData\Local\Programs\Python\Python313\python.exe` |
| Tesseract OCR | `C:\Program Files\Tesseract-OCR\tesseract.exe` |
| Tessdata (por+eng) | `C:\Users\jorge\tessdata\` |
| Script geral | `Scripts/extract_all.py` |
| Script OCR | `Scripts/extract_ocr.py` |
| Manifesto | `Extracoes/_extraction_manifest.json` |

## Convencoes
- Nome do ficheiro de saida: mesmo nome do original, com extensao `.md`
- Header do markdown: titulo, fonte, metodo, data de extracao, contagem de caracteres
- Encoding: UTF-8 (reconfigure stdout para evitar crashes com caracteres portugueses)
- Acentos nos nomes de ficheiro: atenção a NFC vs NFD no Windows/OneDrive

## Notas
- O script `extract_all.py` ja actualiza o manifesto automaticamente
- O script `extract_ocr.py` tambem actualiza o manifesto
- Se o ficheiro ja tiver sido extraido (existe no manifesto), perguntar se deve ser re-extraido
