---
displayed_sidebar: fluentsqlSidebar
title: Introdução
---

## Problema que resolve

Escrever SQL concatenando strings é frágil, difícil de portar entre bancos e propenso a erros de sintaxe. O FluentSQL centraliza a construção em uma **API encadeável** e traduz funções, qualificadores e dialetos via drivers registrados, mantendo o núcleo desacoplado de componentes de conexão.

## Conceitos principais

- **Fluent interface:** métodos encadeados (`Select`, `From`, `Where`, etc.) sobre `TFluentSQL` / `IFluentSQL`.
- **AST:** a consulta é representada internamente antes da serialização, o que ajuda a manter consistência.
- **Drivers:** cada SGBD possui serializadores, funções e qualificadores em `Source/Drivers/` (por exemplo `FluentSQL.Serialize<DB>.pas`).
- **Parâmetros:** valores passados pela API alimentam `IFluentSQLParams`; a partir da v0.2.0, em queries com **conjunto** (`UNION`, `UNION ALL`, `INTERSECT`), a coleção exposta reflete a **ordem dos placeholders** na string final, com reindexação do ramo secundário (incluindo suporte a `?` no MySQL). Na **v1.0.3**, listas em **`IN` / `NOT IN`** via `TArray<String>` ou `TArray<Double>` seguem o mesmo princípio (um binding por elemento; string única continua a representar subconsulta/expressão literal). Na **v1.0.4** (**ESP-010**), sobrecargas com **`array of const`** em predicados (`Where`, `AndOpe`, `OrOpe`, `Having`, `OnCond`), DML (`SetValue`, `Values`) e ramos de **`CASE`** (`When`, etc.) passam **escalares** (número, boolean, variant numérico/data, etc.) para `Params`; entradas **textuais** em `TVarRec` (identificadores, `Char` de operador, strings) continuam **literais** na expressão, conforme **RN-P3** no pipeline. Na **v1.0.5** (**ESP-011**), critérios em **`FluentSQL.Expression.pas`** (`TFluentSQLCriteriaExpression`) associados à query usam **`SqlArrayOfConstToParameterizedSql`** nos ramos acordados; **`Expression(string | array of const)`** no fluente recebe a mesma coleção `Params` (**ADR-011**: sem bind automático de strings em `array of const`). Na **v1.0.6** (**ESP-012**), **`Column(array of const)`** na lista `SELECT` passa a usar o mesmo helper com **`FAST.Params`** (**ADR-009**). Na **v1.0.7** (**ESP-013**), **`CaseExpr(array of const)`** na expressão discriminante do `CASE` passa a usar **`SqlArrayOfConstToParameterizedSql`** com **`FAST.Params`**, alinhado a **ADR-009**, **ADR-011** e **ADR-012**. Na **v1.0.8** (**ESP-014**), o driver **MongoDB** passa a emitir fragmentos **JSON/MQL** canónicos para SELECT e DML mínimo (**ADR-013**). Na **v1.0.9** (**ESP-015**, **ADR-014**), o **Insert** suporta **várias linhas** com **`AddRow`**, SQL `VALUES (...), (...)` e parâmetros **linha a linha**; em **`dbnMongoDB`**, N>1 usa **`insertMany`**.

## Público-alvo

Desenvolvedores Delphi/Lazarus que precisam gerar SQL portável, testável e alinhado a múltiplos dialetos, sem amarrar a lógica a um único componente de acesso.

Para tarefas do dia a dia (SELECT, DML, parâmetros, dialetos), siga o **[Manual de uso](guides/construir-select.md)** na barra lateral.

## Por que usar

