---
displayed_sidebar: fluentsqlSidebar
title: DML — MERGE
---

# DML — MERGE

Introduzido na **v1.5.0** e consolidado na **v1.5.1**, o suporte a **MERGE** permite realizar operações complexas de sincronização de dados (UPSERT) de forma fluente e tipada.

## Sintaxe fluente

A API do MERGE segue o padrão SQL ANSI e oferece métodos para parametrização automática de valores:

```pascal
var
  LMerge: string;
begin
  LMerge := Query(dbnMSSQL)
    .Merge
    .Into('TargetTable', 'T')
    .Using('SourceTable', 'S')
    .On('T.ID = S.ID')
    .WhenMatched
      .Update(['T.VALOR = S.VALOR', 'T.DATA = S.DATA'])
    .WhenNotMatched
      .Insert(['ID', 'VALOR'], ['S.ID', 'S.VALOR'])
    .AsString;
end;
```

## Seções disponíveis

| Método | Descrição |
|--------|-----------|
| **`Into(Table, Alias)`** | Define a tabela alvo. |
| **`Using(Table, Alias)`** | Define a tabela fonte. |
| **`On(Condition)`** | Define o critério de junção. |
| **`WhenMatched`** | Bloco executado quando há correspondência (UPDATE ou DELETE). |
| **`WhenNotMatched`** | Bloco executado quando NÃO há correspondência (INSERT). |
| **`.Update(Columns)`** | Operação de atualização dentro de `WhenMatched`. |
| **`.Delete`** | Operação de exclusão dentro de `WhenMatched`. |
| **`.Insert(Columns, Values)`** | Operação de inserção dentro de `WhenNotMatched`. |

## Suporte por Dialeto

| Dialeto | Estado | Notas |
|---------|--------|-------|
| **MSSQL** | ✅ Completo | Utiliza o comando `MERGE` nativo do SQL Server. |
| **PostgreSQL** | 🔄 Planejado | Mapeamento para `INSERT ... ON CONFLICT` em desenvolvimento. |
| **MySQL** | 🔄 Planejado | Mapeamento para `INSERT ... ON DUPLICATE KEY UPDATE` em desenvolvimento. |

## Exemplo com Parametrização

O `MERGE` também suporta a coleção de parâmetros do FluentSQL:

```pascal
LMerge := Query(dbnMSSQL)
  .Merge
  .Into('PRODUTOS')
  .Using('TEMP_PRODUTOS', 'TMP')
  .On('PRODUTOS.SKU = TMP.SKU')
  .WhenMatched.Update
  .WhenNotMatched.Insert
  .AsString;

// Os parâmetros gerados em cláusulas 'Using' ou 'On' são capturados em Query.Params
```

## Detalhes Técnicos

Internamente, o MERGE utiliza a Árvore Sintática Abstrata (AST) do FluentSQL para garantir que a estrutura do comando esteja correta antes da serialização. O driver do MSSQL (`FluentSQL.Drivers.MSSQL.pas`) é o primeiro a receber suporte completo de serialização para este nó.

