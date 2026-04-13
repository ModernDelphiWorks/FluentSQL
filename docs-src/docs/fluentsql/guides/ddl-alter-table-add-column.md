---
displayed_sidebar: fluentsqlSidebar
title: DDL — ALTER TABLE ADD COLUMN (ESP-019)
---

> **Release:** shipped in **`CHANGELOG.md` [1.1.0]** (2026-04-09), issue [#31](https://github.com/ModernDelphiWorks/FluentSQL/issues/31). Technical-debt follow-up: [#32](https://github.com/ModernDelphiWorks/FluentSQL/issues/32).

A partir da entrega **ESP-019** / **ADR-019**, o FluentSQL gera **texto SQL** para **`ALTER TABLE … ADD …`** com **uma coluna lógica por comando** `AsString`, reutilizando os mesmos **`TDDLLogicalType`** e o mapeamento físico por dialeto que **`CREATE TABLE`** (**ESP-017**). O pacote **não executa** DDL.

## Ponto de entrada

- **`CreateFluentDDLAlterTableAddColumn(ADialect, 'NOME_TABELA')`** (unit `FluentSQL`), devolvendo **`IFluentDDLAlterTableAddBuilder`** (`FluentSQL.Interfaces`).

Chame **um único** método `ColumnInteger`, `ColumnVarChar`, etc., encadeie as **Constraints Avançadas** (**ESP-034**) ou **Foreign Keys** (**ESP-035**) se necessário, e finalize com **`AsString`**. 

## Exemplo com Constraints (ESP-034 / ESP-035)

```delphi
  // Adicionar coluna com NOT NULL e DEFAULT
  LSql := CreateFluentDDLAlterTableAddColumn(dbnPostgreSQL, 'CLIENTES')
    .ColumnBoolean('VIP').NotNull.DefaultValue(False)
    .AsString;

  // Adicionar coluna que é uma Chave Estrangeira
  LSql := CreateFluentDDLAlterTableAddColumn(dbnPostgreSQL, 'PEDIDOS')
    .ColumnInteger('VENDEDOR_ID').References('VENDEDORES', 'ID')
    .AsString;
```

## Dialetos suportados nesta vertical

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |

Outros motores levantam **`ENotSupportedException`** com mensagem que referencia **ESP-019** até extensão explícita do mapeamento.

## Forma canónica da string

Para Firebird e PostgreSQL nesta build, a serialização segue:

`ALTER TABLE <tabela> ADD <coluna> <tipo físico>`

O **tipo físico** é o mesmo produzido por **`DDLCreateTableSQL`** para o mesmo tipo lógico e dialeto (**ADR-019**).

## Limitações declaradas

- **Uma coluna** por `AsString`; várias colunas implicam **várias** cadeias na aplicação.
- Para **`DROP COLUMN`**, ver [ddl-alter-table-drop-column](./ddl-alter-table-drop-column.md) (**ESP-020** / **ADR-020**).
- Para **`CREATE TABLE`** e **`DROP TABLE`**, ver [ddl-create-table](./ddl-create-table.md) e [ddl-drop-table](./ddl-drop-table.md).

## Leitura no código

- `FluentSQL.DDL.pas` — builder (`NewFluentDDLAlterTableAddColumn`).
- `FluentSQL.DDL.Serialize.pas` — `DDLAlterTableAddColumnSQL`.
