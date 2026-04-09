---
displayed_sidebar: fluentsqlSidebar
title: FluentSQL
---

**FluentSQL** is a fluent API for Delphi and Lazarus that builds SQL (SELECT, INSERT, UPDATE, DELETE) in a **database-agnostic** way, with per-driver serialization and an internal AST. Since **v1.1.0**, the same repository also documents **DDL string builders** (`CREATE` / `DROP` / `ALTER TABLE ADD COLUMN`) for selected dialects — still **SQL text only**, no execution in the library.

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
- [Configuration and constants](reference/configuration.md)

### For contributors / integrators

- [Architecture](architecture/overview.md)
- [API reference](reference/api.md)
- [Tests](tests/overview.md)

## Scope

- **In scope:** fluent SQL construction; drivers under `Source/Drivers/`; typed parameters (`IFluentSQLParams`); set operations with **ordered merged parameters** (since v0.2.0); parametrization increments **ESP-009**–**ESP-013** (v1.0.3–v1.0.7); MongoDB JSON/MQL + minimal DML (**ESP-014**, v1.0.8); batch INSERT (**ESP-015**, v1.0.9); per-engine extension (**ESP-016**); DDL text for **CREATE** / **DROP** / **ALTER ADD COLUMN** (**ESP-017**–**ESP-019**, **v1.1.0**); public factory **`CreateFluentSQL`** (v1.0.0); operational **`ROADMAP.md`** — see `CHANGELOG.md` for issue links.
- **Out of scope:** runtime binding with FireDAC/UniDAC (SQL + `Params` contracts only); not a data-access replacement.
