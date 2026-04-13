---
displayed_sidebar: fluentsqlSidebar
title: DDL — CREATE INDEX (ESP-022)
---

> **Rastreio:** entrega **ESP-022** / **ADR-022**, issue [#35](https://github.com/ModernDelphiWorks/FluentSQL/issues/35). Sem entrada em **`CHANGELOG.md`** até **`/release`**.

A partir da entrega **ESP-022** / **ADR-022**, o FluentSQL gera **texto SQL** para **`CREATE [UNIQUE] INDEX … ON … (…)`** em **Firebird** e **PostgreSQL**. O pacote **não executa** DDL.

## Ponto de entrada

- **`CreateFluentDDLCreateIndex(ADialect, 'NOME_INDICE', 'NOME_TABELA')`** (unit `FluentSQL`), devolvendo **`IFluentDDLCreateIndexBuilder`** (`FluentSQL.Interfaces`).

Encadear uma ou mais chamadas **`Column('COLUNA')`** (ordem preservada na lista do índice). Opcionalmente **`Unique`** antes de **`AsString`** para **`CREATE UNIQUE INDEX`**. Uma segunda **`Unique`** na mesma cadeia levanta **`EArgumentException`** com mensagem estável (**ESP-022**).

## Exemplo mínimo

```pascal
uses
  FluentSQL, FluentSQL.Interfaces;

var
  LSql: string;
begin
  LSql := CreateFluentDDLCreateIndex(dbnFirebird, 'IX_CLI_NOME', 'CLIENTES')
    .Column('NOME')
    .AsString;
  // CREATE INDEX IX_CLI_NOME ON CLIENTES (NOME)
end;
```

## Dialetos suportados nesta vertical

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |

Outros motores levantam **`ENotSupportedException`** com mensagem que referencia **ESP-022** até extensão explícita do mapeamento.

## Forma canónica da string

Para **Firebird** e **PostgreSQL** nesta fatia, a forma é a mesma (identificadores passados tal como o consumidor os fornece — ver **ADR-022**):

`CREATE [UNIQUE] INDEX <indice> ON <tabela> (col1, col2, …)`

## Validação

- Nome de índice ou tabela em branco, lista de colunas vazia, ou nome de coluna em branco em **`Column`** → **`EArgumentException`** (mensagens estáveis no código).
- Dialeto não coberto → **`ENotSupportedException`** com **ESP-022** na mensagem.

## Limitações declaradas

- Sem índices parciais, expressões em colunas, **`CONCURRENTLY`**, **`INCLUDE`**, ou opções avançadas de método de acesso (**ADR-022**). Para **`DROP INDEX`** (incl. **`IF EXISTS`**, **ESP-026**), ver [DDL — DROP INDEX (ESP-025 / ESP-026)](ddl-drop-index.md).
- Para **`ALTER TABLE`**, **`CREATE TABLE`** e **`DROP TABLE`**, ver os guias DDL existentes.

## Leitura no código

- `FluentSQL.DDL.pas` — builder (`NewFluentDDLCreateIndex`).
- `FluentSQL.DDL.Serialize.pas` — `DDLCreateIndexSQL`.
