---
displayed_sidebar: fluentsqlSidebar
title: INSERT, UPDATE e DELETE
---

Fluxos básicos de DML com FluentSQL. Os trechos abaixo espelham asserts dos testes DUnitX em `Test Delphi/Firebird_tests/` (Firebird); o padrão de encadeamento é o mesmo para outros dialetos, mudando apenas o argumento `dbn…`.

## INSERT

### Passos

1. Chame `.Insert`.
2. Indique a tabela com `.Into('NOME_TABELA')`.
3. Para cada coluna, use `.SetValue('COLUNA', valor)`.
4. Finalize com `.AsString`.

### Exemplo (teste `test.insert.firebird.pas`)

```pascal
uses FluentSQL, FluentSQL.Interfaces;

var
  SQL: string;
begin
  SQL := CreateFluentSQL(dbnFirebird)
    .Insert
    .Into('CLIENTES')
    .SetValue('ID_CLIENTE', 1)
    .SetValue('NOME_CLIENTE', 'MyName')
    .AsString;
end;
```

### INSERT em lote (`AddRow`, v1.0.9)

Use **`.AddRow`** após preencher uma linha com **`.SetValue`** para fechá-la e começar a próxima. A **última** linha não precisa de **`AddRow`** antes de **`.AsString`** (a serialização inclui a linha pendente). **`.AddRow`** com a linha corrente **vazia** ou **colunas inconsistentes** entre linhas gera **`EFluentSQLInsertBatch`** — ver [Erros comuns](../troubleshooting/common-errors.md).

Exemplo alinhado a **`TestInsertBatchTwoRowsFirebird`** em `Test Delphi/test.core.params.pas`:

```pascal
uses FluentSQL, FluentSQL.Interfaces;

var
  LQuery: IFluentSQL;
begin
  LQuery := CreateFluentSQL(dbnFirebird)
    .Insert
    .Into('USUARIOS')
    .SetValue('NOME', 'ANA')
    .SetValue('IDADE', 20)
    .AddRow
    .SetValue('NOME', 'BOB')
    .SetValue('IDADE', 21);
  // AsString → INSERT ... VALUES (:p1, :p2), (:p3, :p4)
  // Params: ordem ANA, 20, BOB, 21
end;
```

Com **`dbnMongoDB`**, duas ou mais linhas produzem JSON **`insertMany`** com **`documents`**; uma linha continua com **`insertOne`** (teste `TestMongoDB_Insert_SerializesInsertMany` em `UTestFluentSQLFirebird.pas`).

## UPDATE

### Passos

1. Chame `.Update('NOME_TABELA')`.
2. Use `.SetValue` para os campos a alterar.
3. Opcional: restrinja com `.Where(…)`.
4. Finalize com `.AsString`.

### Exemplo sem WHERE (`test.update.firebird.pas`)

```pascal
uses FluentSQL, FluentSQL.Interfaces;

var
  SQL: string;
  LDate: TDate;
  LDateTime: TDateTime;
begin
  LDate := EncodeDate(2021, 12, 31);
  LDateTime := EncodeDate(2021, 12, 31) + EncodeTime(23, 59, 59, 0);
  SQL := CreateFluentSQL(dbnFirebird)
    .Update('CLIENTES')
    .SetValue('ID_CLIENTE', '1')
    .SetValue('NOME_CLIENTE', 'MyName')
    .SetValue('DATA_CADASTRO', LDate)
    .SetValue('DATA_ALTERACAO', LDateTime)
    .AsString;
end;
```

### Exemplo com WHERE

```pascal
SQL := CreateFluentSQL(dbnFirebird)
  .Update('CLIENTES')
  .SetValue('ID_CLIENTE', 1)
  .SetValue('NOME_CLIENTE', 'MyName')
  .Where('ID_CLIENTE = 1')
  .AsString;
```

## DELETE

### Passos

1. Chame `.Delete`.
2. Indique a tabela com `.From('NOME_TABELA')`.
3. Opcional: `.Where(…)`.
4. Finalize com `.AsString`.

### Exemplo sem filtro (`test.delete.firebird.pas`)

```pascal
SQL := CreateFluentSQL(dbnFirebird)
  .Delete
  .From('CLIENTES')
  .AsString;
```

### Exemplo com WHERE

```pascal
SQL := CreateFluentSQL(dbnFirebird)
  .Delete
  .From('CLIENTES')
  .Where('ID_CLIENTE = 1')
  .AsString;
```

## Lembrete

O FluentSQL gera **texto SQL** e expõe **parâmetros** quando aplicável; a execução no banco fica a cargo do seu componente de acesso (FireDAC, UniDAC, etc.), usando `Params` na ordem dos placeholders.
