---
displayed_sidebar: fluentsqlSidebar
title: DDL — Foreign Keys (ESP-035/ESP-072)
---

A partir da entrega **ESP-035/ESP-072**, o FluentSQL suporta a definição de **chaves estrangeiras** (`FOREIGN KEY`) de forma fluida, tanto em linha através do método **`.References`** quanto em nível de tabela através do método **`.ForeignKey`**.

## API

### Definição em Linha (Inline)

O método **`.References`** deve ser chamado imediatamente após a definição da coluna. Após o vínculo, é possível especificar ações de integridade referencial:

- **`.References(const ATableName, AColumnName: string)`**: Define a tabela e coluna de referência.
- **`.OnDelete(TDDLReferentialAction)`**: Define a ação ao excluir (Cascade, SetNull, etc).
- **`.OnUpdate(TDDLReferentialAction)`**: Define a ação ao atualizar.

#### Exemplo

```delphi
LSql := Schema(dbnPostgreSQL).Table('PEDIDOS').Create
  .ColumnInteger('CLIENTE_ID')
    .References('CLIENTES', 'ID')
    .OnDelete(raCascade)
    .OnUpdate(raSetNull)
  .AsString;
```

### Definição em Nível de Tabela (Table-Level)

Para chaves nomeadas ou definições separadas das colunas:

- **`.ForeignKey(const AColumn, ARefTable, ARefColumn: string; const AName: string = '')`**

#### Exemplo

```delphi
LSql := Schema(dbnPostgreSQL).Table('PEDIDOS').Create
  .ColumnInteger('ID').PrimaryKey
  .ColumnInteger('CLIENTE_ID')
  .ForeignKey('CLIENTE_ID', 'CLIENTES', 'ID', 'FK_PEDIDOS_CLIENTES')
    .OnDelete(raCascade)
  .AsString;
```

## Ações Disponíveis (`TDDLReferentialAction`)

As seguintes ações são mapeadas para os dialetos suportados:

- `raCascade`: `CASCADE`
- `raSetNull`: `SET NULL`
- `raSetDefault`: `SET DEFAULT`
- `raRestrict`: `RESTRICT`
- `raNoAction`: `NO ACTION` (padrão)

## Dialetos suportados

A serialização de referencial actions está validada para:

| Dialeto | Constante |
|---------|-----------|
| Firebird | `dbnFirebird` |
| PostgreSQL | `dbnPostgreSQL` |
| MySQL | `dbnMySQL` |
| MSSQL | `dbnMSSQL` |
| SQLite | `dbnSQLite` |

## Leitura no código

- `FluentSQL.Interfaces.pas` — `TDDLReferentialAction` e métodos fluent.
- `FluentSQL.DDL.pas` — Armazenamento das ações nos builders.
- `FluentSQL.DDL.SerializeAbstract.pas` — `ReferentialActionToString` e geração SQL centralizada.
