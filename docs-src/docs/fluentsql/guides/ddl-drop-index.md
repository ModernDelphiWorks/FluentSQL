---
displayed_sidebar: fluentsqlSidebar
title: DDL — DROP INDEX (ESP-025 / ESP-026 / ESP-027 / ESP-028)
---

> **Rastreio:** base **ESP-025** / **ADR-025**; **`IF EXISTS`** **ESP-026** / **ADR-026**, issue [#41](https://github.com/ModernDelphiWorks/FluentSQL/issues/41); **`CONCURRENTLY`** (PostgreSQL) **ESP-027** / **ADR-027**, issue [#42](https://github.com/ModernDelphiWorks/FluentSQL/issues/42); **`DROP INDEX … ON …`** (MySQL / MariaDB) **ESP-028** / **ADR-028**, issue [#43](https://github.com/ModernDelphiWorks/FluentSQL/issues/43). Sem entrada em **`CHANGELOG.md`** até **`/release`**.

O FluentSQL gera **texto SQL** para **`DROP INDEX`** em **Firebird**, **PostgreSQL** e **MySQL** (com **`ON table`**), com cláusulas opcionais **`IF EXISTS`** e, só em **PostgreSQL**, **`CONCURRENTLY`**. O pacote **não executa** DDL.

## Ponto de entrada

- **`CreateFluentDDLDropIndex(ADialect, 'NOME_INDICE')`** (unit `FluentSQL`), devolvendo **`IFluentDDLDropIndexBuilder`** (`FluentSQL.Interfaces`).

Chamar **`AsString`** para obter o comando. Opcionalmente encadear **`.OnTable('TABELA')`** (obrigatório para **`dbnMySQL`**), **`.IfExists`** e/ou **`.Concurrently`** (só PostgreSQL) antes de **`AsString`**.

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

## MySQL / MariaDB — `ON table` (ESP-028 / ADR-028)

Para **`dbnMySQL`**, o comando autónomo **`DROP INDEX`** exige a forma **`DROP INDEX nome_indice ON nome_tabela`**. Chame **`.OnTable('TABELA')`** com um identificador não vazio (espaços à esquerda/direita são ignorados). Sem **`.OnTable`** (ou só espaços após *trim*), **`AsString`** levanta **`EArgumentException`** com rastreio **ESP-028**.

```pascal
LSql := CreateFluentDDLDropIndex(dbnMySQL, 'ix_orders_status')
  .OnTable('orders')
  .AsString;
// DROP INDEX ix_orders_status ON orders
```

**`IF EXISTS` nesta vertical:** neste ciclo, **`.IfExists`** com **`dbnMySQL`** levanta **`ENotSupportedException`** (**ESP-028**) — a emissão de **`DROP INDEX IF EXISTS … ON …`** não está mapeada para o motor de referência desta build; para *scripts* que exijam **`IF EXISTS`**, use SQL específico do motor (por exemplo **`ALTER TABLE … DROP INDEX`** onde aplicável) ou omita **`.IfExists`**.

**`CONCURRENTLY`:** não existe nesta forma para MySQL; **`.Concurrently`** com **`dbnMySQL`** levanta **`ENotSupportedException`** (mensagem com **ESP-027** / **ESP-028**).

**Nota:** como alternativa ao comando autónomo, vários motores aceitam **`ALTER TABLE tbl DROP INDEX idx`**; não é uma segunda API fluente obrigatória neste ciclo.

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
| MySQL | `DROP INDEX <indice> ON <tabela>` (com **`.OnTable`**) | **Não emitido** — **`ENotSupportedException`** (**ESP-028**) |

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
| MySQL | **`ENotSupportedException`** (mensagem com **ESP-027** / **ESP-028**) |
| Outros | **`ENotSupportedException`** (mensagem com **ESP-027**) |

## Dialetos suportados nesta vertical

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |
| MySQL / MariaDB | `dbnMySQL` (requer **`.OnTable`** para **`AsString`**) |

**Firebird** e **PostgreSQL** com **`.OnTable`** definido levantam **`ENotSupportedException`** (**ESP-028**) — **`ON tabela`** não faz parte desta vertical para esses dialectos.

Outros motores (sem ramo dedicado) levantam **`ENotSupportedException`** com mensagem que referencia **ESP-026** (e **ESP-025** como *baseline*) para **`DROP INDEX`** simples; se **`.Concurrently`** estiver activo, a mensagem referencia **ESP-027**.

## Forma canónica da string

Para **Firebird** e **PostgreSQL**, o identificador do índice é passado tal como o consumidor o fornece (ver **ADR-025** / **ADR-026** / **ADR-027**). Para **MySQL**, o nome da tabela em **`ON`** segue o mesmo princípio *string-only* (**ADR-028**).

## Validação

- Nome de índice em branco ou só espaços → **`EArgumentException`** antes da serialização.
- **`dbnMySQL`** sem **`.OnTable`** com nome efectivo → **`EArgumentException`** (**ESP-028**).
- **`dbnMySQL`** com **`.IfExists`** → **`ENotSupportedException`** (**ESP-028**).
- Dialeto não coberto para **`DROP INDEX`** → **`ENotSupportedException`** com **ESP-026** (e rastreio **ESP-025**) na mensagem.
- **`CONCURRENTLY`** fora de **PostgreSQL** → **`ENotSupportedException`** com **ESP-027** (e **ESP-028** quando aplicável a MySQL).

## Limitações declaradas

- **`CONCURRENTLY`**: apenas **PostgreSQL** neste ciclo; **Firebird** e **MySQL** não mapeiam esta forma (**ESP-027** / **ESP-028**).
- **`IF EXISTS`** com **`dbnMySQL`** não é emitido nesta build (**ESP-028**); ver secção MySQL acima.
- Sem **`CASCADE`** / **`RESTRICT`**, nem lista de vários índices (**ADR-025** / **ADR-026**).
- **Runtime no PostgreSQL:** **`CONCURRENTLY`** **não** pode ser usado dentro de um bloco de transacção — é regra do motor; o FluentSQL **não** detecta sessão nem transacção; quem **executa** o texto gerado deve garantir o contexto correcto (documentação oficial PostgreSQL).
- Para **`CREATE [UNIQUE] INDEX`**, ver [DDL — CREATE INDEX](ddl-create-index.md); para **`DROP TABLE`**, ver [DDL — DROP TABLE](ddl-drop-table.md).

## Leitura no código

- `FluentSQL.DDL.pas` — builder (`NewFluentDDLDropIndex`).
- `FluentSQL.DDL.Serialize.pas` — `DDLDropIndexSQL`.
