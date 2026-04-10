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

## «Select do banco … não está registrado» em runtime (testes ou app)

- **Sintoma:** em execução, exceção ao serializar indicando que o **select** do dialeto não foi registrado, apesar de units `FluentSQL.Select*` estarem no `uses`.
- **Provável causa:** em `FluentSQL.inc` / registo condicional, o driver só entra no registo global se a compilação define macros como `MSSQL`, `ORACLE`, `DB2`, `INTERBASE` **antes** da cadeia de `uses` que puxa o núcleo — e o seu `.dpr` pode não definir o símbolo correspondente ao SGBD alvo.
- **Ação:** no `.dpr` do programa, declare `{$DEFINE MSSQL}` (ou `ORACLE`, `DB2`, `INTERBASE`, conforme o dialeto) **antes** dos `uses` que referenciam o FluentSQL, alinhado ao que o projeto espera em `FluentSQL.Register`. Para detalhe e follow-up: issue [#14](https://github.com/ModernDelphiWorks/FluentSQL/issues/14).
