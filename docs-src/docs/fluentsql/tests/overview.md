---
displayed_sidebar: fluentsqlSidebar
title: Testes
---

## Estratégia

- **Unitários:** DUnitX, com foco em serialização, construção da AST e regras por dialeto.
- **Regressão:** cenários adicionados na **v0.2.0** cobrem **parâmetros nos dois lados** de operações de conjunto (Firebird e MySQL), conforme `CHANGELOG.md` e a issue [#11](https://github.com/ModernDelphiWorks/FluentSQL/issues/11).
- **Parametrização:** o fixture **`Test Delphi/test.core.params.pas`** valida placeholders e `Params` (Firebird `:pN`, MySQL `?`, cenários PostgreSQL no runner Firebird) e está referenciado em `PTestFluentSQLFirebird.dpr` e `TestFluentSQL_MySQL.dpr`. Na **v1.0.3** (**ESP-009**): `IN`/`NOT IN` com listas — [#19](https://github.com/ModernDelphiWorks/FluentSQL/issues/19). Na **v1.0.4** (**ESP-010**): `Where`/`Having`/`Values`/`CASE WHEN` com `array of const` — [#21](https://github.com/ModernDelphiWorks/FluentSQL/issues/21); caveats [#22](https://github.com/ModernDelphiWorks/FluentSQL/issues/22). Na **v1.0.5** (**ESP-011**): `Where(Q.Expression([...]))` e cadeia com `AndOpe` no MySQL — [#23](https://github.com/ModernDelphiWorks/FluentSQL/issues/23); caveats [#24](https://github.com/ModernDelphiWorks/FluentSQL/issues/24). Na **v1.0.6** (**ESP-012**): `Column` com `array of const` (`TestColumnArrayOfConstFirebird`, `TestColumnArrayOfConstMySQL`) — [#25](https://github.com/ModernDelphiWorks/FluentSQL/issues/25); dívida [#26](https://github.com/ModernDelphiWorks/FluentSQL/issues/26). Na **v1.0.7** (**ESP-013**): `CaseExpr` com `array of const` (`TestCaseExprArrayOfConstFirebird`, `TestCaseExprArrayOfConstMySQL`) — [#27](https://github.com/ModernDelphiWorks/FluentSQL/issues/27); dívida [#28](https://github.com/ModernDelphiWorks/FluentSQL/issues/28). Na **v1.0.9** (**ESP-015**): INSERT em lote com `AddRow` (`TestInsertBatchTwoRowsFirebird`, `TestInsertBatchTwoRowsMySQL`) — [#31](https://github.com/ModernDelphiWorks/FluentSQL/issues/31); dívida [#32](https://github.com/ModernDelphiWorks/FluentSQL/issues/32).
- **MongoDB (DML):** cenários em **`Firebird_tests/UTestFluentSQLFirebird.pas`** (`TestMongoDB_Insert_SerializesInsertOne`, **`TestMongoDB_Insert_SerializesInsertMany`**, update/delete), alinhados a **ESP-014** / **ESP-015** e `CHANGELOG` **[1.0.8]** / **[1.0.9]**.

## Como executar

No Windows, compile com o `dcc32` do seu RAD Studio os projetos em `Test Delphi/` (ajuste o caminho da instalação). Lista alinhada ao **README** do repositório:

| Projeto | Pasta |
|---------|--------|
| Suíte principal DUnitX | `Firebird_tests/PTestFluentSQLFirebird.dpr` |
| Amostra mínima | `Firebird_tests/PTestFluentSQLSample.dpr` |
| Por dialeto | `MSSQL_tests/TestFluentSQL_MSSQL.dpr`, `MySQL_tests/TestFluentSQL_MySQL.dpr`, `Oracle_tests/TestFluentSQL_Oracle.dpr`, `DB2_tests/TestFluentSQL_DB2.dpr`, `Interbase_tests/TestFluentSQL_Interbase.dpr` |

Após compilar, execute o `.exe` gerado com `CI=1` no ambiente se quiser saída estável nos relatórios DUnitX. Nota: em alguns dialetos, o registo em runtime do serializer depende de **defines** de compilação nos `.dpr` (ver [Erros comuns](../troubleshooting/common-errors.md)).

## Cobertura esperada

- Novos recursos devem incluir testes em **múltiplos dialetos** quando possível (diretriz do projeto: sugerido Firebird, MSSQL, MySQL em `.claude/references/conventions.md`).
- Para mudanças em **parâmetros + conjunto**, mantenha casos com placeholders na query principal **e** na subquery unida.
