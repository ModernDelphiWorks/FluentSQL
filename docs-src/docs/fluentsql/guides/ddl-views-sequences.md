---
displayed_sidebar: fluentsqlSidebar
title: DDL — Views & Sequences
---

# DDL — Views & Sequences

A partir da **v1.4.0**, o FluentSQL suporta a criação e remoção de **Views** e **Sequences** (Geradores) de forma agnóstica.

## Views

As Views permitem encapsular consultas complexas em objetos de banco de dados.

### Criar View

A definição da View utiliza a própria API do FluentSQL para a cláusula `AS SELECT`.

```pascal
uses FluentSQL;

var
  SQL: string;
begin
  SQL := Schema(dbnPostgreSQL)
    .CreateView('VW_VENDAS_POR_STATUS')
    .As(
      Query(dbnPostgreSQL)
        .Select.Column('STATUS').Column('Sum(VALOR)', 'total')
        .From('VENDAS')
        .GroupBy('STATUS')
    )
    .AsString;
end;
```

### Remover View

```pascal
SQL := Schema(dbnFirebird).DropView('VW_CLIENTES_ATIVOS').AsString;
```

## Sequences (Generators)

Sequences são objetos que geram valores numéricos sequenciais, comuns em Firebird, PostgreSQL e Oracle.

### Criar Sequence

```pascal
uses FluentSQL;

var
  SQL: string;
begin
  SQL := Schema(dbnFirebird)
    .CreateSequence('GEN_CLIENTE_ID')
    .StartWith(1)
    .IncrementBy(1)
    .AsString;
end;
```

### Remover Sequence

```pascal
SQL := Schema(dbnPostgreSQL).DropSequence('SEQ_PEDIDO_ID').AsString;
```

## Próximos passos

- [DDL — CREATE TABLE](ddl-create-table.md)
- [DDL — Advanced Columns](ddl-advanced-columns.md)
