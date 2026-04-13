---
displayed_sidebar: fluentsqlSidebar
title: Architecture overview
---

## Contexto

O FluentSQL separa **definição da consulta** (API fluente + AST) da **serialização** específica por SGBD. O núcleo não depende de FireDAC, UniDAC ou conexões físicas: entrega **string SQL** e **parâmetros** para o consumidor aplicar no componente de acesso que preferir.

## Componentes principais

| Área | Papel |
|------|--------|
| `Source/Core/FluentSQL.Interfaces.pas` | Contratos (`IFluentSQL`, seções, `IFluentSQLParams`, AST exposta onde aplicável; contratos DDL `IFluentDDL*` desde **v1.1.0**). |
| `Source/Core/FluentSQL.Insert.pas` | Secção **Insert**: linhas múltiplas (**v1.0.9**, **`AddRow`**), serialização `VALUES (...), (...)` e validações de lote (`EFluentSQLInsertBatch`). |
| `Source/Core/FluentSQL.DDL.pas` | Builders DDL: núcleo **v1.1.0** (`CREATE TABLE`, `DROP TABLE`, `ALTER TABLE ADD COLUMN`); **v1.1.1** (`ALTER TABLE DROP COLUMN`, `CREATE [UNIQUE] INDEX`) — apenas texto via `AsString`. |
| `Source/Core/FluentSQL.DDL.Serialize.pas` | Serialização DDL (`DDLCreateTableSQL`, `DDLDropTableSQL`, `DDLAlterTableAddColumnSQL`, `DDLAlterTableDropColumnSQL`, `DDLCreateIndexSQL`). |
| `Source/Core/FluentSQL.pas` | Implementação principal (`TFluentSQL`), estado da query, operações de conjunto e exposição de `Params` mesclados quando há `UnionQuery`; fábricas `CreateFluentDDL*`. |
| `Source/Core/FluentSQL.Ast.pas` | AST interna; campos como `UnionType` e `UnionQuery` para operações de conjunto. |
| `Source/Core/FluentSQL.Serialize.pas` | Lógica comum de serialização, incluindo remapeamento de placeholders no ramo de conjunto. |
| `Source/Core/FluentSQL.Params.pas` | `TFluentSQLParams` e `TFluentSQLMergedParams` (visão ordenada de duas coleções). |
| `Source/Drivers/` | Serializers, funções e qualificadores por dialeto (`FluentSQL.Serialize*.pas`, etc.). |

## Extensibilidade

- Novos dialetos entram via **registro de drivers** (`FluentSQL.Register.pas` e units de driver).
- Funções escalares devem ser mapeadas em `IFluentSQLFunctions` e nas implementações por banco, conforme convenções do projeto.

## Matriz de dialetos

O repositório inclui drivers e testes sob `Source/Drivers/` e `Test Delphi/` para vários motores, entre outros **Firebird**, **PostgreSQL**, **MySQL**, **MSSQL**, **Oracle**, **DB2**, **Interbase**, **SQLite** e **MongoDB** (cobertura e maturidade por dialeto variam; ver unidades `FluentSQL.Serialize*.pas` e projetos de teste correspondentes).

## Roadmap e pipeline (repositório)

Para **direção do produto** e checklist de fases, use o `ROADMAP.md` na raiz e o `CHANGELOG.md` (artefato vivo desde a v1.0.1; na v1.0.2 a Fase 0 foi encerrada no âmbito consumidor; na **v1.0.3** entrou **ESP-009** (`IN`/`NOT IN` com listas); na **v1.0.4** entrou **ESP-010** (`array of const` em predicados e DML); na **v1.0.5** entrou **ESP-011** (critérios em `FluentSQL.Expression.pas` alinhados a `IFluentSQLParams`); na **v1.0.6** entrou **ESP-012** (`Column(array of const)` parametrizado na projeção); na **v1.0.7** entrou **ESP-013** (`CaseExpr(array of const)` alinhado ao helper de parametrização); na **v1.0.8** entrou **ESP-014** (Mongo MQL/DML); na **v1.0.9** entrou **ESP-015** (INSERT em lote, **ADR-014**); na **v1.1.0** entraram **ESP-016** (fecho formal `ForDialectOnly`), **ESP-017**–**ESP-019** (DDL texto para `CREATE` / `DROP` / `ALTER ADD COLUMN`) e o portal em `docs-src/` com CI; na **v1.1.1** entraram **ESP-020** / **ESP-022** (DDL adicional). **ESP-016** está no código em `FluentSQL.Serialize.pas` / `FluentSQL.pas`. Evidências operacionais finas, quando existirem no clone: `.claude/pipeline/implement-report.md` e relatórios da esteira.
