---
displayed_sidebar: fluentsqlSidebar
title: DDL — Comments
---

# DDL — Table & Column Comments

A **v1.4.0** introduz o suporte para documentação de metadados diretamente no banco de dados através de comentários em tabelas e colunas.

## Comentários em Tabelas

Adicione descrições às suas tabelas para facilitar a manutenção e o entendimento do modelo de dados.

```pascal
uses FluentSQL;

var
  SQL: string;
begin
  SQL := Schema(dbnPostgreSQL)
    .CommentOnTable('USUARIOS', 'Armazena as credenciais e perfis de acesso do sistema.')
    .AsString;
end;
```

## Comentários em Colunas

Você pode comentar colunas logo após a criação ou em qualquer momento posterior.

### No Create Table (Inline)

```pascal
SQL := Schema(dbnFirebird)
  .CreateTable('PRODUTOS')
    .Column('ID', ltyInteger).PrimaryKey
    .Column('PRECO', ltyCurrency).Comment('Preço de venda unitário em BRL.')
  .AsString;
```

### Usando API explícita

```pascal
SQL := Schema(dbnPostgreSQL)
  .CommentOnColumn('PRODUTOS', 'PRECO', 'Preço reajustado conforme inflação.')
  .AsString;
```

## Dialetos Suportados

- **PostgreSQL**: Traduzido para `COMMENT ON TABLE ...` / `COMMENT ON COLUMN ...`.
- **Firebird**: Traduzido para `COMMENT ON TABLE ...` / `COMMENT ON COLUMN ...`.
- **MySQL/MariaDB**: Traduzido para a cláusula `COMMENT` dentro do DDL da coluna ou tabela.

## Próximos passos

- [DDL — CREATE TABLE](ddl-create-table.md)
- [DDL — Advanced Columns](ddl-advanced-columns.md)
