---
displayed_sidebar: fluentsqlSidebar
title: Fluxo em tempo de execução
---

## Sequência principal

1. **Entrada:** o consumidor obtém uma instância fluente (por exemplo via `TCQ(dbnX)`) e encadeia cláusulas (`Select`, `From`, `Where`, …).
2. **Construção:** o estado é mantido na implementação concreta e na AST; operadores podem acumular valores em `IFluentSQLParams`.
3. **Serialização:** ao chamar `AsString`, o serializer do driver percorre a AST e produz o SQL do dialeto. Se houver operação de conjunto com subquery, o texto da subquery pode ser ajustado (`UnionRemapBranchSQL`) para que os índices dos placeholders não colidam com os da query principal. Fragmentos registados com **`ForDialectOnly`** são concatenados ao núcleo apenas quando o dialeto ativo coincide (**ESP-016**; `DialectOnlySqlSuffix` em `FluentSQL.Serialize.pas`).
4. **Saída:** retorno da **string SQL**; a coleção **`Params`** reflete a ordem esperada pelo texto final (incluindo mescla primário + secundário via `TFluentSQLMergedParams` quando aplicável).

## Pontos de atenção

- **Desalinhamento Params × SQL:** em versões anteriores à v0.2.0, `UNION`/`INTERSECT` podiam gerar placeholders sem entrada correspondente em `Params`. Com a v0.2.0 isso foi endereçado na issue [#11](https://github.com/ModernDelphiWorks/FluentSQL/issues/11); se algo divergir, confira a contagem de parâmetros em cada ramo e o dialeto (MySQL usa `?` com reindexação específica no serializer).
- **INSERT em lote (v1.0.9):** em **`Insert`**, os placeholders seguem a **ordem das linhas** (primeira linha consome `:p1`…, a segunda `:pN+1`… no Firebird; no MySQL, `?` repetidos na mesma ordem). **`AddRow`** exige linha corrente **não vazia**; a última linha é incluída em **`AsString`** sem **`AddRow`** final. Exceções **`EFluentSQLInsertBatch`** indicam linha vazia, contagem de colunas inconsistente ou coluna em falta — ver `FluentSQL.Insert.pas` e [Erros comuns](../troubleshooting/common-errors.md).
- **DDL (from v1.1.0; additional builders ESP-020 / ESP-022 in v1.1.1):** fluent builders call **`AsString`** on `IFluentDDL*` interfaces; the library returns SQL text only and does **not** execute DDL on a server.
- **Driver incorreto:** funções e sintaxe variam por banco; usar o driver errado produz SQL inválido para o alvo — valide com testes do dialeto em `Test Delphi/`.
