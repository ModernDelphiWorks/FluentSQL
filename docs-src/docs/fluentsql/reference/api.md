---
displayed_sidebar: fluentsqlSidebar
title: API reference
---

Documentation alinhada ao release **v1.5.1** (2026-04-20), apresentando suporte completo a MERGE DML (MSSQL) e paridade de funções escalares. Detalhes de implementação em `Source/Core/` e `FluentSQL.Interfaces.pas`.

## Main entry points

| Item | Descrição |
|------|-----------|
| **Query Factory (DML)** | **`Query(dbnFirebird)`** (unit `FluentSQL`) é o ponto de entrada principal para consultas. As fábricas legadas `CreateFluentSQL` e `TCQ` encontram-se obsoletas. |
| **Merge (DML)** | **`Query(dbnMSSQL).Merge`** (unit `FluentSQL`) devolve **`IFluentSQLMerge`**, ponto de entrada para operações MERGE. Suporte a **`.Update(array of const)`** e **`.Insert(array of const)`** para parametrização automática de valores. |
| **Schema Factory (DDL)** | **`Schema(dbnPostgreSQL)`** (unit `FluentSQL`) devolve **`IFluentSchema`**, ponto de entrada centralizado para todas as operações DDL. |
| DDL (`CREATE SCHEMA`) | **`Schema(dbnPostgreSQL).Create`** (sem arg) devolve **`IFluentSQLSchemaDef`**; gera `CREATE SCHEMA`. Ver [DDL — Schemas](../guides/ddl-schemas.md). |
| DDL (`DROP SCHEMA`) | **`Schema(dbnPostgreSQL).Drop`** (sem arg) devolve **`IFluentSQLSchemaDef`**; gera `DROP SCHEMA`. Ver [DDL — Schemas](../guides/ddl-schemas.md). |
| DDL (`CREATE TABLE`) | **`Schema(dbnFirebird).CreateTable('TABELA')`** devolve **`IFluentDDLBuilder`**; suporte a constraints e chaves estrangeiras. Ver [DDL — CREATE TABLE](../guides/ddl-create-table.md). |
| DDL (`DROP TABLE`) | **`Schema(dbnFirebird).DropTable('TABELA')`** devolve **`IFluentDDLDropBuilder`**; encadear **`.IfExists`** antes de **`AsString`**. Ver [DDL — DROP TABLE](../guides/ddl-drop-table.md). |
| DDL (`ALTER TABLE ADD`) | **`Schema(ADialect).AlterTableAdd('TABELA')`** devolve **`IFluentDDLAlterTableAddBuilder`**. Ver [DDL — ALTER TABLE ADD COLUMN](../guides/ddl-alter-table-add-column.md). |
| DDL (`ALTER TABLE DROP`) | **`Schema(ADialect).AlterTableDrop('TABELA')`** devolve **`IFluentDDLAlterTableDropBuilder`**. Ver [DDL — ALTER TABLE DROP COLUMN](../guides/ddl-alter-table-drop-column.md). |
| DDL (`RENAME COLUMN`) | **`Schema(ADialect).AlterTableRename('TABELA', 'ANTIGA', 'NOVA')`** (3 args) devolve **`IFluentDDLAlterTableRenameColumnBuilder`**. Ver [RENAME COLUMN](../guides/ddl-alter-table-rename-column.md). |
| DDL (`RENAME TABLE`) | **`Schema(ADialect).AlterTableRename('ANTIGA', 'NOVA')`** (2 args) devolve **`IFluentDDLAlterTableRenameTableBuilder`**. Ver [RENAME TABLE](../guides/ddl-alter-table-rename-table.md). |
| **Constraints** | **`.PrimaryKey`**, **`.NotNull`**, **`.DefaultValue(AValue)`** disponíveis após a definição de coluna no builder de DDL. |
| **Foreign Keys** | **`.References('TABELA', 'COLUNA')`** disponível no builder de DDL; gera a cláusula REFERENCES. |
| Métodos fluentes | Encadeamento de construção: `Select`, `From`, `Where`, `Join`, `OrderBy`, `Union`, `UnionAll`, `Intersect`, `GroupBy`, `Having`, etc., conforme `IFluentSQL` e interfaces de seção. No contexto **Insert**, **`AddRow`** fecha a linha corrente e inicia a próxima para **INSERT em lote**. |
| Subquery em conjunto | `Union`, `UnionAll` e `Intersect` recebem `IFluentSQL` da ramificação secundária; a AST armazena `UnionType` e `UnionQuery`. |