- **Portabilidade:** mesma API, serialização específica por banco.
- **Manutenção:** contratos em `FluentSQL.Interfaces.pas` e extensão via registro de drivers.
- **Parâmetros previsíveis:** contagem e ordem de `Params` coerentes com o texto retornado por `AsString`, inclusive em operações de conjunto (correção entregue na issue [#11](https://github.com/ModernDelphiWorks/FluentSQL/issues/11)).

## Nomenclatura (baseline v1.0.0)

A identidade do pacote e da API pública é **FluentSQL**. A fábrica estável é **`CreateFluentSQL`** na unit `FluentSQL`; o atalho **`TCQ`** na mesma unit permanece equivalente. Migração a partir de `CQuery`, `TCQL.New`, units `CQL` ou pacote Boss antigo: ver secção **[1.0.0]** no [CHANGELOG.md](https://github.com/ModernDelphiWorks/FluentSQL/blob/main/CHANGELOG.md) e a issue [#13](https://github.com/ModernDelphiWorks/FluentSQL/issues/13).

## Roadmap e contribuição

O arquivo [ROADMAP.md](https://github.com/ModernDelphiWorks/FluentSQL/blob/main/ROADMAP.md) na raiz do repositório descreve fases, backlog e **como** o documento deve evoluir (gatilhos alinhados a `/architect`, `/sprint`, `/release` e conclusão de implementação). O rastro operacional fino para agentes fica em `.claude/pipeline/` (`esp.md`, `plan.md`, `task.md`, `implement-report.md`, etc.).

- **v1.0.1:** política de gatilhos e artefato vivo — changelog **[1.0.1]**, issue [#15](https://github.com/ModernDelphiWorks/FluentSQL/issues/15).
- **v1.0.2:** reconciliação da **Fase 0** com evidências do repositório (**ESP-008**, **ADR-008**), bloco **Estado atual** com próximo foco na **Fase 1** (parametrização); dívida interna `FCQL*` em `FluentSQL.Register.pas` documentada como fora da API pública — changelog **[1.0.2]**, issue [#17](https://github.com/ModernDelphiWorks/FluentSQL/issues/17). Acompanhamento de caveats: [#18](https://github.com/ModernDelphiWorks/FluentSQL/issues/18).
- **v1.0.3:** primeiro incremento **ESP-009** — `IN` / `NOT IN` com arrays usam placeholders e `IFluentSQLParams`; fixture `Test Delphi/test.core.params.pas` integrado a projetos Firebird e MySQL — changelog **[1.0.3]**, issue [#19](https://github.com/ModernDelphiWorks/FluentSQL/issues/19). Caveats: [#20](https://github.com/ModernDelphiWorks/FluentSQL/issues/20).
- **v1.0.4:** segundo incremento **ESP-010** — `array of const` em `Where`/`Having`/`Values`/`CASE WHEN` (e sobrecargas relacionadas) com valores escalares parametrizados; helper `TUtils.SqlArrayOfConstToParameterizedSql`; testes estendidos em `test.core.params.pas` — changelog **[1.0.4]**, issue [#21](https://github.com/ModernDelphiWorks/FluentSQL/issues/21). Caveats: [#22](https://github.com/ModernDelphiWorks/FluentSQL/issues/22). `Column(array of const)` foi alinhado ao helper na **v1.0.6**; `CaseExpr(array of const)` na **v1.0.7** (**ESP-013**); `Expression(array of const)` no fluente passou a parametrização na **v1.0.5**.
- **v1.0.5:** terceiro incremento da Fase 1 (**ESP-011**) — `TFluentSQLCriteriaExpression` com `IFluentSQLParams`; sobrecargas `array of const` em `FluentSQL.Expression.pas` alinhadas ao helper quando o contexto fornece `Params`; `Where(Q.Expression([...]))` e encadeamentos cobertos em `test.core.params.pas` — changelog **[1.0.5]**, issue [#23](https://github.com/ModernDelphiWorks/FluentSQL/issues/23). Caveats pós-release: [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24). Instâncias de critério criadas **sem** `IFluentSQLParams` mantêm o caminho legado com **`SqlParamsToStr`**.
- **v1.0.6:** quarto incremento (**ESP-012**) — `Column(array of const)` usa `SqlArrayOfConstToParameterizedSql` com `FAST.Params` na projeção; testes `TestColumnArrayOfConstFirebird` / `TestColumnArrayOfConstMySQL` em `test.core.params.pas` — changelog **[1.0.6]**, issue [#25](https://github.com/ModernDelphiWorks/FluentSQL/issues/25). Dívida técnica pós-caveats: [#26](https://github.com/ModernDelphiWorks/FluentSQL/issues/26).
- **v1.0.7:** quinto incremento (**ESP-013**) — `CaseExpr(array of const)` usa `SqlArrayOfConstToParameterizedSql` com `FAST.Params` na expressão discriminante do `CASE`; testes `TestCaseExprArrayOfConstFirebird` / `TestCaseExprArrayOfConstMySQL` em `test.core.params.pas` — changelog **[1.0.7]** (rastreio da entrega; não confundir com a issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27), hoje **ESP-016**). Dívida técnica pós-caveats: [#28](https://github.com/ModernDelphiWorks/FluentSQL/issues/28).
- **v1.0.8:** driver MongoDB (**ESP-014**, **ADR-013**) — SELECT em JSON canónico; DML `insertOne` / `updateMany` / `deleteMany`; breaking change documentado para quem dependia do pseudo-SQL antigo do select — changelog **[1.0.8]**, issue [#29](https://github.com/ModernDelphiWorks/FluentSQL/issues/29). Dívida técnica pós-caveats: [#30](https://github.com/ModernDelphiWorks/FluentSQL/issues/30).
- **v1.0.9:** INSERT em lote (**ESP-015**, **ADR-014**) — `AddRow` no fluente; SQL multi-`VALUES` com placeholders na ordem das linhas; Mongo `insertMany` quando há mais de uma linha; testes `TestInsertBatchTwoRowsFirebird` / `TestInsertBatchTwoRowsMySQL` em `test.core.params.pas` e `TestMongoDB_Insert_SerializesInsertMany` em `UTestFluentSQLFirebird.pas` — changelog **[1.0.9]**, issue [#31](https://github.com/ModernDelphiWorks/FluentSQL/issues/31). Dívida técnica pós-caveats: [#32](https://github.com/ModernDelphiWorks/FluentSQL/issues/32).
