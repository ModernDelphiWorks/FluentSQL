---
displayed_sidebar: fluentsqlSidebar
title: API reference
---

Documentation aligned with release **v1.1.0** (2026-04-09): **ESP-016** (per-dialect extension), **ESP-017**–**ESP-019** (DDL string generation), plus the parametrization and DML history from **ESP-009** through **ESP-015** documented in `CHANGELOG.md`. The public factory and Boss package **FluentSQL** were stabilized in **v1.0.0**; roadmap reconciliation landed in **v1.0.2** (**ESP-008**). Set-operation parameter behavior was strengthened in **v0.2.0**. Implementation details live under `Source/Core/` and `FluentSQL.Interfaces.pas`.

## Main entry points

| Item | Description |
|------|-------------|
| Factory / entry | **`CreateFluentSQL(dbnFirebird)`** (unit `FluentSQL`); shortcut **`TCQ(dbn…)`** remains equivalent. |
| DDL — `CREATE TABLE` (ESP-017) | **`CreateFluentDDLTable(dbnFirebird, 'TABLE')`** returns **`IFluentDDLBuilder`**; **`AsString`** emits SQL text only. See [DDL — CREATE TABLE](../guides/ddl-create-table.md). |
| DDL — `DROP TABLE` (ESP-018) | **`CreateFluentDDLDropTable(dbnFirebird, 'TABLE')`** returns **`IFluentDDLDropBuilder`**; chain **`.IfExists`** before **`AsString`** when applicable. See [DDL — DROP TABLE](../guides/ddl-drop-table.md). |
| DDL — `ALTER TABLE ADD COLUMN` (ESP-019) | **`CreateFluentDDLAlterTableAddColumn(ADialect, 'TABLE')`** returns **`IFluentDDLAlterTableAddBuilder`**; exactly one `Column*` call before **`AsString`**. See [DDL — ALTER TABLE ADD COLUMN](../guides/ddl-alter-table-add-column.md). |
| Fluent methods | Chaining: `Select`, `From`, `Where`, `Join`, `OrderBy`, `Union`, `UnionAll`, `Intersect`, etc., per `IFluentSQL` and section interfaces. In **Insert**, **`AddRow`** (v1.0.9, **ESP-015**) closes the current row and opens the next for **batch INSERT** (see below). |
| Set-operation subqueries | `Union`, `UnionAll`, and `Intersect` take the secondary branch as `IFluentSQL`; the AST stores `UnionType` and `UnionQuery`. |

## Main outputs

| Item | Description |
|------|-------------|
| `AsString` | Serialized SQL text for the active dialect. |
| `Params` / `IFluentSQLParams` | Bindings in expected order. For set operations (`UNION` / `INTERSECT`), the implementation may use **`TFluentSQLMergedParams`**, merging primary and secondary collections in final SQL order (`TFluentSQL.Params`, `TFluentSQL.pas`). |

## Rules and contracts

