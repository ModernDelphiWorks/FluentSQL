---
displayed_sidebar: fluentsqlSidebar
title: Suporte a MongoDB
---

O FluentSQL oferece suporte a **MongoDB** através do dialeto `dbnMongoDB`. Diferente dos drivers SQL tradicionais, o driver MongoDB serializa a árvore sintática (AST) para **MQL (MongoDB Query Language)** em formato JSON, permitindo que você utilize a mesma API fluente para interagir com coleções do MongoDB.

## DML (Data Manipulation Language)

### Select simples (`find`)

Consultas sem agrupamentos ou joins são serializadas como o comando `find`.

```pascal
var
  LJSON: string;
begin
  LJSON := Query(dbnMongoDB)
    .Select('name')
    .Select('email')
    .From('users')
    .Where('status = "active"')
    .OrderBy('name')
    .AsString;
end;
```

**Resultado:**
```json
{
  "find": "users",
  "filter": { "status": "active" },
  "projection": { "name": 1, "email": 1 },
  "sort": { "name": 1 }
}
```

### Agregações (`aggregate`)

A partir da **v1.4.0**, o uso de `GroupBy`, `Having` ou funções agregadas aciona automaticamente o comando `aggregate` com um pipeline de estágios.

```pascal
LJSON := Query(dbnMongoDB)
  .Select('categoryId')
  .Select('Sum(price)', 'total')
  .From('products')
  .GroupBy('categoryId')
  .Having('Sum(price) > 100')
  .AsString;
```

**Pipeline gerado:**
- `$group`: Agrupa por `categoryId` e calcula a soma.
- `$match`: Aplica o filtro do `Having`.
- `$project`: Formata a saída final.

### Joins ($lookup)

O FluentSQL mapeia `InnerJoin` e `LeftJoin` para o estágio `$lookup` do MongoDB, seguido de um `$unwind` para garantir que o resultado seja "plano", similar ao comportamento do SQL.

```pascal
LJSON := Query(dbnMongoDB)
  .Select('o.id')
  .Select('u.name', 'customer_name')
  .From('orders', 'o')
  .LeftJoin('users', 'u').OnCond('o.userId = u.id')
  .AsString;
```

**Resultado:**
```json
{
  "aggregate": "orders",
  "pipeline": [
    {
      "$lookup": {
        "from": "users",
        "localField": "userId",
        "foreignField": "id",
        "as": "u"
      }
    },
    { "$unwind": { "path": "$u", "preserveNullAndEmptyArrays": true } },
    { "$project": { "id": 1, "customer_name": "$u.name" } }
  ],
  "cursor": {}
}
```

### Insert, Update e Delete

- **Insert:** Mapeia para `insertOne` ou `insertMany` (quando usado `AddRow`).
- **Update:** Mapeia para `updateMany`.
- **Delete:** Mapeia para `deleteMany`.

## DDL (Data Definition Language)

Você também pode gerar comandos administrativos para MongoDB usando a API de Schema.

### Criar Coleção e Índices

```pascal
// Criar coleção
LJSON := Schema(dbnMongoDB).CreateTable('logs').AsString;

// Criar índice
LJSON := Schema(dbnMongoDB)
  .CreateIndex('idx_timestamp')
  .On('logs')
  .Columns(['timestamp'])
  .AsString;
```

**Resultados:**
```json
{ "create": "logs" }
{ "createIndexes": "logs", "indexes": [{ "name": "idx_timestamp", "key": { "timestamp": 1 } }] }
```

## Limitações conhecidas

- **Joins complexos:** Apenas condições de igualdade simples (`A.field = B.field`) são suportadas no `ON`.
- **Transações:** O builder foca na serialização da consulta, não na gestão de transações do driver.
- **Tipos de dados:** Valores passados via parâmetros são serializados respeitando os tipos JSON básicos.
