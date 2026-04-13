---
displayed_sidebar: fluentsqlSidebar
title: DDL — ALTER TABLE DROP COLUMN (ESP-020)
---

> **Rastreio:** entrega **ESP-020** / **ADR-020**, issue [#34](https://github.com/ModernDelphiWorks/FluentSQL/issues/34). Sem entrada em **`CHANGELOG.md`** até **`/release`**.

A partir da entrega **ESP-020** / **ADR-020**, o FluentSQL gera **texto SQL** para **`ALTER TABLE … DROP …`** com **uma coluna alvo por comando** `AsString`. O pacote **não executa** DDL.

## Ponto de entrada

- **`CreateFluentDDLAlterTableDropColumn(ADialect, 'NOME_TABELA')`** (unit `FluentSQL`), devolvendo **`IFluentDDLAlterTableDropBuilder`** (`FluentSQL.Interfaces`).

Chame **um único** **`DropColumn('NOME_COLUNA')`** e finalize com **`AsString`**. Uma segunda chamada a **`DropColumn`** na mesma cadeia levanta **`EArgumentException`** com mensagem estável (regra **ESP-020**).

## Dialetos suportados nesta vertical

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |

Outros motores levantam **`ENotSupportedException`** com mensagem que referencia **ESP-020** até extensão explícita do mapeamento.

## Forma canónica da string

| Dialeto | Forma |
|---------|--------|
| Firebird | `ALTER TABLE <tabela> DROP <coluna>` — **sem** a palavra **`COLUMN`** entre **`DROP`** e o identificador (**ADR-020**). |
| PostgreSQL | `ALTER TABLE <tabela> DROP COLUMN <coluna>` — com **`COLUMN`** explícito (**ADR-020**). |

## Limitações declaradas

- **Uma coluna** por `AsString`; várias colunas implicam **várias** cadeias na aplicação.
- Sem **`DROP COLUMN IF EXISTS`**, **`CASCADE`** / **`RESTRICT`**, **`ALTER COLUMN`**, ou renomear coluna nesta entrega (para **`RENAME COLUMN`**, ver [ddl-alter-table-rename-column](./ddl-alter-table-rename-column.md) — **ESP-030**).
- Para **`ALTER TABLE ADD COLUMN`**, ver [ddl-alter-table-add-column](./ddl-alter-table-add-column.md) (**ESP-019**). Para **`CREATE TABLE`** e **`DROP TABLE`**, ver [ddl-create-table](./ddl-create-table.md) e [ddl-drop-table](./ddl-drop-table.md).

## Leitura no código

- `FluentSQL.DDL.pas` — builder (`NewFluentDDLAlterTableDropColumn`).
- `FluentSQL.DDL.Serialize.pas` — `DDLAlterTableDropColumnSQL`.
