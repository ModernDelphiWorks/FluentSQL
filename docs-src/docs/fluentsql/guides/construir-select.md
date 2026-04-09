---
displayed_sidebar: fluentsqlSidebar
title: Construir um SELECT
---

Passo a passo para montar uma consulta `SELECT` com a API fluente. Os exemplos usam Firebird; troque `dbnFirebird` pelo constante do seu SGBD (ver [Configuração e constantes](../reference/configuration.md)).

## 1. Escolher o dialeto

Indique qual motor de serialização será usado ao criar a query.

## 2. Abrir a construção com `Select`

Encadeie a partir de `CreateFluentSQL(dbn…)` ou `TCQ(dbn…)`.

## 3. Definir colunas e origem

Use `.Column` para colunas explícitas ou `.Select.All` quando fizer sentido para o seu caso.

## 4. Filtrar, ordenar e paginar

Use `.Where`, `.OrderBy`, joins conforme `IFluentSQL` e as interfaces de seção do projeto.

## 5. Obter o texto SQL

Chame `.AsString` no final da cadeia.

## Exemplo completo (mínimo)

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

## Exemplo com join (referência do repositório)

Adaptado de `.claude/references/examples.md`:

```pascal
uses FluentSQL;

var
  SQL: string;
begin
  SQL := TCQ(dbnMSSQL)
    .Select.All
    .From('PEDIDOS', 'P')
    .InnerJoin('ITENS', 'I').OnCond('P.ID = I.ID_PEDIDO')
    .Where('P.DATA').GreaterEqThan(Date)
    .OrderBy('P.ID').Desc
    .AsString;
end;
```

## Próximos passos

- [Parâmetros e UNION / INTERSECT](parametros-e-uniao.md)
- [INSERT, UPDATE e DELETE](dml-insert-update-delete.md)
- [Referência de API](../reference/api.md) (contratos para contribuidores)
