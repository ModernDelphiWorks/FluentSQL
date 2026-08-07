---
displayed_sidebar: fluentsqlSidebar
title: Erros comuns
---

## Parâmetros não batem com a SQL em UNION / INTERSECT

- **Sintoma:** driver ou log mostra número de parâmetros diferente do esperado, ou binding na ordem errata após `Union` / `Intersect` / `UnionAll`.
- **Provável causa:** versão anterior à **v0.2.0**, ou ramo secundário com placeholders não reindexados para o dialeto.
- **Ação:** atualize para **v0.2.0** ou superior; confira `FluentSQL.Serialize.pas` e testes Firebird/MySQL da issue [#11](https://github.com/ModernDelphiWorks/FluentSQL/issues/11). Garanta que está usando o **driver correto** (especialmente MySQL com `?`).

## SQL inválido para o banco em uso

- **Sintoma:** erro de sintaxe no servidor ao executar a string gerada.
- **Provável causa:** driver (`dbn…`) não corresponde ao SGBD real, ou função não mapeada naquele dialeto.
- **Ação:** troque o driver; verifique `IFluentSQLFunctions` e a implementação em `Source/Drivers/` para o seu banco.

## Nomenclatura legada (CQuery4D / CQuery / TCQL) vs FluentSQL

- **Sintoma:** exemplos antigos não compilam ou units não encontradas (`CQL`, `CQuery`, `TCQL.New`, pacote Boss `CQuery4D`).
- **Provável causa:** renomeação da API pública e do pacote para **FluentSQL** (CHANGELOG **[1.0.0]**).
- **Ação:** use `CreateFluentSQL(dbn…)` na unit `FluentSQL` em vez de `CQuery` / `TCQL.New`; `uses FluentSQL, FluentSQL.Interfaces`; pacote Boss **FluentSQL**. O atalho `TCQ(dbn…)` permanece disponível na mesma unit.

## `EFluentSQLInsertBatch` ao usar `AddRow` ou INSERT em lote

- **Sintoma:** em tempo de execução, exceção **`EFluentSQLInsertBatch`** com mensagem como *AddRow requires a non-empty current row*, *inconsistent column count between rows* ou *missing value for column "…"*.
- **Provável causa:** **`AddRow`** chamado sem **`SetValue`** (ou equivalente) na linha corrente; linhas com **número ou nomes de colunas** diferentes; valor em falta para uma coluna esperada na linha.
- **Ação:** preencha cada linha com o mesmo conjunto de colunas antes de **`AddRow`**; não chame **`AddRow`** com **`Values`** vazio. A **última** linha pode ser fechada só com **`AsString`** (*flush* implícito). Use **`Clear`** na secção Insert para recomeçar todas as linhas. Referência: **`FluentSQL.Insert.pas`**, guia [INSERT, UPDATE e DELETE](../guides/dml-insert-update-delete.md); rastreio **ESP-015** / **[1.0.9]**: issue [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24).

## `ENotSupportedException` ao usar Schemas ou MERGE

- **Sintoma:** erro em tempo de execução ao chamar `.AsString` em operações de Schema ou Merge.
- **Provável causa:** o dialeto selecionado (ex: SQLite, Firebird) não possui suporte implementado para a operação solicitada (Schemas ou MERGE skeleton).
- **Ação:** verifique a [Matriz de Suporte](../architecture/overview.md#matriz-de-dialetos). No caso de Schemas, utilize dialetos como PostgreSQL ou MSSQL. Operações de Schema no MySQL são mapeadas para Database.

## `EFluentSQLDriverNotRegistered` — «… do banco … não está registrado» em runtime (testes ou app)

- **Sintoma:** em execução, exceção ao serializar indicando que o **select**, o **serialize** ou as **funções** do dialeto não foram registrados, apesar de units `FluentSQL.Select*` / `FluentSQL.Functions*` estarem no `uses`.
- **Classe da exceção:** `EFluentSQLDriverNotRegistered` (declarada em `FluentSQL.Interfaces.pas`). Até a **1.5.1** o `select` e o `serialize` levantavam `Exception` crua e as **funções** não levantavam nada — devolviam `nil`, e o consumidor recebia uma `EAccessViolation` opaca. Se a sua camada captura esse erro para o traduzir em erro de domínio, passe a capturar a classe nomeada.
- **Provável causa:** o dialeto está desligado em **`Source\FluentSQL.inc`**. Esse ficheiro é a única fonte de verdade sobre quais drivers entram no registo global: `FluentSQL.Register.pas` inclui-o (`{$include ..\FluentSQL.inc}`) e todos os blocos `{$IFDEF FIREBIRD}`, `{$IFDEF DB2}` etc. são resolvidos a partir dele. Por omissão vêm ligados **Firebird, MSSQL, MySQL, SQLite, Oracle, PostgreSQL e MongoDB**; **`INTERBASE` e `DB2` vêm desligados**.
- **Ação — o que funciona.** Escolha **uma** das duas:
  1. **Editar `Source\FluentSQL.inc`** e descomentar o símbolo do dialeto (`{.$DEFINE DB2}` → `{$DEFINE DB2}`).
  2. **Definir o símbolo globalmente para toda a compilação**, o que não exige tocar no ficheiro da biblioteca: `-DDB2` na linha de comando do `dcc32` / `dcclinux64`, ou *Project Options → Building → Delphi Compiler → Conditional defines* na IDE.

> **Não funciona: `{$DEFINE}` no seu `.dpr`.** No Delphi, `{$DEFINE}` tem **escopo de ficheiro** — vale só para o ficheiro onde está escrito, e **não se propaga** para as units do FluentSQL que estão a ser compiladas. Declarar `{$DEFINE DB2}` no topo do seu programa não tem efeito nenhum sobre como `FluentSQL.Register.pas` compila.
>
> Os `{$DEFINE}` no topo de `Test Delphi\Firebird_tests\PTestFluentSQLFirebird.dpr` são, pela mesma razão, **decorativos** — quem imitar aquele padrão cai exatamente neste erro. Verificado em 2026-08-07: (a) apagar os sete `{$DEFINE}` daquele `.dpr` deixa o resultado idêntico (94 testes, 93 verdes), porque quem já os ligava era o `.inc`; (b) o `.dpr` do DB2 não define símbolo nenhum e falha com esta exceção em 22 testes — recompilado com `-DDB2`, passam 10 e nenhum erra.

Para detalhe e follow-up: issue [#14](https://github.com/ModernDelphiWorks/FluentSQL/issues/14).

## `EFluentSQLFunctionNotSupported` ao usar funções escalares no MongoDB

- **Sintoma:** ao chamar `Trim`, `Upper` via `Length`, `Concat`, `Coalesce`, `Year`, `CurrentDate`, `Ceil`, `Modulus` e afins com `dbnMongoDB`, a chamada levanta em vez de devolver texto.
- **Provável causa:** não é um driver incompleto — é deliberado. O serializador MongoDB só sabe consumir **nome de campo** ou **marcador de agregação**; um documento MQL devolvido no lugar de uma coluna seria tratado como nome de campo e produziria MQL inválido em silêncio. Agregações (`Count`, `Sum`, `Min`, `Max`, `Average`) **funcionam** normalmente.
- **Ação:** faça a transformação escalar no pipeline da aplicação, ou use um dialeto SQL. A exceção é nomeada e traz a função e o dialeto na mensagem, para tradução em erro de domínio.
