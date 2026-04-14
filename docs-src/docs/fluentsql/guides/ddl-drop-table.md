---
displayed_sidebar: fluentsqlSidebar
title: DDL — DROP TABLE (ESP-018)
---

A partir da entrega **ESP-018** / **ADR-018**, o FluentSQL inclui geração de texto **`DROP TABLE`** na mesma família DDL que **`CREATE TABLE`** (**ADR-017**). O pacote continua a gerar **apenas string**; **não executa** DDL (**RB-DROP-1**, **RB-DROP-3**).

## Ponto de entrada

- **`Schema(ADialect).DropTable('NOME_TABELA')`** (unit `FluentSQL`), devolvendo **`IFluentDDLDropBuilder`** (`FluentSQL.Interfaces`). Tambem suportado via `CreateFluentDDLDropTable`.

Opcionalmente encadeie **`.IfExists`** antes de **`AsString`** para pedir uma remoção idempotente onde o dialeto e esta build o suportam (detalhe normativo em **ADR-018**).

## Dialetos suportados nesta vertical

| Dialeto | Constante | `DROP TABLE` simples | `.IfExists` |
|---------|-----------|----------------------|-------------|
| PostgreSQL | `dbnPostgreSQL` | `DROP TABLE nome` | Emite `DROP TABLE IF EXISTS nome` |
| Firebird | `dbnFirebird` | `DROP TABLE nome` | **`ENotSupportedException`** — o núcleo não emite `IF EXISTS` para Firebird nesta build (versões e sintaxe variam; ver **ADR-018**) |

Outros motores levantam **`ENotSupportedException`** até extensão do mapeamento.

## Relação com CREATE TABLE e extensões por motor

- **`CREATE TABLE`:** guia [ddl-create-table](./ddl-create-table.md) (**ESP-017** / **ADR-017**).
- Sintaxe **só de um motor** (por exemplo `DROP TABLE IF EXISTS` em Firebird 4+ quando precisar do literal exato): **ESP-016** / **ADR-016** — composição na aplicação ou extensão documentada, não obrigação do subconjunto portável.

## Limitações

- Apenas **`DROP TABLE`** nesta fatia; para **`ALTER TABLE ADD COLUMN`** ver [ddl-alter-table-add-column](./ddl-alter-table-add-column.md) (**ESP-019**). Sem `TRUNCATE`, índices, etc.
- Identificadores como em **ESP-017** (nomes simples na primeira vertical).

## Leitura no código

- `FluentSQL.DDL.pas` — builder.
- `FluentSQL.DDL.Serialize.pas` — `DDLDropTableSQL`.
