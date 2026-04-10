---
displayed_sidebar: fluentsqlSidebar
title: DDL — DROP INDEX (ESP-025 / ESP-026)
---

> **Rastreio:** base **ESP-025** / **ADR-025**; extensão opcional **`IF EXISTS`** **ESP-026** / **ADR-026**, issue [#41](https://github.com/ModernDelphiWorks/FluentSQL/issues/41). Sem entrada em **`CHANGELOG.md`** até **`/release`**.

O FluentSQL gera **texto SQL** para **`DROP INDEX`** em **Firebird** e **PostgreSQL**, com cláusula opcional **`IF EXISTS`** (opt-in na API). O pacote **não executa** DDL.

## Ponto de entrada

- **`CreateFluentDDLDropIndex(ADialect, 'NOME_INDICE')`** (unit `FluentSQL`), devolvendo **`IFluentDDLDropIndexBuilder`** (`FluentSQL.Interfaces`).

Chamar **`AsString`** para obter o comando. Opcionalmente encadear **`.IfExists`** antes de **`AsString`** (ver secção abaixo).

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

## `IF EXISTS` (ESP-026 / ADR-026)

Para gerar **`DROP INDEX IF EXISTS …`** nos dialectos mapeados, chame **`.IfExists`** (sem parâmetros), alinhado a **`IFluentDDLDropBuilder.IfExists`** em **`DROP TABLE`**:

```pascal
LSql := CreateFluentDDLDropIndex(dbnPostgreSQL, 'ix_legacy').IfExists.AsString;
// DROP INDEX IF EXISTS ix_legacy
```

| Dialeto | Sem `.IfExists` | Com `.IfExists` |
|---------|-----------------|-----------------|
| Firebird | `DROP INDEX <indice>` | `DROP INDEX IF EXISTS <indice>` |
| PostgreSQL | `DROP INDEX <indice>` | `DROP INDEX IF EXISTS <indice>` |

**Firebird:** a forma com **`IF EXISTS`** em **`DROP INDEX`** requer **Firebird 4+**. O FluentSQL **não valida** a versão do servidor — documente o requisito mínimo na sua pipeline de *deployment*.

## Dialetos suportados nesta vertical

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |

Outros motores levantam **`ENotSupportedException`** com mensagem que referencia **ESP-026** (e **ESP-025** como *baseline*) até extensão explícita do mapeamento.

## Forma canónica da string

Para **Firebird** e **PostgreSQL**, o identificador do índice é passado tal como o consumidor o fornece (ver **ADR-025** / **ADR-026**).

## Validação

- Nome de índice em branco ou só espaços → **`EArgumentException`** antes da serialização.
- Dialeto não coberto → **`ENotSupportedException`** com **ESP-026** (e rastreio **ESP-025**) na mensagem.

## Limitações declaradas

- Sem **`CONCURRENTLY`**, **`CASCADE`** / **`RESTRICT`**, nem lista de vários índices (**ADR-025** / **ADR-026**).
- Sem sintaxe que exija nome de tabela (ex.: MySQL `DROP INDEX … ON …`) neste ciclo.
- Para **`CREATE [UNIQUE] INDEX`**, ver [DDL — CREATE INDEX](ddl-create-index.md); para **`DROP TABLE`**, ver [DDL — DROP TABLE](ddl-drop-table.md).

## Leitura no código

- `FluentSQL.DDL.pas` — builder (`NewFluentDDLDropIndex`).
- `FluentSQL.DDL.Serialize.pas` — `DDLDropIndexSQL`.
