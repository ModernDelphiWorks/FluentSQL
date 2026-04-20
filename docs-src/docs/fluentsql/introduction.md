---
displayed_sidebar: fluentsqlSidebar
title: Introduction
---

> **Documentation language:** this page is being aligned with the **English-first** editorial rule for technical docs; older paragraphs may still be in Portuguese until fully migrated.

## Problema que resolve

Escrever SQL concatenando strings é frágil, difícil de portar entre bancos e propenso a erros de sintaxe. O FluentSQL centraliza a construção em uma **API encadeável** e traduz funções, qualificadores e dialetos via drivers registrados, mantendo o núcleo desacoplado de componentes de conexão.

## Conceitos princ- **Fluent interface:** métodos encadeados (`Select`, `From`, `Where`, etc.) sobre `TFluentSQL` / `IFluentSQL`.
- **AST:** a consulta é representada internamente antes da serialização, o que ajuda a manter consistência.
- **Drivers:** cada SGBD possui serializadores, funções e qualificadores em `Source/Drivers/`.
- **Parâmetros:** valores passados pela API alimentam `IFluentSQLParams`; inclui suporte a reindexação em operações de conjunto e tratamento de listas em `IN` / `NOT IN`.
- **Extensão por motor:** `ForDialectOnly` permite adicionar fragmentos específicos que só entram na SQL final quando o dialeto da instância coincide. Ver o guia [Extensão explícita por motor](guides/extensao-por-dialeto.md).

## Público-alvo

Desenvolvedores Delphi/Lazarus que precisam gerar SQL portável, testável e alinhado a múltiplos dialetos, sem amarrar a lógica a um único componente de acesso.

Para tarefas do dia a dia (SELECT, DML, parâmetros, dialetos), siga o **[Manual de uso](guides/construir-select.md)** na barra lateral.

## Por que usar

- **Portabilidade:** mesma API, serialização específica por banco.
- **Manutenção:** contratos em `FluentSQL.Interfaces.pas` e extensão via registro de drivers.
- **Parâmetros previsíveis:** contagem e ordem de `Params` coerentes com o texto retornado por `AsString`.

## Nomenclatura

A identidade do pacote e da API pública é **FluentSQL**. O ponto de entrada estável para consultas DML é **`Query(ADialect)`** e para DDL é **`Schema(ADialect)`**, ambos na unit `FluentSQL`. As fábricas legadas `CreateFluentSQL` e `TCQ` encontram-se obsoletas e serão removidas em versões futuras.

## Roadmap e contribuição

O arquivo [ROADMAP.md](https://github.com/ModernDelphiWorks/FluentSQL/blob/main/ROADMAP.md) na raiz do repositório descreve fases e o backlog planejado.

- **v1.0.3:** suporte a `IN` / `NOT IN` com listas parametrizadas.
- **v1.0.4:** suporte a `array of const` em predicados e DML com valores escalares parametrizados.
- **v1.0.9:** suporte a INSERT em lote com `AddRow` e multi-`VALUES`.
- **v1.1.0:** introdução da API DDL (CREATE TABLE, DROP TABLE, ALTER TABLE ADD COLUMN).
- **v1.1.1:** suporte a ALTER TABLE DROP COLUMN e CREATE INDEX.
- **v1.2.0:** Cache Distribuído (Redis), Constraints Avançadas e Chaves Estrangeiras.
- **v1.3.0:** suporte a Renomear Tabela e refinamento do ponto de entrada `Schema`.
- **v1.4.0:** MongoDB Aggregations & Joins, MongoDB DDL, Views, Sequences, Identity e Comments.
- **v1.5.0:** suporte a DDL Schemas (logical namespaces) e esqueleto inicial para DML MERGE.
- **v1.5.1:** suporte completo a DML MERGE (MSSQL), paridade de Funções Escalares e reestruturação da suíte de testes.
