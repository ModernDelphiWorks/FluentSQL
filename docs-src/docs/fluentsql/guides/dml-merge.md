---
displayed_sidebar: fluentsqlSidebar
title: DML — MERGE
---

# DML — MERGE

Introduzido na **v1.5.0** e consolidado na **v1.5.1**, o suporte a **MERGE** permite realizar operações de sincronização de dados (UPSERT) de forma fluente.

:::danger Correção — o exemplo anterior desta página nunca funcionou

Até esta revisão, esta página ensinava `.Update(['T.VALOR = S.VALOR', 'T.DATA = S.DATA'])` — o array como **lista de fragmentos de SQL** — e um overload `.Insert(['ID','VALOR'], ['S.ID','S.VALOR'])` com **dois arrays**.

Nenhuma das duas formas jamais funcionou:

- **O overload de dois arrays não existe** e nunca existiu em `IFluentSQLMergeWhenNotMatched`. Copiar aquela linha dá erro de compilação: `E2034 Too many actual parameters`.
- **A forma de fragmentos produzia SQL que nenhum motor aceita.** `.Update(['T.VALOR = S.VALOR', 'T.DATA = S.DATA'])` emitia `UPDATE SET T.VALOR = S.VALOR = ...`, porque o array sempre foi lido como pares *nome, valor* — o primeiro item virava o nome da coluna e o segundo, o valor. Submetido ao SQL Server 2022, o resultado é `Msg 102, Level 15: Incorrect syntax near '='`.

O array de `.Update` e `.Insert` é, e sempre foi, uma **lista alternada de nome de coluna e valor**. A forma correta está abaixo. Se você copiou o exemplo antigo e ele "não funcionava", o problema não era seu.
:::

## Sintaxe fluente

O array de `.Update` e `.Insert` alterna **nome da coluna** e **valor**: `['COLUNA1', valor1, 'COLUNA2', valor2, ...]`. Os nomes das colunas saem literais (delimitados pelo dialeto); **todos os valores viram parâmetros** `:pN`, recolhidos em `Query.Params`.

```pascal
var
  LQuery: IFluentSQL;
  LMerge: string;
begin
  LQuery := Query(dbnMSSQL);
  LQuery
    .Merge
    .Into('TargetTable', 'T')
    .Using('SourceTable', 'S')
    .On('T.ID = S.ID')
    .WhenMatched
      .Update(['VALOR', 123.45, 'DATA', '2026-08-07'])
    .WhenNotMatched
      .Insert(['ID', 7, 'VALOR', 123.45]);

  LMerge := LQuery.AsString;
  // MERGE INTO [TargetTable] AS [T] USING [SourceTable] AS [S] ON (T.ID = S.ID)
  //   WHEN MATCHED THEN UPDATE SET [VALOR] = :p1, [DATA] = :p2
  //   WHEN NOT MATCHED THEN INSERT ([ID], [VALOR]) VALUES (:p3, :p4);

  // LQuery.Params.Count = 4
end;
```

### E se eu quiser copiar coluna a coluna da fonte, como `T.VALOR = S.VALOR`?

Isso é uma **expressão**, não um valor, e o array de `.Update` não a exprime — foi exatamente essa confusão que produziu o exemplo errado acima. Use `.Update` sem argumentos, que emite o `UPDATE` sem lista de atribuições, ou escreva a atribuição onde o dialeto a aceita. Um `Update(['T.VALOR', 'S.VALOR'])` **não** faz isso — emite `SET T.VALOR = :p1`, com o parâmetro carregando a string literal `'S.VALOR'` como dado, e não a coluna `S.VALOR`.

A distinção entre **valor** e **expressão** nesta API está sob revisão; até lá, trate o array como dados, nunca como SQL.

## Valores são sempre parametrizados

Qualquer valor passado a `.Update` / `.Insert` — inclusive string — vira `:pN`, e o texto original **nunca** aparece no SQL:

```pascal
LQuery.Merge
  .Into('TARGET', 't').Using('SOURCE', 's').On('t.ID = s.ID')
  .WhenMatched.Update(['NOME', 'O''Brien']);

// ... UPDATE SET [NOME] = :p1;      Params[0].Value = O'Brien
```

Isso vale igualmente para valores hostis: um `'1; DROP TABLE USERS; --'` chega ao banco como **dado da coluna**, não como comando. Ver o oráculo em `Test Delphi\Common_tests\test.merge.mssql.sql`, com a medição em motor real antes e depois.

:::warning O nome da coluna não é parametrizado
Nomes de coluna são identificadores e não podem ser *bind parameters*; eles são delimitados pelo dialeto, mas o delimitador interno **ainda não é escapado**. Não monte nome de coluna a partir de entrada não confiável.
:::

