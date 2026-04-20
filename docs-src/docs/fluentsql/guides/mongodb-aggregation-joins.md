---
displayed_sidebar: fluentsqlSidebar
title: MongoDB Aggregations & Joins
---

# MongoDB Aggregations & Joins

Desde a **v1.4.0**, o driver MongoDB do FluentSQL suporta o mapeamento automático de cláusulas SQL complexas para o **Aggregation Pipeline** do MongoDB.

## Cláusulas suportadas

O driver detecta automaticamente quando uma consulta exige o comando `aggregate` em vez de `find`. As seguintes cláusulas acionam essa transição:

- `GroupBy` -> `$group`
- `Having` -> `$match` (pós-group)
- `InnerJoin` / `LeftJoin` -> `$lookup` + `$unwind`
- Funções agregadas (`Sum`, `Count`, `Min`, `Max`, `Avg`) -> Operadores de acumulação do `$group`.

## Joins (Cross-Collection)

O FluentSQL mapeia `INNER JOIN` e `LEFT JOIN` para o estágio `$lookup`. Para manter o comportamento SQL de "achatar" os resultados (flatten), o driver executa um `$unwind` automático nos resultados do lookup.

### Exemplo de Join

```pascal
uses FluentSQL;

var
  MQL: string;
begin
  MQL := Query(dbnMongoDB)
    .Select
    .Column('P.ID', 'id')
    .Column('P.VALOR', 'total')
    .Column('C.NOME', 'cliente')
    .From('PEDIDOS', 'P')
    .InnerJoin('CLIENTES', 'C').OnCond('P.ID_CLIENTE = C.ID')
    .AsString;
    
  // Gera um Aggregation Pipeline com $lookup, $unwind e $project
end;
```

## Agregações (Group By)

Quando `GroupBy` é utilizado, o driver agrupa os campos no estágio `$group`. O identificador central do grupo (`_id`) é resolvido automaticamente ou focado nos campos do agrupamento.

### Exemplo de Agregação

```pascal
uses FluentSQL;

var
  MQL: string;
begin
  MQL := Query(dbnMongoDB)
    .Select
    .Column('STATUS')
    .Column('Sum(VALOR)', 'total_vendas')
    .Column('Count(*)', 'qtd')
    .From('PEDIDOS')
    .GroupBy('STATUS')
    .Having('Sum(VALOR)').GreaterThan(1000)
    .AsString;
    
  // Gera stages: $group (com $sum e $count), $match (para o Having) e $project
end;
```

## Limitações conhecidas

- **Join Conditions**: O driver utiliza uma heurística para mapear `P.ID_CLIENTE = C.ID`. Condições complexas de join (múltiplas expressões ou subconsultas no ON) podem não ser suportadas em todas as versões.
- **Lookup e Unwind**: O driver assume que o join é de cardinalidade 1:1 ou que o usuário deseja o achatamento do resultado via `$unwind`.

## Próximos passos

- [MongoDB DDL Extensions](mongodb-ddl.md)
- [Build a SELECT](construir-select.md)
