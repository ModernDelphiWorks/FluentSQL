---
displayed_sidebar: fluentsqlSidebar
title: Início rápido
---

## Pré-requisitos

- Projeto Delphi/Lazarus com units do FluentSQL no path.
- Escolha do **driver** adequado (por exemplo Firebird, MySQL, MSSQL) na inicialização da query.

## Exemplo mínimo

O ponto de entrada recomendado é **`Query(ADialect)`**. Exemplo:

```pascal
uses FluentSQL;

var
  SQL: string;
begin
  SQL := Query(dbnFirebird)
    .Select
    .Column('ID')
    .Column('NOME')
    .From('CLIENTES')
    .Where('ATIVO').Equal(1)
    .AsString;
end;
```

## Exemplo DDL

Para gerar comandos de definição de dados (DDL), utilize a fábrica **`Schema(ADialect)`**:

```pascal
uses FluentSQL;

var
  LSql: string;
begin
  LSql := Schema(dbnPostgreSQL).CreateTable('USUARIOS')
    .ColumnInteger('ID').PrimaryKey
    .ColumnVarChar('NOME', 100).NotNull
    .ColumnBoolean('ATIVO').DefaultValue(True)
    .AsString;
end;
```

## SQL e parâmetros

- Use `.AsString` para obter o texto SQL gerado.
- A propriedade/coleção **`Params`** exposta pela query deve ser usada para fazer o **binding** na mesma ordem dos placeholders da string.
- Com **UNION / UNION ALL / INTERSECT** e parâmetros nos **dois** ramos, a partir da **v0.2.0** a coleção visível é uma visão **mesclada** (`TFluentSQLMergedParams` em `FluentSQL.Params.pas`), alinhada à serialização que **reindexa** placeholders no ramo secundário (`UnionRemapBranchSQL` em `FluentSQL.Serialize.pas`).

## Próximos passos

- [Site de documentação (CI)](./documentation-ci.md)
- [Visão da arquitetura](../architecture/overview.md)
- [Referência de API](../reference/api.md)
