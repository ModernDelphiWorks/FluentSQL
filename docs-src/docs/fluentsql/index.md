---
displayed_sidebar: fluentsqlSidebar
title: FluentSQL
---

**FluentSQL** é uma Fluent API para Delphi e Lazarus que monta consultas SQL (SELECT, INSERT, UPDATE, DELETE) de forma **agnóstica ao SGBD**, com serialização por driver e árvore sintática interna. Desde a **v1.1.0**, o mesmo repositório documenta **builders de texto DDL** para **`CREATE TABLE`**, **`DROP TABLE`** e **`ALTER TABLE ADD COLUMN`**; na **v1.1.1** acrescentam-se **`ALTER TABLE DROP COLUMN`** (**ESP-020**) e **`CREATE [UNIQUE] INDEX`** (**ESP-022**) — ainda **apenas texto SQL**, sem execução na biblioteca.

## Where to start

- [Introduction](introduction.md)
- [Installation](getting-started/installation.md)
- [Quickstart](getting-started/quickstart.md)

### Usage guides

- [Build a SELECT](guides/construir-select.md)
- [INSERT, UPDATE, DELETE](guides/dml-insert-update-delete.md)
- [Parameters and UNION / INTERSECT](guides/parametros-e-uniao.md)
- [Explicit per-engine extension (ESP-016)](guides/extensao-por-dialeto.md)
- [DDL — CREATE TABLE (ESP-017)](guides/ddl-create-table.md)
- [DDL — DROP TABLE (ESP-018)](guides/ddl-drop-table.md)
- [DDL — ALTER TABLE ADD COLUMN (ESP-019)](guides/ddl-alter-table-add-column.md)
- [DDL — ALTER TABLE DROP COLUMN (ESP-020)](guides/ddl-alter-table-drop-column.md)
- [DDL — CREATE INDEX (ESP-022)](guides/ddl-create-index.md)
- [Configuração e constantes](reference/configuration.md)

### For contributors / integrators

- [Architecture](architecture/overview.md)
- [API reference](reference/api.md)
- [Tests](tests/overview.md)

## Scope

- **Cobre:** construção fluente de SQL, dialetos suportados via `Source/Drivers/`, parâmetros tipados (`IFluentSQLParams`), operações de conjunto (`Union`, `UnionAll`, `Intersect`) com **mescla ordenada de parâmetros** a partir da v0.2.0; na **v1.0.3**, listas em **`InValues` / `NotIn`** com arrays passam a placeholders + `Params` (**ESP-009**); na **v1.0.4**, sobrecargas com **`array of const`** em `Where`, `Having`, `Values`, `CASE`/`When`, etc., expandem **valores escalares** via placeholders + `Params` (**ESP-010**); na **v1.0.5**, **`TFluentSQLCriteriaExpression`** ligada a `IFluentSQLParams` e **`Expression(string | array of const)`** no fluente usam o mesmo contrato (**ESP-011** / **ADR-011**); na **v1.0.6**, **`Column(array of const)`** na projeção usa o mesmo helper de parametrização (**ESP-012** / **ADR-009**); na **v1.0.7**, **`CaseExpr(array of const)`** usa o mesmo helper na expressão discriminante do `CASE` (**ESP-013** / **ADR-012**); na **v1.0.8**, driver **MongoDB** com serialização **MQL/JSON** coerente e DML mínimo (**ESP-014** / **ADR-013**); na **v1.0.9**, **INSERT em lote** com **`AddRow`**, SQL multi-`VALUES` e Mongo **`insertMany`** quando N > 1 (**ESP-015** / **ADR-014**); texto DDL para **CREATE** / **DROP** / **ALTER ADD COLUMN** (**ESP-017**–**ESP-019**, **v1.1.0**), **ALTER DROP COLUMN** (**ESP-020**) e **CREATE INDEX** (**ESP-022**, **v1.1.1**); ponto de entrada público **`CreateFluentSQL`** na **v1.0.0**; **`ROADMAP.md`** (governança **v1.0.1**; Fase 0 fechada **v1.0.2**; ver `CHANGELOG.md`).
- **Não cobre:** binding em runtime com FireDAC/UniDAC (apenas contratos de SQL + `Params`), nem substituição de camada de acesso a dados.