:::warning A lista tem de ter contagem par
Um nome sem valor levanta `EArgumentException` na chamada. Antes, emitia `VALUES (:p1, )` ou `SET [NOME] = `, que o motor recusa com `Msg 102`.
:::

## Seções disponíveis

| Método | Descrição |
|--------|-----------|
| **`Into(Table[, Alias])`** | Define a tabela alvo. |
| **`Using(Table[, Alias])`** | Define a tabela fonte. Aceita também um `IFluentSQL` como subconsulta. |
| **`On(Condition)`** | Define o critério de junção. Aceita `string` ou `array of const`. |
| **`WhenMatched`** | Bloco executado quando há correspondência (`UPDATE` ou `DELETE`). |
| **`WhenNotMatched`** | Bloco executado quando **não** há correspondência (`INSERT`). |
| **`.Update`** | `UPDATE` sem lista de atribuições. |
| **`.Update([Nome, Valor, ...])`** | `UPDATE SET` a partir de pares nome/valor. Contagem **par**. |
| **`.Delete`** | `DELETE`, dentro de `WhenMatched`. |
| **`.Insert`** | `INSERT` sem lista de colunas. |
| **`.Insert([Nome, Valor, ...])`** | `INSERT (colunas) VALUES (...)` a partir de pares nome/valor. Contagem **par**. |

Não existe overload de dois arrays. Colunas e valores vão no **mesmo** array, alternados.

## Suporte por dialeto

Apenas o **MSSQL** possui serializador de `MERGE`. Nos demais, a chamada **levanta exceção nomeada** — não emite SQL parcial nem silencioso:

| Dialeto | Estado | O que acontece hoje |
|---------|--------|---------------------|
| **MSSQL** | ✅ Completo | Emite o `MERGE` nativo do SQL Server. |
| **PostgreSQL** | ❌ Não suportado | `EFluentSQLStatementNotSupported`. Mapeamento para `MERGE` (15+) / `INSERT ... ON CONFLICT` planejado. |
| **Oracle** | ❌ Não suportado | `EFluentSQLStatementNotSupported`. Oracle tem `MERGE` nativo; falta o serializador. |
| **MySQL** | ❌ Não suportado | `EFluentSQLStatementNotSupported`. Não há `MERGE` em MySQL; mapeamento para `INSERT ... ON DUPLICATE KEY UPDATE` planejado. |
| **SQLite** | ❌ Não suportado | `EFluentSQLStatementNotSupported`. Não há `MERGE` em SQLite; equivalente é `INSERT ... ON CONFLICT`. |
| **Firebird** | ❌ Não suportado | `EFluentSQLStatementNotSupported`. Firebird tem `MERGE` nativo; falta o serializador. |
| **MongoDB** | ⚠️ Lacuna conhecida | A cláusula é **descartada em silêncio** e a saída é `{}`. Não levanta. |
| **Interbase**, **DB2** | ⚪ Desligados | `EFluentSQLDriverNotRegistered` — desligados por omissão no `FluentSQL.inc`. |

Até a v1.5.1 os cinco dialetos sem serializador não levantavam: entravam em recursão infinita e terminavam em **`EStackOverflow`**, derrubando o processo. Se o seu código captura `EStackOverflow` para tratar isso, troque por `EFluentSQLStatementNotSupported`.

A matriz executável correspondente está em `Test Delphi\Common_tests\test.merge.matrix.pas`.

## Parâmetros

Os parâmetros gerados em `.Update`, `.Insert` e nas cláusulas `Using` / `On` são recolhidos em `Query.Params`:

```pascal
LQuery := Query(dbnMSSQL);
LQuery.Merge
  .Into('PRODUTOS')
  .Using('TEMP_PRODUTOS', 'TMP')
  .On(['PRODUTOS.SKU = TMP.SKU AND TMP.ATIVO =', 1])
  .WhenMatched.Update(['PRECO', 9.99]);

// ON (PRODUTOS.SKU = TMP.SKU AND TMP.ATIVO = :p1) ... SET [PRECO] = :p2
```

:::note `On(array of const)` trata string como fragmento de SQL
Em `On([...])`, escalares numéricos viram parâmetros, mas **strings seguem literais** — é a convenção do restante da biblioteca para `array of const` em posição de expressão. Não passe entrada não confiável ali. Isso difere de `.Update` / `.Insert`, onde o array é de dados e toda string é parametrizada.
:::

## Detalhes técnicos

O `MERGE` usa a Árvore Sintática Abstrata (AST) do FluentSQL para garantir a estrutura antes da serialização. O serializador do MSSQL fica em `Source\Drivers\FluentSQL.SerializeMSSQL.pas` — é o único que sobrescreve `Merge`; a implementação base, em `Source\Core\FluentSQL.Serialize.pas`, levanta `EFluentSQLStatementNotSupported`.
