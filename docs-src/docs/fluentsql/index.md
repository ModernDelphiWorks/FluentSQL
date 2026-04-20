---
displayed_sidebar: fluentsqlSidebar
title: FluentSQL
---

**FluentSQL** é uma Fluent API para Delphi e Lazarus que monta consultas SQL (SELECT, INSERT, UPDATE, DELETE) de forma **agnóstica ao SGBD**, com serialização por driver e árvore sintática interna. Desde a **v1.1.0**, o repositório documenta builders DDL; na **v1.4.0** introduziu suporte completo a **MongoDB Aggregations & Joins**, **DDL MongoDB** (Capped Collections, TTL), **Views**, **Sequences** e **Identidade Nativa**. Na **v1.5.1** (atual), o framework atinge maturidade em **DML MERGE** (MSSQL), **DDL Schemas** e paridade de **Funções Escalares**, com suíte de testes modularizada por driver.

## Where to start

- [Introduction](introduction.md)
- [Installation](getting-started/installation.md)
- [Quickstart](getting-started/quickstart.md)
- [Configuration](reference/configuration.md)
- [Troubleshooting](troubleshooting/common-errors.md)

### Usage guides

- [Build a SELECT](guides/construir-select.md)
- [INSERT, UPDATE, DELETE](guides/dml-insert-update-delete.md)
- [DML — MERGE (Produção)](guides/dml-merge.md)
- [Parameters and UNION / INTERSECT](guides/parametros-e-uniao.md)
- [Explicit per-engine extension](guides/extensao-por-dialeto.md)
- [Cache Distribuído (Redis)](guides/cache-distribuido.md)
- [MongoDB Aggregations & Joins](guides/mongodb-aggregation-joins.md)
- [MongoDB DDL Extensions](guides/mongodb-ddl.md)
- [DDL — Schemas](guides/ddl-schemas.md)
- [DDL — CREATE TABLE](guides/ddl-create-table.md)
- [DDL — Foreign Keys](guides/ddl-foreign-keys.md)
- [DDL — Views & Sequences](guides/ddl-views-sequences.md)
- [DDL — Table & Column Comments](guides/ddl-comments.md)
- [DDL — Advanced Columns (Identity, Computed)](guides/ddl-advanced-columns.md)
- [DDL — DROP TABLE](guides/ddl-drop-table.md)
- [DDL — ALTER TABLE ADD COLUMN](guides/ddl-alter-table-add-column.md)
- [DDL — ALTER TABLE DROP COLUMN](guides/ddl-alter-table-drop-column.md)
- [DDL — ALTER TABLE RENAME COLUMN](guides/ddl-alter-table-rename-column.md)
- [DDL — ALTER TABLE RENAME TABLE](guides/ddl-alter-table-rename-table.md)
- [DDL — CREATE INDEX](guides/ddl-create-index.md)
- [DDL — DROP INDEX](guides/ddl-drop-index.md)
- [DDL — TRUNCATE TABLE](guides/ddl-truncate-table.md)
- [Configuração e constantes](reference/configuration.md)

### For contributors / integrators

- [Architecture](architecture/overview.md)
- [API reference](reference/api.md)
- [Tests](tests/overview.md)

## Scope

- **Cobre:** construção fluente de SQL, dialetos suportados via `Source/Drivers/`; na **v1.5.1**, suporte completo a **DML MERGE** (MSSQL), **DDL Schemas** (namespaces lógicos), paridade de **Funções Escalares** (Math/Dates) e arquitetura de testes modular.
- **Não cobre:** binding em runtime com FireDAC/UniDAC (apenas contratos de SQL + `Params`), nem substituição de camada de acesso a dados.
