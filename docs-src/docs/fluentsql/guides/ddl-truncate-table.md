---
displayed_sidebar: fluentsqlSidebar
title: DDL — TRUNCATE TABLE (ESP-029)
---

> **Rastreio:** **ESP-029** / **ADR-029**, issue [#44](https://github.com/ModernDelphiWorks/FluentSQL/issues/44). Sem entrada em **`CHANGELOG.md`** até **`/release`**.

O FluentSQL gera **texto SQL** para **`TRUNCATE TABLE`** em **PostgreSQL**, **Firebird** e **MySQL** / **MariaDB** (`dbnMySQL`). Em **PostgreSQL** são opcionais **`RESTART IDENTITY`** e **`CASCADE`** (ver matriz abaixo). O pacote **não executa** DDL.

## Motor de referência

- **PostgreSQL:** cláusulas opcionais seguem a [documentação oficial](https://www.postgresql.org/docs/current/sql-truncate.html): após o nome da tabela, **`RESTART IDENTITY`** (se pedido) e depois **`CASCADE`** (se pedido).
- **Firebird:** **`TRUNCATE TABLE`** está alinhado a versões que suportam o comando (ex.: **Firebird 3+**); **`RESTART IDENTITY`** / **`CASCADE`** **não** são emitidos — ver matriz de excepções.
- **MySQL / MariaDB:** forma canónica **`TRUNCATE TABLE nome`**; modificadores PG **não** são emitidos — **`ENotSupportedException`** se forem solicitados na API fluente.

## Ponto de entrada

- **`CreateFluentDDLTruncateTable(ADialect, 'TABELA')`** (unit `FluentSQL`), devolvendo **`IFluentDDLTruncateTableBuilder`** (`FluentSQL.Interfaces`).

Chamar **`AsString`** para obter o comando. Opcionalmente encadear **`.RestartIdentity`** e/ou **`.Cascade`** **apenas** quando o dialecto for **`dbnPostgreSQL`** (ver tabela).

## Exemplo mínimo

```pascal
uses
  FluentSQL, FluentSQL.Interfaces;

var
  LSql: string;
begin
  LSql := CreateFluentDDLTruncateTable(dbnFirebird, 'CLIENTES').AsString;
  // TRUNCATE TABLE CLIENTES
end;
```

## PostgreSQL — opcionais

```pascal
LSql := CreateFluentDDLTruncateTable(dbnPostgreSQL, 'orders')
  .RestartIdentity
  .Cascade
  .AsString;
// TRUNCATE TABLE orders RESTART IDENTITY CASCADE
```

A ordem canónica na **string** é sempre **`RESTART IDENTITY`** antes de **`CASCADE`**, independentemente da ordem das chamadas na API (ambos são apenas indicadores).

## Matriz de comportamento (ADR-029)

| Dialeto | Núcleo `TRUNCATE TABLE t` | `.RestartIdentity` | `.Cascade` |
|---------|---------------------------|--------------------|------------|
| **PostgreSQL** | Sim | Emite **`RESTART IDENTITY`** | Emite **`CASCADE`** |
| **Firebird** | Sim | **`ENotSupportedException`** (**ESP-029**) | **`ENotSupportedException`** (**ESP-029**) |
| **MySQL** | Sim | **`ENotSupportedException`** (**ESP-029**) | **`ENotSupportedException`** (**ESP-029**) |
| Outros (`dbnOracle`, …) | **`ENotSupportedException`** até haver ramo dedicado | — | — |

Nome de tabela **obrigatório**; só espaços após *trim* → **`EArgumentException`** com rastreio **ESP-029**.

## Ligações

- [API reference](../reference/api.md) — fábrica **`CreateFluentDDLTruncateTable`**
- [DDL — DROP TABLE](./ddl-drop-table.md) (**ESP-018**) — remoção de tabela vs limpeza de dados
