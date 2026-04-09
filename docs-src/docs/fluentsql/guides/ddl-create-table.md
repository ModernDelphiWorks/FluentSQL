---
displayed_sidebar: fluentsqlSidebar
title: DDL — CREATE TABLE (ESP-017)
---

A partir da entrega **ESP-017** / **ADR-017**, o FluentSQL expõe uma **superfície DDL dedicada** que gera apenas **texto SQL** (`CREATE TABLE`) para um subconjunto fechado de tipos lógicos. O pacote **não executa** DDL nem consulta catálogo (**RB-DDL-1**, **RB-DDL-3**).

## Ponto de entrada

- **`CreateFluentDDLTable(ADialect, 'NOME_TABELA')`** (unit `FluentSQL`), devolvendo **`IFluentDDLBuilder`** (`FluentSQL.Interfaces`).

Encadeie colunas com métodos `ColumnInteger`, `ColumnVarChar`, `ColumnBoolean`, `ColumnDate`, `ColumnDateTime`, `ColumnLongText`, `ColumnBlob`, etc., e finalize com **`AsString`**.

## Dialetos suportados nesta vertical

Na primeira entrega, a serialização de **`CREATE TABLE`** está implementada para:

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |

Outros motores levantam **`ENotSupportedException`** até extensão explícita do mapeamento.

## Divergência entre motores

O mapeamento **tipo lógico → SQL** é **por dialeto** (**RB-DDL-2**). Por exemplo, texto longo e binário divergem:

- **Texto longo (`ColumnLongText`):** Firebird tende a **`BLOB SUB_TYPE 1`**; PostgreSQL **`TEXT`**.
- **Binário (`ColumnBlob`):** Firebird **`BLOB SUB_TYPE 0`**; PostgreSQL **`BYTEA`**.

Quando precisar de sintaxe **só de um motor**, siga **ESP-016** / **ADR-016** (`ForDialectOnly` na API DML ou composição na aplicação); o núcleo DDL portável não promete um único literal SQL para todos os SGBDs em tipos que não sejam semanticamente alinhados.

## Limitações do subconjunto

- Apenas **`CREATE TABLE`**; sem `ALTER`/`DROP`, índices, FK, `CHECK` complexo, etc.
- Tipos lógicos fechados (`TDDLLogicalType` em `FluentSQL.Interfaces`); extensões proprietárias não entram no contrato portável sem novo ADR ou uso de **ESP-016** na camada DML/aplicação.

## Leitura no código

- `FluentSQL.DDL.pas` — builder.
- `FluentSQL.DDL.Serialize.pas` — `DDLCreateTableSQL` e mapeamentos por dialeto.