- **1:1 placeholders × Params:** `AsString` and `Params` must stay aligned; v0.2.0 enforces this for set operations with remapping on the secondary branch (`FluentSQL.Serialize.pas`).
- **`IN` / `NOT IN` (v1.0.3):** overloads with **`TArray<String>`** or **`TArray<Double>`** on `InValues` / `NotIn` emit **one placeholder per element** (e.g. `:p1`, `:p2` on Firebird; repeated `?` on MySQL) and register values on `IFluentSQLParams`. A single **`String`** overload still denotes a **subquery or parenthesized expression**, not a list expansion. Normalized operators in concatenation: **`IN`** / **`NOT IN`**. See `CHANGELOG.md` **[1.0.3]**, issue [#19](https://github.com/ModernDelphiWorks/FluentSQL/issues/19); post-review notes [#20](https://github.com/ModernDelphiWorks/FluentSQL/issues/20).
- **`array of const` (v1.0.4, ESP-010):** overloads in `FluentSQL.pas` (`Where`, `AndOpe`, `OrOpe`, `Having`, `OnCond`, `SetValue`, `Values`) and in `TFluentSQLCriteriaCase` in `FluentSQL.Cases.pas` (`When`, `AndOpe`, `OrOpe`) expand **scalar** `TVarRec` entries to placeholders and `IFluentSQLParams`; **textual** entries (identifiers, operator `Char`, strings) remain **literals** (**RN-P3**). **`CaseExpr(array of const)`** was aligned to the same helper in **v1.0.7** (**ESP-013**). See **[1.0.4]**, issue [#21](https://github.com/ModernDelphiWorks/FluentSQL/issues/21); helper **`TUtils.SqlArrayOfConstToParameterizedSql`**. Caveats: [#22](https://github.com/ModernDelphiWorks/FluentSQL/issues/22).
- **`Column(array of const)` (v1.0.6, ESP-012):** `TFluentSQL.Column(const AColumnsName: array of const)` delegates to **`SqlArrayOfConstToParameterizedSql`** with **`FAST.Params`** (**ADR-009** / **ADR-011**). See **[1.0.6]**, issue [#25](https://github.com/ModernDelphiWorks/FluentSQL/issues/25); debt [#26](https://github.com/ModernDelphiWorks/FluentSQL/issues/26).
- **`CaseExpr(array of const)` (v1.0.7, ESP-013):** uses **`SqlArrayOfConstToParameterizedSql`** with **`FAST.Params`** for the discriminant; **strings** in the array stay literal fragments. See **[1.0.7]** (do not confuse with issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27), which is **ESP-016** on GitHub). Debt: [#28](https://github.com/ModernDelphiWorks/FluentSQL/issues/28).
- **Criteria `Expression` (v1.0.5, ESP-011):** in `FluentSQL.Expression.pas`, `TFluentSQLCriteriaExpression` can hold **`IFluentSQLParams`**; with it set, `array of const` overloads use **`SqlArrayOfConstToParameterizedSql`**. **`Expression(string | array of const)`** on the fluent surface receives the same `Params` collection (**ADR-011**: strings in `array of const` are not auto-bound). See **[1.0.5]**, issue [#23](https://github.com/ModernDelphiWorks/FluentSQL/issues/23); caveats [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24).
- **Interfaces over concrete types:** prefer contracts in `FluentSQL.Interfaces.pas`.
- **EXCEPT:** not documented as a set operation on this page; if added later, it should follow the same parameter contract as `Union` / `Intersect`.
- **Batch INSERT (v1.0.9, ESP-015, ADR-014):** in **`IFluentSQLInsert`** / **`TFluentSQLInsert`** (`FluentSQL.Insert.pas`), **`AddRow`** commits the current row (`Values` / `SetValue`) and starts an empty row; requires a **non-empty** current row (`EFluentSQLInsertBatch` otherwise). On serialize, the **last** pending row is included without an extra **`AddRow`** (implicit flush in **`AsString`**). SQL: `INSERT INTO … (cols) VALUES (…), (…), …` with placeholders **row-major** (**ADR-009**). **`Clear`** resets table, columns, accumulated rows, and current row.
- **Per-engine extension (ESP-016, ADR-016):** **`ForDialectOnly`** appends opt-in fragments tied to a **`TFluentSQLDriver`**; they only appear when the instance dialect matches. Issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27). Guide: [Explicit per-engine extension](../guides/extensao-por-dialeto.md).
- **MongoDB — batch INSERT (v1.0.9, ESP-015):** with **`dbnMongoDB`**, one logical row uses **`insertOne`**; multiple rows use **`insertMany`** with a **`documents`** array (**ADR-014** / **ADR-013**). See `CHANGELOG.md` **[1.0.9]**; traceability issue [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24); post-caveat debt [#32](https://github.com/ModernDelphiWorks/FluentSQL/issues/32).
- **DDL (v1.1.0, ESP-017–ESP-019):** builders in `FluentSQL.DDL.pas` and serializers in `FluentSQL.DDL.Serialize.pas` emit **strings only**; FluentSQL does not execute DDL. Unsupported dialects raise **`ENotSupportedException`** with a stable message referencing the delivery scope.

## Suggested reading in code

- `FluentSQL.Insert.pas` — `AddRow`, batch serialize, `EFluentSQLInsertBatch`.
- `FluentSQL.pas` — set operations, merged `Params`, `InValues` / `NotIn`, `Column` / `CaseExpr` / `Expression`, `AddRow` delegation.
- `FluentSQL.DDL.pas` / `FluentSQL.DDL.Serialize.pas` — DDL builders and `DDLCreateTableSQL` / `DDLDropTableSQL` / `DDLAlterTableAddColumnSQL`.
- `FluentSQL.Expression.pas` — `TFluentSQLCriteriaExpression`, `FSQLParams`, ESP-011.
- `FluentSQL.Cases.pas` — `When` / `CASE` with `array of const`.
- `FluentSQL.Operators.pas` — `IsIn` / `IsNotIn` (arrays vs string).
- `FluentSQL.Params.pas` — `TFluentSQLMergedParams`.
- `FluentSQL.Serialize.pas` — `UnionRemapBranchSQL`, `ComposeSqlCore`, `DialectOnlySqlSuffix` (ESP-016).
- `FluentSQL.Utils.pas` — `TUtils.SqlArrayOfConstToParameterizedSql` (ESP-010).
