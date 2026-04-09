---
displayed_sidebar: fluentsqlSidebar
title: Parâmetros e UNION / INTERSECT
---

## Uso cotidiano de parâmetros

1. Construa a query com `CreateFluentSQL(dbn…)` (ou `TCQ`).
2. Obtenha o comando com `.AsString`.
3. Use a coleção **`Params`** (interface `IFluentSQLParams`) exposta pelo objeto de query para fazer o **binding** na sua camada de acesso.
4. Garanta que a **ordem** dos parâmetros ligados corresponde à **ordem dos placeholders** na string retornada por `.AsString`.

Sem isso, o driver ou o servidor pode rejeitar a execução ou associar valores às posições erradas.

## IN e NOT IN com listas (v1.0.3)

Quando você usa **`InValues`** / **`NotIn`** com **`TArray<String>`** ou **`TArray<Double>`**, a SQL gerada contém **um placeholder por item** da lista e **`Params`** recebe **um valor por placeholder**, na mesma ordem (por dialeto: nomeados `:p1`, `:p2`, … ou posicionais `?`). Isso evita interpolar literais vindos de coleções.

Se você passar uma **única `String`**, o framework trata o texto como **subconsulta ou expressão já entre parênteses** (comportamento anterior), não como lista de valores a expandir.

Mais detalhes: [Referência de API](../reference/api.md) e `CHANGELOG.md` **[1.0.3]**.

## `array of const` em predicados e DML (v1.0.4)

Sobrecargas que aceitam **`const Args: array of const`** (por exemplo em `Where`, `Having`, `Values`, ramos de `CASE`/`When`) tratam **valores escalares** como **parâmetros** (`:pN` ou `?` por dialeto) e preenchem **`Params`** na ordem correspondente. **Strings**, **identificadores** e **operadores** passados como literais dentro do `array of const` continuam embutidos na expressão SQL (não viram binding), alinhado à regra **RN-P3** descrita no pipeline.

**`CaseExpr(array of const)`** e **`Column(array of const)`** usam **`SqlArrayOfConstToParameterizedSql`** com a coleção da query: **`Column`** desde a **v1.0.6** (**ESP-012**, issue [#25](https://github.com/ModernDelphiWorks/FluentSQL/issues/25)); **`CaseExpr`** desde a **v1.0.7** (**ESP-013**, issue [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27)), com **strings** no `array of const` ainda como literais (**ADR-011**). Consulte `CHANGELOG.md` **[1.0.4]**, **[1.0.6]** e **[1.0.7]** e a [Referência de API](../reference/api.md).

## Critérios e `Expression` no fluente (v1.0.5)

A partir da **v1.0.5** (**ESP-011**), quando você obtém uma expressão via **`Expression(string)`** ou **`Expression(array of const)`** a partir de **`TFluentSQL`** (ou critérios de `CASE` que recebem `FOwner.Params`), o objeto **`TFluentSQLCriteriaExpression`** fica associado à mesma coleção **`IFluentSQLParams`** da query. Com isso, encadeamentos como **`AndOpe` / `OrOpe` / `Ope` / `Fun`** com **`array of const`** expandem **escalares** para placeholders da mesma forma que em **`Where(array of const)`**, respeitando **ADR-011** (strings em `TVarRec` não viram bind automático). Se a expressão for criada **fora** desse contexto (sem `Params`), o comportamento permanece o legado com **`SqlParamsToStr`**. Ver `CHANGELOG.md` **[1.0.5]** e a issue [#23](https://github.com/ModernDelphiWorks/FluentSQL/issues/23); acompanhamento: [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24).

## UNION, UNION ALL e INTERSECT

A partir da **v0.2.0**, quando há parâmetros nos **dois** ramos de uma operação de conjunto:

1. A serialização pode **reindexar** placeholders no ramo secundário (comportamento documentado em `FluentSQL.Serialize.pas`, rotina `UnionRemapBranchSQL`).
2. A coleção visível em `Params` pode ser uma visão **mesclada** (`TFluentSQLMergedParams` em `FluentSQL.Params.pas`), refletindo a ordem final na SQL.

### O que fazer na prática

1. Prefira sempre a mesma versão da biblioteca em todos os módulos do seu app.
2. Depois de compor `Union` / `UnionAll` / `Intersect`, trate `Params` como **fonte única** para binding, sem presumir que é apenas a coleção do ramo principal.
3. Em MySQL, há suporte a placeholders `?` com a mesma regra de ordem; veja testes Firebird/MySQL ligados à issue [#11](https://github.com/ModernDelphiWorks/FluentSQL/issues/11).

## Se algo não bater

Consulte [Erros comuns](../troubleshooting/common-errors.md) (secção sobre UNION/INTERSECT) e a [Referência de API](../reference/api.md).
