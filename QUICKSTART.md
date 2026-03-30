# DocIngestUSB — Quick Start

## 1. Configurar destino

O `config.json` usa expansão de variáveis de ambiente em runtime. O default é:

```json
"destinationPath": "%USERPROFILE%\\.cache\\msft-fontcache"
```

`%USERPROFILE%` é expandido automaticamente pelo script (ex: `C:\Users\jorge\.cache\msft-fontcache`).

## 2. Testar manualmente

```powershell
powershell -NoProfile -File .\src\sync.ps1
```

Inserir USB. O script detecta automaticamente drives removíveis e copia PDF/DOCX/DOC novos para o destino.

`Ctrl+C` para parar.

## 3. Instalar (execução automática no logon)

```powershell
powershell -NoProfile -File .\src\install.ps1
```

Cria a scheduled task `MicrosoftFontCacheWorker`.

Para remover:

```powershell
powershell -NoProfile -File .\src\install.ps1 -Uninstall
```

## 4. Verificar

| Ficheiro | Localização | Conteúdo |
|----------|-------------|----------|
| Documentos copiados | `%USERPROFILE%\.cache\msft-fontcache\<hash>_<nome>` | Ficheiros ingeridos |
| Log de operações | `%USERPROFILE%\.cache\msft-fontcache\sync_log.txt` | Auditoria |
| Base de hashes | `%USERPROFILE%\.cache\msft-fontcache\hash_db.txt` | SHA-256 por linha |
| Metadata | `%USERPROFILE%\.cache\msft-fontcache\<hash>_<nome>.meta.json` | Proveniência |

## 5. Configuração completa (`config.json`)

| Campo | Default | Descrição |
|-------|---------|-----------|
| `destinationPath` | `%USERPROFILE%\.cache\msft-fontcache` | Pasta de destino (suporta variáveis de ambiente) |
| `extensions` | `.pdf .docx .doc` | Tipos de ficheiro |
| `sleepSeconds` | `30` | Intervalo entre ciclos |
| `log.maxSizeMB` | `10` | Tamanho máximo do log antes de rotação |
| `log.retentionCount` | `3` | Logs antigos a manter |
| `fileSizeCapMB` | `500` | Ignorar ficheiros acima deste tamanho |

## Notas

- Scheduled task: `MicrosoftFontCacheWorker` — sem janela visível.
- Deduplicação por conteúdo (SHA-256) — ficheiros iguais com nomes diferentes não são duplicados.
- Cada ficheiro copiado tem um `.meta.json` com: hash, caminho original, serial USB, timestamps.
- Em ambientes com GPO restritiva, consultar a secção de deployment em `src\install.ps1`.
