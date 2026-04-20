---
displayed_sidebar: fluentsqlSidebar
title: Tests
---

> **Release alignment:** examples and issue pointers below are reconciled with **`CHANGELOG.md`** and tag **v1.5.1** (2026-04-20).

## Estratégia

- **Unitários:** DUnitX, com foco em serialização, construção da AST e regras por dialeto.
- **Regressão:** cenários adicionados na **v0.2.0** cobrem **parâmetros nos dois lados** de operações de conjunto (Firebird e MySQL), conforme `CHANGELOG.md` e a issue [#11](https://github.com/ModernDelphiWorks/FluentSQL/issues/11).
- **Arquitetura de Testes (v1.5.1):** modularização completa (ESP-079). As unidades de teste foram movidas da raiz de `Test Delphi/` para subpastas por driver, seguindo o padrão `Test Delphi/<DB>_tests/test.<feature>.<driver>.pas`.
- **Parametrização:** o fixture **`Test Delphi/test.core.params.pas`** (agora modularizado) valida placeholders e `Params`. Na **v1.0.3** (**ESP-009**): `IN`/`NOT IN` com listas. Na **v1.0.4** (**ESP-010**): `array of const` parametrizado. Na **v1.5.1** (**ESP-079**): parametrização total no MERGE DML (`Update` / `Insert`).
- **MongoDB (DML):** suporte a agregações (**ESP-067**) e joins (**ESP-068**).
- **DDL (v1.1.x a v1.5.1):** suporte a Schemas (Fase 5). Testes organizados em suas pastas de driver correspondentes.

## Como executar

No Windows, compile com o `dcc32` do seu RAD Studio os projetos em `Test Delphi/<DB>_tests/` (ajuste o caminho da instalação).

| Projeto | Pasta |
|---------|--------|
| Suíte principal Firebird | `Firebird_tests/PTestFluentSQLFirebird.dpr` |
| Suíte MSSQL | `MSSQL_tests/TestFluentSQL_MSSQL.dpr` |
| Suíte MySQL | `MySQL_tests/TestFluentSQL_MySQL.dpr` |
| Outros dialetos | `PostgreSQL_tests/`, `Oracle_tests/`, `SQLite_tests/`, etc. |

Após compilar, execute o `.exe` gerado com `CI=1` no ambiente se quiser saída estável nos relatórios DUnitX. Cada driver pode ser testado de forma isolada (RN-002).

## Cobertura esperada

- Novos recursos devem incluir testes em **múltiplos dialetos** quando possível, dentro de suas respectivas pastas de driver em `Test Delphi/`.
- Para mudanças em **parâmetros + conjunto**, mantenha casos com placeholders na query principal **e** na subquery unida.