## Main outputs

| Item | Description |
|------|-------------|
| `AsString` | Serialized SQL text for the active dialect. |
| `Params` / `IFluentSQLParams` | Bindings in expected order. For set operations (`UNION` / `INTERSECT`), the implementation may use **`TFluentSQLMergedParams`**, merging primary and secondary collections in final SQL order (`TFluentSQL.Params`, `TFluentSQL.pas`). |

## Rules and contracts

- **1:1 placeholders × Params:** a string retornada por `AsString` e os itens expostos em `Params` devem permanecer alinhados para todas as operações, incluindo conjuntos (`UNION`, `INTERSECT`).
- **`IN` / `NOT IN`:** sobrecargas com `TArray<String>` ou `TArray<Double>` emitem um placeholder por elemento e registram cada valor em `IFluentSQLParams`. Sobrecargas com `String` única tratam o argumento como subconsulta ou expressão literal entre parênteses.
- **`array of const`:** sobrecargas em predicados e DML expandem valores escalares (inteiros, booleanos, variantes numéricos/data) para placeholders. Entradas textuais em `TVarRec` permanecem literais na expressão.
- **`Column(array of const)`:** escalares na projeção tornam-se placeholders em vez de literais concatenados.
- **`CaseExpr(array of const)`:** escalares na expressão discriminante do `CASE` tornam-se placeholders; strings no array continuam fragmentos literais.
- **Critérios e `Expression`:** instâncias de critério podem ser associadas a `IFluentSQLParams`. Quando fornecidas com uma coleção, as sobrecargas `array of const` utilizam parametrização automática.
- **Interfaces sobre tipos concretos:** consumo preferencial via interfaces definidas em `FluentSQL.Interfaces.pas`, conforme convenções do projeto.
- **INSERT em lote:** em `IFluentSQLInsert`, `AddRow` grava a linha corrente e abre uma nova linha; exige que a linha corrente não esteja vazia. A última linha pendente é serializada automaticamente no `AsString` (flush implícito).
- **Extensão por motor:** `ForDialectOnly` acrescenta fragmentos opt-in associados a um dialeto específico; estes fragmentos só entram na string final quando o dialeto da instância coincide.
- **MongoDB — INSERT em lote:** com `dbnMongoDB`, o uso de múltiplas linhas através de `AddRow` produz um comando `insertMany` com um array de documentos.
- **MongoDB — Agregações:** o uso de `GroupBy`, `Having` ou funções agregadas (`Sum`, `Count`, etc.) em `dbnMongoDB` aciona o pipeline de agregação (`aggregate` command), mapeando SQL para estágios `$group`, `$match`, `$project` e `$sort`.
- **MongoDB — Joins:** `InnerJoin` e `LeftJoin` são mapeados para estágios `$lookup` no MongoDB, seguidos de `$unwind` para manter a estrutura de resultado plana (SQL-like).
- **DDL:** builders e serializers para DDL emitem apenas strings SQL; o framework não realiza a execução dos comandos no banco de dados. Dialetos não suportados levantam `ENotSupportedException`.

## Suggested reading in code

- `FluentSQL.Insert.pas` — `AddRow`, batch serialize, `EFluentSQLInsertBatch`.
- `FluentSQL.pas` — `Query` and `Schema` entry points.
- `FluentSQL.DDL.pas` — `TFluentSchema` and DDL builders.
- `FluentSQL.DDL.SerializeAbstract.pas` — base DDL serialization logic.
- `Source/Drivers/` — per-dialect serialization overrides.

- `FluentSQL.Cases.pas` — `When` / `CASE` with `array of const`.
- `FluentSQL.Operators.pas` — `IsIn` / `IsNotIn` (arrays vs string).
- `FluentSQL.Params.pas` — `TFluentSQLMergedParams`.
- `FluentSQL.Serialize.pas` — `UnionRemapBranchSQL`, `ComposeSqlCore`, `DialectOnlySqlSuffix` (ESP-016).
- `FluentSQL.Utils.pas` — `TUtils.SqlArrayOfConstToParameterizedSql` (ESP-010).
