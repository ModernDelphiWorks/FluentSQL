---
displayed_sidebar: fluentsqlSidebar
title: MongoDB DDL Extensions
---

# MongoDB DDL Extensions

A **v1.4.0** expande o suporte DDL para MongoDB, permitindo gerenciar coleções e índices de forma fluente, incluindo recursos específicos como **Capped Collections** e **TTL Indexes**.

## Criar Coleção

Embora o MongoDB crie coleções implicitamente no primeiro insert, a API `Schema` permite a criação explícita com opções avançadas.

### Capped Collections

Coleções de tamanho fixo que substituem documentos antigos automaticamente.

```pascal
uses FluentSQL;

var
  MQL: string;
begin
  MQL := Schema(dbnMongoDB)
    .CreateTable('LOGS_SISTEMA')
    .WithOption('capped', True)
    .WithOption('size', 10485760) // 10MB
    .WithOption('max', 5000)      // Max 5000 docs
    .AsString;
end;
```

## Gerenciamento de Índices

O FluentSQL permite criar e remover índices no MongoDB usando a mesma sintaxe SQL-like.

### Índices com TTL (Time To Live)

Útil para sessões ou dados temporários.

```pascal
uses FluentSQL;

var
  MQL: string;
begin
  MQL := Schema(dbnMongoDB)
    .CreateIndex('IDX_EXPIRACAO')
    .On('SESSOES')
    .Column('DATA_HORA')
    .WithOption('expireAfterSeconds', 3600) // Expira em 1 hora
    .AsString;
end;
```

## Operações Diversas

- **Truncate**: Traduzido para `drop` da coleção (ou remoção de todos os documentos dependendo da configuração).
- **Rename**: Traduzido para `renameCollection`.

```pascal
// Exemplo de Rename
MQL := Schema(dbnMongoDB)
  .AlterTableRename('ANTIGO_NOME', 'NOVO_NOME')
  .AsString;
```

## Próximos passos

- [MongoDB Aggregations & Joins](mongodb-aggregation-joins.md)
- [DDL — CREATE TABLE](ddl-create-table.md)
