---
displayed_sidebar: fluentsqlSidebar
title: DDL — DROP INDEX (ESP-025)
---

> **Rastreio:** entrega **ESP-025** / **ADR-025**, issue [#40](https://github.com/ModernDelphiWorks/FluentSQL/issues/40). Sem entrada em **`CHANGELOG.md`** até **`/release`**.

A partir da entrega **ESP-025** / **ADR-025**, o FluentSQL gera **texto SQL** para **`DROP INDEX`** em **Firebird** e **PostgreSQL**. O pacote **não executa** DDL.

## Ponto de entrada

- **`CreateFluentDDLDropIndex(ADialect, 'NOME_INDICE')`** (unit `FluentSQL`), devolvendo **`IFluentDDLDropIndexBuilder`** (`FluentSQL.Interfaces`).

Chamar **`AsString`** para obter o comando.

## Exemplo mínimo

```pascal
uses
  FluentSQL, FluentSQL.Interfaces;

var
  LSql: string;
begin
  LSql := CreateFluentDDLDropIndex(dbnFirebird, 'IX_CLI_NOME').AsString;
  // DROP INDEX IX_CLI_NOME
end;
```

## Dialetos suportados nesta vertical

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |

Outros motores levantam **`ENotSupportedException`** com mensagem que referencia **ESP-025** até extensão explícita do mapeamento.

## Forma canónica da string

Para **Firebird** e **PostgreSQL** nesta fatia, a forma é a mesma (identificador do índice passado tal como o consumidor o fornece — ver **ADR-025**):

`DROP INDEX <indice>`

## Validação

- Nome de índice em branco ou só espaços → **`EArgumentException`** antes da serialização.
- Dialeto não coberto → **`ENotSupportedException`** com **ESP-025** na mensagem.

## Limitações declaradas

- Sem **`IF EXISTS`**, **`CONCURRENTLY`**, **`CASCADE`** / **`RESTRICT`**, nem lista de vários índices (**ADR-025**).
- Sem sintaxe que exija nome de tabela (ex.: MySQL `DROP INDEX … ON …`) neste ciclo.
- Para **`CREATE [UNIQUE] INDEX`**, ver [DDL — CREATE INDEX](ddl-create-index.md); para **`DROP TABLE`**, ver [DDL — DROP TABLE](ddl-drop-table.md).

## Leitura no código

- `FluentSQL.DDL.pas` — builder (`NewFluentDDLDropIndex`).
- `FluentSQL.DDL.Serialize.pas` — `DDLDropIndexSQL`.
