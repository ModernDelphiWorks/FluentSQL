---
displayed_sidebar: fluentsqlSidebar
title: Início rápido
---

## Pré-requisitos

- Projeto Delphi/Lazarus com units do FluentSQL no path.
- Escolha do **driver** adequado (por exemplo Firebird, MySQL, MSSQL) na inicialização da query.

## Exemplo mínimo

O repositório documenta o ponto de entrada **`CreateFluentSQL`** (e o atalho `TCQ`) com constantes de driver (`dbnFirebird`, etc.). Exemplo adaptado de `.claude/references/examples.md`:

```pascal
uses FluentSQL;

var
  SQL: string;
begin
  SQL := CreateFluentSQL(dbnFirebird)
    .Select
    .Column('ID')
    .Column('NOME')
    .From('CLIENTES')
    .Where('ATIVO').Equal(1)
    .AsString;
end;
```

## Exemplo DDL (ESP-017 / ESP-034)

A partir da **v1.1.0**, você também pode gerar comandos `CREATE TABLE` de forma fluente:

```pascal
uses FluentSQL;

var
  LSql: string;
begin
  LSql := CreateFluentDDLTable(dbnPostgreSQL, 'USUARIOS')
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
