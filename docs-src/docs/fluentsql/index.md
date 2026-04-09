---
displayed_sidebar: fluentsqlSidebar
title: FluentSQL
---

**FluentSQL** é uma Fluent API para Delphi e Lazarus que monta consultas SQL (SELECT, INSERT, UPDATE, DELETE) de forma **agnóstica ao SGBD**, com serialização por driver e árvore sintática interna.

## Por onde começar

- [Introdução](introduction.md)
- [Instalação](getting-started/installation.md)
- [Início rápido](getting-started/quickstart.md)

### Manual de uso (fluxos)

- [Construir um SELECT](guides/construir-select.md)
- [INSERT, UPDATE e DELETE](guides/dml-insert-update-delete.md)
- [Parâmetros e UNION / INTERSECT](guides/parametros-e-uniao.md)
- [Extensão explícita por motor (ESP-016)](guides/extensao-por-dialeto.md)
- [DDL — CREATE TABLE (ESP-017)](guides/ddl-create-table.md)
- [Configuração e constantes](reference/configuration.md)

### Para quem desenvolve ou integra o framework

- [Arquitetura](architecture/overview.md)
- [Referência de API](reference/api.md)
- [Testes](tests/overview.md)

## Escopo

- **Cobre:** construção fluente de SQL, dialetos suportados via `Source/Drivers/`, parâmetros tipados (`IFluentSQLParams`), operações de conjunto (`Union`, `UnionAll`, `Intersect`) com **mescla ordenada de parâmetros** a partir da v0.2.0; na **v1.0.3**, listas em **`InValues` / `NotIn`** com arrays passam a placeholders + `Params` (**ESP-009**); na **v1.0.4**, sobrecargas com **`array of const`** em `Where`, `Having`, `Values`, `CASE`/`When`, etc., expandem **valores escalares** via placeholders + `Params` (**ESP-010**); na **v1.0.5**, **`TFluentSQLCriteriaExpression`** ligada a `IFluentSQLParams` e **`Expression(string | array of const)`** no fluente usam o mesmo contrato (**ESP-011** / **ADR-011**); na **v1.0.6**, **`Column(array of const)`** na projeção usa o mesmo helper de parametrização (**ESP-012** / **ADR-009**); na **v1.0.7**, **`CaseExpr(array of const)`** usa o mesmo helper na expressão discriminante do `CASE` (**ESP-013** / **ADR-012**); na **v1.0.8**, driver **MongoDB** com serialização **MQL/JSON** coerente e DML mínimo (**ESP-014** / **ADR-013**); na **v1.0.9**, **INSERT em lote** com **`AddRow`**, SQL multi-`VALUES` e Mongo **`insertMany`** quando N > 1 (**ESP-015** / **ADR-014**); ponto de entrada público **`CreateFluentSQL`** na **v1.0.0**; **`ROADMAP.md`** (governança **v1.0.1**; Fase 0 fechada **v1.0.2**; ver `CHANGELOG.md`).
- **Não cobre:** binding em runtime com FireDAC/UniDAC (apenas contratos de SQL + `Params`), nem substituição de camada de acesso a dados.
