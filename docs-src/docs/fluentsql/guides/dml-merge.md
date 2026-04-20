---
displayed_sidebar: fluentsqlSidebar
title: DML — MERGE (Skeleton)
---

# DML — MERGE (Skeleton)

Introduzido na **v1.5.0**, o suporte a **MERGE** permite realizar operações complexas de sincronização de dados (UPSERT) de forma fluente.

> [!NOTE]
> Na versão v1.5.0, esta funcionalidade está em estágio de **esqueleto (skeleton)**. A serialização completa e otimização por dialeto serão expandidas em versões futuras.

## Sintaxe fluente

A API do MERGE segue o padrão SQL ANSI:

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
      .Update
    .WhenNotMatched
      .Insert
    .AsString;
end;
```

## Seções disponíveis

| Método | Descrição |
|--------|-----------|
| **`Into(Table, Alias)`** | Define a tabela alvo. |
| **`Using(Table, Alias)`** | Define a tabela fonte (pode ser subquery futuramente). |
| **`On(Condition)`** | Define o critério de junção. |
| **`WhenMatched`** | Bloco executado quando há correspondência. |
| **`WhenNotMatched`** | Bloco executado quando NÃO há correspondência. |
| **`Update`** | Operação de atualização (dentro de WhenMatched). |
| **`Delete`** | Operação de exclusão (dentro de WhenMatched - *previsto*). |
| **`Insert`** | Operação de inserção (dentro de WhenNotMatched). |

## Suporte por Dialeto

Atualmente, o foco da serialização inicial é o **MSSQL**. SQL Server possui suporte nativo robusto ao comando `MERGE`.

Para outros dialetos que utilizam sintaxes diferentes (como `INSERT ... ON CONFLICT` no PostgreSQL), a serialização será implementada nas próximas fases para manter a abstração.

## Exemplo de AST

Internamente, o MERGE gera um nó de AST que captura todas as seções e condições, permitindo que o serializer do driver decida como traduzir para o SQL específico do banco de dados.
