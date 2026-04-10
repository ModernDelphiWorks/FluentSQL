---
displayed_sidebar: fluentsqlSidebar
title: DDL — DROP INDEX (ESP-025 / ESP-026 / ESP-027)
---

> **Rastreio:** base **ESP-025** / **ADR-025**; **`IF EXISTS`** **ESP-026** / **ADR-026**, issue [#41](https://github.com/ModernDelphiWorks/FluentSQL/issues/41); **`CONCURRENTLY`** (PostgreSQL) **ESP-027** / **ADR-027**, issue [#42](https://github.com/ModernDelphiWorks/FluentSQL/issues/42). Sem entrada em **`CHANGELOG.md`** até **`/release`**.

O FluentSQL gera **texto SQL** para **`DROP INDEX`** em **Firebird** e **PostgreSQL**, com cláusulas opcionais **`IF EXISTS`** e, só em **PostgreSQL**, **`CONCURRENTLY`**. O pacote **não executa** DDL.

## Ponto de entrada

- **`CreateFluentDDLDropIndex(ADialect, 'NOME_INDICE')`** (unit `FluentSQL`), devolvendo **`IFluentDDLDropIndexBuilder`** (`FluentSQL.Interfaces`).

Chamar **`AsString`** para obter o comando. Opcionalmente encadear **`.IfExists`** e/ou **`.Concurrently`** (só PostgreSQL) antes de **`AsString`**.

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

| Dialeto | Sem `.IfExists` | Com `.IfExists` (sem `.Concurrently`) |
|---------|-----------------|--------------------------------------|
| Firebird | `DROP INDEX <indice>` | `DROP INDEX IF EXISTS <indice>` |
| PostgreSQL | `DROP INDEX <indice>` | `DROP INDEX IF EXISTS <indice>` |

**Firebird:** a forma com **`IF EXISTS`** em **`DROP INDEX`** requer **Firebird 4+**. O FluentSQL **não valida** a versão do servidor — documente o requisito mínimo na sua pipeline de *deployment*.

## `CONCURRENTLY` (ESP-027 / ADR-027, só PostgreSQL)

O modificador **`CONCURRENTLY`** é específico do **PostgreSQL** (reduz bloqueios ao remover o índice). Na API fluente é **opt-in** via **`.Concurrently`**.

```pascal
LSql := CreateFluentDDLDropIndex(dbnPostgreSQL, 'ix_legacy').Concurrently.AsString;
// DROP INDEX CONCURRENTLY ix_legacy

LSql := CreateFluentDDLDropIndex(dbnPostgreSQL, 'ix_legacy').Concurrently.IfExists.AsString;
// DROP INDEX CONCURRENTLY IF EXISTS ix_legacy
```

A ordem canónica na string segue a [gramática do PostgreSQL](https://www.postgresql.org/docs/current/sql-dropindex.html): **`DROP INDEX`** → opcional **`CONCURRENTLY`** → opcional **`IF EXISTS`** → nome do índice. A ordem das chamadas **`.Concurrently`** e **`.IfExists`** na API não altera o resultado (ambos são apenas indicadores).

| Dialeto | `.Concurrently` |
|---------|-----------------|
| PostgreSQL | Emite **`DROP INDEX CONCURRENTLY`** (com ou sem **`IF EXISTS`** conforme **`.IfExists`**) |
| Firebird | **`ENotSupportedException`** (mensagem com **ESP-027**) |
| Outros | **`ENotSupportedException`** (mensagem com **ESP-027**) |

## Dialetos suportados nesta vertical

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |

Outros motores levantam **`ENotSupportedException`** com mensagem que referencia **ESP-026** (e **ESP-025** como *baseline*) para **`DROP INDEX`** simples; se **`.Concurrently`** estiver activo, a mensagem referencia **ESP-027**.

## Forma canónica da string

Para **Firebird** e **PostgreSQL**, o identificador do índice é passado tal como o consumidor o fornece (ver **ADR-025** / **ADR-026** / **ADR-027**).

## Validação

- Nome de índice em branco ou só espaços → **`EArgumentException`** antes da serialização.
- Dialeto não coberto para **`DROP INDEX`** → **`ENotSupportedException`** com **ESP-026** (e rastreio **ESP-025**) na mensagem.
- **`CONCURRENTLY`** fora de **PostgreSQL** → **`ENotSupportedException`** com **ESP-027**.

## Limitações declaradas

- **`CONCURRENTLY`**: apenas **PostgreSQL** neste ciclo; **Firebird** e outros motores não mapeiam esta forma (**ESP-027**).
- Sem **`CASCADE`** / **`RESTRICT`**, nem lista de vários índices (**ADR-025** / **ADR-026**).
- Sem sintaxe que exija nome de tabela (ex.: MySQL `DROP INDEX … ON …`) neste ciclo.
- **Runtime no PostgreSQL:** **`CONCURRENTLY`** **não** pode ser usado dentro de um bloco de transacção — é regra do motor; o FluentSQL **não** detecta sessão nem transacção; quem **executa** o texto gerado deve garantir o contexto correcto (documentação oficial PostgreSQL).
- Para **`CREATE [UNIQUE] INDEX`**, ver [DDL — CREATE INDEX](ddl-create-index.md); para **`DROP TABLE`**, ver [DDL — DROP TABLE](ddl-drop-table.md).

## Leitura no código

- `FluentSQL.DDL.pas` — builder (`NewFluentDDLDropIndex`).
- `FluentSQL.DDL.Serialize.pas` — `DDLDropIndexSQL`.
